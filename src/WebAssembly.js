import { NativeModules } from "react-native";
import { Instance as WasmInstance } from "./Instance";

const { Wasm } = NativeModules;

const generateId = () => {
  return (
    new Date().getTime().toString(16) +
    Math.floor(1000 * Math.random()).toString(16)
  );
};

const instantiate = (buffer) =>
  new Promise((resolve, reject) => {
    const id = generateId();

    Wasm.instantiate(id, buffer.toString())
      .then((keys) => {
        if (!keys) {
          reject("failed to get exports");
        } else {
          resolve({
            instance: new WasmInstance(id, keys),
            module: {
              // TODO
            },
          });
        }
      })
      .catch((e) => {
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
