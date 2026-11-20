# Android 构建说明

## wasm_run 原生库（libwasm_run_dart.so）

grain_video 的扩展系统基于 WASM 插件（grain_plugins），运行时依赖 pub 包
`wasm_run` 执行 WASM。wasm_run 通过 flutter_rust_bridge 的 ffi 加载原生库，
pub.dev 只发布 Windows 的预编译 `wasm_run_dart.dll`（Windows 端零配置），
Android 没有预编译产物，需要自己用 NDK clang 交叉编译。

Android 上 wasm_run 的加载顺序（`lib/src/ffi/io.dart`）：

1. 环境变量指定的路径
2. `DynamicLibrary.open('wasm_run_dart')` —— 裸库名，Android 解析为
   `System.loadLibrary`，从 APK 的 `lib/<abi>/libwasm_run_dart.so` 加载
3. `.dart_tool` / localTesting 路径

因此把 so 按 ABI 放进 `app/src/main/jniLibs/` 即可命中，无需改任何 Dart/宿主代码。

### 构建

要求：Rust（已装 `aarch64-linux-android` / `x86_64-linux-android` target）、
NDK `27.0.12077973`（与 `app/build.gradle.kts` 的 ndkVersion 一致，可用
`NDK_HOME` 环境变量覆盖）、Windows Git Bash。

```bash
bash android/build_wasm_run_so.sh
```

脚本把 pub 缓存里的 `wasm_run-0.1.0+2` 整包拷到临时目录（frb 1.82.x 的
build.rs 要求所在 Dart 项目根有 `pubspec.lock`，整包拷贝正好满足它以及
`lib/src/bridge_generated*.dart` 等全部相对路径约定），然后用 NDK 的
`android21` clang 包装器交叉编译两个 ABI（minSdk 21）：

- `aarch64-linux-android` → `arm64-v8a`（真机）
- `x86_64-linux-android` → `x86_64`（模拟器）

首次构建需下载 wasmtime 14 / frb codegen 等依赖，单 ABI 约 5~15 分钟。

### 产物

```
android/app/src/main/jniLibs/arm64-v8a/libwasm_run_dart.so
android/app/src/main/jniLibs/x86_64/libwasm_run_dart.so
```

so 单 ABI 约 20MB（wasmtime 静态链接），两个 ABI 使 debug APK 增重约 40MB。
该目录已加入 `.gitignore`（大体积二进制不入库），首次构建须跑上述脚本。

验证 so 是否打进 APK：

```bash
unzip -l build/app/outputs/flutter-apk/app-debug.apk | grep wasm_run
```

### 与 Windows 的关系

Windows 桌面端继续用 pub 缓存自带/工程目录的 `wasm_run_dart.dll`，与本目录
下的 Android so 互不影响；两条链路共用同一份 wasm_run Dart 源码与 API。
