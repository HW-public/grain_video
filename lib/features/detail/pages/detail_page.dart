import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/detail_providers.dart';
import '../widgets/detail_header.dart';
import '../widgets/episode_section.dart';

/// 番剧详情页（二级页，无 bottom nav；对齐设计稿「详情页」5:76）。
///
/// 入参走 queryParams：`url`（条目 url）+ `src`（插件 package）。
/// 结构：薄荷软色块头部（返回键 + 海报探出 + 标题/元信息）→ 简介（可展开）
/// → ▶播放 / ☆收藏 / 🔔追番 按钮行 → 选集网格（4 列）→ 底部安全区留白。
class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.url, required this.src});

  final String url;
  final String src;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = DetailArgs(src: src, url: url);
    final actions = ref.watch(detailActionsProvider);
    final async = ref.watch(bangumiDetailProvider(args));

    // 插件不存在/已卸载：专用空态兜底，不崩。
    if (async is AsyncError<BangumiDetail> &&
        async.error is PluginNotFoundException) {
      return Scaffold(
        body: SafeArea(
          child: EmptyState(
            icon: Icons.extension_off_outlined,
            message: FlutterI18n.translate(context, 'detail.pluginMissing'),
          ),
        ),
      );
    }

    return Scaffold(
      body: AsyncView<BangumiDetail>(
        value: async,
        onRetry: () => actions.retry(args),
        // 骨架屏占位（帧 86:213 范式）：头部色块+海报+选集网格同形。
        loading: const _DetailSkeleton(),
        builder: (context, detail) => _DetailBody(
          args: args,
          entry: ref.watch(detailEntryProvider(args)),
          detail: detail,
        ),
      ),
    );
  }
}

/// 详情页加载骨架：与 _DetailBody 布局同形（头部色块+海报探出+按钮行+选集网格）。
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          // 头部：品牌色块 183h + 海报 104×156 探出。
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 183,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.07),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
              ),
              const Positioned(
                left: 16,
                top: 130,
                child: SkeletonBox(width: 104, height: 156),
              ),
              Positioned(
                left: 132,
                top: 140,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 150, height: 18, radius: 4),
                    SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 13, radius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 120, height: 13, radius: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          // 按钮行 42h。
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: SkeletonBox(height: 42)),
                SizedBox(width: 8),
                SkeletonBox(width: 72, height: 42),
                SizedBox(width: 8),
                SkeletonBox(width: 72, height: 42),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 选集网格：4 列 47h × 2 行。
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                for (var r = 0; r < 2; r++) ...[
                  if (r > 0) const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var c = 0; c < 4; c++) ...[
                        if (c > 0) const SizedBox(width: 8),
                        const Expanded(child: SkeletonBox(height: 47)),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.args,
    required this.entry,
    required this.detail,
  });

  final DetailArgs args;
  final PluginEntry? entry;
  final BangumiDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: [
        DetailHeader(
          entry: entry,
          episodeCount: detail.episodes.length,
          detail: detail,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space3,
            AppTokens.space4,
            AppTokens.space6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Description(text: detail.description),
              const SizedBox(height: AppTokens.space4),
              _ActionBar(args: args, detail: detail),
              const SizedBox(height: AppTokens.space5),
              EpisodeSection(
                args: args,
                episodes: detail.episodes,
                onTapEpisode: (ep) =>
                    _playEpisode(context, args, detail.title, ep),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 跳播放器：按共享契约拼 queryParams（ep/src/title/bangumi）。
void _playEpisode(
  BuildContext context,
  DetailArgs args,
  String title,
  Episode ep,
) {
  context.push(
    '${AppRoutes.player}'
    '?ep=${Uri.encodeComponent(ep.url)}'
    '&src=${Uri.encodeComponent(args.src)}'
    '&title=${Uri.encodeComponent(title)}'
    '&bangumi=${Uri.encodeComponent(args.url)}',
  );
}

/// ▶ 播放（主）/ ☆ 收藏（toggle）/ 🔔 追番（toggle）按钮行。
class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.args, required this.detail});

  final DetailArgs args;
  final BangumiDetail detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.watch(detailActionsProvider);
    final favorite = ref.watch(favoriteProvider(args)).value ?? false;
    final follow = ref.watch(followProvider(args)).value;
    final followed = follow != null;
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final firstEp = detail.episodes.isEmpty ? null : detail.episodes.first;

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: cs.onPrimary,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
              ),
            ),
            onPressed: firstEp == null
                ? null
                : () => _playEpisode(context, args, detail.title, firstEp),
            icon: const Icon(Icons.play_arrow, size: 18),
            label: Text(
              FlutterI18n.translate(context, 'detail.play'),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space2),
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(
            backgroundColor: primary.withValues(alpha: 0.15),
            foregroundColor: primary,
            minimumSize: const Size(72, 42),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            ),
          ),
          onPressed: () {
            actions.toggleFavorite(args, detail);
            // 帧 86:247 底部 Toast 范式：深色胶囊轻提示。
            showAppToast(
              context,
              FlutterI18n.translate(
                context,
                favorite ? 'detail.favoriteRemoved' : 'detail.favoriteAdded',
              ),
              icon: favorite ? Icons.star_border : Icons.check,
            );
          },
          icon: Icon(
            favorite ? Icons.star : Icons.star_border,
            size: 18,
            color: primary,
          ),
          label: Text(
            FlutterI18n.translate(
              context,
              favorite ? 'detail.favorited' : 'detail.favorite',
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: AppTokens.space2),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: cs.onSurface,
            minimumSize: const Size(72, 42),
            side: BorderSide(color: Theme.of(context).dividerColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            ),
          ),
          onPressed: () => actions.toggleFollow(args, detail),
          icon: Icon(
            followed ? Icons.notifications : Icons.notifications_none,
            size: 18,
            color: cs.onSurface,
          ),
          label: Text(
            FlutterI18n.translate(
              context,
              followed ? 'detail.followed' : 'detail.follow',
            ),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}

/// 简介：默认最多 2 行，可展开/收起。
class _Description extends StatefulWidget {
  const _Description({required this.text});

  final String text;

  @override
  State<_Description> createState() => _DescriptionState();
}

class _DescriptionState extends State<_Description> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    if (widget.text.isEmpty) {
      return Text(
        FlutterI18n.translate(context, 'detail.noDescription'),
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: cs.onSurface.withValues(alpha: 0.65),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : 2,
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.only(top: AppTokens.space1),
            child: Text(
              FlutterI18n.translate(
                context,
                _expanded ? 'detail.collapse' : 'detail.expand',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: cs.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
