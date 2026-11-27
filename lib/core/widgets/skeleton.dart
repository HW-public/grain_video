import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 骨架屏套件（帧 86:213 范式：中性灰圆角块 + 呼吸脉冲）。
///
/// 加载态用骨架占位替代转圈——布局先行稳定，视觉等待感更轻。
/// 脉冲由 [SkeletonPulse] 统一驱动：同屏多个骨架共享一个动画节拍。

/// 脉冲驱动器：包住一组骨架块，子树内所有 [SkeletonBox] 同步呼吸。
class SkeletonPulse extends StatefulWidget {
  const SkeletonPulse({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonPulse> createState() => _SkeletonPulseState();
}

class _SkeletonPulseState extends State<SkeletonPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => _PulseScope(
        // 0.55 ~ 1.0 呼吸区间：低调不晃眼。
        opacity: 0.55 + 0.45 * _controller.value,
        child: child!,
      ),
      child: widget.child,
    );
  }
}

class _PulseScope extends InheritedWidget {
  const _PulseScope({required this.opacity, required super.child});

  final double opacity;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_PulseScope>()?.opacity ?? 1.0;

  @override
  bool updateShouldNotify(_PulseScope oldWidget) =>
      opacity != oldWidget.opacity;
}

/// 单个骨架块：中性灰圆角矩形，随 [SkeletonPulse] 呼吸（无驱动器时常显）。
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = AppTokens.radiusCard,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: _PulseScope.of(context),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// 封面卡网格骨架（首页「最近更新」/搜索结果同形）：
/// 两列 16:9 封面 + 标题行 + 副标行，与 BangumiCard 布局同构。
class SkeletonBangumiGrid extends StatelessWidget {
  const SkeletonBangumiGrid({super.key, this.rows = 2});

  /// 行数（每行两张卡）。
  final int rows;

  @override
  Widget build(BuildContext context) {
    return SkeletonPulse(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          0,
          AppTokens.space4,
          9,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const gap = 10.0;
            final cardWidth = (constraints.maxWidth - gap) / 2;
            final coverHeight = cardWidth / AppTokens.coverRatioVideo;
            return Column(
              children: [
                for (var r = 0; r < rows; r++) ...[
                  if (r > 0) const SizedBox(height: gap),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var c = 0; c < 2; c++) ...[
                        if (c > 0) const SizedBox(width: gap),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonBox(height: coverHeight),
                              const SizedBox(height: 6),
                              SkeletonBox(
                                width: cardWidth * 0.7,
                                height: 14,
                                radius: 4,
                              ),
                              const SizedBox(height: 4),
                              SkeletonBox(
                                width: cardWidth * 0.4,
                                height: 11,
                                radius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
