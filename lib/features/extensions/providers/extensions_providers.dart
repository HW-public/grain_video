import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../extension/plugin_manager.dart';
import '../../../extension/plugin_updater.dart';

/// 站点标识：优先 webSite 主机名（去 www.），回退 package。
/// 用于稳定矢量 icon 的哈希与日志分组标题。
String siteOfEntry(PluginEntry entry) {
  final web = entry.info.webSite;
  final host = Uri.tryParse(web)?.host ?? '';
  if (host.isNotEmpty) {
    return host.startsWith('www.') ? host.substring(4) : host;
  }
  final pkg = entry.info.package;
  return pkg.endsWith('.ts') ? pkg.substring(0, pkg.length - 3) : pkg;
}

/// 扩展管理动作入口：页面只调本控制器，不直接碰文件/网络。
class ExtensionsController {
  ExtensionsController(this._ref);

  final Ref _ref;

  PluginManager get _manager => _ref.read(pluginManagerProvider.notifier);

  /// 重新扫描安装目录。
  Future<void> reload() => _manager.load();

  /// 导入本地 `.wasm`（path 为用户输入的绝对路径）。
  Future<PluginEntry> importWasm(String path) =>
      _manager.importPlugin(File(path));

  /// 删除插件（释放实例并删除文件）。
  Future<void> remove(PluginEntry entry) => _manager.removePlugin(entry);

  /// 拉取清单并筛出可更新的条目。
  Future<List<PluginRelease>> checkUpdates() async {
    final updater = PluginUpdater();
    final releases = await updater.fetchManifest();
    return PluginUpdater.pendingUpdates(
      releases,
      _ref.read(pluginManagerProvider),
    );
  }

  /// 安装/更新到清单指定版本（验签 + 安全替换）。
  Future<PluginEntry> install(PluginRelease release) =>
      PluginUpdater().installOrUpdate(_manager, release);

  List<LogEntry> logsOf(PluginEntry entry) => _manager.logsOf(entry);
}

final extensionsControllerProvider = Provider<ExtensionsController>(
  (ref) => ExtensionsController(ref),
);

/// 可更新插件表（package → 清单 release），页面进入时静默检查填充；
/// 行内「更新」药丸按钮与「vA → vB 可更新」状态都读这里。
class PendingUpdatesNotifier extends Notifier<Map<String, PluginRelease>> {
  @override
  Map<String, PluginRelease> build() => const {};

  /// 静默检查：失败（离线/清单不可用）保留旧态，不打扰用户。
  Future<void> refresh() async {
    try {
      final pending = await ref
          .read(extensionsControllerProvider)
          .checkUpdates();
      state = {for (final r in pending) r.package: r};
    } catch (_) {
      // 离线等场景：维持现状。
    }
  }

  void clear() => state = const {};
}

final pendingUpdatesProvider =
    NotifierProvider<PendingUpdatesNotifier, Map<String, PluginRelease>>(
      PendingUpdatesNotifier.new,
    );

/// 扩展仓库清单（全量 release 列表），仓库页加载；安装后 invalidate 刷新状态。
final repoManifestProvider = FutureProvider<List<PluginRelease>>((ref) {
  return PluginUpdater().fetchManifest();
});
