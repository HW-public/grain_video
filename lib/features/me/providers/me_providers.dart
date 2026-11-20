import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/db/repositories.dart';

/// 「我的」三个列表页的数据提供者：一次性读取，进入页面时加载。
///
/// 写操作（如历史覆盖写）发生在播放器/详情页，本 feature 只读展示，
/// 故不做自动刷新；后续可换为 StreamProvider 监听表变化。
final watchHistoryListProvider = FutureProvider<List<WatchHistory>>((ref) {
  return ref.watch(watchHistoryRepositoryProvider).recent();
});

final favoritesListProvider = FutureProvider<List<Favorite>>((ref) {
  return ref.watch(favoritesRepositoryProvider).list();
});

final followsListProvider = FutureProvider<List<Follow>>((ref) {
  return ref.watch(followsRepositoryProvider).list();
});
