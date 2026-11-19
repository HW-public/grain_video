import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../extension/plugin_manager.dart';
import '../../../extension/plugin_updater.dart';

/// 同一内容源的已安装插件分组（多语言实现归为一组）。
class SiteGroup {
  const SiteGroup({required this.site, required this.variants});

  final String site;
  final List<PluginEntry> variants;

  PluginEntry get primary => variants.first;
}

/// 站点标识：优先 webSite 主机名（去 www.），回退 package。
String siteOfEntry(PluginEntry entry) {
  final web = entry.info.webSite;
  final host = Uri.tryParse(web)?.host ?? '';
  if (host.isNotEmpty) {
    return host.startsWith('www.') ? host.substring(4) : host;
  }
  final pkg = entry.info.package;
  return pkg.endsWith('.ts') ? pkg.substring(0, pkg.length - 3) : pkg;
}

/// 实现语言标识（当前由 package 后缀推断：`.ts` = TypeScript）。
String implOfEntry(PluginEntry entry) =>
    entry.info.package.endsWith('.ts') ? 'ts' : 'rust';

final installedGroupsProvider = Provider<List<SiteGroup>>((ref) {
  final entries = ref.watch(pluginManagerProvider);
  final map = <String, List<PluginEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(siteOfEntry(e), () => []).add(e);
  }
  final groups =
      map.entries.map((e) => SiteGroup(site: e.key, variants: e.value)).toList()
        ..sort((a, b) => a.site.compareTo(b.site));
  return groups;
});

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

  /// 站点的全部日志（多实现合并，按时间排序）。
  List<LogEntry> logsOfGroup(SiteGroup group) {
    final logs = <LogEntry>[for (final v in group.variants) ...logsOf(v)]
      ..sort((a, b) => a.ts.compareTo(b.ts));
    return logs;
  }
}

final extensionsControllerProvider = Provider<ExtensionsController>(
  (ref) => ExtensionsController(ref),
);
