import { NativeModules } from "react-native";
const { Wasm } = NativeModules;

export class Instance {
  _exports;
  constructor(id, keys) {
    this._exports = JSON.parse(keys).reduce((acc, k) => {
      acc[k] = (...args) => Wasm.call(id, k, JSON.stringify(args));
      return acc;
    }, {});
  }
  get exports() {
    return this._exports;
  }
}
