import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/theme/tokens.dart';
import '../providers/player_providers.dart';
import 'player_controls.dart';
import 'player_ep_sheet.dart';
import 'player_gestures.dart';

/// 视频渲染区：media_kit Video（contain，darkBg 留黑）+ 点击显隐的遮罩。
///
/// [immersive]（横屏全屏）：顶部标题 + 中央播放键 + 左右 ±10s + 底部
/// 进度条与「源 · 选集 · 倍速 · 退出全屏」控制条（设计稿播放器暗夜风格）。
/// 非 immersive（竖屏）：仅顶部标题 + 右下全屏键（控制条在下方亮底 body）。
class PlayerVideoArea extends ConsumerWidget {
  const PlayerVideoArea({
    super.key,
    required this.title,
    this.immersive = false,
    this.onBack,
    this.onFullscreen,
    this.controlsVisible = true,
    this.onToggleControls,
  });

  final String title;
  final bool immersive;
  final VoidCallback? onBack;
  final VoidCallback? onFullscreen;
  final bool controlsVisible;
  final VoidCallback? onToggleControls;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(videoControllerProvider);
    final state = ref.watch(playerControllerProvider);
    final player = ref.watch(playerProvider);

    return ColoredBox(
      color: AppTokens.darkBg,
      // 手势层：单击显隐控制、双击 ±10s、水平拖进度、垂直拖亮度/音量。
      child: PlayerGestures(
        onToggleControls: () => onToggleControls?.call(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Video(
                  controller: controller,
                  fit: BoxFit.contain,
                  controls: null,
                ),
              ),
            ),
            // 起播前：加载环（design spec 07 VideoArea 首帧前）。
            if (!state.started)
              const Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF6CE5B0),
                  ),
                ),
              ),
            if (controlsVisible || !immersive) ...[
              // 顶部遮罩：返回 + 标题（+ 源信息）。
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 64,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x99000000), Colors.transparent],
                    ),
                  ),
                  child: Row(
                    children: [
                      if (immersive)
                        IconButton(
                          tooltip: 'back',
                          color: Colors.white,
                          icon: const Icon(Icons.arrow_back),
                          onPressed: onBack,
                        ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (immersive && controlsVisible) ...[
              // 左右 ±10s。
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: _MidSkipButton(seconds: -10),
                ),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 30),
                  child: _MidSkipButton(seconds: 10),
                ),
              ),
            ],
            // 中央播放键：横屏随控制层显隐；竖屏暂停时常显（设计稿帧范式）。
            StreamBuilder(
              stream: player.stream.playing,
              builder: (context, _) {
                final playing = player.state.playing;
                final show = immersive ? controlsVisible : !playing;
                if (!show) return const SizedBox.shrink();
                return Center(
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(playerControllerProvider.notifier).toggle(),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(blurRadius: 24, color: Color(0x66000000)),
                        ],
                      ),
                      child: Icon(
                        playing ? Icons.pause : Icons.play_arrow,
                        size: 32,
                        color: AppTokens.darkBg,
                      ),
                    ),
                  ),
                );
              },
            ),
            if (immersive && controlsVisible)
              // 底部遮罩：进度条 + 控制条。
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xA6000000), Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
                  child: const _ImmersiveControls(),
                ),
              )
            else if (!immersive)
              // 竖屏：右下全屏键。
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton.filledTonal(
                    tooltip: 'fullscreen',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x66000000),
                    ),
                    color: Colors.white,
                    icon: const Icon(Icons.fullscreen),
                    onPressed: onFullscreen,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 横屏左右侧的圆形 ±10s 键。
class _MidSkipButton extends ConsumerWidget {
  const _MidSkipButton({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton.filledTonal(
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.13),
        minimumSize: const Size(52, 52),
      ),
      color: Colors.white,
      iconSize: 22,
      icon: Icon(seconds < 0 ? Icons.replay_10 : Icons.forward_10),
      onPressed: () => unawaited(
        ref
            .read(playerControllerProvider.notifier)
            .skip(Duration(seconds: seconds)),
      ),
    );
  }
}

/// 横屏底部：进度条 + 「源 · 选集 · 倍速 · 退出全屏」。
class _ImmersiveControls extends ConsumerWidget {
  const _ImmersiveControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final state = ref.watch(playerControllerProvider);

    return StreamBuilder(
      stream: player.stream.position,
      builder: (context, _) {
        final position = player.state.position;
        final duration = player.state.duration;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ImmersiveSeekBar(position: position, duration: duration),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  _SourceChip(label: state.args.src),
                  const Spacer(),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => showPlayerEpSheet(context),
                    child: Text(
                      FlutterI18n.translate(context, 'player.episodes'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    onPressed: () => showPlayerSpeedSheet(context),
                    child: Text(
                      '${state.rate.toStringAsFixed(state.rate.truncateToDouble() == state.rate ? 1 : 2)}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'exit fullscreen',
                    color: Colors.white,
                    icon: const Icon(Icons.fullscreen_exit),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 横屏进度条：轨道/已播/手柄 + 两侧时间（seek 即跳）。
class _ImmersiveSeekBar extends ConsumerStatefulWidget {
  const _ImmersiveSeekBar({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  ConsumerState<_ImmersiveSeekBar> createState() => _ImmersiveSeekBarState();
}

class _ImmersiveSeekBarState extends ConsumerState<_ImmersiveSeekBar> {
  double? _dragFraction;

  void _seek(double fraction) {
    final target = Duration(
      milliseconds: (fraction * widget.duration.inMilliseconds).round(),
    );
    setState(() => _dragFraction = fraction);
    unawaited(ref.read(playerControllerProvider.notifier).seekTo(target));
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

    return LayoutBuilder(
      builder: (context, constraints) {
        void update(double dx) =>
            _seek((dx / constraints.maxWidth).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => update(d.localPosition.dx),
          onHorizontalDragUpdate: (d) => update(d.localPosition.dx),
          onHorizontalDragEnd: (_) => setState(() => _dragFraction = null),
          onHorizontalDragCancel: () => setState(() => _dragFraction = null),
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                Text(
                  formatDuration(shown),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: LayoutBuilder(
                      builder: (context, trackConstraints) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: fraction,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTokens.defaultPalette.primarySoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Positioned(
                              left: (fraction * trackConstraints.maxWidth - 7)
                                  .clamp(0.0, trackConstraints.maxWidth - 14),
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Text(
                  formatDuration(duration),
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 左下「源」chip：插件 package 标识。
class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTokens.darkSurface,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFFEFF5F1)),
      ),
    );
  }
}
