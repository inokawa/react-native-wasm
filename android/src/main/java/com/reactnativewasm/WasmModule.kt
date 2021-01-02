package com.reactnativewasm

import android.webkit.JavascriptInterface
import android.webkit.WebView
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter

const val js: String = """
var wasm = {};
var promise = {};
function instantiate(id, bytes){
  promise[id] = WebAssembly.instantiate(Uint8Array.from(bytes))
    .then(function(res){
      delete promise[id];
      wasm[id] = res;
      android.resolve(JSON.stringify(Object.keys(res.instance.exports)));
    }).catch(function(e){
      delete promise[id];
      // TODO handle error
    });
  return true;
}
"""

class WasmModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private val context: ReactContext = reactContext
    private val webView: WebView;

    init {
        this.webView = WebView(reactContext.getApplicationContext());
        this.webView.settings.javaScriptEnabled = true
        this.webView.addJavascriptInterface(this, "android");
        this.webView.loadUrl("javascript:" + js)
    }

    override fun getName(): String {
        return "Wasm"
    }

    @ReactMethod
    fun instantiate(id: String, bytes: String, promise: Promise) {
        this.webView.loadUrl("""
            javascript:instantiate("$id", [$bytes]);
            """)
        // TODO handle error
        promise.resolve(true)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun callSync(id: String, name: String, args: String, promise: Promise) {
        this.webView.loadUrl("""
            javascript:wasm["$id"].instance.exports.$name(...$args);
            """)
        // TODO return value synchronously
        // TODO handle error
        promise.resolve(true)
    }

    private fun sendEvent(reactContext: ReactContext, eventName: String, params: String?) {
        reactContext
                .getJSModule(RCTDeviceEventEmitter::class.java)
                .emit(eventName, params)
    }

    @JavascriptInterface
    fun resolve(data: String?) {
        sendEvent(this.context, "resolve", data);
    }
}
