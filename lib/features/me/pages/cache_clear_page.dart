import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/app_image_cache.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/update/app_updater.dart';
import '../providers/me_providers.dart';

/// 设置-缓存清理（Figma 27:213 范式）：环形占比图（按总量分两段：图片缓存/
/// 安装包缓存）+ 缓存总量大字 + 两条按总量缩放的占比条（各带单行清理）+
/// 提示 + 底部通栏「清理全部」主按钮。数据源与旧版一致（真实磁盘统计）。
class CacheClearPage extends ConsumerWidget {
  const CacheClearPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final size = ref.watch(imageCacheSizeProvider);
    final apkSize = ref.watch(apkCacheSizeProvider);
    final imageBytes = size.value ?? 0;
    final apkBytes = apkSize.value ?? 0;
    final total = imageBytes + apkBytes;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.cacheTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          // 汇总卡：左总量大字 + 右环形图。
          Container(
            height: 140,
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        FlutterI18n.translate(context, 'me.cacheTotal'),
                        style: TextStyle(
                          fontSize: 13,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: AppTokens.space1),
                      Text(
                        total <= 0 ? '0 B' : formatBytes(total),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 104,
                  height: 104,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      shares: [
                        if (imageBytes > 0)
                          (share: imageBytes / total, color: cs.primary),
                        if (apkBytes > 0)
                          (share: apkBytes / total, color: cs.secondary),
                      ],
                      trackColor: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          // 占比条：轨道宽按总量缩放，标签 + 条 + 值 + 单行清理。
          _CacheBar(
            labelKey: 'me.cacheImage',
            bytes: imageBytes,
            total: total,
            fillColor: cs.primary,
            onClear: () async {
              await AppImageCache.clear();
              ref.invalidate(imageCacheSizeProvider);
            },
          ),
          const SizedBox(height: AppTokens.space3),
          _CacheBar(
            labelKey: 'me.apkCache',
            bytes: apkBytes,
            total: total,
            fillColor: cs.secondary,
            onClear: () async {
              await AppUpdater.clearApkCache();
              ref.invalidate(apkCacheSizeProvider);
            },
          ),
          const SizedBox(height: AppTokens.space4),
          Text(
            FlutterI18n.translate(context, 'me.cachePreloadNote'),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
              ),
            ),
            onPressed: total <= 0
                ? null
                : () async {
                    await AppImageCache.clear();
                    await AppUpdater.clearApkCache();
                    ref
                      ..invalidate(imageCacheSizeProvider)
                      ..invalidate(apkCacheSizeProvider);
                    if (!context.mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          FlutterI18n.translate(context, 'me.cacheCleared'),
                        ),
                      ),
                    );
                  },
            child: Text(
              FlutterI18n.translate(context, 'me.cacheClearAll'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

/// 占比条行：标签 + 按总量缩放的轨道/填充 + 数值 + 清理按钮。
class _CacheBar extends StatelessWidget {
  const _CacheBar({
    required this.labelKey,
    required this.bytes,
    required this.total,
    required this.fillColor,
    required this.onClear,
  });

  final String labelKey;
  final int bytes;
  final int total;
  final Color fillColor;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTokens.space4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  FlutterI18n.translate(context, labelKey),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                formatBytes(bytes),
                style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: AppTokens.space2),
              InkWell(
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                onTap: bytes <= 0
                    ? null
                    : () async {
                        await onClear();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              FlutterI18n.translate(context, 'me.cacheCleared'),
                            ),
                          ),
                        );
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                  ),
                  child: Text(
                    FlutterI18n.translate(context, 'me.cacheClear'),
                    style: TextStyle(
                      fontSize: 13,
                      color: bytes <= 0
                          ? cs.onSurface.withValues(alpha: 0.45)
                          : cs.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: total <= 0 ? 0 : bytes / total,
              minHeight: 4,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation(fillColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// 环形占比图画笔：按 share 依次画弧，剩余留轨道色。
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.shares, required this.trackColor});

  final List<({double share, Color color})> shares;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    const stroke = 12.0;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2);

    // 轨道（剩余部分）。
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    // 分段（pathLength 思路：从 -90° 起顺时针累计）。
    var start = -math.pi / 2;
    for (final segment in shares) {
      final sweep = 2 * math.pi * segment.share;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.shares != shares || oldDelegate.trackColor != trackColor;
}
