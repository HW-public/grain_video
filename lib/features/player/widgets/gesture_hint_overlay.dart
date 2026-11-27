import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

/// 首次进播放页的手势引导浮层（D4）：三宫格手势图示 +
/// 进度/亮度/音量说明，点任意处消失（调用方负责写已展示标记）。
class GestureHintOverlay extends StatelessWidget {
  const GestureHintOverlay({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: ColoredBox(
          color: const Color(0xD916241F),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.touch_app_outlined,
                    size: 44,
                    color: Colors.white70,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    FlutterI18n.translate(context, 'player.gestureTitle'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  // 三宫格：与手势分区一致（左/中/右）。
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _HintCell(
                          icon: Icons.fast_rewind,
                          text: FlutterI18n.translate(
                            context,
                            'player.hintLeft',
                          ),
                        ),
                      ),
                      Expanded(
                        child: _HintCell(
                          icon: Icons.play_circle_outline,
                          text: FlutterI18n.translate(
                            context,
                            'player.hintCenter',
                          ),
                        ),
                      ),
                      Expanded(
                        child: _HintCell(
                          icon: Icons.fast_forward,
                          text: FlutterI18n.translate(
                            context,
                            'player.hintRight',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.swap_vert,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          FlutterI18n.translate(
                            context,
                            'player.hintSeekVolume',
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    FlutterI18n.translate(context, 'player.hintDismiss'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HintCell extends StatelessWidget {
  const _HintCell({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.white),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            height: 1.5,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
