import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';

/// 应用图片缓存：磁盘缓存（对象数上限 + 30 天过期；
/// flutter_cache_manager 3.x 已不支持字节上限，以对象数控量），
/// 与「我的 → 缓存清理」联动（统计/清理走本类）。
abstract final class AppImageCache {
  static const _key = 'app_image_cache';
  static const int maxObjects = 1000;
  static const Duration stalePeriod = Duration(days: 30);

  static CacheManager? _instance;

  /// 全应用共用一个 CacheManager（上限/过期在此配置）。
  static CacheManager get instance =>
      _instance ??= CacheManager(
        Config(
          _key,
          maxNrOfCacheObjects: maxObjects,
          stalePeriod: stalePeriod,
        ),
      );

  /// 缓存目录（cache_manager 存于临时目录下以 [_key] 命名的子目录）。
  static Future<Directory> cacheDir() async {
    final tmp = await getTemporaryDirectory();
    return Directory('${tmp.path}${Platform.pathSeparator}$_key');
  }

  /// 当前磁盘占用（字节）；目录不可读时返回 0。
  static Future<int> sizeBytes() async {
    try {
      final dir = await cacheDir();
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } on Object {
      return 0;
    }
  }

  /// 清空图片缓存（含内存表与磁盘文件）。
  static Future<void> clear() async {
    try {
      await instance.emptyCache();
      final dir = await cacheDir();
      if (await dir.exists()) await dir.delete(recursive: true);
    } on Object {
      // 清理失败不阻塞 UI。
    }
  }
}

/// 人类可读体积（B/KB/MB，保留一位小数）。
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
  return '${(kb / 1024).toStringAsFixed(1)} MB';
}
