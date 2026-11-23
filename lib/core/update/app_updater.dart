import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'app_release.dart';

/// App 自升级：远端检查（GitHub Releases，镜像链兜底）→ 下载 APK → 系统安装器。
///
/// 强制更新标记：release body 以 `[force]` 行开头（CI 发版时写）。
abstract final class AppUpdater {
  static const _repoApi =
      'https://api.github.com/repos/HW-public/grain_video/releases/latest';

  /// GitHub 加速镜像前缀（本机/弱网环境直连 github.com 不可达），逐个尝试。
  static const _mirrorPrefixes = [
    'https://ghfast.top/',
    'https://mirror.ghproxy.com/',
    '',
  ];

  static final _dio = Dio(
    BaseOptions(connectTimeout: const Duration(seconds: 8)),
  );

  /// 当前应用版本（x.y.z）。
  static Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 拉取最新 release（镜像链首个成功者）。
  static Future<AppRelease> fetchLatestRelease() async {
    Object? lastError;
    for (final prefix in _mirrorPrefixes) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(prefix + _repoApi);
        final release = AppRelease.fromGitHubJson(res.data!);
        if (release != null) return release;
        lastError = StateError('release 无 APK 资产');
      } on Object catch (e) {
        lastError = e;
      }
    }
    throw StateError('检查更新失败: $lastError');
  }

  /// 判断 release 是否为可升级的新版本。
  static Future<bool> isUpdateAvailable(AppRelease release) async {
    final current = await currentVersion();
    return isNewerVersion(current: current, latest: release.version);
  }

  static Future<Directory> _apkDir() async {
    final cache = await getTemporaryDirectory();
    final dir = Directory('${cache.path}${Platform.pathSeparator}apk_updates');
    await dir.create(recursive: true);
    return dir;
  }

  /// 下载 APK（镜像链同上），[onProgress] 回调 0~1。
  static Future<File> downloadApk(
    AppRelease release, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _apkDir();
    final file = File(
      '${dir.path}${Platform.pathSeparator}grain_video_${release.version}.apk',
    );
    Object? lastError;
    for (final prefix in _mirrorPrefixes) {
      try {
        await _dio.download(
          prefix + release.apkUrl,
          file.path,
          onReceiveProgress: (received, total) {
            if (total > 0) onProgress?.call(received / total);
          },
        );
        if (await file.exists() && await file.length() > 0) return file;
        lastError = StateError('下载文件为空');
      } on Object catch (e) {
        lastError = e;
      }
    }
    throw StateError('下载失败: $lastError');
  }

  /// 调系统安装器安装 APK；用户需授予「安装未知应用」权限。
  static Future<OpenResult> installApk(File apk) {
    return OpenFilex.open(apk.path);
  }

  /// 安装包缓存占用（字节）。
  static Future<int> apkCacheBytes() async {
    try {
      final cache = await getTemporaryDirectory();
      final dir = Directory(
        '${cache.path}${Platform.pathSeparator}apk_updates',
      );
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list()) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } on Object {
      return 0;
    }
  }

  /// 清空安装包缓存。
  static Future<void> clearApkCache() async {
    try {
      final cache = await getTemporaryDirectory();
      final dir = Directory(
        '${cache.path}${Platform.pathSeparator}apk_updates',
      );
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object {
      // 清理失败不阻塞。
    }
  }
}
