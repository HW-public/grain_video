import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../cache/app_image_cache.dart';
import '../theme/tokens.dart';

/// 带磁盘缓存的网络图（cached_network_image 封装）：
/// 命中即秒显，未命中/失败时显示统一占位（surfaceAlt 底 + 图标）。
///
/// 规格与原裸 Image.network 一致：cover 填充、圆角由调用方 ClipRRect 控制。
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      cacheManager: AppImageCache.instance,
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: width?.round(),
      placeholder: (_, _) => const _ImagePlaceholder(),
      errorWidget: (_, _, _) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppTokens.surfaceAlt,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: AppTokens.textTertiary,
        ),
      ),
    );
  }
}
