import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/data/db/database.dart';
import 'package:grain_video/data/db/repositories.dart';
import 'package:grain_video/extension/plugin_manager.dart';
import 'package:grain_video/extension/plugin_updater.dart';

/// 真实场景全链路：签名清单 → 验签安装 → 调用插件 → 进度落库 → 更新比对。
///
/// 依赖本地构建的 `../grain_plugins/dist`（含 manifest 与签名产物）；
/// 目录缺失时跳过。网络请求走真实链路（flutter_test 默认 mock 必须解除）。
void main() {
  final dist = Directory('../grain_plugins/dist');
  final manifestFile = File('${dist.path}/manifest.json');

  test(
    'scenario: install from signed manifest, use plugin, persist progress',
    () async {
      if (!manifestFile.existsSync()) return;
      HttpOverrides.global = null;

      final json = jsonDecode(await manifestFile.readAsString()) as Map;
      final releases = (json['plugins'] as List)
          .map(PluginRelease.fromJson)
          .whereType<PluginRelease>()
          .toList();
      expect(releases, isNotEmpty);

      // 安装目录隔离在临时目录，不污染应用目录。
      final tmp = await Directory.systemTemp.createTemp('grain_scenario_');
      addTearDown(() => tmp.delete(recursive: true));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final mgr = container.read(pluginManagerProvider.notifier);
      final updater = PluginUpdater();

      // 1) 逐条验签并安装（模拟在线更新器下载后的路径）。
      for (final r in releases) {
        final bytes = await File('${dist.path}/${r.file}').readAsBytes();
        expect(
          await updater.verifyBytes(r, bytes),
          isTrue,
          reason: '${r.package} 验签失败',
        );
        await mgr.installBytes(bytes, fileName: r.file, dir: tmp);
      }
      final installed = container.read(pluginManagerProvider);
      expect(installed.length, releases.length);
      expect(
        PluginUpdater.groupBySite(releases).keys.toSet(),
        containsAll(['360zy.com', 'bilibili.com']),
      );

      // 2) 版本一致时没有待更新项。
      expect(
        PluginUpdater.pendingFromVersions(releases, {
          for (final e in installed) e.info.package: e.info.version,
        }),
        isEmpty,
      );

      // 3) 用 TS 版 360 资源走一遍业务链：列表 → 详情 → 播放解析。
      final ts = installed.firstWhere((e) => e.info.package == '360zy.com.ts');
      final items = await mgr.callLatest(ts, 1);
      expect(items, isNotEmpty);
      final detail = await mgr.callDetail(ts, items.first.url);
      expect(detail, isNotNull);
      expect(detail!.episodes, isNotEmpty);
      final stream = await mgr.callWatch(ts, detail.episodes.first.url);
      expect(stream, isNotNull);
      expect(stream!.url, isNotEmpty);

      // 4) 播放进度落库（真实 DB 读写）。
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final history = WatchHistoryRepository(db);
      await history.saveProgress(
        sourcePackage: ts.info.package,
        bangumiUrl: items.first.url,
        title: items.first.title,
        episodeUrl: detail.episodes.first.url,
        episodeTitle: detail.episodes.first.title,
        positionMs: 42000,
        durationMs: 1440000,
      );
      final recent = await history.recent();
      expect(recent, hasLength(1));
      expect(recent.single.positionMs, 42000);

      // 记录关键实测数据，便于价值评估。
      // ignore: avoid_print
      print(
        'scenario ok: items=${items.length} episodes=${detail.episodes.length} '
        'stream=${stream.url.substring(0, 40)}...',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
