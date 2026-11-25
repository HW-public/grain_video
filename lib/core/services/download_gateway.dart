import 'package:flutter/foundation.dart';

/// 跨 feature 动作网关：features 之间禁止互引，下载入队这类
/// 「触发即忘」动作经本网关转发——下载 feature 启动时注册实现，
/// 调用方（如播放器选集弹层）只依赖本文件的纯函数签名。
///
/// 参数约定：pkg/bangumi/ep/title/cover/eptitle。
typedef EnqueueDownload = Future<void> Function(Map<String, String> params);

abstract final class DownloadGateway {
  static EnqueueDownload? enqueue;

  /// 同步查询该集是否已在下载队列/已完成（隐藏重复入队入口）。
  static bool Function(String package, String episodeUrl)? isEnqueued;

  /// 下载状态版本号：任何状态变化 +1，调用方据此重建查询。
  static final ValueNotifier<int> version = ValueNotifier(0);
}
