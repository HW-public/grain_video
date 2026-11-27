import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/services/app_logger.dart';

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('app_logger_test');
    await AppLogger.clear();
    await AppLogger.init(dir: tmp);
  });

  tearDown(() async {
    await AppLogger.clear();
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('级别/tag/消息记录；error 附带异常对象', () {
    AppLogger.i('download', 'started');
    AppLogger.w('player', 'preload failed', StateError('boom'));
    final entries = AppLogger.entries;
    expect(entries, hasLength(2));
    expect(entries[0].level, LogLevel.info);
    expect(entries[0].tag, 'download');
    expect(entries[1].level, LogLevel.warning);
    expect(entries[1].message, contains('boom'));
  });

  test('环形缓冲上限 1000：最旧的被淘汰', () {
    for (var i = 0; i < 1005; i++) {
      AppLogger.d('t', 'msg $i');
    }
    final entries = AppLogger.entries;
    expect(entries, hasLength(1000));
    expect(entries.first.message, 'msg 5');
    expect(entries.last.message, 'msg 1004');
  });

  test('错误级落盘：写入文件且重启回读', () async {
    AppLogger.e('db', 'migration exploded');
    // 落盘是异步 append，让出一拍。
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final file = File('${tmp.path}/logs/error.log');
    expect(await file.exists(), isTrue);
    expect(await file.readAsString(), contains('migration exploded'));

    // 模拟重启：清内存环后重新 init 回读。
    await AppLogger.clear();
    // clear 会删文件——重新造一份再回读。
    await file.create(recursive: true);
    await file.writeAsString(
      '${DateTime.now().toIso8601String()}|E|db|history error\n',
    );
    await AppLogger.init(dir: tmp);
    expect(AppLogger.entries.any((e) => e.message == 'history error'), isTrue);
  });

  test('导出格式：[HH:mm:ss] [级别] [tag] 消息', () {
    AppLogger.e('proxy', 'oops');
    final text = AppLogger.exportText();
    expect(
      text,
      matches(RegExp(r'\[\d{2}:\d{2}:\d{2}\] \[E\] \[proxy\] oops')),
    );
  });

  test('清空：环与文件同时清', () async {
    AppLogger.e('t', 'x');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await AppLogger.clear();
    expect(AppLogger.entries, isEmpty);
    expect(await File('${tmp.path}/logs/error.log').exists(), isFalse);
  });
}
