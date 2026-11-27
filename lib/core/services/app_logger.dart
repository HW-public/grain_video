import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// 应用日志级别。
enum LogLevel { debug, info, warning, error }

/// 单条日志。
class LogEntry {
  const LogEntry({
    required this.time,
    required this.level,
    required this.tag,
    required this.message,
  });

  final DateTime time;
  final LogLevel level;
  final String tag;
  final String message;

  /// 级别徽标字母（E/W/I/D）。
  String get levelLetter => level.name[0].toUpperCase();
}

/// 应用日志（P2 日志体系，设计帧 259:2）。
///
/// - 四级 + tag 分模块；1000 条内存环（O(1) 进出，内存恒定）
/// - **错误级落盘**：追加写 `logs/error.log`，崩溃/重启后可查；
///   文件超 256KB 截断保留后半
/// - debug 构建镜像到控制台（原 debugPrint 行为不丢）
/// - [version] 驱动查看页刷新（DownloadGateway 同款模式）
///
/// 异常三层约定（新代码强制）：
/// L1 用户可感知失败 → 界面 friendlyError + AppLogger.e（下载另入库 errorMsg）
/// L2 可降级失败 → AppLogger.w 留痕，界面静默
/// L3 环境性失败（测试 stub/平台不支持）→ 空 catch + 注释，不留痕
/// 脱敏铁律：不记请求头值与用户输入原文；URL 可记（排障必需）。
abstract final class AppLogger {
  static const int _cap = 1000;
  static const int _maxFileBytes = 256 * 1024;

  static final ListQueue<LogEntry> _ring = ListQueue();
  static File? _errorFile;

  /// 日志版本号：任何写入/清空 +1，查看页据此重建。
  static final ValueNotifier<int> version = ValueNotifier(0);

  /// 当前全部日志（旧→新）。
  static List<LogEntry> get entries => List.unmodifiable(_ring);

  /// 启动初始化：装载错误日志文件（重启后可查历史错误）。
  /// [dir] 测试注入用；缺省应用支持目录。失败静默（不阻塞启动）。
  static Future<void> init({Directory? dir}) async {
    try {
      final base = dir ?? await getApplicationSupportDirectory();
      final logDir = Directory('${base.path}${Platform.pathSeparator}logs');
      await logDir.create(recursive: true);
      _errorFile = File('${logDir.path}${Platform.pathSeparator}error.log');
      if (await _errorFile!.exists()) {
        // 截断：超上限只留后半（按行对齐）。
        final len = await _errorFile!.length();
        if (len > _maxFileBytes) {
          final text = await _errorFile!.readAsString();
          final tail = text.substring(len - _maxFileBytes ~/ 2);
          final firstNewline = tail.indexOf('\n');
          await _errorFile!.writeAsString(
            firstNewline > 0 ? tail.substring(firstNewline + 1) : tail,
          );
        }
        // 回读历史错误进环（解析失败的行跳过）。
        final lines = await _errorFile!.readAsLines();
        for (final line in lines) {
          final entry = _parse(line);
          if (entry != null) _append(entry, persist: false);
        }
      }
    } on Object {
      // 无 path_provider（测试环境）/文件不可写：仅内存环。
    }
  }

  static void d(String tag, String message) =>
      _log(LogLevel.debug, tag, message);
  static void i(String tag, String message) =>
      _log(LogLevel.info, tag, message);
  static void w(String tag, String message, [Object? error]) =>
      _log(LogLevel.warning, tag, message, error);
  static void e(String tag, String message, [Object? error]) =>
      _log(LogLevel.error, tag, message, error);

  static void _log(
    LogLevel level,
    String tag,
    String message, [
    Object? error,
  ]) {
    _append(
      LogEntry(
        time: DateTime.now(),
        level: level,
        tag: tag,
        message: error == null ? message : '$message: $error',
      ),
    );
  }

  static void _append(LogEntry entry, {bool persist = true}) {
    if (_ring.length >= _cap) _ring.removeFirst();
    _ring.add(entry);
    if (kDebugMode) {
      debugPrint('[${entry.levelLetter}] [${entry.tag}] ${entry.message}');
    }
    if (persist && entry.level == LogLevel.error) {
      unawaited(_persist(entry));
    }
    version.value++;
  }

  static Future<void> _persist(LogEntry entry) async {
    try {
      await _errorFile?.writeAsString(
        '${_serialize(entry)}\n',
        mode: FileMode.append,
      );
    } on Object {
      // 落盘失败不影响内存环。
    }
  }

  /// 序列化：`ISO时间|E|tag|消息`（消息可含 |，解析按前 3 段切）。
  static String _serialize(LogEntry e) =>
      '${e.time.toIso8601String()}|${e.levelLetter}|${e.tag}|${e.message}';

  static LogEntry? _parse(String line) {
    final parts = line.split('|');
    if (parts.length < 4) return null;
    final time = DateTime.tryParse(parts[0]);
    final level =
        LogLevel.values.asNameMap()[switch (parts[1]) {
          'E' => 'error',
          'W' => 'warning',
          'I' => 'info',
          _ => 'debug',
        }];
    if (time == null || level == null) return null;
    return LogEntry(
      time: time,
      level: level,
      tag: parts[2],
      message: parts.sublist(3).join('|'),
    );
  }

  /// 导出为纯文本（分享用）：`[HH:mm:ss] [E] [tag] 消息` 每行一条。
  static String exportText() {
    final buf = StringBuffer();
    for (final e in _ring) {
      buf.writeln(
        '[${_hhmmss(e.time)}] [${e.levelLetter}] [${e.tag}] ${e.message}',
      );
    }
    return buf.toString();
  }

  /// 清空内存环与错误日志文件。
  static Future<void> clear() async {
    _ring.clear();
    try {
      if (await _errorFile?.exists() ?? false) await _errorFile!.delete();
    } on Object {
      // 删除失败不阻塞清空。
    }
    version.value++;
  }

  static String _hhmmss(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
}
