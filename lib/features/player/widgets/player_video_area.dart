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
import 'player_immersive_controls.dart';

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
      // 锁屏态（帧 21:21「锁屏」）整体关闭手势，只留解锁钮。
      child: state.locked
          ? _buildStack(context, ref, controller, state, player)
          : PlayerGestures(
              onToggleControls: () => onToggleControls?.call(),
              child: _buildStack(context, ref, controller, state, player),
            ),
    );
  }

  Widget _buildStack(
    BuildContext context,
    WidgetRef ref,
    VideoController controller,
    PlayerViewState state,
    dynamic player,
  ) {
    return Stack(
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
          Center(
            child: SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        if (controlsVisible && !state.locked) ...[
          // 顶部遮罩：返回 + 标题（横屏带「源」副标）+ ⋯ 播放设置。
          // 竖屏同款遮罩式（用户拍板 2026-11-26：控制件全部叠视频上）。
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: immersive ? 72 : 64,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  // 返回：竖屏（帧 21:18 左上 ‹）与横屏都显示。
                  if (onBack != null)
                    IconButton(
                      tooltip: 'back',
                      color: Colors.white,
                      icon: const Icon(Icons.arrow_back),
                      onPressed: onBack,
                    ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        if (immersive && state.args.src.isNotEmpty)
                          Text(
                            state.args.src,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // ⋯ 播放设置（帧 21:18/21:21 右上角，竖横屏都有）。
                  IconButton(
                    tooltip: 'settings',
                    color: Colors.white,
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => showPlayerSpeedSheet(context),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (immersive && controlsVisible && !state.locked) ...[
          // 左右跳段圆钮（帧 21:21：⏪<<15s / 30s>>⏩ 带文字标签）。
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 30),
              child: _MidSkipButton(seconds: -15, label: '<< 15s'),
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: EdgeInsets.only(right: 30),
              child: _MidSkipButton(seconds: 30, label: '30s >>'),
            ),
          ),
          // 三区手势提示（帧 21:21 底部灰字）。
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 96),
              child: Row(
                children: [
                  Expanded(
                    child: _GestureHint(
                      text: FlutterI18n.translate(context, 'player.hintLeft'),
                    ),
                  ),
                  Expanded(
                    child: _GestureHint(
                      text: FlutterI18n.translate(context, 'player.hintCenter'),
                    ),
                  ),
                  Expanded(
                    child: _GestureHint(
                      text: FlutterI18n.translate(context, 'player.hintRight'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        // 中央播放键：竖横屏统一——随控制层显隐（锁屏时隐藏）。
        StreamBuilder(
          stream: player.stream.playing,
          builder: (context, _) {
            final playing = player.state.playing;
            final show = controlsVisible && !state.locked;
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
        if (immersive && controlsVisible && !state.locked)
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
              child: const ImmersiveControls(),
            ),
          )
        else if (immersive && state.locked)
          // 锁屏态：仅右侧居中解锁钮（帧 21:21「锁屏」语义）。
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 24),
              child: IconButton.filledTonal(
                tooltip: 'unlock',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.13),
                  minimumSize: const Size(52, 52),
                ),
                color: Colors.white,
                icon: const Icon(Icons.lock_outline),
                onPressed: () =>
                    ref.read(playerControllerProvider.notifier).toggleLock(),
              ),
            ),
          )
        else if (!immersive && controlsVisible)
          // 竖屏：底部遮罩叠进度条 + 控制行（用户拍板 2026-11-26：
          // 与横屏同款叠视频上，不再放外部 body）。
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
              padding: const EdgeInsets.fromLTRB(12, 20, 4, 0),
              child: _PortraitControls(onFullscreen: onFullscreen),
            ),
          ),
      ],
    );
  }
}

/// 竖屏底部控制层：进度条 + 播放控制行（dark 样式叠视频上）。
class _PortraitControls extends ConsumerWidget {
  const _PortraitControls({this.onFullscreen});

  final VoidCallback? onFullscreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(playerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    return StreamBuilder(
      stream: player.stream.position,
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayerSeekBar(
              dark: true,
              position: player.state.position,
              duration: player.state.duration,
              onSeek: (d) => unawaited(controller.seekTo(d)),
            ),
            PlayerCtrlRow(
              dark: true,
              playing: player.state.playing,
              onFullscreen: onFullscreen,
            ),
          ],
        );
      },
    );
  }
}

/// 横屏左右侧的圆形跳段键（帧 21:21：圆钮 + 下方「<< 15s」文字标签）。
class _MidSkipButton extends ConsumerWidget {
  const _MidSkipButton({required this.seconds, required this.label});

  final int seconds;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.13),
            minimumSize: const Size(52, 52),
          ),
          color: Colors.white,
          iconSize: 22,
          icon: Icon(seconds < 0 ? Icons.fast_rewind : Icons.fast_forward),
          onPressed: () => unawaited(
            ref
                .read(playerControllerProvider.notifier)
                .skip(Duration(seconds: seconds)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

/// 三区手势提示灰字（帧 21:21 底部：双击/长按说明）。
class _GestureHint extends StatelessWidget {
  const _GestureHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 11,
        height: 1.5,
        color: Colors.white.withValues(alpha: 0.55),
      ),
    );
  }
}
