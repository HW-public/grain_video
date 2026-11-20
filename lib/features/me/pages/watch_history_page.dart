import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../data/db/database.dart';
import '../utils/date_format.dart';
import '../providers/me_providers.dart';
import '../widgets/me_empty_state.dart';

/// 观看历史列表：AsyncView 三态 + 空态走「状态-空态」帧范式。
///
/// 点击条目跳播放器（ep/src/title/bangumi 四参数，见路由契约）。
class WatchHistoryPage extends ConsumerWidget {
  const WatchHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryListProvider);
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.historyTitle')),
      ),
      body: AsyncView(
        value: history,
        onRetry: () => ref.read(watchHistoryListProvider.notifier).refresh(),
        builder: (context, items) {
          if (items.isEmpty) {
            return MeEmptyState(
              icon: Icons.history,
              title: FlutterI18n.translate(context, 'me.emptyHistoryTitle'),
              hint: FlutterI18n.translate(context, 'me.emptyHistoryHint'),
              actionLabel: FlutterI18n.translate(context, 'me.emptyGo'),
              onAction: () => context.go(AppRoutes.home),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTokens.space4),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTokens.space3),
            itemBuilder: (context, index) {
              final item = items[index];
              // 左滑删除：滑掉即从数据库移除并刷新列表。
              return Dismissible(
                key: ValueKey('history-${item.id}'),
                direction: DismissDirection.endToStart,
                background: const _DeleteBackground(),
                onDismissed: (_) =>
                    ref.read(watchHistoryListProvider.notifier).remove(item.id),
                child: _HistoryItem(
                  item: item,
                  onTap: () => _play(context, item),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _play(BuildContext context, WatchHistory item) {
    final location =
        '${AppRoutes.player}?ep=${Uri.encodeComponent(item.episodeUrl)}'
        '&src=${Uri.encodeComponent(item.sourcePackage)}'
        '&title=${Uri.encodeComponent(item.title)}'
        '&bangumi=${Uri.encodeComponent(item.bangumiUrl)}';
    context.push(location);
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.item, required this.onTap});

  final WatchHistory item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Cover(url: item.cover),
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
                  item.episodeTitle.isEmpty
                      ? formatMeDate(item.updatedAt)
                      : '${item.episodeTitle} · ${formatMeDate(item.updatedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary,
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
}

/// 左滑删除露出的背景：危险色底 + 删除图标/文字，靠右对齐。
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.danger,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppTokens.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.delete_outline, color: Colors.white, size: 20),
          const SizedBox(width: AppTokens.space1),
          Text(
            FlutterI18n.translate(context, 'me.delete'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// 16:9 封面占位：无图时用浅绿底 + 图标。
class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const width = 120.0;
    const height = width / AppTokens.coverRatioVideo;
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
          Icons.play_circle_outline,
          size: 28,
          color: AppTokens.defaultPalette.primary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: Image.network(
        url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: width,
          height: height,
          color: AppTokens.defaultPalette.primaryContainer,
          child: Icon(
            Icons.play_circle_outline,
            size: 28,
            color: AppTokens.defaultPalette.primary,
          ),
        ),
      ),
    );
  }
}
