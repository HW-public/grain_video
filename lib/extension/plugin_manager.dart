import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grain_engine/grain_engine.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

export 'package:grain_engine/grain_engine.dart' show LogEntry;

/// 插件管理器：装载沙箱默认全开（fuel 单次调用上限），
/// UI 层只读 [state] 与调用 [callLatest]/[callSearch]，不直接接触 wasm 文件。
///
/// 装载目录：默认应用支持目录下的 `plugins/`（不存在时空表，不报错）；
/// 可用 [load] 的 [dir] 参数指向其他目录（调试/测试）。
final pluginManagerProvider =
    NotifierProvider<PluginManager, List<PluginEntry>>(PluginManager.new);

class PluginManager extends Notifier<List<PluginEntry>> {
  /// 已装载实例镜像。riverpod 3 禁止在 dispose 生命周期内读写 [state]，
  /// 故实例释放走本列表，状态同步由 [_sync] 维护。
  final List<PluginEntry> _live = [];

  @override
  List<PluginEntry> build() {
    ref.onDispose(() {
      for (final e in _live) {
        e.plugin.dispose();
      }
      _live.clear();
    });
    // 启动即扫描安装目录：应用重启后插件直接生效，
    // 无需先进扩展页点刷新（装载失败不致命，如测试环境无 path_provider 实现）。
    Future<void>.microtask(() async {
      try {
        await load();
      } on Object {
        // 保持空表，扩展页手动刷新可重试。
      }
    });
    return const [];
  }

  void _sync(List<PluginEntry> next) {
    state = next;
    _live
      ..clear()
      ..addAll(next);
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
      _sync(const []);
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
    _sync(entries);
  }

  Future<Directory> _defaultDir() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}${Platform.pathSeparator}plugins');
  }

  /// 插件安装目录（不存在则创建）。
  Future<Directory> ensurePluginDir() async {
    final d = await _defaultDir();
    await d.create(recursive: true);
    return d;
  }

  /// 导入插件：读取文件字节后走 [installBytes]（安全替换语义）。
  Future<PluginEntry> importPlugin(File wasmFile, {Directory? dir}) async {
    if (!await wasmFile.absolute.exists()) {
      throw ArgumentError('插件文件不存在: ${wasmFile.path}');
    }
    final bytes = await wasmFile.readAsBytes();
    return installBytes(
      bytes,
      fileName: wasmFile.uri.pathSegments.last,
      dir: dir,
    );
  }

  /// 以字节安装/更新插件（导入与在线更新共用）。
  ///
  /// 安全替换：写 `.tmp` → 换入正式文件（旧文件先改 `.bak`）→ 装载验证
  /// 正式文件 → 成功删 `.bak`；装载失败则删新文件、`.bak` 还原旧文件，
  /// **旧文件与旧实例保持可用**。文件名决定安装位置（同名即更新）。
  Future<PluginEntry> installBytes(
    List<int> bytes, {
    required String fileName,
    Directory? dir,
  }) async {
    final d = dir ?? await ensurePluginDir();
    await d.create(recursive: true);
    final sep = Platform.pathSeparator;
    final finalFile = File('${d.path}$sep$fileName');
    final tmp = File('${finalFile.path}.tmp');
    final bak = File('${finalFile.path}.bak');

    await tmp.writeAsBytes(bytes, flush: true);

    // 旧文件移开（保留回滚源）。
    if (await finalFile.exists()) {
      if (await bak.exists()) await bak.delete();
      await finalFile.rename(bak.path);
    }
    await tmp.rename(finalFile.path);

    late PluginEntry entry;
    try {
      entry = await PluginEntry.load(finalFile.path);
    } catch (_) {
      // 回滚：新文件作废，旧文件还原。
      if (await finalFile.exists()) await finalFile.delete();
      if (await bak.exists()) await bak.rename(finalFile.path);
      rethrow;
    }
    if (await bak.exists()) await bak.delete();

    final oldIndex = state.indexWhere(
      (e) => e.info.sourcePath == entry.info.sourcePath,
    );
    if (oldIndex >= 0) {
      state[oldIndex].plugin.dispose();
      _sync([
        for (var i = 0; i < state.length; i++)
          if (i == oldIndex) entry else state[i],
      ]);
    } else {
      _sync([...state, entry]);
    }
    return entry;
  }

  /// 卸载插件：释放实例并从安装目录删除文件。
  Future<void> removePlugin(PluginEntry entry) async {
    entry.plugin.dispose();
    _sync(state.where((e) => e != entry).toList());
    final f = File(entry.info.sourcePath);
    if (await f.exists()) await f.delete();
  }

  /// 重新扫描安装目录（等价于 [load] 无参默认行为）。
  Future<void> reload() => load();

  /// 卸载并释放全部插件实例。
  void disposeAll() {
    for (final e in state) {
      e.plugin.dispose();
    }
    _sync(const []);
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

  /// 条目详情（插件未实现 detail 时抛 AbiError）。
  Future<BangumiDetail?> callDetail(PluginEntry entry, String url) async {
    final raw = await entry.plugin.callDetail(url);
    return BangumiDetail.parse(raw);
  }

  /// 解析播放直链（插件未实现 watch 时抛 AbiError）。
  Future<StreamInfo?> callWatch(PluginEntry entry, String url) async {
    final raw = await entry.plugin.callWatch(url);
    return StreamInfo.parse(raw);
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
