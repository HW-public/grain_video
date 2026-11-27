import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/data/db/database.dart';

/// drift 迁移快照回归（A2）：历史版本 DDL 硬编码为不可变快照，
/// 逐个旧版本造库 → 跑真实 MigrationStrategy → 校验终态结构与数据面。
///
/// 本周两起线上事故（v2 直跳 v4 重复加列、半迁移残留）这类问题
/// 必须在此拦截，不再依赖真机人肉验证。
///
/// ⚠️ 历史 DDL 是「快照」：升级 schemaVersion 时新增对应版本常量，
/// 禁止修改已有版本的字串（历史不可变）。

// ---- v1：三表（观看历史/收藏/追番） ----
const _v1Tables = [
  'CREATE TABLE "watch_histories" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "source_package" TEXT NOT NULL, "bangumi_url" TEXT NOT NULL, "title" TEXT NOT NULL, "cover" TEXT NOT NULL DEFAULT \'\', "episode_url" TEXT NOT NULL, "episode_title" TEXT NOT NULL DEFAULT \'\', "position_ms" INTEGER NOT NULL DEFAULT 0, "duration_ms" INTEGER NOT NULL DEFAULT 0, "updated_at" INTEGER NOT NULL, UNIQUE ("source_package", "episode_url"))',
  'CREATE TABLE "favorites" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "source_package" TEXT NOT NULL, "bangumi_url" TEXT NOT NULL, "title" TEXT NOT NULL, "cover" TEXT NOT NULL DEFAULT \'\', "created_at" INTEGER NOT NULL, UNIQUE ("source_package", "bangumi_url"))',
  'CREATE TABLE "follows" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "source_package" TEXT NOT NULL, "bangumi_url" TEXT NOT NULL, "title" TEXT NOT NULL, "cover" TEXT NOT NULL DEFAULT \'\', "current_episode" INTEGER NOT NULL DEFAULT 0, "total_episode" INTEGER NOT NULL DEFAULT 0, "updated_at" INTEGER NOT NULL, UNIQUE ("source_package", "bangumi_url"))',
];

// ---- v2：+ 搜索历史 ----
const _v2NewTables = [
  'CREATE TABLE "search_histories" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "keyword" TEXT NOT NULL, "searched_at" INTEGER NOT NULL, UNIQUE ("keyword"))',
];

// ---- v3：+ 下载任务（无 error_msg 列） ----
const _v3NewTables = [
  'CREATE TABLE "downloads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "source_package" TEXT NOT NULL, "bangumi_url" TEXT NOT NULL, "episode_url" TEXT NOT NULL, "title" TEXT NOT NULL, "cover" TEXT NOT NULL DEFAULT \'\', "episode_title" TEXT NOT NULL DEFAULT \'\', "stream_url" TEXT NOT NULL DEFAULT \'\', "headers_json" TEXT NOT NULL DEFAULT \'\', "local_path" TEXT NOT NULL DEFAULT \'\', "status" TEXT NOT NULL DEFAULT \'queued\', "total_bytes" INTEGER NOT NULL DEFAULT 0, "received_bytes" INTEGER NOT NULL DEFAULT 0, "total_segments" INTEGER NOT NULL DEFAULT 0, "done_segments" INTEGER NOT NULL DEFAULT 0, "created_at" INTEGER NOT NULL, UNIQUE ("source_package", "episode_url"))',
];

/// 按历史快照造一个 version 版本的旧库（DDL + user_version）。
AppDatabase _openAtVersion(int version) {
  final ddls = <String>[
    ..._v1Tables,
    if (version >= 2) ..._v2NewTables,
    if (version >= 3) ..._v3NewTables,
  ];
  final executor = NativeDatabase.memory(
    setup: (db) {
      for (final ddl in ddls) {
        db.execute(ddl);
      }
      db.execute('PRAGMA user_version = $version');
    },
  );
  return AppDatabase.forTesting(executor);
}

Future<void> _expectMigratedToV4(AppDatabase db, int from) async {
  // 触发打开 + 迁移。
  await db.customSelect('SELECT 1').get();

  // 版本号到 4。
  final v = await db.customSelect('PRAGMA user_version').getSingle();
  expect(v.read<int>('user_version'), 4, reason: 'from v$from');

  // 五表齐全。
  final tables = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  expect(tables.map((r) => r.read<String>('name')), [
    'downloads',
    'favorites',
    'follows',
    'search_histories',
    'watch_histories',
  ], reason: 'from v$from');

  // downloads 必含 error_msg 列（v4 新增）。
  final cols = await db.customSelect('PRAGMA table_info(downloads)').get();
  expect(
    cols.map((r) => r.read<String>('name')),
    contains('error_msg'),
    reason: 'from v$from',
  );

  // 数据面冒烟：插入并读回一条下载任务。
  await db.customStatement(
    "INSERT INTO downloads (source_package, bangumi_url, episode_url, title, created_at) VALUES ('p', 'b', 'e', 't', 0)",
  );
  final row = await db
      .customSelect('SELECT error_msg FROM downloads')
      .getSingle();
  expect(row.read<String>('error_msg'), '', reason: 'from v$from');
}

void main() {
  for (final from in [1, 2, 3]) {
    test('v$from → v4：迁移后结构与数据面正确', () async {
      final db = _openAtVersion(from);
      await _expectMigratedToV4(db, from);
      await db.close();
    });
  }

  test('v3 旧库已有下载数据：迁移后数据保留', () async {
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in [..._v1Tables, ..._v2NewTables, ..._v3NewTables]) {
          db.execute(ddl);
        }
        db.execute(
          "INSERT INTO downloads (source_package, bangumi_url, episode_url, title, status, created_at) VALUES ('pkg', 'bg', 'ep', '老任务', 'done', 0)",
        );
        db.execute('PRAGMA user_version = 3');
      },
    );
    final db = AppDatabase.forTesting(executor);
    await db.customSelect('SELECT 1').get();
    final row = await db
        .customSelect('SELECT title, status, error_msg FROM downloads')
        .getSingle();
    expect(row.read<String>('title'), '老任务');
    expect(row.read<String>('status'), 'done');
    expect(row.read<String>('error_msg'), '');
    await db.close();
  });

  test('半迁移残留（v3 版本号但 error_msg 列已在）：幂等通过', () async {
    // 复刻真机事故形态：开发期装过「表定义先行、版本号未升」的构建。
    final fullDownloads = _v3NewTables.single.replaceFirst(
      '"status" TEXT NOT NULL DEFAULT \'queued\',',
      '"status" TEXT NOT NULL DEFAULT \'queued\', "error_msg" TEXT NOT NULL DEFAULT \'\',',
    );
    final executor = NativeDatabase.memory(
      setup: (db) {
        for (final ddl in [..._v1Tables, ..._v2NewTables, fullDownloads]) {
          db.execute(ddl);
        }
        db.execute('PRAGMA user_version = 3');
      },
    );
    final db = AppDatabase.forTesting(executor);
    await _expectMigratedToV4(db, 3);
    await db.close();
  });
}
