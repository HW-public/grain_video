import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/swipe_delete_tile.dart';
import '../../../data/db/database.dart';
import '../utils/date_format.dart';
import '../providers/me_providers.dart';
import '../widgets/me_empty_state.dart';

/// 我的历史列表，按 Figma 帧 233:1298「我的-历史」还原：
/// 红色清空（确认后清空）+ 副标题 + 今天/昨天/日期分组 +
/// 三行条目（来源·集数 / 看到进度·相对时间 / 续播）+ 本机保存页脚。
///
/// 保留左滑删除（Dismissible，设计稿未禁止）。
class WatchHistoryPage extends ConsumerWidget {
  const WatchHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryListProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.historyTitle')),
        actions: [
          history.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: () => _confirmClear(context, ref, items.length),
                    child: Text(
                      FlutterI18n.translate(context, 'me.clear'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTokens.danger,
                      ),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
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
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space2,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppTokens.space1,
                  bottom: AppTokens.space2,
                ),
                child: Text(
                  FlutterI18n.translate(
                    context,
                    'me.totalHistory',
                    translationParams: {'count': '${items.length}'},
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              ..._buildGrouped(context, ref, items),
              const SizedBox(height: AppTokens.space6),
              Padding(
                padding: const EdgeInsets.only(left: AppTokens.space1),
                child: Text(
                  FlutterI18n.translate(context, 'me.onlyLocalHistory'),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 按 今天/昨天/日期 分组；组标签变化时插入标题行。
  List<Widget> _buildGrouped(
    BuildContext context,
    WidgetRef ref,
    List<WatchHistory> items,
  ) {
    final widgets = <Widget>[];
    String? lastLabel;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final labelKey = formatMeGroupLabel(item.updatedAt);
      if (labelKey != lastLabel) {
        lastLabel = labelKey;
        widgets.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space1,
              AppTokens.space3,
              0,
              AppTokens.space1,
            ),
            child: Text(
              labelKey.startsWith('me.')
                  ? FlutterI18n.translate(context, labelKey)
                  : labelKey,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        );
      }
      // 左滑露出删除按钮 → 点击 → 二次确认后移除。
      widgets.add(
        SwipeDeleteTile(
          confirmTitleKey: 'me.deleteHistoryTitle',
          confirmHintKey: 'me.deleteHistoryHint',
          onDelete: () async =>
              ref.read(watchHistoryListProvider.notifier).remove(item.id),
          child: _HistoryItem(
            item: item,
            isLatest: i == 0,
            onTap: () => _play(context, item),
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _confirmClear(
    BuildContext context,
    WidgetRef ref,
    int count,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: FlutterI18n.translate(context, 'me.clearHistoryTitle'),
      message: FlutterI18n.translate(
        context,
        'me.clearHistoryConfirm',
        translationParams: {'count': '$count'},
      ),
      cancelLabel: FlutterI18n.translate(context, 'me.cancel'),
      confirmLabel: FlutterI18n.translate(context, 'me.clear'),
      danger: true,
    );
    if (confirmed == true) {
      await ref.read(watchHistoryListProvider.notifier).clearAll();
    }
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
  const _HistoryItem({
    required this.item,
    required this.isLatest,
    required this.onTap,
  });

  final WatchHistory item;
  final bool isLatest;
  final VoidCallback onTap;

  /// 第三行：看到 mm:ss · 相对时间；无进度时只显示相对时间。
  String _progressLine(BuildContext context) {
    final time = _relativeTime(context, item.updatedAt);
    if (item.positionMs <= 0) return time;
    return '${FlutterI18n.translate(context, 'me.watchedTo')} '
        '${formatPositionClock(item.positionMs)} · $time';
  }

  String _relativeTime(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) {
      return FlutterI18n.translate(context, 'me.justNow');
    }
    if (diff.inHours < 1) {
      return FlutterI18n.translate(
        context,
        'me.minutesAgo',
        translationParams: {'count': '${diff.inMinutes}'},
      );
    }
    if (diff.inHours < 24) {
      return FlutterI18n.translate(
        context,
        'me.hoursAgo',
        translationParams: {'count': '${diff.inHours}'},
      );
    }
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    if (today.difference(day).inDays == 1) {
      return FlutterI18n.translate(context, 'me.yesterday');
    }
    return formatMeDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final episodeLine = item.episodeTitle.isEmpty
        ? item.sourcePackage
        : '${item.sourcePackage} · ${item.episodeTitle}';
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    episodeLine,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    _progressLine(context),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isLatest)
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.space3),
                child: Text(
                  '${FlutterI18n.translate(context, 'me.playContinue')} ›',
                  style: TextStyle(fontSize: 13, color: cs.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 封面占位（设计稿统一 56×76 竖版槽）：无图时浅绿底 + 图标。
class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const width = 56.0;
    const height = 76.0;
    final radius = BorderRadius.circular(AppTokens.space2);
    if (url.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.15),
          borderRadius: radius,
        ),
        child: Icon(Icons.play_circle_outline, size: 24, color: cs.primary),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedImage(url: url, width: width, height: height),
    );
  }
}
