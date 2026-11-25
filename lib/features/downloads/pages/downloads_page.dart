import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/cache/app_image_cache.dart';
import '../../../data/db/database.dart';
import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/swipe_delete_tile.dart';
import '../providers/download_manager.dart';

/// 下载管理（Figma 98:6 范式）：汇总卡 + 三态分段 + 条目行
/// （封面/标题/来源·集数/进度或状态/右操作）+ 底栏全部暂停·开始全部。
/// 支持动作路由入队：/downloads?enqueue=1&pkg=..&ep=..（播放器选集跳入）。
class DownloadsPage extends ConsumerStatefulWidget {
  const DownloadsPage({super.key, this.enqueueQuery = const {}});

  /// enqueue=1 时的入队参数（routes 从 query 解析）。
  final Map<String, String> enqueueQuery;

  @override
  ConsumerState<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends ConsumerState<DownloadsPage> {
  var _tab = 0;

  @override
  void initState() {
    super.initState();
    if (widget.enqueueQuery['enqueue'] == '1') {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final messenger = ScaffoldMessenger.of(context);
        // 异步前取好文案，catch 里不再跨 gap 用 context。
        final failedPrefix = FlutterI18n.translate(
          context,
          'downloads.enqueueFailed',
        );
        try {
          await ref
              .read(downloadManagerProvider.notifier)
              .enqueueFromQuery(widget.enqueueQuery);
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('$failedPrefix: $e')));
        }
        // 清掉入队参数，避免回退重放。
        if (mounted) context.replace(AppRoutes.downloads);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(downloadManagerProvider);
    final cs = Theme.of(context).colorScheme;
    final downloading = items.where((d) => d.status == 'downloading').length;
    final done = items.where((d) => d.status == 'done').length;
    final totalBytes = items
        .where((d) => d.status == 'done')
        .fold<int>(0, (sum, d) => sum + d.receivedBytes);

    final visible = switch (_tab) {
      1 => items.where(
        (d) => d.status == 'downloading' || d.status == 'queued',
      ),
      2 => items.where((d) => d.status == 'done'),
      _ => items,
    }.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'downloads.title')),
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.download_outlined,
              message: FlutterI18n.translate(context, 'downloads.empty'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                AppTokens.space2,
                AppTokens.space4,
                AppTokens.space6,
              ),
              children: [
                // 汇总卡（帧 98:12~16）。
                Container(
                  height: 64,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.download_outlined, color: cs.primary),
                      const SizedBox(width: AppTokens.space3),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${FlutterI18n.translate(context, 'downloads.summarySize')} '
                              '${formatBytes(totalBytes)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              FlutterI18n.translate(
                                context,
                                'downloads.summaryCount',
                                translationParams: {
                                  'count': '${items.length}',
                                  'downloading': '$downloading',
                                },
                              ),
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.65),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                // 三态分段（帧 98:17~21）。
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      _segButton(
                        0,
                        FlutterI18n.translate(
                          context,
                          'downloads.segAll',
                          translationParams: {'count': '${items.length}'},
                        ),
                      ),
                      _segButton(
                        1,
                        FlutterI18n.translate(
                          context,
                          'downloads.segActive',
                          translationParams: {'count': '$downloading'},
                        ),
                      ),
                      _segButton(
                        2,
                        FlutterI18n.translate(
                          context,
                          'downloads.segDone',
                          translationParams: {'count': '$done'},
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppTokens.space3),
                for (final item in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTokens.space2),
                    child: SwipeDeleteTile(
                      confirmTitleKey: 'downloads.removeTitle',
                      confirmHintKey: 'downloads.removeHint',
                      onDelete: () => ref
                          .read(downloadManagerProvider.notifier)
                          .remove(item.id),
                      child: _DownloadRow(item: item),
                    ),
                  ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                  vertical: AppTokens.space3,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          ref.read(downloadManagerProvider.notifier).pauseAll(),
                      child: Text(
                        FlutterI18n.translate(context, 'downloads.pauseAll'),
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          ref.read(downloadManagerProvider.notifier).startAll(),
                      child: Text(
                        FlutterI18n.translate(context, 'downloads.startAll'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _segButton(int index, String label) {
    final cs = Theme.of(context).colorScheme;
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: active ? cs.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              color: active ? cs.primary : cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

/// 条目行（帧 98:22~42 范式）：56×76 封面 + 标题/来源·集数/进度或状态，
/// 右侧按状态出操作图标；done 点击播放本地文件。
class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({required this.item});

  final Download item;

  String _statusLine(BuildContext context) {
    switch (item.status) {
      case 'queued':
        return FlutterI18n.translate(context, 'downloads.stateQueued');
      case 'downloading':
        final pct = item.totalBytes > 0
            ? (item.receivedBytes / item.totalBytes * 100).round()
            : item.totalSegments > 0
            ? (item.doneSegments / item.totalSegments * 100).round()
            : 0;
        return '$pct% · ${formatBytes(item.receivedBytes)}';
      case 'paused':
        return FlutterI18n.translate(context, 'downloads.statePaused');
      case 'failed':
        return FlutterI18n.translate(context, 'downloads.stateFailed');
      default:
        return FlutterI18n.translate(
          context,
          'downloads.stateDone',
          translationParams: {'size': formatBytes(item.receivedBytes)},
        );
    }
  }

  void _playLocal(BuildContext context) {
    final ep = Uri.encodeComponent(item.localPath);
    final title = Uri.encodeComponent(item.title);
    final bangumi = Uri.encodeComponent(item.bangumiUrl);
    // src 占位传来源包名：本地文件分支在查插件前就返回，src 不会被使用。
    final src = Uri.encodeComponent(item.sourcePackage);
    context.push(
      '${AppRoutes.player}?ep=$ep&src=$src&title=$title&bangumi=$bangumi',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final manager = ref.read(downloadManagerProvider.notifier);

    final (statusColor, trailing, onTap) = switch (item.status) {
      'downloading' || 'queued' => (
        cs.primary,
        IconButton(
          icon: Icon(Icons.pause, color: cs.primary),
          onPressed: () => manager.pause(item.id),
        ),
        null,
      ),
      'paused' || 'failed' => (
        item.status == 'failed'
            ? AppTokens.danger
            : cs.onSurface.withValues(alpha: 0.65),
        IconButton(
          icon: Icon(Icons.play_arrow, color: cs.primary),
          onPressed: () => manager.retry(item.id),
        ),
        () => manager.retry(item.id),
      ),
      _ => (
        cs.onSurface.withValues(alpha: 0.65),
        IconButton(
          icon: Icon(Icons.play_circle_outline, color: cs.primary),
          onPressed: () => _playLocal(context),
        ),
        () => _playLocal(context),
      ),
    };

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space3),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        child: Row(
          children: [
            _Cover(url: item.cover),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.episodeTitle.isEmpty
                        ? item.title
                        : '${item.title} · ${item.episodeTitle}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.sourcePackage,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.status == 'downloading') ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        // 总长已知按字节；HLS 按分段；都未知走不确定态。
                        value: item.totalBytes > 0
                            ? (item.receivedBytes / item.totalBytes).clamp(
                                0.0,
                                1.0,
                              )
                            : item.totalSegments > 0
                            ? (item.doneSegments / item.totalSegments).clamp(
                                0.0,
                                1.0,
                              )
                            : null,
                        minHeight: 4,
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else
                    const SizedBox(height: 6),
                  Text(
                    _statusLine(context),
                    style: TextStyle(fontSize: 12, color: statusColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const width = 56.0;
    const height = 76.0;
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTokens.space2),
        ),
        child: Icon(
          Icons.play_circle_outline,
          size: 24,
          color: cs.onSurface.withValues(alpha: 0.45),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.space2),
      child: CachedImage(url: url, width: width, height: height),
    );
  }
}
