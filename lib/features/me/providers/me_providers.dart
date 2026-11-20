import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/db/repositories.dart';

/// 「我的-观看历史」列表：AsyncNotifier 保持三态语义。
///
/// 左滑删除走乐观移除（先同步从 state 去掉满足 Dismissible
/// 「onDismissed 后须同步出树」的断言，再后台落库）。
class WatchHistoryListNotifier extends AsyncNotifier<List<WatchHistory>> {
  @override
  Future<List<WatchHistory>> build() {
    return ref.watch(watchHistoryRepositoryProvider).recent();
  }

  /// 乐观删除：UI 立即移除，数据库后台落盘。
  Future<void> remove(int id) async {
    final current = state.value ?? const <WatchHistory>[];
    state = AsyncData(current.where((e) => e.id != id).toList());
    await ref.read(watchHistoryRepositoryProvider).remove(id);
  }

  /// 重新加载（错误重试）。
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(watchHistoryRepositoryProvider).recent(),
    );
  }
}

final watchHistoryListProvider =
    AsyncNotifierProvider<WatchHistoryListNotifier, List<WatchHistory>>(
      WatchHistoryListNotifier.new,
    );

final favoritesListProvider = FutureProvider<List<Favorite>>((ref) {
  return ref.watch(favoritesRepositoryProvider).list();
});

final followsListProvider = FutureProvider<List<Follow>>((ref) {
  return ref.watch(followsRepositoryProvider).list();
});
