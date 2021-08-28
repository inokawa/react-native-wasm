package com.reactnativewasm;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;

public class WasmModule extends ReactContextBaseJavaModule {
    public static final String NAME = "Wasm";

    public WasmModule(ReactApplicationContext reactContext) {
      super(reactContext);
    }

    static {
      System.loadLibrary("example");
    }

    private static native void setup(long jsiPtr);
    private static native void cleanUp();

    @NonNull
    @Override
    public String getName() {
      return NAME;
    }

    @NonNull
    @Override
    public void initialize() {
      super.initialize();

      WasmModule.setup(this.getReactApplicationContext().getJavaScriptContextHolder().get());
    }

    @Override
    public void onCatalystInstanceDestroy() {
      WasmModule.cleanUp();
    }
}
