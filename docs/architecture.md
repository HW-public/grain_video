# 架构约定

> 禾禾影视（grain_video）目录分层与铁律。Phase 路线以团队内部计划文档为准
> （仓库外共享，随项目推进同步）。

## 目录分层

```
lib/
├── main.dart        # 入口：ProviderScope + runApp(HeHeApp) + 桌面窗口初始化
├── app.dart         # 应用根：MaterialApp.router + 主题 + i18n + 路由
├── core/            # 基础层：主题 token、路由、通用工具
│                     # 铁律：core 不得依赖任何业务层（extension/data/页面）
├── extension/       # 扩展引擎层（Phase 2，WASM 插件体系——唯一线路）
│                     # wasm_run 宿主 + 自研 PDK；任意语言可写插件
│                     # （Rust/Go/AssemblyScript/C/C#/Zig，编译到 .wasm 即可）
├── data/            # 数据层（Phase 3）：drift 数据库、仓库、网络
└── 页面层            # Phase 2+ 逐步落地（features/ 或 pages/，届时定名）
```

## 铁律

1. **WASM 是唯一插件线路**：不设第二套插件运行时，不设兼容层；
   插件只能是以 WebAssembly 为目标的 `.wasm` 二进制。
2. **任意语言可写插件**：插件作者不受语言绑定——Rust / Go / TinyGo /
   AssemblyScript / C / C# / Zig 等，凡能编译到 WASM 者皆可；
   宿主提供统一 ABI 与能力进口，语言差异由 PDK 吸收。
3. **沙箱硬隔离**：插件仅能调用宿主显式暴露的能力（http/xpath/crypto/log），
   无文件系统、无网络原生能力；单插件可设燃料（指令数）上限。
4. **设计 token 单一来源**：颜色/圆角/间距/封面比例一律引用
   `core/theme/tokens.dart`，页面与组件禁止硬编码。
5. **core 无业务依赖**：core 只放与业务无关的基础设施。
6. **不 pub add 新包**：依赖清单以 pubspec 现状为准，新增需用户确认。

## Phase 路线

- Phase 1（已完成）：地基骨架——目录结构、主题 token（三主题色板）、
  路由占位、i18n、桌面窗口管理、lint 门禁、双端构建验证。
- Phase 2（当前）：WASM 插件体系——spike 验证 wasm_run 双端 +
  Rust 插件跑通最新列表流程，通过后落地宿主 + PDK（Rust/TinyGo/AssemblyScript）。
- Phase 3：数据层（drift 建表 + 迁移框架）。
- 后续：页面层按 Figma 设计稿（手机/平板/桌面三端）逐步落地，
  规格文件在桌面设计工作区（团队共享）。
