import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/db/repositories.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';

/// 最近观看历史（首页「继续观看」横滑条数据源）。
final recentWatchProvider = FutureProvider.autoDispose<List<WatchHistory>>((
  ref,
) async {
  return ref.watch(watchHistoryRepositoryProvider).recent(limit: 20);
});

/// 追番列表（首页「追更提醒」数据源）。
final followsProvider = FutureProvider.autoDispose<List<Follow>>((ref) async {
  return ref.watch(followsRepositoryProvider).list();
});

/// 指定插件的 latest 第一页（首页「<插件名> · 最近更新」横滑条数据源）。
///
/// 以插件 package 为键；插件被卸载后返回空表（分区由页面隐藏）。
final pluginLatestProvider = FutureProvider.autoDispose
    .family<List<BangumiItem>, String>((ref, package) async {
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
