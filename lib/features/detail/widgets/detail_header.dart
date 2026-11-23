import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';

/// 详情页头部（设计稿「详情页」5:76）：
/// 薄荷软色块 + 悬浮返回键，海报（104x156 圆角 16）从色块下沿探出，
/// 标题/元信息/来源排在海报右侧同一 Stack 内。
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.entry,
    required this.episodeCount,
    required this.detail,
  });

  /// 来源插件（未找到时为 null，来源行不显示）。
  final PluginEntry? entry;

  final int episodeCount;
  final BangumiDetail detail;

  /// 色块高度（设计稿 183）。
  static const double _blockHeight = 183;

  /// 海报探出色块的高度（设计稿 53）。
  static const double _posterOverlap = 53;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: _blockHeight + _posterOverlap,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: _blockHeight,
              width: double.infinity,
              child: ColoredBox(color: AppTokens.defaultPalette.primarySoft),
            ),
          ),
          SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Positioned(
            left: AppTokens.space4,
            top: 130,
            child: _Poster(cover: detail.cover),
          ),
          Positioned(
            left: AppTokens.space4 + 104 + AppTokens.space3,
            top: 182,
            right: AppTokens.space4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    color: AppTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  FlutterI18n.translate(
                    context,
                    'detail.totalEpisodes',
                    translationParams: {'count': '$episodeCount'},
                  ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppTokens.textSecondary,
                  ),
                ),
                if (entry != null)
                  Text(
                    FlutterI18n.translate(
                      context,
                      'detail.source',
                      translationParams: {'name': entry!.info.name},
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: AppTokens.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 海报卡：2:3 封面 + 圆角 16，加载失败/为空时用浅灰紫块兜底。
class _Poster extends StatelessWidget {
  const _Poster({required this.cover});

  final String cover;

  @override
  Widget build(BuildContext context) {
    const size = 104.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: size,
        height: size / AppTokens.coverRatioComic,
        child: cover.isEmpty
            ? const ColoredBox(color: AppTokens.surfaceAlt)
            : CachedImage(url: cover),
      ),
    );
  }
}
