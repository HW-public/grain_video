#!/usr/bin/env bash
# build_wasm_run_so.sh — 交叉编译 wasm_run 的 Android 原生库 libwasm_run_dart.so
#
# 背景：wasm_run 通过 flutter_rust_bridge 的 ffi 加载原生库。Android 上
# createLibraryImpl 回退到 DynamicLibrary.open('wasm_run_dart')（裸名 ->
# System.loadLibrary），因此把 so 按 ABI 放进 jniLibs 即可命中。
# pub.dev 只发布 Windows 的预编译 dll，Android 需要用 NDK clang 自行交叉编译。
#
# 用法（Windows Git Bash）：
#   bash android/build_wasm_run_so.sh
# 产物（不入 git）：
#   android/app/src/main/jniLibs/arm64-v8a/libwasm_run_dart.so
#   android/app/src/main/jniLibs/x86_64/libwasm_run_dart.so
#
# 说明：
# - wasm_run 的 native/ 是 frb 1.82.x 的 build.rs，要求所在 Dart 项目根有
#   pubspec.lock（frb_codegen 会解析它）。所以把整个 pub 缓存包拷到临时目录
#   直接构建（包根自带 pubspec.yaml + pubspec.lock + lib/src/bridge_generated*.dart，
#   正好满足 build.rs 的全部相对路径约定）。
# - 首次构建需下载 wasmtime 14 / frb codegen 等依赖，单 ABI 约 5~15 分钟。
# - frb 1.82.x 的 build.rs 会调用 Dart 的 ffigen，ffigen 需要 libclang.dll。
#   ffigen 只从两处默认位置找：C:\Program Files\LLVM\bin 与
#   %USERPROFILE%\scoop\apps\llvm\current\bin。本机做法是解包官方
#   LLVM-18.1.8-win64.exe 的 bin/libclang.dll 到后者（无 scoop 也能用，
#   该目录只是 ffigen 的约定搜索路径），SHA256 已与 winget 官方清单核对。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$SCRIPT_DIR"   # 本脚本位于 android/
APP_JNILIBS="$ANDROID_DIR/app/src/main/jniLibs"

# ---- 可覆盖参数 ----
NDK_HOME="${NDK_HOME:-D:/Android/Sdk/ndk/27.0.12077973}"
WASM_RUN_PUB_DIR="${WASM_RUN_PUB_DIR:-D:/Pub/PubRepository/hosted/pub.flutter-io.cn/wasm_run-0.1.0+2}"
WASM_RUN_VERSION="$(basename "$WASM_RUN_PUB_DIR")"

LLVM_BIN="$NDK_HOME/toolchains/llvm/prebuilt/windows-x86_64/bin"

if [[ ! -x "$LLVM_BIN/llvm-ar.exe" ]]; then
  echo "error: NDK llvm-ar 不存在: $LLVM_BIN/llvm-ar.exe" >&2
  exit 1
fi

BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/wasm_run_build.XXXXXX")"
trap 'rm -rf "$BUILD_ROOT"' EXIT
SRC="$BUILD_ROOT/wasm_run"

echo "==> 拷贝 wasm_run $WASM_RUN_VERSION 源码到 $SRC"
cp -r "$WASM_RUN_PUB_DIR" "$SRC"

# pub 缓存发布的包不带 pubspec.lock，而 frb 1.82.x 的 build.rs 会解析
# Dart 项目根的 pubspec.lock 校验依赖（wasm: true 时需要）。在临时副本里
# 跑一次 pub get 生成真实 lock 文件。
# 发布的 pubspec.yaml 里 dev_dependencies 引用了 example/（path 依赖，指向
# 发布包中不存在的兄弟仓库），必须连同 example/ 一起去掉才能 resolve。
rm -rf "$SRC/example"
sed -i '/^  wasm_run_example:$/,+1d' "$SRC/pubspec.yaml"
# frb 1.82.6 的 RawOpts 默认 dart_format_line_length=0，新版 dart format
# 拒绝 0（"Page width must be a positive number"）。旧版 frb 时代 0 被接受，
# 属环境版本漂移；给临时副本的 build.rs 补上 80（frb CLI 的同款取值）。
sed -i 's/        inline_rust: true,/        inline_rust: true,\n        dart_format_line_length: 80,/' "$SRC/native/build.rs"
echo "==> 生成 pubspec.lock（flutter pub get）"
(
  cd "$SRC"
  FLUTTER_GIT_SKIP_FETCH=1 flutter pub get
)

# triple:abi 映射（minSdk 21 -> android21 clang 包装器）
TARGETS=(
  "aarch64-linux-android:arm64-v8a"
  "x86_64-linux-android:x86_64"
)

for entry in "${TARGETS[@]}"; do
  TRIPLE="${entry%%:*}"
  ABI="${entry##*:}"
  CLANG="$LLVM_BIN/${TRIPLE}21-clang.cmd"

  if [[ ! -f "$CLANG" ]]; then
    echo "error: NDK clang 不存在: $CLANG" >&2
    exit 1
  fi

  echo "==> 构建 $TRIPLE (ABI: $ABI)，linker: $CLANG"
  # cc-rs 编译 C 依赖（zstd-sys 等）需要目标平台的 clang/ar，不显式给会去找
  # 不存在的裸名工具链。两种命名（带横线/下划线）都设，兼容不同 crate 的读取。
  TRIPLE_US="${TRIPLE//-/_}"
  export CC="${CLANG}"
  export "CC_${TRIPLE_US}=${CLANG}"
  export AR="${LLVM_BIN}/llvm-ar.exe"
  export "AR_${TRIPLE_US}=${AR}"
  (
    cd "$SRC/native"
    cargo build --release --target "$TRIPLE" \
      --config "target.${TRIPLE}.linker=\"${CLANG}\""
  )

  SO="$SRC/native/target/$TRIPLE/release/libwasm_run_dart.so"
  if [[ ! -f "$SO" ]]; then
    echo "error: 产物不存在: $SO" >&2
    exit 1
  fi

  mkdir -p "$APP_JNILIBS/$ABI"
  cp "$SO" "$APP_JNILIBS/$ABI/libwasm_run_dart.so"
  SIZE="$(du -h "$APP_JNILIBS/$ABI/libwasm_run_dart.so" | cut -f1)"
  echo "==> $ABI/libwasm_run_dart.so 已就位 ($SIZE)"
done

echo "==> 完成。so 位于 $APP_JNILIBS 下，下次 flutter build/run 会自动打进 APK。"
