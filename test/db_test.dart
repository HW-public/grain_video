import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/data/db/database.dart';
import 'package:grain_video/data/db/repositories.dart';

void main() {
  late AppDatabase db;
  late WatchHistoryRepository history;
  late FavoritesRepository favorites;
  late FollowsRepository follows;
  late SearchHistoryRepository searchHistory;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    history = WatchHistoryRepository(db);
    favorites = FavoritesRepository(db);
    follows = FollowsRepository(db);
    searchHistory = SearchHistoryRepository(db);
  });

  tearDown(() => db.close());

  test('watch history upsert keeps one row per episode', () async {
    await history.saveProgress(
      sourcePackage: 'bilibili.com.wbi',
      bangumiUrl: 'BV1xx',
      title: '测试番',
      episodeUrl: 'BV1xx?p=1',
      positionMs: 1000,
    );
    await history.saveProgress(
      sourcePackage: 'bilibili.com.wbi',
      bangumiUrl: 'BV1xx',
      title: '测试番',
      episodeUrl: 'BV1xx?p=1',
      positionMs: 5000,
      durationMs: 24000,
    );

    final rows = await history.recent();
    expect(rows, hasLength(1));
    expect(rows.single.positionMs, 5000);
    expect(rows.single.durationMs, 24000);
  });

  test('favorites toggle and list', () async {
    expect(await favorites.isFavorite('p', 'u'), isFalse);
    expect(
      await favorites.toggle(sourcePackage: 'p', bangumiUrl: 'u', title: '番剧'),
      isTrue,
    );
    expect(await favorites.isFavorite('p', 'u'), isTrue);
    expect(await favorites.list(), hasLength(1));

    expect(
      await favorites.toggle(sourcePackage: 'p', bangumiUrl: 'u', title: '番剧'),
      isFalse,
    );
    expect(await favorites.list(), isEmpty);
  });

  test('follows progress upsert', () async {
    await follows.setProgress(
      sourcePackage: 'p',
      bangumiUrl: 'u',
      title: '追番',
      currentEpisode: 3,
      totalEpisode: 12,
    );
    await follows.setProgress(
      sourcePackage: 'p',
      bangumiUrl: 'u',
      title: '追番',
      currentEpisode: 7,
      totalEpisode: 12,
    );
    final row = await follows.find('p', 'u');
    expect(row, isNotNull);
    expect(row!.currentEpisode, 7);
    expect(await follows.list(), hasLength(1));

    await follows.remove('p', 'u');
    expect(await follows.list(), isEmpty);
  });

  test('unique key value used through companion default', () async {
    // 覆盖 Value 默认值路径，确保 companion 可正常构造。
    await db
        .into(db.watchHistories)
        .insert(
          WatchHistoriesCompanion.insert(
            sourcePackage: 'p',
            bangumiUrl: 'u',
            title: 't',
            episodeUrl: 'e',
            updatedAt: DateTime.now(),
            cover: const Value('c'),
          ),
        );
    expect(await history.recent(), hasLength(1));
  });
  test('search history dedupes, re-adds to top, caps and clears', () async {
    await searchHistory.add('孤独摇滚');
    await searchHistory.add('迷宫饭');
    await searchHistory.add('孤独摇滚'); // 重复：更新置顶

    var rows = await searchHistory.recent();
    expect(rows, ['孤独摇滚', '迷宫饭']);

    for (var i = 0; i < 25; i++) {
      await searchHistory.add('关键词$i');
    }
    rows = await searchHistory.recent();
    expect(rows, hasLength(20)); // 上限 20
    expect(rows.first, '关键词24');

    await searchHistory.clear();
    expect(await searchHistory.recent(), isEmpty);
  });
}
