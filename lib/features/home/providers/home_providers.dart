import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/db/repositories.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';

/// 最近观看历史（首页「继续观看」横滑条数据源）。
/// 常驻不自动销毁：切底部 tab 回来保持缓存，仅下拉刷新重新拉取。
final recentWatchProvider = FutureProvider<List<WatchHistory>>((ref) async {
  return ref.watch(watchHistoryRepositoryProvider).recent(limit: 20);
});

/// 追番列表（首页「追更提醒」数据源）。常驻缓存，同上。
final followsProvider = FutureProvider<List<Follow>>((ref) async {
  return ref.watch(followsRepositoryProvider).list();
});

/// 指定插件的 latest 第一页（首页「<插件名> · 最近更新」网格数据源）。
///
/// 以插件 package 为键，常驻缓存；插件被卸载后返回空表（分区由页面隐藏），
/// 重新安装后 invalidate 对应 family 实例即可。
final pluginLatestProvider = FutureProvider.family<List<BangumiItem>, String>((
  ref,
  package,
) async {
  final entries = ref.watch(pluginManagerProvider);
  PluginEntry? entry;
  for (final e in entries) {
    if (e.info.package == package) {
      entry = e;
      break;
    }
  }
  if (entry == null) return const [];
  return ref.watch(pluginManagerProvider.notifier).callLatest(entry, 1);
});
