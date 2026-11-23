import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screen_brightness/screen_brightness.dart';

import '../../../core/theme/tokens.dart';
import '../providers/player_providers.dart';
import 'player_controls.dart';

/// 视频区手势层（用户拍板 2026-11-23）：包在视频 Stack 最外层。
///
/// - 单击：显隐控制层；
/// - 双击：左/右半屏 回退/前进 10 秒（闪现反馈）；
/// - 水平拖动：进度预览气泡（松手才 seek，拖动中不跳帧）；
/// - 垂直拖动：左半屏亮度、右半屏音量（media_kit 音量 0~100）。
///
/// 底部进度条自带手势（opaque 子节点优先），不与本层冲突。
class PlayerGestures extends ConsumerStatefulWidget {
  const PlayerGestures({
    super.key,
    required this.child,
    required this.onToggleControls,
  });

  final Widget child;
  final VoidCallback onToggleControls;

  @override
  ConsumerState<PlayerGestures> createState() => _PlayerGesturesState();
}

enum _VerticalMode { brightness, volume }

class _PlayerGesturesState extends ConsumerState<PlayerGestures> {
  Timer? _flashTimer;

  /// 双击闪现图标（null=不显示）。
  IconData? _flashIcon;

  /// 水平拖动进度预览。
  bool _seeking = false;
  Duration _seekTarget = Duration.zero;
  double _seekStartFraction = 0;
  double _seekStartX = 0;

  /// 垂直拖动（亮度/音量）。
  _VerticalMode? _verticalMode;
  double _verticalBase = 0;
  double _verticalValue = 0;

  /// 长按倍速（用户拍板 2026-11-23）：按住不动 → 最大档，松手恢复原倍速。
  static const double _holdSpeedRate = 2.0; // 速度弹层最大档
  bool _holdingSpeed = false;
  double _savedRate = 1.0;

  PlayerController get _controller =>
      ref.read(playerControllerProvider.notifier);

  @override
  void dispose() {
    _flashTimer?.cancel();
    if (_holdingSpeed) {
      unawaited(_controller.setRate(_savedRate));
    }
    // 退出播放页恢复系统亮度（会话级调节不驻留）。
    unawaited(
      ScreenBrightness().resetApplicationScreenBrightness().catchError(
        (Object _) {},
      ),
    );
    super.dispose();
  }

  // ---- 双击 ±10s ----

