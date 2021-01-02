import { Platform } from "react-native";
import { WebAssembly as WasmPolyfill } from "./WebAssembly";

if (Platform.OS === "ios") {
  window.WebAssembly = window.WebAssembly || WasmPolyfill;
}
