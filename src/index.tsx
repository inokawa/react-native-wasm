import { NativeModules } from 'react-native';

type WasmType = {
  multiply(a: number, b: number): Promise<number>;
};

const { Wasm } = NativeModules;

export default Wasm as WasmType;