  void _onDoubleTap(TapDownDetails d) {
    final width = context.size?.width ?? 0;
    final x = d.localPosition.dx;
    final IconData icon;
    if (x < width / 3) {
      unawaited(_controller.skip(const Duration(seconds: -10)));
      icon = Icons.replay_10;
    } else if (x > width * 2 / 3) {
      unawaited(_controller.skip(const Duration(seconds: 10)));
      icon = Icons.forward_10;
    } else {
      // 中间三区：暂停/播放（用户拍板 2026-11-23）。
      final playing = ref.read(playerProvider).state.playing;
      _controller.toggle();
      icon = playing ? Icons.pause : Icons.play_arrow;
    }
    setState(() => _flashIcon = icon);
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 550), () {
      if (mounted) setState(() => _flashIcon = null);
    });
  }

  // ---- 长按倍速 ----

  void _onLongPressStart(LongPressStartDetails _) {
    if (_holdingSpeed) return;
    final state = ref.read(playerControllerProvider);
    _savedRate = state.rate;
    setState(() => _holdingSpeed = true);
    unawaited(_controller.setRate(_holdSpeedRate));
  }

  void _onLongPressEnd() {
    if (!_holdingSpeed) return;
    setState(() => _holdingSpeed = false);
    unawaited(_controller.setRate(_savedRate));
  }

  // ---- 水平拖动进度 ----

  void _onHorizontalDragStart(DragStartDetails d) {
    final player = ref.read(playerProvider);
    final duration = player.state.duration;
    if (duration <= Duration.zero) return;
    _seekStartFraction =
        (player.state.position.inMilliseconds / duration.inMilliseconds).clamp(
          0.0,
          1.0,
        );
    _seekStartX = d.localPosition.dx;
    _seekTarget = player.state.position;
    setState(() => _seeking = true);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (!_seeking) return;
    final player = ref.read(playerProvider);
    final duration = player.state.duration;
    final width = context.size?.width ?? 1;
    final fraction =
        (_seekStartFraction + (d.localPosition.dx - _seekStartX) / width).clamp(
          0.0,
          1.0,
        );
    setState(() {
      _seekTarget = Duration(
        milliseconds: (fraction * duration.inMilliseconds).round(),
      );
    });
  }

  void _endHorizontalDrag() {
    if (!_seeking) return;
    final target = _seekTarget;
    setState(() => _seeking = false);
    unawaited(_controller.seekTo(target));
  }

  // ---- 垂直拖动：亮度 / 音量 ----

  Future<void> _onVerticalDragStart(DragStartDetails d) async {
    final width = context.size?.width ?? 0;
    final isLeft = d.localPosition.dx < width / 2;
    if (isLeft) {
      _verticalMode = _VerticalMode.brightness;
      _verticalBase = await ScreenBrightness().application.catchError(
        (Object _) => 0.5,
      );
    } else {
      _verticalMode = _VerticalMode.volume;
      _verticalBase = ref.read(playerProvider).state.volume / 100;
    }
    _verticalBase = _verticalBase.clamp(0.0, 1.0);
    _verticalValue = _verticalBase;
    setState(() {});
  }

  Future<void> _onVerticalDragUpdate(DragUpdateDetails d) async {
    final mode = _verticalMode;
    if (mode == null) return;
    final next = (_verticalValue - d.delta.dy / 240).clamp(0.0, 1.0);
    setState(() => _verticalValue = next);
    if (mode == _VerticalMode.brightness) {
      await ScreenBrightness()
          .setApplicationScreenBrightness(next)
          .catchError((Object _) {});
    } else {
      await ref.read(playerProvider).setVolume(next * 100);
    }
  }

  void _endVerticalDrag() {
    if (_verticalMode == null) return;
    setState(() => _verticalMode = null);
  }

  @override
  Widget build(BuildContext context) {
    final player = ref.watch(playerProvider);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onToggleControls,
      onDoubleTapDown: _onDoubleTap,
      onLongPressStart: _onLongPressStart,
      onLongPressEnd: (_) => _onLongPressEnd(),
      onLongPressCancel: _onLongPressEnd,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: (_) => _endHorizontalDrag(),
      onHorizontalDragCancel: _endHorizontalDrag,
      onVerticalDragStart: (d) => unawaited(_onVerticalDragStart(d)),
      onVerticalDragUpdate: (d) => unawaited(_onVerticalDragUpdate(d)),
      onVerticalDragEnd: (_) => _endVerticalDrag(),
      onVerticalDragCancel: _endVerticalDrag,
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          // 双击闪现反馈（左 -10s / 中 暂停播放 / 右 +10s）。
          if (_flashIcon != null)
            IgnorePointer(
              child: Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_flashIcon, size: 30, color: AppTokens.darkBg),
                ),
              ),
            ),
          // 长按倍速中指示。
          if (_holdingSpeed)
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 56),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xB3000000),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fast_forward, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          '2.0x',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // 进度预览气泡。
          if (_seeking)
            IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xB3000000),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${formatDuration(_seekTarget)} / '
                    '${formatDuration(player.state.duration)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          // 亮度/音量指示。
          if (_verticalMode != null)
            IgnorePointer(
              child: Align(
                alignment: _verticalMode == _VerticalMode.brightness
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xB3000000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _verticalMode == _VerticalMode.brightness
                              ? Icons.wb_sunny_outlined
                              : Icons.volume_up_outlined,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${(_verticalValue * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
