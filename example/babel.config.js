const path = require("path");
const pak = require("../package.json");
const source = "src/index";

module.exports = {
  presets: ["module:metro-react-native-babel-preset"],
  plugins: [
    [
      "module-resolver",
      {
        extensions: [".tsx", ".ts", ".js", ".json"],
        alias: {
          [pak.name]: path.join(__dirname, "..", source),
        },
      },
    ],
  ],
};
