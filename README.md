# react-native-wasm

![npm](https://img.shields.io/npm/v/react-native-wasm)

A polyfill to use [WebAssembly](https://webassembly.org/) in [React Native](https://github.com/facebook/react-native).

This package instantiates WebAssembly in a native WebView environment and makes the communication with React Native to simulate original behavior.
Native module of React Native has limited argument types ([iOS](https://reactnative.dev/docs/native-modules-ios#argument-types)/[Android](https://reactnative.dev/docs/native-modules-android#argument-types)) so we need to serialize/deserialize the exchanged data, which may have some overhead but will work as in a web app.

### ⚠️ Note

I recommend using [react-native-react-bridge](https://github.com/inokawa/react-native-react-bridge) rather than this to run WebAssembly. Although its aim is a bit different, it's built on WebView like this and it's working much more stably.

And also check the current progress of wasm support in React Native:

- https://github.com/react-native-community/jsc-android-buildscripts/issues/113
- https://github.com/facebook/hermes/issues/429

## Install

```sh
npm install react-native-wasm

# <=0.59 you have to link manually.
react-native link react-native-wasm

# In iOS
cd ios && pod install
```

And currently you have to create bridging header manually in iOS.

https://reactnative.dev/docs/native-modules-ios#exporting-swift

> Important when making third party modules: Static libraries with Swift are only supported in Xcode 9 and later. In order for the Xcode project to build when you use Swift in the iOS static library you include in the module, your main app project must contain Swift code and a bridging header itself. If your app project does not contain any Swift code, a workaround can be a single empty .swift file and an empty bridging header.

### Requirements

- react-native 0.59+ (because of [Proxy](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Proxy) support in React Native)

## Usage

```javascript
// index.js
import { AppRegistry } from "react-native";
import "react-native-wasm";
...

AppRegistry.registerComponent(appName, () => App);

// Foo.js
const buffer = Uint8Array.from([
	 0x00,0x61,0x73,0x6D,0x01,0x00,0x00,0x00
	,0x01,0x87,0x80,0x80,0x80,0x00,0x01,0x60
	,0x02,0x7F,0x7F,0x01,0x7F,0x03,0x82,0x80
	,0x80,0x80,0x00,0x01,0x00,0x07,0x87,0x80
	,0x80,0x80,0x00,0x01,0x03,0x61,0x64,0x64
	,0x00,0x00,0x0A,0x8D,0x80,0x80,0x80,0x00
	,0x01,0x87,0x80,0x80,0x80,0x00,0x00,0x20
	,0x00,0x20,0x01,0x6A,0x0B]);

WebAssembly.instantiate(buffer).then((res) => {
  console.log(res.instance.exports.add(3, 5)); // 8
});
```

## TODOs

- [x] instantiate
  - [x] Support iOS
  - [x] Support Android
  - [ ] Support importObject
- [ ] compile
- [ ] validate
- [ ] WebAssembly.Instance
- [ ] WebAssembly.Module
- [ ] WebAssembly.Memory
- [ ] WebAssembly.Table
- [ ] Support bundling .wasm file
