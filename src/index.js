import { Platform } from "react-native";
import { WebAssembly as WasmPolyfill } from "./WebAssembly";

if (Platform.OS === "ios" || Platform.OS === "android") {
  window.WebAssembly = window.WebAssembly || WasmPolyfill;
}
