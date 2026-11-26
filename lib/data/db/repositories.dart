import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'database.dart';

/// 数据库单例（随 ProviderContainer 生命周期关闭）。
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

/// 观看历史仓库。
class WatchHistoryRepository {
  WatchHistoryRepository(this._db);

  final AppDatabase _db;

  /// 记录/更新一集的播放进度（同 (sourcePackage, episodeUrl) 覆盖）。
  Future<void> saveProgress({
    required String sourcePackage,
    required String bangumiUrl,
    required String title,
    required String episodeUrl,
    String cover = '',
    String episodeTitle = '',
    int positionMs = 0,
    int durationMs = 0,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.watchHistories)..where(
            (t) =>
                t.sourcePackage.equals(sourcePackage) &
                t.episodeUrl.equals(episodeUrl),
          ))
          .go();
      await _db
          .into(_db.watchHistories)
          .insert(
            WatchHistoriesCompanion.insert(
              sourcePackage: sourcePackage,
              bangumiUrl: bangumiUrl,
              title: title,
              episodeUrl: episodeUrl,
              updatedAt: DateTime.now(),
              cover: Value(cover),
              episodeTitle: Value(episodeTitle),
              positionMs: Value(positionMs),
              durationMs: Value(durationMs),
            ),
          );
    });
  }

  /// 最近观看（按更新时间倒序）。
  Future<List<WatchHistory>> recent({int limit = 50}) {
    return (_db.select(_db.watchHistories)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
          ..limit(limit))
        .get();
  }

  /// 删除单条观看历史（左滑删除）。
  Future<void> remove(int id) async {
    await (_db.delete(_db.watchHistories)..where((t) => t.id.equals(id))).go();
  }

  /// 某条目的全部观看记录（续播/选集用）。
  Future<List<WatchHistory>> forBangumi(
    String sourcePackage,
    String bangumiUrl,
  ) {
    return (_db.select(_db.watchHistories)
          ..where(
            (t) =>
                t.sourcePackage.equals(sourcePackage) &
                t.bangumiUrl.equals(bangumiUrl),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// 清空全部观看历史。
  Future<void> clear() => _db.delete(_db.watchHistories).go();
}

/// 搜索历史仓库：keyword 去重置顶，最多保留 [recent] 的 limit 条。
class SearchHistoryRepository {
  SearchHistoryRepository(this._db);

  final AppDatabase _db;

  /// 最近搜索（按时间倒序；毫秒并列时按插入序倒序兜底）。
  Future<List<String>> recent({int limit = 20}) async {
    final rows =
        await (_db.select(_db.searchHistories)
              ..orderBy([
                (t) => OrderingTerm.desc(t.searchedAt),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(limit))
            .get();
    return [for (final r in rows) r.keyword];
  }

  /// 记录一次搜索（已存在则删旧插新：时间戳与自增 id 都刷新，双关键字排序都置顶）。
  Future<void> add(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) return;
    await _db.transaction(() async {
      await (_db.delete(
        _db.searchHistories,
      )..where((t) => t.keyword.equals(k))).go();
      await _db
          .into(_db.searchHistories)
          .insert(
            SearchHistoriesCompanion.insert(
              keyword: k,
              searchedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          );
    });
  }

  /// 删除单条搜索历史。
  Future<void> remove(String keyword) async {
    await (_db.delete(
      _db.searchHistories,
    )..where((t) => t.keyword.equals(keyword))).go();
  }

  Future<void> clear() => _db.delete(_db.searchHistories).go();
}

/// 收藏仓库。
class FavoritesRepository {
  FavoritesRepository(this._db);

  final AppDatabase _db;

  Future<bool> isFavorite(String sourcePackage, String bangumiUrl) async {
    final row =
        await (_db.select(_db.favorites)..where(
              (t) =>
                  t.sourcePackage.equals(sourcePackage) &
                  t.bangumiUrl.equals(bangumiUrl),
            ))
            .getSingleOrNull();
    return row != null;
  }

  /// 切换收藏状态，返回切换后的状态（true=已收藏）。
  Future<bool> toggle({
    required String sourcePackage,
    required String bangumiUrl,
    required String title,
    String cover = '',
  }) async {
    final fav = await isFavorite(sourcePackage, bangumiUrl);
    if (fav) {
      await (_db.delete(_db.favorites)..where(
            (t) =>
                t.sourcePackage.equals(sourcePackage) &
                t.bangumiUrl.equals(bangumiUrl),
          ))
          .go();
      return false;
    }
    await _db
        .into(_db.favorites)
        .insert(
          FavoritesCompanion.insert(
            sourcePackage: sourcePackage,
            bangumiUrl: bangumiUrl,
            title: title,
            createdAt: DateTime.now(),
            cover: Value(cover),
          ),
        );
    return true;
  }

  Future<List<Favorite>> list() {
    return (_db.select(
      _db.favorites,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }
}

/// 追番进度仓库。
class FollowsRepository {
  FollowsRepository(this._db);

  final AppDatabase _db;

  /// 写入/更新追番进度。
  Future<void> setProgress({
    required String sourcePackage,
    required String bangumiUrl,
    required String title,
    String cover = '',
    int currentEpisode = 0,
    int totalEpisode = 0,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.follows)..where(
            (t) =>
                t.sourcePackage.equals(sourcePackage) &
                t.bangumiUrl.equals(bangumiUrl),
          ))
          .go();
      await _db
          .into(_db.follows)
          .insert(
            FollowsCompanion.insert(
              sourcePackage: sourcePackage,
              bangumiUrl: bangumiUrl,
              title: title,
              updatedAt: DateTime.now(),
              cover: Value(cover),
              currentEpisode: Value(currentEpisode),
              totalEpisode: Value(totalEpisode),
            ),
          );
    });
  }

  Future<Follow?> find(String sourcePackage, String bangumiUrl) {
    return (_db.select(_db.follows)..where(
          (t) =>
              t.sourcePackage.equals(sourcePackage) &
              t.bangumiUrl.equals(bangumiUrl),
        ))
        .getSingleOrNull();
  }

  Future<List<Follow>> list() {
    return (_db.select(
      _db.follows,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  Future<void> remove(String sourcePackage, String bangumiUrl) async {
    await (_db.delete(_db.follows)..where(
          (t) =>
              t.sourcePackage.equals(sourcePackage) &
              t.bangumiUrl.equals(bangumiUrl),
        ))
        .go();
  }
}

final watchHistoryRepositoryProvider = Provider<WatchHistoryRepository>(
  (ref) => WatchHistoryRepository(ref.watch(databaseProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(databaseProvider)),
);

final followsRepositoryProvider = Provider<FollowsRepository>(
  (ref) => FollowsRepository(ref.watch(databaseProvider)),
);

final searchHistoryRepositoryProvider = Provider<SearchHistoryRepository>(
  (ref) => SearchHistoryRepository(ref.watch(databaseProvider)),
);

/// 下载任务仓库。
class DownloadsRepository {
  DownloadsRepository(this._db);

  final AppDatabase _db;

  Future<Download?> findByEpisode(String sourcePackage, String episodeUrl) {
    return (_db.select(_db.downloads)..where(
          (t) =>
              t.sourcePackage.equals(sourcePackage) &
              t.episodeUrl.equals(episodeUrl),
        ))
        .getSingleOrNull();
  }

  Future<Download> insert({
    required String sourcePackage,
    required String bangumiUrl,
    required String episodeUrl,
    required String title,
    String cover = '',
    String episodeTitle = '',
    String streamUrl = '',
    String headersJson = '',
  }) async {
    final existing = await findByEpisode(sourcePackage, episodeUrl);
    if (existing != null) return existing;
    final id = await _db
        .into(_db.downloads)
        .insert(
          DownloadsCompanion.insert(
            sourcePackage: sourcePackage,
            bangumiUrl: bangumiUrl,
            episodeUrl: episodeUrl,
            title: title,
            createdAt: DateTime.now(),
            cover: Value(cover),
            episodeTitle: Value(episodeTitle),
            streamUrl: Value(streamUrl),
            headersJson: Value(headersJson),
          ),
        );
    return (await (_db.select(
      _db.downloads,
    )..where((t) => t.id.equals(id))).getSingle());
  }

  Future<List<Download>> list() {
    return (_db.select(
      _db.downloads,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();
  }

  Future<void> updateStatus(int id, String status, {String? errorMsg}) {
    return (_db.update(_db.downloads)..where((t) => t.id.equals(id))).write(
      DownloadsCompanion(
        status: Value(status),
        errorMsg: errorMsg == null ? const Value.absent() : Value(errorMsg),
      ),
    );
  }

  Future<void> updateProgress({
    required int id,
    int? receivedBytes,
    int? totalBytes,
    int? doneSegments,
    int? totalSegments,
  }) {
    return (_db.update(_db.downloads)..where((t) => t.id.equals(id))).write(
      DownloadsCompanion(
        receivedBytes: receivedBytes == null
            ? const Value.absent()
            : Value(receivedBytes),
        totalBytes: totalBytes == null
            ? const Value.absent()
            : Value(totalBytes),
        doneSegments: doneSegments == null
            ? const Value.absent()
            : Value(doneSegments),
        totalSegments: totalSegments == null
            ? const Value.absent()
            : Value(totalSegments),
      ),
    );
  }

  /// 起下即写本地路径（半成品试播用；markDone 完成时仍会重写）。
  Future<void> setLocalPath(int id, String localPath) {
    return (_db.update(_db.downloads)..where((t) => t.id.equals(id))).write(
      DownloadsCompanion(localPath: Value(localPath)),
    );
  }

  Future<void> markDone(int id, String localPath) {
    return (_db.update(_db.downloads)..where((t) => t.id.equals(id))).write(
      DownloadsCompanion(
        status: const Value('done'),
        localPath: Value(localPath),
      ),
    );
  }

  Future<void> resetProgress(int id) {
    return (_db.update(_db.downloads)..where((t) => t.id.equals(id))).write(
      const DownloadsCompanion(
        status: Value('queued'),
        receivedBytes: Value(0),
        doneSegments: Value(0),
      ),
    );
  }

  Future<void> remove(int id) {
    return (_db.delete(_db.downloads)..where((t) => t.id.equals(id))).go();
  }
}

final downloadsRepositoryProvider = Provider<DownloadsRepository>(
  (ref) => DownloadsRepository(ref.watch(databaseProvider)),
);
