import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../providers/player_providers.dart';
import 'player_controls.dart';
import 'player_ep_sheet.dart';

/// 横屏底部：进度条 + 「选集 · 倍速 · 锁屏」控制条（帧 21:21；
/// 画质/投屏无底层能力未做——ABI 单流、无 cast）。
class ImmersiveControls extends ConsumerWidget {
  const ImmersiveControls({super.key});

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
                  Expanded(
                    child: _BarAction(
                      icon: Icons.video_library_outlined,
                      label: FlutterI18n.translate(context, 'player.episodes'),
                      onTap: () => showPlayerEpSheet(context),
                    ),
                  ),
                  Expanded(
                    child: _BarAction(
                      icon: Icons.speed,
                      label:
                          '${FlutterI18n.translate(context, 'player.speed')} '
                          '${state.rate.toStringAsFixed(state.rate.truncateToDouble() == state.rate ? 1 : 2)}x',
                      onTap: () => showPlayerSpeedSheet(context),
                    ),
                  ),
                  Expanded(
                    child: _BarAction(
                      icon: Icons.lock_open,
                      label: FlutterI18n.translate(context, 'player.lock'),
                      onTap: () => ref
                          .read(playerControllerProvider.notifier)
                          .toggleLock(),
                    ),
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

/// 控制条单项：小图标 + 12 号白字，居中。
class _BarAction extends StatelessWidget {
  const _BarAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
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
