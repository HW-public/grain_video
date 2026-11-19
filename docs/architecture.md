# 架构约定

> 禾禾影视（grain_video）模块分层与铁律。新增页面/模块前先读本文；
> 规则违反由 `tool/check_imports.dart` 在 CI 与本地门禁中拦截。

## 目录分层（feature-first）

```
lib/
├── main.dart            # 入口：ProviderScope + runApp + 桌面窗口初始化
├── app.dart             # 应用根：MaterialApp.router + 主题 + i18n
├── router.dart          # 路由汇总（app 层聚合各 feature 的 GoRoute 列表）
├── core/                # 零业务依赖的基础设施
│   ├── theme/           #   设计 token（颜色/圆角/间距的唯一来源）
│   ├── widgets/         #   通用组件（AsyncView / EmptyState 等）
│   └── utils/           #   纯函数工具
├── data/                # 持久化与仓库（drift 表、repositories）
│   ├── db/
│   └── repositories.dart
├── extension/           # 插件引擎适配层（plugin_manager / updater / models）
└── features/            # 每个功能一个模块，模块内自带页面、状态、私有组件
    ├── extensions/      #   扩展管理（列表/分组/导入/删除/更新/日志）
    │   ├── pages/
    │   ├── providers/
    │   └── widgets/
    ├── home/            #   首页（latest 瀑布流 + 源切换）
    ├── search/          #   搜索（跨插件）
    ├── detail/          #   详情 + 选集
    ├── player/          #   播放（media_kit 单例）
    └── library/         #   收藏 / 追番 / 观看历史
```

## 依赖矩阵（硬规则）

| 层 | 允许 import |
|---|---|
| `core` | 仅 `core` + Dart/Flutter/pub 包 |
| `data` | `core`、`data` |
| `extension` | `core`、`extension`、`package:grain_engine` |
| `features/<x>` | `core`、`data`、`extension`、**同 feature** 内部 |
| `main.dart` / `app.dart` | 任意 |

- **features 之间禁止互相 import**：跨模块复用下沉到 `core/widgets`、
  `core/utils` 或 `data/` 的仓库。
- 反向依赖一律禁止（core 不得出现业务概念；data/extension 不得 import
  features）。
- 页面之间跳转只通过路由，不直接 import 别的 feature 的 Page。

## feature 模块规范

每个 feature 固定三件套：

| 目录 | 职责 |
|---|---|
| `pages/` | 页面（`XxxPage`），只读 provider、组装 body；禁止直接发 HTTP/读写 DB |
| `providers/` | riverpod 状态与用例编排（`xxxProvider`）；调用 extension/data 层 |
| `widgets/` | 模块私有组件（`XxxCard`/`XxxView`），可被本模块 pages 复用 |

- 路由：每个 feature 导出 `List<RouteBase> xxxRoutes` 与
  `abstract final class XxxRoutes`（路径常量），由 `lib/router.dart`（app 层）
  聚合——core 不 import features。
- 跨模块共享的模型/工具放到 `core`（纯 UI 模型）或 `extension`（插件相关）。

## 状态与异步三态

- 统一 `AsyncValue<T>`，UI 一律经 `core/widgets/async_view.dart` 渲染
  加载/错误（带重试）/数据三态；禁止页面里散写 `if (loading)`。
- 空列表用 `core/widgets/empty_state.dart`，文案走 i18n。
- provider 只暴露不可变数据；写操作（收藏、进度）走对应 repository。

## 错误处理

- 插件调用错误是类型化异常（`GrainException` 子类，见 grain_engine）：
  UI 层按 `code` 呈现（`plugin` 业务失败 / `timeout` / `fuel` / `http`）。
- 任何 provider 捕获后转 `AsyncError`，不吞异常；日志进插件日志环 + 调试输出。

## 命名约定

| 对象 | 规则 | 示例 |
|---|---|---|
| 文件/目录 | snake_case | `extensions_page.dart` |
| 页面 | `XxxPage` | `SearchPage` |
| 组件 | `XxxView` / `XxxCard` / `XxxTile` | `BangumiCard` |
| provider | `xxxProvider`（Notifier 用 `XxxNotifier`） | `pluginManagerProvider` |
| 路由常量 | `abstract final class XxxRoutes` | `DetailRoutes.page` |
| 私有实现 | 前缀 `_` + 留在同文件 | `_CoverPlaceholder` |

## 测试约定

- 镜像目录：`test/features/<feature>/...`、`test/core/...`、`test/data/...`。
- 仓库测试用 `NativeDatabase.memory()`；插件相关测试在引擎产物缺失时跳过
  （不把环境依赖带进 CI）。
- 真网验证（`HttpOverrides.global = null`）只放在显式场景测试里。

## 强制手段

- 本地门禁：`dart run tool/check_imports.dart`（分层校验）+ `flutter analyze`
  + `dart format --set-exit-if-changed .`。
- CI：`.github/workflows/dart.yaml` 对 main 的 push/PR 跑同一套。
- 新增 pub 依赖仍需用户确认（见铁律 6）。

## 铁律

1. **WASM 是唯一插件线路**：不设第二套插件运行时；插件只能是以
   WebAssembly 为目标的 `.wasm` 二进制。
2. **多语言插件**：宿主提供统一 ABI 与能力进口；当前官方 PDK 为
   **Rust 与 AssemblyScript（TS 语法子集）**，C/Zig/Go 等扩展待后续
   （Go 需 WASI 子集支持，暂缓）。
3. **沙箱硬隔离**：插件仅能调用宿主显式暴露的能力（http/xpath/crypto/log），
   无文件系统、无网络原生能力；可设燃料（指令数）上限。
4. **设计 token 单一来源**：颜色/圆角/间距/封面比例一律引用
   `core/theme/tokens.dart`，页面与组件禁止硬编码。
5. **core 无业务依赖**：core 只放与业务无关的基础设施。
6. **不 pub add 新包**：依赖清单以 pubspec 现状为准，新增需用户确认。

## 阶段状态

- Phase 1（完成）：地基骨架——主题 token、路由占位、i18n、桌面窗口。
- Phase 2（完成）：WASM 插件体系接入（grain_engine ABI v0.2 + 签名更新）。
- Phase 3（完成）：数据层（drift 三表 + 仓库 + 测试）。
- Phase 4（进行中）：扩展管理页；随后首页/搜索 → 详情/播放 → 收藏/追番。
