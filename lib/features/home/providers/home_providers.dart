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

/// 跨源条目：内容 + 所属插件包名（点跳详情取 src 用）。
typedef SourcedItem = ({BangumiItem item, String sourcePackage});

/// 首页合并「最近更新」：全部插件 latest 第一页并发拉取，按源轮流交错混排。
/// 单插件失败不影响其余源（该源缺席混排）；全部失败抛错由分区错误态呈现。
final mergedLatestProvider = FutureProvider<List<SourcedItem>>((ref) async {
  final entries = ref.watch(pluginManagerProvider);
  final results = await Future.wait(
    entries.map(
      (e) => ref
          .read(pluginManagerProvider.notifier)
          .callLatest(e, 1)
          .then((items) => (entry: e, items: items))
          .catchError((Object _) => (entry: e, items: <BangumiItem>[])),
    ),
  );
  // 按源轮流交错（源 A1 B1 C1 A2 B2 C2…），避免头部被单一源占满。
  final maxLen = results.fold(
    0,
    (m, r) => r.items.length > m ? r.items.length : m,
  );
  final merged = <SourcedItem>[];
  for (var i = 0; i < maxLen; i++) {
    for (final r in results) {
      if (i < r.items.length) {
        merged.add((item: r.items[i], sourcePackage: r.entry.info.package));
      }
    }
  }
  return merged;
});
