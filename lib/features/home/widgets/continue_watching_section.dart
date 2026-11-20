import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../data/db/database.dart';
import '../providers/home_providers.dart';
import 'section_header.dart';

/// 「继续观看」hero 大卡（设计稿 4:31 / 节点 5:34，帧 390×844 坐标系）：
/// 纯色主色圆角大卡（高184/圆角24），左上标签+标题+上次看到+进度条，
/// 右侧 52 白圆播放钮；多条历史轮播，卡下居中指示点；
/// 无历史显示占位提醒卡（用户拍板：帧未画空态，占位保留 hero 位）。
class ContinueWatchingSection extends ConsumerStatefulWidget {
  const ContinueWatchingSection({super.key});

  @override
  ConsumerState<ContinueWatchingSection> createState() =>
      _ContinueWatchingSectionState();
}

class _ContinueWatchingSectionState
    extends ConsumerState<ContinueWatchingSection> {
  static const double _cardHeight = 184;
  static const int _maxPages = 5;

  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(recentWatchProvider);
    return value.when(
      data: (items) {
        final heroItems = items.take(_maxPages).toList();
        if (heroItems.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: _EmptyHeroCard(),
          );
        }
        return Column(
          children: [
            SizedBox(
              height: _cardHeight,
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: heroItems.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                  ),
                  child: _HeroCard(item: heroItems[i]),
                ),
              ),
            ),
            if (heroItems.length > 1)
              _Dots(count: heroItems.length, page: _page),
          ],
        );
      },
      loading: () => const SectionLoading(),
      error: (error, _) => SectionError(
        error: error,
        onRetry: () => ref.invalidate(recentWatchProvider),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item});

  final WatchHistory item;

  // 白色透明度（帧规格）：标签 95%、副文案 92%、进度轨道 30%。
  static const _white92 = Color(0xEBFFFFFF);
  static const _white30 = Color(0x4DFFFFFF);

  @override
  Widget build(BuildContext context) {
    final durationMs = item.durationMs;
    final hasProgress = durationMs > 0;
    final progress = hasProgress
        ? (item.positionMs / durationMs).clamp(0.0, 1.0)
        : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(
          '${AppRoutes.detail}'
          '?url=${Uri.encodeComponent(item.bangumiUrl)}'
          '&src=${Uri.encodeComponent(item.sourcePackage)}',
        ),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            // 帧为纯色主色（变量 3:18），非渐变。
            color: AppTokens.mint.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // 标签 (18,42)：10/600 白95%，纯文字无底。
              Positioned(
                left: 18,
                top: 42,
                child: _ContinueChip(episodeTitle: item.episodeTitle),
              ),
              // 标题 (18,60)：19/700 白。
              Positioned(
                left: 18,
                top: 60,
                right: 96,
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              // 进度文字 (18,86)：11/400 白92%。
              if (hasProgress)
                Positioned(
                  left: 18,
                  top: 86,
                  child: Text(
                    // i18n 模板插值：{{position}} / {{duration}}。
                    FlutterI18n.translate(
                      context,
                      'home.lastSeen',
                      translationParams: {
                        'position': _formatMs(item.positionMs),
                        'duration': _formatMs(durationMs),
                      },
                    ),
                    style: const TextStyle(fontSize: 11, color: _white92),
                  ),
                ),
              // 进度条 y=108：轨道宽120 高4 白30%，填充白100%。
              if (progress != null)
                Positioned(
                  left: 18,
                  top: 108,
                  child: Container(
                    width: 120,
                    height: 4,
                    color: _white30,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: const ColoredBox(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              // 播放钮：52 白圆，圆心相对卡左上 (286,74)（右留46），▶ 18 主色。
              Positioned(
                right: 46,
                top: 48,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: 18,
                    color: AppTokens.mint.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatMs(int ms) {
    final totalSeconds = ms ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

/// 无观看历史的占位 hero（用户拍板 2026-11-20）：同款薄荷大卡，
/// 居中白色提醒文案，点按去搜索页挑内容。
class _EmptyHeroCard extends StatelessWidget {
  const _EmptyHeroCard();

  static const _white80 = Color(0xCCFFFFFF);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: _ContinueWatchingSectionState._cardHeight,
          decoration: BoxDecoration(
            color: AppTokens.mint.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  FlutterI18n.translate(context, 'home.continueEmpty'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FlutterI18n.translate(context, 'home.continueEmptyHint'),
                  style: const TextStyle(fontSize: 12, color: _white80),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 「继续观看 · 第N集」标签（帧 5:34：10/600 白95%，纯文字无底）。
class _ContinueChip extends StatelessWidget {
  const _ContinueChip({required this.episodeTitle});

  final String episodeTitle;

  @override
  Widget build(BuildContext context) {
    final base = FlutterI18n.translate(context, 'home.continueWatching');
    final text = episodeTitle.isEmpty ? base : '$base · $episodeTitle';
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: Color(0xF2FFFFFF),
      ),
    );
  }
}

/// 轮播指示点：未选 6×6 正圆 divider；选中 18×6 圆角3 主色；
/// 项间距 7，距卡底 12，水平居中。
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.page});

  final int count;
  final int page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            Container(
              width: i == page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == page ? AppTokens.mint.primary : AppTokens.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
