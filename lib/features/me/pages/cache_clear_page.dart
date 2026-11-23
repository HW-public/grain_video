import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/app_image_cache.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/update/app_updater.dart';
import '../providers/me_providers.dart';
import '../widgets/me_list_card.dart';

/// 设置-缓存清理：图片磁盘缓存 + 安装包缓存真实统计与清理；
/// 视频预加载缓冲为内存占用（不持久），页内说明。
class CacheClearPage extends ConsumerWidget {
  const CacheClearPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(imageCacheSizeProvider);
    final apkSize = ref.watch(apkCacheSizeProvider);
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.cacheTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          MeListCard(
            children: [
              _CacheRow(
                icon: Icons.image_outlined,
                labelKey: 'me.cacheImage',
                size: size,
                onClear: () async {
                  await AppImageCache.clear();
                  ref.invalidate(imageCacheSizeProvider);
                },
              ),
              _CacheRow(
                icon: Icons.android_outlined,
                labelKey: 'me.apkCache',
                size: apkSize,
                onClear: () async {
                  await AppUpdater.clearApkCache();
                  ref.invalidate(apkCacheSizeProvider);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            FlutterI18n.translate(context, 'me.cachePreloadNote'),
            style: const TextStyle(
              fontSize: 12,
              color: AppTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// 单行缓存项：图标 + 标签 + 实时大小 + 清理按钮。
class _CacheRow extends StatelessWidget {
  const _CacheRow({
    required this.icon,
    required this.labelKey,
    required this.size,
    required this.onClear,
  });

  final IconData icon;
  final String labelKey;
  final AsyncValue<int> size;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppTokens.textPrimary),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Text(
                FlutterI18n.translate(context, labelKey),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.textPrimary,
                ),
              ),
            ),
            Text(
              size.when(
                data: formatBytes,
                loading: () => '…',
                error: (_, _) => '—',
              ),
              style: const TextStyle(fontSize: 13, color: AppTokens.textTertiary),
            ),
            const SizedBox(width: AppTokens.space2),
            TextButton(
              onPressed: () async {
                await onClear();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        FlutterI18n.translate(context, 'me.cacheCleared'),
                      ),
                    ),
                  );
                }
              },
              child: Text(
                FlutterI18n.translate(context, 'me.cacheClear'),
                style: TextStyle(color: AppTokens.defaultPalette.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
