import { NativeModules, NativeEventEmitter } from "react-native";
import { Instance as WasmInstance } from "./Instance";

const { Wasm } = NativeModules;
const eventEmitter = new NativeEventEmitter(Wasm);

const instantiate = (buffer) =>
  new Promise((resolve, reject) => {
    let id = "";
    const subResolve = eventEmitter.addListener("resolve", (keys) => {
      subResolve.remove();
      if (!id || !keys) {
        reject("failed to instantiate WebAssembly");
      }
      resolve({
        instance: new WasmInstance(id, keys),
        module: {
          // TODO
        },
      });
    });

    Wasm.instantiate(buffer.toString())
      .then((res) => {
        if (!res) {
          subResolve.remove();
          reject("failed to instantiate WebAssembly");
        } else {
          id = res;
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
  // Do not support because `FileReader.readAsArrayBuffer` is not supported by React Native currently.
  // instantiateStreaming: (response, importObject) =>
  //   Promise.resolve(response.arrayBuffer()).then((bytes) =>
  //     instantiate(bytes)
  //   ),
  compile: (bytes) => {},
  // Do not support because `FileReader.readAsArrayBuffer` is not supported by React Native currently.
  // compileStreaming: () => {},
  validate: () => true,
  Instance: () => {},
  Module: () => {},
  Memory: () => {},
  Table: () => {},
};
