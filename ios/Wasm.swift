import Foundation
import WebKit

let js: String = """
var wasm = {};
function instantiate(id, bytes){
  var wasmModule = new WebAssembly.Module(Uint8Array.from(bytes));
  var instance = new WebAssembly.Instance(wasmModule);
  wasm[id] = instance;
  return JSON.stringify(Object.keys(instance.exports));
}
"""

@objc(Wasm)
class Wasm: NSObject {
    
    var webView: WKWebView!
    
    static func requiresMainQueueSetup() -> Bool {
        return true
    }
    
    override init() {
        super.init()
        let webCfg: WKWebViewConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webCfg)
        
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript(js) { (value, error) in
                // NOP
            }
        }
    }
    
    @objc
    func instantiate(_ modId: NSString, bytesStr bytes: NSString, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) -> Void {        
        DispatchQueue.main.async {
            self.webView.evaluateJavaScript("""
            instantiate("\(modId)", [\(bytes)]);
            """
            ) { (value, error) in
                if error != nil {
                    reject("error", "\(error)", nil)
                } else {
                    resolve(value)
                }
            }
        }
    }
    
    @objc @discardableResult
    func callSync(_ modId: NSString, funcName name: NSString, arguments args: NSString) -> NSNumber {
        var result: NSNumber = 0
        let semaphore = DispatchSemaphore(value: 0)
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
                semaphore.signal()
            }
        }
        
        semaphore.wait()
        return result
    }
}

