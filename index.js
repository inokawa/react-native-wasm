import {
  NativeModules,
  NativeEventEmitter,
  Platform,
  Image,
} from "react-native";

const { resolveAssetSource } = Image;

export const resolveWasm = (w) => resolveAssetSource(w).uri;

const { Wasm } = NativeModules;
const eventEmitter = new NativeEventEmitter(Wasm);

if (Platform.OS === "ios") {
  const instantiate = (bytes) =>
    new Promise((resolve, reject) => {
      const subscription = eventEmitter.addListener(
        "wasmResolved",
        (methodNames) => {
          subscription.remove();
          resolve({
            instance: {
              exports: JSON.parse(methodNames).reduce((acc, k) => {
                acc[k] = (...args) => Wasm.call(k, JSON.stringify(args));
                return acc;
              }, {}),
            },
            module: {},
          });
        }
      );

      Wasm.instantiate(bytes.toString())
        .then((res) => {
          if (!res) {
            subscription.remove();
            reject("failed to contact to webview");
          }
        })
        .catch((e) => {
          subscription.remove();
          reject(e);
        });
    });

  window.WebAssembly = {
    instantiate: (bytes, importObject) => instantiate(bytes),
    instantiateStreaming: (response, importObject) =>
      Promise.resolve(response.arrayBuffer()).then((bytes) =>
        instantiate(bytes)
      ),
    compile: (bytes) => {},
    compileStreaming: () => {},
    validate: () => true,
  };
}
