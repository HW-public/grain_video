import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/async_view.dart';
import '../../../data/db/database.dart';
import '../utils/date_format.dart';
import '../providers/me_providers.dart';
import '../widgets/me_empty_state.dart';

/// 追番列表：2:3 封面行 + 进度文案 + 空态（「状态-空态」帧范式）。
///
/// 点击跳详情（src/url 参数为假定契约，待详情页定稿对齐）。
class FollowsPage extends ConsumerWidget {
  const FollowsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final follows = ref.watch(followsListProvider);
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.followsTitle')),
      ),
      body: AsyncView(
        value: follows,
        builder: (context, items) {
          if (items.isEmpty) {
            return MeEmptyState(
              icon: Icons.live_tv_outlined,
              title: FlutterI18n.translate(context, 'me.emptyFollowsTitle'),
              hint: FlutterI18n.translate(context, 'me.emptyFollowsHint'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTokens.space4),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTokens.space3),
            itemBuilder: (context, index) => _FollowItem(
              item: items[index],
              onTap: () => _openDetail(context, items[index]),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, Follow item) {
    context.push(
      '${AppRoutes.detail}?src=${Uri.encodeComponent(item.sourcePackage)}'
      '&url=${Uri.encodeComponent(item.bangumiUrl)}',
    );
  }
}

class _FollowItem extends StatelessWidget {
  const _FollowItem({required this.item, required this.onTap});

  final Follow item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = _progressText(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      onTap: onTap,
      child: Row(
        children: [
          _Poster(url: item.cover),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  progress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  '${FlutterI18n.translate(context, 'me.updatedAt')}'
                  ' ${formatMeDate(item.updatedAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTokens.textTertiary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppTokens.textTertiary,
          ),
        ],
      ),
    );
  }

  String _progressText(BuildContext context) {
    if (item.currentEpisode <= 0) {
      return FlutterI18n.translate(context, 'me.followNotStarted');
    }
    final episode = FlutterI18n.translate(
      context,
      'me.followEpisode',
      translationParams: {'n': '${item.currentEpisode}'},
    );
    if (item.totalEpisode > 0) {
      final total = FlutterI18n.translate(
        context,
        'me.followTotal',
        translationParams: {'n': '${item.totalEpisode}'},
      );
      return '$episode / $total';
    }
    return episode;
  }
}

/// 2:3 封面占位：无图时用浅绿底 + 图标。
class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const width = 64.0;
    const height = width / AppTokens.coverRatioComic;
    final radius = BorderRadius.circular(AppTokens.space2);
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTokens.defaultPalette.primaryContainer,
          borderRadius: radius,
        ),
        child: Icon(
          Icons.movie_outlined,
          size: 24,
          color: AppTokens.defaultPalette.primary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedImage(url: url, width: width, height: height),
    );
  }
}
