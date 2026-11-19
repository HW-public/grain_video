# 扩展引擎内置 js

CryptoJS.min.js / jsencrypt.min.js / md5.min.js：扩展引擎前导（preamble）注入用，
由 `lib/extension/engine.dart` 通过 rootBundle 读入后拼进 JS 运行时 eval。
文件内容原样拷贝自旧实现资产，未做改动。
