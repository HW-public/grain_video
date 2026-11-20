import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/database.dart';
import '../../../data/db/repositories.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';

/// 详情页入参：插件包名（src）+ 条目 url。
class DetailArgs {
  const DetailArgs({required this.src, required this.url});

  final String src;
  final String url;

  @override
  bool operator ==(Object other) =>
      other is DetailArgs && other.src == src && other.url == url;

  @override
  int get hashCode => Object.hash(src, url);
}

/// 插件不存在（未安装/已卸载），页面据此展示专用空态。
class PluginNotFoundException implements Exception {
  PluginNotFoundException(this.package);

  final String package;

  @override
  String toString() => 'plugin not found: $package';
}

/// 按包名从已装载插件里找条目来源；找不到（未安装/已卸载）返回 null。
final detailEntryProvider = Provider.autoDispose
    .family<PluginEntry?, DetailArgs>((ref, args) {
      final entries = ref.watch(pluginManagerProvider);
      for (final e in entries) {
        if (e.info.package == args.src) return e;
      }
      return null;
    });

/// 条目详情（callDetail）；插件缺失或解析失败时抛错，由 AsyncView 呈现。
final bangumiDetailProvider = FutureProvider.autoDispose
    .family<BangumiDetail, DetailArgs>((ref, args) async {
      final entry = ref.watch(detailEntryProvider(args));
      if (entry == null) {
        throw PluginNotFoundException(args.src);
      }
      final detail = await ref
          .read(pluginManagerProvider.notifier)
          .callDetail(entry, args.url);
      if (detail == null) {
        throw StateError('detail parse failed: ${args.url}');
      }
      return detail;
    });

/// 收藏状态（实时反映 favorites 表）。
final favoriteProvider = FutureProvider.autoDispose.family<bool, DetailArgs>((
  ref,
  args,
) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.isFavorite(args.src, args.url);
});

/// 追番记录（null = 未追）。
final followProvider = FutureProvider.autoDispose.family<Follow?, DetailArgs>((
  ref,
  args,
) async {
  final repo = ref.watch(followsRepositoryProvider);
  return repo.find(args.src, args.url);
});

/// 详情页动作入口：页面只调本控制器，不直接碰仓库。
class DetailActions {
  DetailActions(this._ref);

  final Ref _ref;

  Future<void> toggleFavorite(DetailArgs args, BangumiDetail detail) async {
    final repo = _ref.read(favoritesRepositoryProvider);
    await repo.toggle(
      sourcePackage: args.src,
      bangumiUrl: args.url,
      title: detail.title,
      cover: detail.cover,
    );
    _ref.invalidate(favoriteProvider(args));
  }

  /// 追番/取消追番切换；追番时以当前选集数作为总集数写入进度。
  Future<void> toggleFollow(DetailArgs args, BangumiDetail detail) async {
    final repo = _ref.read(followsRepositoryProvider);
    final existing = await repo.find(args.src, args.url);
    if (existing != null) {
      await repo.remove(args.src, args.url);
    } else {
      await repo.setProgress(
        sourcePackage: args.src,
        bangumiUrl: args.url,
        title: detail.title,
        cover: detail.cover,
        currentEpisode: 0,
        totalEpisode: detail.episodes.length,
      );
    }
    _ref.invalidate(followProvider(args));
  }

  void retry(DetailArgs args) => _ref.invalidate(bangumiDetailProvider(args));
}

final detailActionsProvider = Provider<DetailActions>(
  (ref) => DetailActions(ref),
);
