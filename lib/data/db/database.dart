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

/// 搜索历史：keyword 唯一去重，重复搜索更新时间戳置顶。
/// searchedAt 用毫秒整型——drift 的 dateTime 默认秒级精度，
/// 同秒连续搜索会并列导致排序不确定；毫秒并列时再按自增 id 倒序兜底。
class SearchHistories extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get keyword => text()();

  /// 搜索时间（Unix 毫秒）。
  IntColumn get searchedAt => integer()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {keyword},
  ];
}

/// 下载任务：按 (sourcePackage, episodeUrl) 唯一。
/// status: queued/downloading/paused/done/failed；
/// HLS 任务用 totalSegments/doneSegments 计段进度，直连文件用字节进度。
class Downloads extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 插件包名 + 集地址（重试/去重键）。
  TextColumn get sourcePackage => text()();
  TextColumn get bangumiUrl => text()();
  TextColumn get episodeUrl => text()();
  TextColumn get title => text()();
  TextColumn get cover => text().withDefault(const Constant(''))();
  TextColumn get episodeTitle => text().withDefault(const Constant(''))();

  /// callWatch 解析结果（streamUrl + headers JSON），queued 时先解析好。
  TextColumn get streamUrl => text().withDefault(const Constant(''))();
  TextColumn get headersJson => text().withDefault(const Constant(''))();

  /// 本地文件路径（done 后可离线播放）。
  TextColumn get localPath => text().withDefault(const Constant(''))();
  TextColumn get status => text().withDefault(const Constant('queued'))();
  IntColumn get totalBytes => integer().withDefault(const Constant(0))();
  IntColumn get receivedBytes => integer().withDefault(const Constant(0))();
  IntColumn get totalSegments => integer().withDefault(const Constant(0))();
  IntColumn get doneSegments => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {sourcePackage, episodeUrl},
  ];
}

/// 迁移约定：schemaVersion 从 1 开始，每次表结构变更 +1；
/// 迁移写 onUpgrade，禁止 Destructive。
@DriftDatabase(tables: [
  WatchHistories,
  Favorites,
  Follows,
  SearchHistories,
  Downloads,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'grain_video'));

  /// 测试用：注入内存连接。
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // v1 → v2：新增搜索历史表。
      if (from < 2) {
        await m.createTable(searchHistories);
      }
      // v2 → v3：新增下载任务表。
      if (from < 3) {
        await m.createTable(downloads);
      }
    },
  );
}
