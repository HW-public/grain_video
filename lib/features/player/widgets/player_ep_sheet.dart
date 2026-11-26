import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/download_gateway.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/tokens.dart';
import '../providers/player_providers.dart';

/// 亮底弹层骨架（选集/倍速共用）：surface 底 + 深色文字，选中=主色。
/// 设计稿「播放设置」弹层范式（帧 86:225）：顶部拖拽把手 + 居中标题，
/// 无关闭钮（下滑/点遮罩关闭）。
Future<T?> showPlayerSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖拽把手（帧顶部小横条）。
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: child),
            ],
          ),
        ),
      );
    },
  );
}

/// 选集弹层：剧集列表，当前集主色标记，点击换集并关闭。
Future<void> showPlayerEpSheet(BuildContext context) {
  final state = ProviderScope.containerOf(
    context,
  ).read(playerControllerProvider);
  final episodes = state.episodes;
  return showPlayerSheet(
    context,
    title: FlutterI18n.translate(context, 'player.episodes'),
    child: episodes.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                FlutterI18n.translate(context, 'player.emptyEpisodes'),
                style: const TextStyle(color: AppTokens.textSecondary),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: episodes.length,
            itemBuilder: (_, i) {
              final current = i == state.currentEpIndex;
              final title = episodes[i].title.isEmpty
                  ? '${i + 1}'
                  : episodes[i].title;
              return ListTile(
                dense: true,
                title: Text(
                  title,
                  style: TextStyle(
                    color: current
                        ? AppTokens.defaultPalette.primary
                        : AppTokens.textPrimary,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (current)
                      Icon(
                        Icons.check,
                        color: AppTokens.defaultPalette.primary,
                      ),
                    // 下载入口：就地入队 + 图标变勾动画（不跳页）。
                    // 当前集也显示（单集番剧否则永远看不到下载入口）。
                    _EnqueueDownloadIcon(
                      params: {
                        'pkg': ProviderScope.containerOf(
                          context,
                        ).read(playerControllerProvider).args.src,
                        'bangumi': ProviderScope.containerOf(
                          context,
                        ).read(playerControllerProvider).args.bangumi,
                        'ep': episodes[i].url,
                        'title': ProviderScope.containerOf(
                          context,
                        ).read(playerControllerProvider).args.title,
                        'eptitle': episodes[i].title,
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(
                    ProviderScope.containerOf(context)
                        .read(playerControllerProvider.notifier)
                        .switchEpisode(episodes[i].url),
                  );
                },
              );
            },
          ),
  );
}

/// 倍速弹层：「播放设置」内 chips 单选（帧 86:225：五档均分一行，
/// 选中=实心主色底+深字），点击立即生效并关闭。
Future<void> showPlayerSpeedSheet(BuildContext context) {
  const speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
  final current = ProviderScope.containerOf(
    context,
  ).read(playerControllerProvider).rate;

  return showPlayerSheet(
    context,
    title: FlutterI18n.translate(context, 'player.settings'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 预加载开关（用户拍板 2026-11-23：L1 预解析 + L2 播放单预缓冲）。
        _PreloadTile(),
        const Divider(height: 17, color: AppTokens.divider),
        Text(
          FlutterI18n.translate(context, 'player.speed'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 0; i < speeds.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _SpeedChip(
                  label: '${speeds[i]}x',
                  selected: speeds[i] == current,
                  onTap: () {
                    Navigator.of(context).pop();
                    unawaited(
                      ProviderScope.containerOf(context)
                          .read(playerControllerProvider.notifier)
                          .setRate(speeds[i]),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          // 帧 86:225：选中=实心主色底，未选=浅灰底。
          color: selected
              ? AppTokens.defaultPalette.primary
              : AppTokens.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppTokens.textPrimary : AppTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// 预加载下一集开关（持久化在 shared_preferences）。
class _PreloadTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(preloadNextProvider);
    return SwitchListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(
        FlutterI18n.translate(context, 'player.preloadNext'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTokens.textPrimary,
        ),
      ),
      subtitle: Text(
        FlutterI18n.translate(context, 'player.preloadNextDesc'),
        style: const TextStyle(fontSize: 11, color: AppTokens.textTertiary),
      ),
      value: enabled,
      activeColor: AppTokens.defaultPalette.primary,
      onChanged: (v) =>
          unawaited(ref.read(preloadNextProvider.notifier).set(v)),
    );
  }
}

/// 选集行内下载按钮：点按经 DownloadGateway 就地入队，
/// 图标下载→对勾 morph（900ms）代表已进入下载队列；失败弹提示并还原。
class _EnqueueDownloadIcon extends StatefulWidget {
  const _EnqueueDownloadIcon({required this.params});

  final Map<String, String> params;

  @override
  State<_EnqueueDownloadIcon> createState() => _EnqueueDownloadIconState();
}

class _EnqueueDownloadIconState extends State<_EnqueueDownloadIcon> {
  var _done = false;
  var _busy = false;

  Future<void> _tap() async {
    if (_busy || _done) return;
    final enqueue = DownloadGateway.enqueue;
    final messenger = ScaffoldMessenger.of(context);
    final failedPrefix = FlutterI18n.translate(
      context,
      'downloads.enqueueFailed',
    );
    if (enqueue == null) {
      messenger.showSnackBar(SnackBar(content: Text(failedPrefix)));
      return;
    }
    setState(() => _busy = true);
    try {
      await enqueue(widget.params);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _done = true;
      });
      // 图标变勾动画：勾停留 900ms 后还原为下载图标。
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _done = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(SnackBar(content: Text('$failedPrefix: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _done
        ? AppTokens.defaultPalette.primary
        : AppTokens.textTertiary;
    // 已入队（排队/下载中/暂停/完成）则隐藏入口，防重复入队；
    // 下载状态变化经 DownloadGateway.version 触发重建。
    return ValueListenableBuilder<int>(
      valueListenable: DownloadGateway.version,
      builder: (context, _, child) {
        final enqueued =
            DownloadGateway.isEnqueued?.call(
              widget.params['pkg'] ?? '',
              widget.params['ep'] ?? '',
            ) ??
            false;
        if (enqueued) return const SizedBox.shrink();
        return child!;
      },
      child: IconButton(
        tooltip: FlutterI18n.translate(context, 'downloads.enqueue'),
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Icon(
            _done ? Icons.check : Icons.download_outlined,
            key: ValueKey(_done),
            size: 20,
            color: color,
          ),
        ),
        onPressed: _tap,
      ),
    );
  }
}
