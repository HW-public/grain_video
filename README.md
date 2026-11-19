# 禾禾影视（grain_video）

**全新独立**的 Flutter 多端视频应用（追番/影视聚合），包名 `top.wprop.grain_video`。

## 插件体系（核心架构，唯一线路）

本项目采用 **WASM 插件体系**，不设其他兼容线路：

- **任意语言可写插件**——只要能编译到 WebAssembly（Rust / Go / TinyGo /
  AssemblyScript / C / C# / Zig……），无单一语言绑定
- 插件 = `.wasm` 二进制 + 内嵌元数据（custom section），装载即读元数据，
  零执行
- 宿主经 `wasm_run`（wasmtime FFI，Android/Windows/macOS/Linux/Web 全平台）
  装载插件；插件仅能调用宿主显式暴露的能力（http / xpath / crypto / log），
  线性内存隔离 + 燃料（指令数）上限，沙箱为 VM 级硬保证
- 当前处于技术验证期（spike），宿主与 PDK 验证通过后落地 `lib/extension/`

Phase 路线见 `docs/architecture.md`。

## 环境

- Flutter 3.32 / Dart ^3.8.0
- Gradle 镜像：全局 `init.d/mirrors.gradle` 已配，新项目零改动

## 跑法

```bash
# Windows 桌面
flutter run -d windows

# Android 模拟器/真机
flutter run -d <device-id>
```

桌面端启动时窗口自动初始化：标题「禾禾影视」，最小尺寸 1080x720，居中。
Android 不初始化窗口管理。

## 签名

- keystore 位置：`android/app/grain_video.jks`（**不入库**，已在 .gitignore）
- 口令机制：`android/key.properties` 引用 keystore 路径与密码（**不入库**）
- 密码问用户，勿写入任何文档或代码

## 结构速览

```
lib/
├── main.dart                # 入口：ProviderScope + runApp + 桌面窗口初始化
├── app.dart                 # HeHeApp：MaterialApp.router + 主题 + i18n + 路由
├── core/                    # 无业务依赖的基础层
│   ├── theme/tokens.dart        # 设计 token 单一来源（色/圆角/间距/封面比例）
│   ├── theme/app_theme.dart     # 亮/暗 ThemeData
│   └── router/app_router.dart   # go_router 配置
├── extension/               # Phase 2 WASM 插件体系（选型验证中）
└── data/db/                 # Phase 3 drift 数据库骨架
assets/l10n/               # flutter_i18n JSON 词条
```
