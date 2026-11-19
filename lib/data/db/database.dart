import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// 观看历史：每集一条，按 (sourcePackage, episodeUrl) 唯一，续播取最近一条。
class WatchHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 插件包名（PluginInfo.package），跨插件区分条目。
  TextColumn get sourcePackage => text()();
  TextColumn get bangumiUrl => text()();
  TextColumn get title => text()();
  TextColumn get cover => text().withDefault(const Constant(''))();
  TextColumn get episodeUrl => text()();
  TextColumn get episodeTitle => text().withDefault(const Constant(''))();

  /// 播放进度（毫秒）。
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourcePackage, episodeUrl},
  ];
}

/// 收藏：按 (sourcePackage, bangumiUrl) 唯一。
class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourcePackage => text()();
  TextColumn get bangumiUrl => text()();
  TextColumn get title => text()();
  TextColumn get cover => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourcePackage, bangumiUrl},
  ];
}

/// 追番进度：按 (sourcePackage, bangumiUrl) 唯一，记录看到第几集。
class Follows extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get sourcePackage => text()();
  TextColumn get bangumiUrl => text()();
  TextColumn get title => text()();
  TextColumn get cover => text().withDefault(const Constant(''))();

  /// 当前进度与已知总集数（未知为 0）。
  IntColumn get currentEpisode => integer().withDefault(const Constant(0))();
  IntColumn get totalEpisode => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourcePackage, bangumiUrl},
  ];
}

/// 迁移约定：schemaVersion 从 1 开始，每次表结构变更 +1；
/// 迁移写 onUpgrade，禁止 Destructive。
@DriftDatabase(tables: [WatchHistories, Favorites, Follows])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'grain_video'));

  /// 测试用：注入内存连接。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 起无升级分支；后续版本在此追加 if (from < N) 迁移。
    },
  );
}
