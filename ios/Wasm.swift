import Foundation
import WebKit

let js: String = """
var wasm = {};
var promise = {};
function instantiate(id, bytes){
  promise[id] = WebAssembly.instantiate(Uint8Array.from(bytes))
    .then(function(res){
      delete promise[id];
      wasm[id] = res;
      window.webkit.messageHandlers.resolve.postMessage(JSON.stringify(Object.keys(res.instance.exports)));
    }).catch(function(e){
      delete promise[id];
      // TODO handle error
    });
  return true;
}
"""

@objc(Wasm)
class Wasm: RCTEventEmitter, WKScriptMessageHandler {
    
    var webView: WKWebView!
    
    override init() {
        super.init()
        let webCfg: WKWebViewConfiguration = WKWebViewConfiguration()
        
        let userController: WKUserContentController = WKUserContentController()
        userController.add(self, name: "resolve")
        webCfg.userContentController = userController
        
        webView = WKWebView(frame: .zero, configuration: webCfg)
        
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js) { (value, error) in
                // NOP
            }
        }
    }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    @objc
    func instantiate(_ modId: NSString, bytesStr bytes: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("""
            instantiate("\(modId)", [\(bytes)]);
            """
            ) { (value, error) in
                if error != nil {
                    return reject("error", "failed to instantiate", error)
                }
                resolve(value)
            }
        }
    }
    
    @objc @discardableResult
    func call(_ modId: NSString, funcName name: NSString, arguments args: NSString) -> NSNumber {
        var result: NSNumber = 0
        var isCompletion: Bool = false
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("""
            wasm["\(modId)"].instance.exports.\(name)(...\(args));
            """
            ) { (value, error) in
                // TODO handle error
                if value == nil {
                    result = 0
                } else {
                    result = value as! NSNumber
                }
                isCompletion = true
            }
        }
        
        while !isCompletion { RunLoop.current.run(mode: .default, before: Date() + 0.25) }
        return result
    }
    
    override func supportedEvents() -> [String]! {
        return ["resolve"]
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "resolve") {
            sendEvent(withName: "resolve", body: message.body)
        }
    }
}
