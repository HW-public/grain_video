import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'app_exception.dart';

/// 错误文案分层（D5 + 异常体系类型化）：技术错误 → 用户友好一句话。
///
/// 先经 [AppException.wrap] 归一为类型，再按类型分派文案——
/// sealed 穷尽性保证新增异常类型时此处必须给出文案。
String friendlyError(BuildContext context, Object error) {
  final key = switch (AppException.wrap(error)) {
    NetworkException() => 'error.network',
    PluginException() => 'error.pluginMissing',
    SourceException() => 'error.sourceBad',
    PlaybackException() => 'error.sourceBad',
    StorageException() => 'error.unknown',
    UnknownException() => 'error.unknown',
  };
  return FlutterI18n.translate(context, key);
}
