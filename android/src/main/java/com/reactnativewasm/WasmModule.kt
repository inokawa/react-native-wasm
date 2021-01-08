package com.reactnativewasm

import android.os.Build
import android.os.Handler
import android.os.Looper
import android.webkit.JavascriptInterface
import android.webkit.ValueCallback
import android.webkit.WebView
import androidx.annotation.RequiresApi
import com.facebook.react.bridge.*
import java.util.concurrent.CountDownLatch
import kotlin.collections.HashMap


const val js: String = """
var wasm = {};
var promise = {};
function instantiate(id, bytes){
  promise[id] = WebAssembly.instantiate(Uint8Array.from(bytes))
    .then(function(res){
      delete promise[id];
      wasm[id] = res;
      android.resolve(id, JSON.stringify(Object.keys(res.instance.exports)));
    }).catch(function(e){
      delete promise[id];
      android.reject(id, e.toString());
    });
  return true;
}
"""

class WasmModule(reactContext: ReactApplicationContext) : ReactContextBaseJavaModule(reactContext) {

    private val context: ReactContext = reactContext
    lateinit var webView: WebView;
    val asyncPool = HashMap<String, Promise>()
    val syncPool = HashMap<String, CountDownLatch>()
    val syncResults = HashMap<String, Double>()

    init {
        val self = this;
        Handler(Looper.getMainLooper()).post(object : Runnable {
            @RequiresApi(Build.VERSION_CODES.KITKAT)
            override fun run() {
                webView = WebView(context);
                webView.settings.javaScriptEnabled = true
                webView.addJavascriptInterface(JSHandler(self, asyncPool, syncPool, syncResults), "android")
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
        asyncPool[id] = promise

        Handler(Looper.getMainLooper()).post(object : Runnable {
            @RequiresApi(Build.VERSION_CODES.KITKAT)
            override fun run() {
                webView.evaluateJavascript("""
                    javascript:instantiate("$id", [$bytes]);
                    """, ValueCallback<String> { value ->
                    {
                        if (value == null) {
                            asyncPool.remove(id)
                            promise.reject("failed to instantiate")
                        }
                    }
                })
            }
        });
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun callSync(id: String, name: String, args: String): Double {
        val latch = CountDownLatch(1)
        syncPool[id] = latch

        Handler(context.getMainLooper()).post(object : Runnable {
            @RequiresApi(Build.VERSION_CODES.KITKAT)
            override fun run() {
                webView.evaluateJavascript("""
                    javascript:android.returnSync("$id", wasm["$id"].instance.exports.$name(...$args));
                    """, ValueCallback<String> { value ->
                    {
                        // NOP
                    }
                })
            }
        });

        latch.await()
        val result = syncResults[id]
        syncResults.remove(id)
        return result ?: 0.0
    }

    protected class JSHandler internal constructor(ctx: WasmModule, asyncPool: HashMap<String, Promise>, syncPool: HashMap<String, CountDownLatch>, syncResults: HashMap<String, Double>) {
        val ctx: WasmModule = ctx
        val asyncPool: HashMap<String, Promise> = asyncPool
        val syncPool: HashMap<String, CountDownLatch> = syncPool
        val syncResults: HashMap<String, Double> = syncResults

        @JavascriptInterface
        fun resolve(id: String, data: String) {
            val p = asyncPool[id]
            if (p != null) {
                asyncPool.remove(id)
                p.resolve(data)
            }
        }

        @JavascriptInterface
        fun reject(id: String, data: String) {
            val p = asyncPool[id]
            if (p != null) {
                asyncPool.remove(id)
                p.reject(data)
            }
        }

        @JavascriptInterface
        fun returnSync(id: String, data: Double) {
            val l = syncPool[id]
            if (l != null) {
                syncPool.remove(id)
                syncResults[id] = data
                l.countDown()
            }
        }
    }
}
