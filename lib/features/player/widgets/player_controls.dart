import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/player_providers.dart';
import 'player_ep_sheet.dart';

/// 进度时间格式化：h:mm:ss / m:ss。
String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '${d.inMinutes}:$s';
}

/// 播放页进度条：轨道 + 已播条 + 手柄，点击/拖拽即 seek。
///
/// [dark] 为暗夜（横屏遮罩）样式；浅色 body 传 false。
class PlayerSeekBar extends StatefulWidget {
  const PlayerSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.dark = false,
  });

  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final bool dark;

  @override
  State<PlayerSeekBar> createState() => _PlayerSeekBarState();
}

class _PlayerSeekBarState extends State<PlayerSeekBar> {
  double? _dragFraction;

  Color _trackColor(BuildContext context) =>
      widget.dark ? const Color(0x33FFFFFF) : Theme.of(context).dividerColor;
  Color _playedColor(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  void _update(double dx, double width) {
    final fraction = (dx / width).clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (fraction * widget.duration.inMilliseconds).round(),
    );
    setState(() => _dragFraction = fraction);
    widget.onSeek(target);
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.duration;
    final base = duration.inMilliseconds > 0
        ? widget.position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final fraction = (_dragFraction ?? base).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _update(d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragUpdate: (d) =>
              _update(d.localPosition.dx, constraints.maxWidth),
          onHorizontalDragEnd: (_) => setState(() => _dragFraction = null),
          onHorizontalDragCancel: () => setState(() => _dragFraction = null),
          child: SizedBox(
            height: 28,
            child: Align(
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _trackColor(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: _playedColor(context),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: fraction * (constraints.maxWidth - 14),
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(blurRadius: 6, color: Color(0x59000000)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 控制行：播放/暂停、±10s、下一集、倍速、选集、全屏切换。
///
/// [dark] 同 [PlayerSeekBar]；全屏/退出由 [onFullscreen] 回调给页面。
class PlayerCtrlRow extends ConsumerWidget {
  const PlayerCtrlRow({
    super.key,
    required this.playing,
    required this.dark,
    this.fullscreen = false,
    this.onFullscreen,
  });

  final bool playing;
  final bool dark;
  final bool fullscreen;
  final VoidCallback? onFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final state = ref.watch(playerControllerProvider);
    final player = ref.watch(playerProvider);
    final iconColor = dark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final hasNext =
        state.currentEpIndex >= 0 &&
        state.currentEpIndex + 1 < state.episodes.length;

    // 不写死行高：系统字体放大时按钮 intrinsic 高度可能超 48，
    // 硬约束会触发 BOTTOM OVERFLOW（用户真机抓包）。
    // 布局（用户拍板 2026-11-26）：左组=播放/下一集/时间，右组=倍速/选集/全屏；
    // 时间用 Expanded 吃掉中间余量，把右组顶到行尾（兼作溢出缓冲）。
    // 按钮统一紧凑化（用户拍板：组内 icon 间距调小）。
    const iconBtnPadding = EdgeInsets.symmetric(horizontal: 4);
    const iconBtnConstraints = BoxConstraints(minWidth: 36, minHeight: 36);
    final textBtnStyle = TextButton.styleFrom(
      foregroundColor: iconColor,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      minimumSize: const Size(0, 36),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Row(
      children: [
        IconButton(
          tooltip: playing ? 'pause' : 'play',
          iconSize: 28,
          color: iconColor,
          padding: iconBtnPadding,
          constraints: iconBtnConstraints,
          icon: Icon(playing ? Icons.pause : Icons.play_arrow),
          onPressed: controller.toggle,
        ),
        // ±10s 按钮已去（用户拍板 2026-11-26）：屏幕双击手势已覆盖。
        if (hasNext)
          // 下一集：纯图标（用户拍板 2026-11-26，不要文字）。
          IconButton(
            tooltip: FlutterI18n.translate(context, 'player.next'),
            iconSize: 24,
            color: iconColor,
            padding: iconBtnPadding,
            constraints: iconBtnConstraints,
            icon: const Icon(Icons.skip_next),
            onPressed: () => unawaited(controller.nextEpisode()),
          ),
        // 进度时间：当前/总长，跟在「下一集」后（左组末尾）。
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              '${formatDuration(player.state.position)}/'
              '${formatDuration(player.state.duration)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: iconColor.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
        TextButton(
          style: textBtnStyle,
          onPressed: () => showPlayerSpeedSheet(context),
          child: Text(
            '${state.rate.toStringAsFixed(state.rate.truncateToDouble() == state.rate ? 1 : 2)}x',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        if (state.episodes.isNotEmpty)
          TextButton(
            style: textBtnStyle,
            onPressed: () => showPlayerEpSheet(context),
            child: Text(
              FlutterI18n.translate(context, 'player.episodes'),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        IconButton(
          tooltip: 'fullscreen',
          iconSize: 24,
          color: iconColor,
          padding: iconBtnPadding,
          constraints: iconBtnConstraints,
          icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
          onPressed: onFullscreen,
        ),
      ],
    );
  }
}
