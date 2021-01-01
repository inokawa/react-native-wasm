import Foundation
import WebKit

@objc(Wasm)
class Wasm: RCTEventEmitter, WKScriptMessageHandler {
    
    var webView: WKWebView!
    
    override init() {
        super.init()
        let webCfg: WKWebViewConfiguration = WKWebViewConfiguration()
        
        let userController: WKUserContentController = WKUserContentController()
        userController.add(self, name: "wasmResolved")
        webCfg.userContentController = userController
        
        webView = WKWebView(frame: .zero, configuration: webCfg)
        
        let js: String = """
        var wasm;
        var promise;
        function instantiate(bytes){
          promise = WebAssembly.instantiate(Uint8Array.from(bytes));
          promise.then(function(res){
            wasm = res;
            window.webkit.messageHandlers.wasmResolved.postMessage(JSON.stringify(Object.keys(wasm.instance.exports)));
          }).catch(function(e){
            // TODO
          })
          return true;
        }
        """
    }
    
    @objc
    func instantiate(_ bytes: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("instantiate([\(bytes)]);") { (value, error) in
                if error {
                    return reject(error)
                }
                resolve(value)
            }
        }
    }

    @objc @discardableResult
    func call(_ name: NSString, arguments args: NSString) -> NSNumber {
        var result: NSNumber = 0
        var isCompletion: Bool = false
        let js: String = """
        (function(){
          return wasm.instance.exports.\(name)(...\(args));
        })();
        """
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js) { (value, error) in
                result = value as! NSNumber ?? 0
                isCompletion = true
            }
        }

        while !isCompletion { RunLoop.current.run(mode: .default, before: Date() + 0.25) }
        return result
    }
    
    override func supportedEvents() -> [String]! {
        return ["wasmResolved"]
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if(message.name == "wasmResolved") {
            sendEvent(withName: "wasmResolved", body: message.body)
        }
    }
}
