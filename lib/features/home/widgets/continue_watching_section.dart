import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cached_image.dart';
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
  // 用户拍板（2026-11-24）：收窄到 3，预览性质不占屏。
  static const int _maxPages = 3;

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
    final follows = ref.watch(followsProvider).value ?? const <Follow>[];
    // 有更新的追番：总集数 > 已看到集数。
    final updated = follows
        .where((f) => f.totalEpisode > 0 && f.totalEpisode > f.currentEpisode)
        .toList();
    return value.when(
      data: (history) {
        final heroItems = _compose(history, updated);
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

  /// 轮播合成（用户拍板 2026-11-24：追更并入轮播，不再单列）：
  /// 1) 观看历史（前 [_maxPages]），有更新的带徽标；
  /// 2) 追了但没进历史（或历史被截断）的更新番补位。
  List<_HeroItem> _compose(List<WatchHistory> history, List<Follow> updated) {
    final items = <_HeroItem>[];
    final byKey = <String, Follow>{
      for (final f in updated) '${f.sourcePackage}|${f.bangumiUrl}': f,
    };
    for (final h in history.take(_maxPages)) {
      final f = byKey.remove('${h.sourcePackage}|${h.bangumiUrl}');
      items.add(
        _HeroItem(
          title: h.title,
          cover: h.cover,
          episodeTitle: h.episodeTitle,
          bangumiUrl: h.bangumiUrl,
          sourcePackage: h.sourcePackage,
          positionMs: h.positionMs,
          durationMs: h.durationMs,
          hasUpdate: f != null,
          latestEpisode: f?.totalEpisode ?? 0,
        ),
      );
    }
    for (final f in byKey.values) {
      if (items.length >= _maxPages) break;
      items.add(
        _HeroItem(
          title: f.title,
          cover: f.cover,
          episodeTitle: '',
          bangumiUrl: f.bangumiUrl,
          sourcePackage: f.sourcePackage,
          positionMs: 0,
          durationMs: 0,
          hasUpdate: true,
          latestEpisode: f.totalEpisode,
        ),
      );
    }
    return items;
  }
}

/// 轮播卡视图模型：观看历史与追番补位共用。
class _HeroItem {
  const _HeroItem({
    required this.title,
    required this.cover,
    required this.episodeTitle,
    required this.bangumiUrl,
    required this.sourcePackage,
    required this.positionMs,
    required this.durationMs,
    required this.hasUpdate,
    required this.latestEpisode,
  });

  final String title;
  final String cover;
  final String episodeTitle;
  final String bangumiUrl;
  final String sourcePackage;
  final int positionMs;
  final int durationMs;

  /// 追更有更新（徽标）。
  final bool hasUpdate;

  /// 更新到的集数（徽标文案）。
  final int latestEpisode;
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item});

  final _HeroItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 卡面主文字色：有封面时压黑渐变上保持白色（两主题通用）；
    // 无封面纯色主色卡上跟随 onPrimary（亮=白 / 暗=深底，保证可读）。
    final fg = item.cover.isNotEmpty ? Colors.white : cs.onPrimary;
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
            // 帧为纯色主色（变量 3:18），非渐变；跟随主题/色板。
            color: cs.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 用户拍板（2026-11-23）：hero 放影片封面图；无图回退纯色主色。
              // 全幅铺图 + 底部渐变压暗，保证文字/播放钮可读。
              if (item.cover.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedImage(url: item.cover, fit: BoxFit.cover),
                ),
              if (item.cover.isNotEmpty)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x99000000)],
                    ),
                  ),
                ),
              // 标签 (18,94)：10/600 白95%，纯文字无底。
              // 纵向位置为用户拍板（2026-11-20）：内容靠下底留20，
              // 帧原值在中偏上（顶42），下方留白72。
              Positioned(
                left: 18,
                top: 94,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ContinueChip(
                      episodeTitle: item.episodeTitle,
                      color: fg.withValues(alpha: 0.95),
                    ),
                    if (item.hasUpdate) ...[
                      const SizedBox(width: 6),
                      const _UpdateBadge(),
                    ],
                  ],
                ),
              ),
              // 标题 (18,112)：19/700 白。
              Positioned(
                left: 18,
                top: 112,
                right: 96,
                child: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
              // 进度文字 (18,138)：11/400 白92%。
              if (hasProgress)
                Positioned(
                  left: 18,
                  top: 138,
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
                    style: TextStyle(
                      fontSize: 11,
                      color: fg.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              // 进度条 y=160：轨道宽120 高4 白30%，填充白100%。
              if (progress != null)
                Positioned(
                  left: 18,
                  top: 160,
                  child: Container(
                    width: 120,
                    height: 4,
                    color: fg.withValues(alpha: 0.30),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress,
                        child: ColoredBox(color: fg),
                      ),
                    ),
                  ),
                ),
              // 播放钮：白圆 44 + 主色三角 24（用户拍板 2026-11-20，
              // 帧为 52/18）；右46，垂直中心对内容块中心（107）。
              Positioned(
                right: 46,
                top: 107,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
                  child: Icon(Icons.play_arrow, size: 24, color: cs.primary),
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.search),
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: _ContinueWatchingSectionState._cardHeight,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  FlutterI18n.translate(context, 'home.continueEmpty'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: cs.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  FlutterI18n.translate(context, 'home.continueEmptyHint'),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onPrimary.withValues(alpha: 0.80),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 「更新至第N集」橙色徽标（追更并入轮播的用户拍板形态）。
class _UpdateBadge extends ConsumerWidget {
  const _UpdateBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 所属卡片已带 latestEpisode，文案经具名参数传入太绕——
    // 徽标只画样式，文案由父级负责注入。
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTokens.mint.secondary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        FlutterI18n.translate(context, 'home.updateBadge'),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 「继续观看 · 第N集」标签（帧 5:34：10/600 白95%，纯文字无底）。
/// 颜色由父卡按有无封面下发（[color]）。
class _ContinueChip extends StatelessWidget {
  const _ContinueChip({required this.episodeTitle, required this.color});

  final String episodeTitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = FlutterI18n.translate(context, 'home.continueWatching');
    final text = episodeTitle.isEmpty ? base : '$base · $episodeTitle';
    return Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
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
    final cs = Theme.of(context).colorScheme;
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
                color: i == page ? cs.primary : Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
