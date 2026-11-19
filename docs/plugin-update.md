# 插件更新机制

> 状态（2026-11-19）：**宿主侧已实施**（安全替换 + 在线更新服务 + 验签测试）；
> 插件分发仓库已建（grain_plugins，双插件 CI 签名发布）；
> **待办**：扩展管理页 UI、创建 GitHub 仓库并配置签名 secret、发首个 release。
> 相关：`lib/extension/plugin_manager.dart`、`lib/extension/plugin_updater.dart`、
> grain_engine Roadmap「Hot plugin updates and source-signature verification」。

## 已实施

- `PluginManager.installBytes`：`.tmp` 写入 → 旧文件改 `.bak` → 换入 → 装载验证
  → 成功删 `.bak`；装载失败回滚（旧文件与旧实例保持可用）。`importPlugin`
  改为读取字节后走同一路径（修复了「先覆盖后验证」缺陷）。
- `PluginUpdater`：拉清单 → 下载 → sha256 + Ed25519 验签（消息
  `{package}|{version}|{sha256}`，公钥内置 `defaultPublicKeyHex`）→ 安全替换。
- 版本比较与待更新筛选（`compareVersions` / `pendingFromVersions`）。
- 测试：验签正/负例、篡改拒绝、版本比较、损坏更新回滚、
  真实清单端到端验签（本地 dist）。

## 分发清单（grain_plugins 仓库）

```json
{"schema":1,"generatedAt":"...","plugins":[
  {"package":"360zy.com","name":"360资源","version":"v0.0.2",
   "site":"360zy.com","impl":"rust",
   "file":"plugin_360zy_rust.wasm",
   "url":"https://github.com/HW-public/grain_plugins/releases/download/<tag>/plugin_360zy_rust.wasm",
   "sha256":"<hex>","signature":"<hex>"}]}
```

- `site` = 内容源（UI 分组维度）；`impl` = 语言实现；`package` = 实现唯一 ID
  （安装/更新按它匹配）。同站点多语言实现共存，宿主用
  `PluginUpdater.groupBySite` 归组呈现。
- 仓库布局：`plugins/<插件>/<语言>/`（如 `plugins/360zy/{rust,ts}/`），
  `build_dist.sh` 按语言分别构建为 `plugin_<name>_<impl>.wasm`。

- 清单地址：`https://github.com/HW-public/grain_plugins/releases/latest/download/manifest.json`
- 签名消息：UTF-8 `{package}|{version}|{sha256}`（Ed25519，公钥 `keys/public.hex`）
- 发布：grain_plugins 打 `v*` tag → CI 构建、签名、`gh release create`。
- 私钥只存本地 `C:/Users/WH/.grain/plugin-signing.pem` 与 GitHub secret
  `PLUGIN_SIGNING_KEY`（PEM 全文），绝不入库。

## 剩余待办

1. 创建 GitHub 仓库 `HW-public/grain_plugins`，配置 secret 后推送源码。
2. 打首个 tag（如 `v0.1.0`）触发 release；确认 `latest/download/manifest.json` 可访问。
3. 扩展管理页 UI：展示待更新列表（`pendingFromVersions`）、更新按钮
   （`installOrUpdate`）、进度与错误（`PluginUpdateException`）。
4. 插件将来引入配置/存储时，更新须保留数据（按 package 隔离的 KV）。

## 明确不做

- 第二套插件格式/兼容层（架构铁律 1）
- 自动静默更新（必须用户确认）
- 从任意 URL 直接安装（只认清单来源或本地文件导入）
