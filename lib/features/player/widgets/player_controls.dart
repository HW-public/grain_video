import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
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

  Color get _trackColor =>
      widget.dark ? const Color(0x33FFFFFF) : AppTokens.divider;
  Color get _playedColor => AppTokens.defaultPalette.primarySoft;
  Color get _timeColor => widget.dark
      ? Colors.white.withValues(alpha: 0.85)
      : AppTokens.textTertiary;

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
    final shown = _dragFraction != null
        ? Duration(milliseconds: (fraction * duration.inMilliseconds).round())
        : widget.position;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) =>
                  _update(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragUpdate: (d) =>
                  _update(d.localPosition.dx, constraints.maxWidth),
              onHorizontalDragEnd: (_) => setState(() => _dragFraction = null),
              onHorizontalDragCancel: () =>
                  setState(() => _dragFraction = null),
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
                          color: _trackColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: _playedColor,
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
                              BoxShadow(
                                blurRadius: 6,
                                color: Color(0x59000000),
                              ),
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
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatDuration(shown),
                style: TextStyle(fontSize: 11, color: _timeColor),
              ),
              Text(
                formatDuration(duration),
                style: TextStyle(fontSize: 11, color: _timeColor),
              ),
            ],
          ),
        ),
      ],
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

  Color get _iconColor => dark ? Colors.white : AppTokens.textPrimary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(playerControllerProvider.notifier);
    final state = ref.watch(playerControllerProvider);
    final hasNext =
        state.currentEpIndex >= 0 &&
        state.currentEpIndex + 1 < state.episodes.length;

    // 不写死行高：系统字体放大时按钮 intrinsic 高度可能超 48，
    // 硬约束会触发 BOTTOM OVERFLOW（用户真机抓包）。
    // 横向可滚动：窄屏/大字下内容超宽时滑览而不是溢出（二次抓包修复）。
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          IconButton(
            tooltip: playing ? 'pause' : 'play',
            iconSize: 28,
            color: _iconColor,
            icon: Icon(playing ? Icons.pause : Icons.play_arrow),
            onPressed: controller.toggle,
          ),
          IconButton(
            tooltip: 'skip back 10s',
            iconSize: 24,
            color: _iconColor,
            icon: const Icon(Icons.replay_10),
            onPressed: () =>
                unawaited(controller.skip(const Duration(seconds: -10))),
          ),
          IconButton(
            tooltip: 'skip forward 10s',
            iconSize: 24,
            color: _iconColor,
            icon: const Icon(Icons.forward_10),
            onPressed: () =>
                unawaited(controller.skip(const Duration(seconds: 10))),
          ),
          if (hasNext)
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: _iconColor),
              icon: const Icon(Icons.skip_next, size: 22),
              label: Text(FlutterI18n.translate(context, 'player.next')),
              onPressed: () => unawaited(controller.nextEpisode()),
            ),
          // 原 Spacer：横向滚动场景下 Row 宽度无界，Spacer 非法，改固定间隙。
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: _iconColor),
            onPressed: () => showPlayerSpeedSheet(context),
            child: Text(
              '${state.rate.toStringAsFixed(state.rate.truncateToDouble() == state.rate ? 1 : 2)}x',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          if (state.episodes.isNotEmpty)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: _iconColor),
              onPressed: () => showPlayerEpSheet(context),
              child: Text(
                FlutterI18n.translate(context, 'player.episodes'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          IconButton(
            tooltip: 'fullscreen',
            iconSize: 24,
            color: _iconColor,
            icon: Icon(fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: onFullscreen,
          ),
        ],
      ),
    );
  }
}
