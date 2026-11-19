# Extension 扩展引擎层

> WASM 插件体系——**本项目唯一插件线路**，由独立仓库
> [grain_engine](https://github.com/HW-public/grain_engine) 提供宿主运行时。
> spike 已完成（六项判决全过），本目录是其应用侧封装。

## 结构

| 文件 | 职责 |
|---|---|
| `models.dart` | `PluginInfo`、`BangumiItem`（latest/search）、`BangumiDetail`/`Episode`（detail）、`StreamInfo`（watch 直链+请求头） |
| `plugin_manager.dart` | `PluginManager`（riverpod）：装载/卸载/导入 `.wasm`、调用 latest/search/detail/watch、日志环访问 |

## 宿主沙箱默认配置

`PluginEntry.load` 以 `consumeFuel: true + perCallFuel: 100000` 实例化：
每次 latest/search 调用前充值燃料，死循环插件单次调用内被 trap，
不影响宿主与其他插件。SSRF 收窄（`allowedHosts`）按需开启。

## 插件目录

默认 `getApplicationSupportDirectory()/plugins/`；`PluginManager.load(dir:)`
可指向任意目录（调试用）。非 `.wasm` 文件忽略，单个坏插件不影响其余。

导入即更新（同名覆盖），当前有"先覆盖后验证"的已知缺陷；
安全替换与在线更新设计见 [docs/plugin-update.md](../../docs/plugin-update.md)。

## UI 层用法

```dart
final plugins = ref.watch(pluginManagerProvider);
await ref.read(pluginManagerProvider.notifier).load();
final mgr = ref.read(pluginManagerProvider.notifier);

final items = await mgr.callLatest(plugins.first, 1);      // 列表
final detail = await mgr.callDetail(plugins.first, items.first.url); // 详情+剧集
final stream = await mgr.callWatch(plugins.first, detail!.episodes.first.url);
// stream.url / stream.headers → media_kit Player.open(Media(url), httpHeaders: ...)
```

错误处理：插件逻辑/超时/沙箱错误以 `GrainException` 子类抛出
（`PluginLogicError` / `TimeoutError` / `SandboxError` / `CapabilityError`），
由调用方按 code 呈现。

## Android 状态

Windows/macOS/Linux 经 grain_engine 内嵌原生库零配置运行。
Android 需 `libwasm_run_dart.so` 进 APK（插件化打包，见 grain_engine
Roadmap）；在此之前扩展功能仅桌面端可用，Android 端装载会抛
`UnsupportedError`（wasm_run 查找失败）。
