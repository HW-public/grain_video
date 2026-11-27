import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

/// 错误文案分层（D5）：技术错误 → 用户友好一句话 + 可行动建议。
///
/// 原始错误不进界面主文案（保留在日志/数据库 errorMsg 供排障），
/// 界面只告诉用户「发生了什么、能怎么办」。按错误串特征归类，
/// 未识别的走通用兜底。
String friendlyError(BuildContext context, Object error) {
  final raw = error.toString().toLowerCase();
  final String key;
  if (raw.contains('socketexception') ||
      raw.contains('failed host lookup') ||
      raw.contains('connection') ||
      raw.contains('timed out') ||
      raw.contains('timeout') ||
      raw.contains('network')) {
    key = 'error.network';
  } else if (raw.contains('plugin not installed')) {
    key = 'error.pluginMissing';
  } else if (raw.contains('segment') ||
      raw.contains('not ts/mp4') ||
      raw.contains('playlist') ||
      raw.contains('m3u8') ||
      raw.contains('no stream') ||
      raw.contains('recognize file format') ||
      raw.contains('watch')) {
    key = 'error.sourceBad';
  } else {
    key = 'error.unknown';
  }
  return FlutterI18n.translate(context, key);
}
