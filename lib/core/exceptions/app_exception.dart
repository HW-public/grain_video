import 'package:dio/dio.dart';

/// 应用异常体系（core/exceptions/ 专属目录）。
///
/// 设计要点：
/// - **sealed 基类**：switch 穷尽性检查，新增子类漏处理编译器直接报错
/// - 子类同库（Dart sealed 硬约束），新增类型加在本文件
/// - **类型只回答「是什么」，不回答「怎么办」**——L1/L2/L3 处理策略
///   属于调用点（同一 NetworkException 起播是 L1、预载是 L2）
/// - 第三方异常（dio/mpv/drift）不进门：`wrap` 在各模块 catch 边界归一，
///   原始异常存 [cause] 永久携带
/// - grain_engine 的 GrainException 属插件域，由 plugin_manager 边界转换，
///   core 不依赖 grain_engine
sealed class AppException implements Exception {
  const AppException(this.message, [this.cause]);

  /// 技术描述（进日志/详情折叠）。
  final String message;

  /// 原始异常（保留现场，不丢信息）。
  final Object? cause;

  /// toString 直接给消息体：`'$e'` 插值/日志输出不含 "Instance of..."。
  @override
  String toString() => message;

  /// 任意异常 → AppException 归一。
  ///
  /// 已是 AppException 原样返回；已知第三方类型直接映射；
  /// 其余按消息特征归类（存量 StateError/字符串错误的过渡路径，
  /// 抛点逐模块改抛具体类型后此段自然萎缩）。
  static AppException wrap(Object error) => switch (error) {
    final AppException e => e,
    final DioException e => NetworkException(e.message ?? 'network error', e),
    _ => _wrapByMessage(error),
  };

  static AppException _wrapByMessage(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('connection') ||
        raw.contains('timed out') ||
        raw.contains('timeout') ||
        raw.contains('network')) {
      return NetworkException(error.toString(), error);
    }
    if (raw.contains('plugin not installed') || raw.contains('trap')) {
      return PluginException(error.toString(), error);
    }
    if (raw.contains('segment') ||
        raw.contains('not ts/mp4') ||
        raw.contains('playlist') ||
        raw.contains('m3u8') ||
        raw.contains('no stream') ||
        raw.contains('recognize file format') ||
        raw.contains('watch')) {
      return SourceException(error.toString(), error);
    }
    return UnknownException(error.toString(), error);
  }
}

/// 网络类：dio/socket/超时归一。
final class NetworkException extends AppException {
  const NetworkException(super.message, [super.cause]);
}

/// 源类：源不可用——无流、HLS 清单/分段格式异常、key 方法不支持。
final class SourceException extends AppException {
  const SourceException(super.message, [super.cause]);
}

/// 扩展类：未安装、装载失败、沙箱 trap。
final class PluginException extends AppException {
  const PluginException(super.message, [super.cause]);
}

/// 播放类：mpv 起播/解码失败。
final class PlaybackException extends AppException {
  const PlaybackException(super.message, [super.cause]);
}

/// 存储类：数据库/文件读写。
final class StorageException extends AppException {
  const StorageException(super.message, [super.cause]);
}

/// 兜底：未识别错误。
final class UnknownException extends AppException {
  const UnknownException(super.message, [super.cause]);
}
