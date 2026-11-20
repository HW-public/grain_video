import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 共享封面卡片（设计稿横滑行卡片范式）：
/// 16:9 封面（[AppTokens.coverRatioVideo]）+ 标题 + update 角标，整卡可点。
///
/// 横滑条（继续观看 / 各插件「最近更新」）共用本组件；
/// 封面一律 [Image.network] + errorBuilder 占位（不使用 CachedNetworkImage）。
class BangumiCard extends StatelessWidget {
  const BangumiCard({
    super.key,
    required this.coverUrl,
    required this.title,
    this.update = '',
    this.subtitle = '',
    this.progress,
    this.width = 160,
    this.onTap,
  });

  /// 封面图地址；为空或加载失败时显示占位。
  final String coverUrl;

  /// 卡片标题（单行截断）。
  final String title;

  /// 角标文案（「第 12 集」「更至 28」）；为空则不显示。
  final String update;

  /// 标题下方副文案（「樱花源 · 3 天前」）；为空则不显示。
  final String subtitle;

  /// 0~1 播放进度；非空时在封面底缘内嵌进度条。
  final double? progress;

  /// 卡片总宽；封面高度由 16:9 推出。
  final double width;

  final VoidCallback? onTap;

  /// 角标底 `rgba(22,36,31,.72)`（设计稿角标底 #16241F 72%）。
  static const Color badgeBackground = Color(0xB816241F);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _Cover(
              coverUrl: coverUrl,
              update: update,
              progress: progress,
              width: width,
            ),
            const SizedBox(height: AppTokens.space1 + 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTokens.textPrimary,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  // 帧 21:19/4:31 副标规格 11/400。
                  fontSize: 11,
                  color: AppTokens.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({
    required this.coverUrl,
    required this.update,
    required this.progress,
    required this.width,
  });

  final String coverUrl;
  final String update;
  final double? progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress?.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: SizedBox(
        width: width,
        height: width / AppTokens.coverRatioVideo,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (coverUrl.isEmpty)
              const _CoverPlaceholder()
            else
              Image.network(
                coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _CoverPlaceholder(),
              ),
            if (update.isNotEmpty)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: BangumiCard.badgeBackground,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    update,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (clampedProgress != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 3,
                  color: const Color(0x59FFFFFF),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: clampedProgress,
                      child: ColoredBox(
                        // AppPalette 字段是 final 非 const，const 上下文取不到；
                        // 去 const 保留 token 引用（设计 token 单一来源铁律）。
                        color: AppTokens.mint.primarySoft,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 封面占位：浅灰紫底 + 描边图标（与卡片表面区分）。
class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

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
