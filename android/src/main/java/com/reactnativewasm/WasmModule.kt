package com.reactnativewasm

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.webkit.JavascriptInterface
import android.webkit.ValueCallback
import android.webkit.WebView
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import java.util.concurrent.CountDownLatch


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
    lateinit var webView: WebView;

    protected class JSHandler internal constructor(c: WasmModule) {
        var ctx: WasmModule

        init {
            ctx = c
        }

        @JavascriptInterface
        fun resolve(data: String?) {
            ctx.sendEvent("resolve", data);
        }
    }

    init {
        val self = this;
        Handler(Looper.getMainLooper()).post(object : Runnable {
            @RequiresApi(Build.VERSION_CODES.KITKAT)
            override fun run() {
                webView = WebView(context);
                webView.settings.javaScriptEnabled = true
                webView.addJavascriptInterface(JSHandler(self), "android")
                webView.evaluateJavascript("javascript:" + js, ValueCallback<String> { reply -> // NOP
                })
            }
        });
    }

    override fun getName(): String {
        return "Wasm"
    }

    @ReactMethod
    fun instantiate(id: String, bytes: String, promise: Promise) {
        Handler(Looper.getMainLooper()).post(object : Runnable {
            @RequiresApi(Build.VERSION_CODES.KITKAT)
            override fun run() {
                webView.evaluateJavascript("""
                    javascript:instantiate("$id", [$bytes]);
                    """, ValueCallback<String> { value ->
                    {
                        // TODO handle error
                        if (value == null) {
                            promise.reject("error")
                        } else {
                            promise.resolve(true)
                        }
                    }
                })
            }
        });
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun callSync(id: String, name: String, args: String): Int {
        var result: Int = 0
        val latch = CountDownLatch(1)
        Handler(Looper.getMainLooper()).post(object : Runnable {
            @RequiresApi(Build.VERSION_CODES.KITKAT)
            override fun run() {
                webView.evaluateJavascript("""
                    javascript:wasm["$id"].instance.exports.$name(...$args);
                    """, ValueCallback<String> { value ->
                    {
                        // TODO handle error
                        if (value == null) {
                            result = 0
                        } else {
                            result = value as Int
                        }
                        latch.countDown();
                    }
                })
            }
        });

        latch.await()
        return result
    }

    fun sendEvent(eventName: String, params: String?) {
        context.getJSModule(RCTDeviceEventEmitter::class.java)
                .emit(eventName, params)
    }
}
