import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain_engine/grain_engine.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// 插件管理器：装载沙箱默认全开（fuel 单次调用上限），
/// UI 层只读 [state] 与调用 [callLatest]/[callSearch]，不直接接触 wasm 文件。
///
/// 装载目录：默认应用支持目录下的 `plugins/`（不存在时空表，不报错）；
/// 可用 [load] 的 [dir] 参数指向其他目录（调试/测试）。
final pluginManagerProvider =
    NotifierProvider<PluginManager, List<PluginEntry>>(PluginManager.new);

class PluginManager extends Notifier<List<PluginEntry>> {
  @override
  List<PluginEntry> build() {
    ref.onDispose(disposeAll);
    return const [];
  }

  /// 单次调用燃料预算：真实插件（2 次 HTTP 往返 + 签名计算）经实测
  /// 100k 不够（bili-wbi latest 即触发 trap）；100M 给足余量，
  /// 死循环插件约 7 秒内被掐（fuel 耗尽 trap，宿主不受影响）。
  static const int _perCallFuel = 100000000;

  /// 装载目录中的全部 .wasm 插件（替换当前已装载的）。
  /// 单个插件失败（非法文件/trap/超时）不影响其余插件。
  Future<void> load({Directory? dir}) async {
    final d = dir ?? await _defaultDir();
    if (!await d.exists()) {
      state = const [];
      return;
    }
    disposeAll();

    final entries = <PluginEntry>[];
    final files = await d
        .list()
        .where((f) => f is File && f.path.endsWith('.wasm'))
        .cast<File>()
        .toList();
    for (final f in files) {
      try {
        entries.add(await PluginEntry.load(f.path));
      } on Object {
        // 坏插件跳过：装载期不因单个文件拖垮全部。
      }
    }
    state = entries;
  }

  Future<Directory> _defaultDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}plugins');
  }

  /// 卸载并释放全部插件实例。
  void disposeAll() {
    for (final e in state) {
      e.plugin.dispose();
    }
    state = const [];
  }

  /// 指定插件的日志环（guest + 宿主事件统一时间线）。
  List<LogEntry> logsOf(PluginEntry entry) => entry.plugin.logs;

  /// 调 latest；插件超时/逻辑错误抛 [GrainException] 子类，由调用方呈现。
  Future<List<BangumiItem>> callLatest(PluginEntry entry, int page) async {
    final raw = await entry.plugin.callLatest(page);
    return BangumiItem.parseList(raw);
  }

  Future<List<BangumiItem>> callSearch(
    PluginEntry entry,
    String keyword,
  ) async {
    final raw = await entry.plugin.callSearch(keyword);
    return BangumiItem.parseList(raw);
  }
}

/// 已装载插件条目：实例 + 元数据视图。
class PluginEntry {
  PluginEntry._({required this.plugin, required this.info});

  static Future<PluginEntry> load(String wasmPath) async {
    final plugin = await GrainPlugin.instantiate(
      wasmPath,
      consumeFuel: true,
      perCallFuel: PluginManager._perCallFuel,
    );
    return PluginEntry._(
      plugin: plugin,
      info: PluginInfo.fromMetadata(wasmPath, plugin.metadata),
    );
  }

  final GrainPlugin plugin;
  final PluginInfo info;

  /// 类型过滤辅助（bangumi / manga ……）。
  bool get isBangumi => info.type == 'bangumi';
}
