import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../extension/models.dart';
import '../providers/detail_providers.dart';

/// 选集区（设计稿「详情页」5:76）：标题 + 计数，4 列网格（83x47 圆角 8），
/// 点集跳播放；已追番时高亮当前进度集。
class EpisodeSection extends ConsumerWidget {
  const EpisodeSection({
    super.key,
    required this.args,
    required this.episodes,
    required this.onTapEpisode,
  });

  final DetailArgs args;
  final List<Episode> episodes;
  final ValueChanged<Episode> onTapEpisode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final current = ref.watch(followProvider(args)).value?.currentEpisode ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              FlutterI18n.translate(context, 'detail.episodes'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 16,
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (episodes.isNotEmpty)
              Text(
                FlutterI18n.translate(
                  context,
                  'detail.episodeCount',
                  translationParams: {'count': '${episodes.length}'},
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.space3),
        if (episodes.isEmpty)
          Text(
            FlutterI18n.translate(context, 'detail.noEpisodes'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisExtent: 47,
              mainAxisSpacing: AppTokens.space2,
              crossAxisSpacing: AppTokens.space2,
            ),
            itemCount: episodes.length,
            itemBuilder: (context, index) => _EpisodeCell(
              episode: episodes[index],
              selected: current > 0 && index + 1 == current,
              onTap: () => onTapEpisode(episodes[index]),
            ),
          ),
      ],
    );
  }
}

class _EpisodeCell extends StatelessWidget {
  const _EpisodeCell({
    required this.episode,
    required this.selected,
    required this.onTap,
  });

  final Episode episode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textColor = selected
        ? cs.primary
        : cs.onSurface.withValues(alpha: 0.65);
    return Material(
      color: selected
          ? cs.primary.withValues(alpha: 0.15)
          : cs.onSurface.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            episode.title.isEmpty ? episode.url : episode.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
