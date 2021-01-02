import { NativeModules, NativeEventEmitter } from "react-native";
import { Instance as WasmInstance } from "./Instance";

const { Wasm } = NativeModules;
const eventEmitter = new NativeEventEmitter(Wasm);

const instantiate = (buffer) =>
  new Promise((resolve, reject) => {
    const subResolve = eventEmitter.addListener("resolve", (res) => {
      subResolve.remove();
      try {
        const { id, keys } = JSON.parse(res);
        resolve({
          instance: new WasmInstance(id, keys),
          module: {
            // TODO
          },
        });
      } catch (e) {
        reject(e);
      }
    });

    Wasm.instantiate(buffer.toString())
      .then((res) => {
        if (!res) {
          subResolve.remove();
          reject("failed to instantiate WebAssembly");
        }
      })
      .catch((e) => {
        subResolve.remove();
        reject(e);
      });
  });

export const WebAssembly = {
  instantiate: (buffer, importObject) => {
    return instantiate(buffer);
  },
  // `instantiateStreaming` do not work because `FileReader.readAsArrayBuffer` is not supported by React Native currently.
  // instantiateStreaming: (response, importObject) =>
  //   Promise.resolve(response.arrayBuffer()).then((bytes) =>
  //     instantiate(bytes)
  //   ),
  compile: (bytes) => {},
  compileStreaming: () => {},
  validate: () => true,
  Instance: WasmInstance,
  Module: () => {},
  Memory: () => {},
  Table: () => {},
};
