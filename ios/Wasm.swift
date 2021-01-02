import Foundation
import WebKit

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
        
        let js: String = """
        var generateId = function () {
          return new Date().getTime().toString(16) + Math.floor(1000 * Math.random()).toString(16);
        }
        var wasm = {};
        var promise = {};
        function instantiate(bytes){
          var id = generateId();
          promise[id] = WebAssembly.instantiate(Uint8Array.from(bytes))
            .then(function(res){
              delete promise[id];
              wasm[id] = res;
              window.webkit.messageHandlers.resolve.postMessage(JSON.stringify({id: id, keys: Object.keys(wasm.instance.exports)}));
            }).catch(function(e){
              delete promise[id];
              // TODO handle error
            });
          return true;
        }
        """
    }
    
    @objc
    override static func requiresMainQueueSetup() -> Bool {
      return true
    }
    
    @objc
    func instantiate(_ bytes: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("instantiate([\(bytes)]);") { (value, error) in
                if error {
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
        let js: String = """
        (function(){
          return wasm[\(modId)].instance.exports.\(name)(...\(args));
        })();
        """
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js) { (value, error) in
                // TODO handle error
                result = value as! NSNumber ?? 0
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
