import 'package:flutter/material.dart';

import 'svg_path_utils.dart';

/// 禾苗生长动画（`loading-options/08-sprout-grow.svg` 的 Flutter 移植）：
/// 4.2s 无缝循环——根茎生长(4-30%) → 左叶(26-46%) → 右叶(40-58%) →
/// 小叶带过冲(58-76%) → 整体呼吸(76-90%) → 淡出重演。
/// 部件路径与关键帧逐值取自 SVG，渐变 #45AB66→#248752。
class SproutGrowLogo extends StatefulWidget {
  const SproutGrowLogo({super.key, this.size = 200});

  final double size;

  @override
  State<SproutGrowLogo> createState() => _SproutGrowLogoState();
}

class _SproutGrowLogoState extends State<SproutGrowLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _SproutGrowPainter(_controller.value),
      ),
    );
  }
}

class _SproutGrowPainter extends CustomPainter {
  _SproutGrowPainter(this.t);

  /// 循环进度 0~1（对应 4.2s）。
  final double t;

  static const _viewBox = 240.0;

  // 部件路径（SVG 内嵌 viewBox 坐标；四个部件 scale 均为 1，
  // 外画布坐标 = 路径 + 偏移）。
  static final Path _stem = parseSvgPath(
    'M19.891 0.0281991C19.9653 -0.0274966 19.7748 0.0596051 19.841 0.00392217L23.6605 3.81512C23.606 3.88934 23.5525 3.96312 23.5 4.03587C22.88 4.89587 22.27 5.87587 22 7.03587C21.66 8.45587 21.5 10.5059 21.5 12.2859C21.5 14.3059 20.94 17.4759 22 18.5359C23.02 19.5559 26.18 19.3959 28 19.7859C29.65 20.1359 31.05 20.1059 32.5 20.7859C33.88 21.4359 36.62 22.0459 36.5 22.5359C32.5 22.7859 5.50002 22.5359 0 22.5359C1.50002 21.7859 2.50003 21.6859 3.50002 21.2859C4.5 20.8859 5.14 20.8959 6.5 20.5359C7.86 20.1759 9.54 19.7859 11 19.7859C12.37 19.7859 14.25 19.2859 15 18.5359C15.9051 17.6308 16.0366 13.1789 16 11.7859L16 8.78592V2.30382L15.9782 2.20952L19.841 0.00392217C19.9392 0.0894896 19.7759 -0.0581428 19.891 0.0281991Z',
  ).shift(const Offset(101.25, 134.80));

  static final Path _leafL = parseSvgPath(
    'M1.25273 20.75C0.702731 18.14 0.00273344 15.7201 0.0027244 12.5C0.00271878 10.5 -0.0672812 6.88 0.502719 5C1.07272 3.12 1.68273 1.05995 2.25273 0.749954C3.15273 0.269954 6.31272 0 8.00272 0C10.1827 0 11.7727 0.429954 14.2527 0.749954C16.7727 1.07995 19.3427 1.83995 21.7527 2.74995C24.1727 3.66995 26.7527 4.89995 28.7527 6.24995C30.5127 7.43995 32.4827 8.81995 34.0027 10.25C35.6527 11.8 36.4827 13.67 37.7527 15.5C38.7527 18.25 38.7527 18.5 39.7527 20.75C40.3627 23.23 40.6727 26.61 40.7527 29.25C40.8227 31.56 40.6427 34.28 40.7527 36.25C40.8427 37.89 40.5827 39.79 40.7527 41.25C40.9035 42.5411 40.7456 43.899 42.3527 45.3L38.231 47.4236C37.8867 45.9177 37.7323 44.4796 36.7527 43.5C35.7527 42.5 33.9727 42.41 32.2527 42C29.5527 41.36 25.7927 42.05 22.2527 41.25C18.6127 40.43 14.7327 38.43 11.7527 36.25C8.95273 34.2 6.53273 31.45 4.75273 28.75C3.11273 26.26 1.82273 23.48 1.25273 20.75Z',
  ).shift(const Offset(79.0, 89.6));

  static final Path _leafR = parseSvgPath(
    'M0.722343 36.4881C1.40467 35.3364 1.27707 34.4956 1.27707 33.2504C1.27707 32.0052 1.18793 30.7999 1.27707 29.0167C1.36621 27.3132 1.60392 26.6458 1.7723 25.0319C1.94068 23.4181 1.85155 23.458 2.26754 22.0434C2.68353 20.6388 3.99094 17.8196 4.74368 16.5644C5.47662 15.3291 5.83316 14.9704 6.72458 13.8248C7.6457 12.6394 8.60644 11.5137 9.69594 10.3382C10.8944 9.03317 12.1622 7.43927 13.6578 6.35343C15.1434 5.27755 15.9259 4.43084 17.6196 3.61397C19.3826 2.76721 22.0865 1.88056 24.0575 1.37251C26.187 0.824606 26.8407 0.207017 29.0098 0.127322C30.9313 0.0575892 34.4573 -0.37077 38.9144 0.874415C40.4001 3.11588 39.9048 3.86297 39.9048 7.34962C39.9048 10.5873 40.4539 9.09299 38.9144 14.572C38.2706 16.8632 37.9239 21.0472 34.4573 25.53C30.9907 30.0129 31.651 30.0129 29.0098 32.0052C27.0289 33.4995 25.6423 33.8283 24.0576 34.9938C22.5025 36.1394 20.2938 36.6475 18.6101 37.4843C16.9956 38.2912 16.8922 38.2314 12.6673 38.9785C10.4205 38.9785 8.49749 39.2275 7.2198 39.2275C6.40763 39.2275 6.31997 38.7867 5.23889 39.2275C4.15781 39.6683 4.03191 40.2711 3.5 41L0 37.3178C0.328032 37.0404 0.559299 36.7633 0.722343 36.4881Z',
  ).shift(const Offset(121.25, 97.6));

  static final Path _leafS = parseSvgPath(
    'M12.0211 5.78619V7.77524C12.0211 7.8163 12.0195 7.72026 12.0211 7.77524C11.6524 7.43313 11.5924 6.78072 9.87766 7.37747C8.54018 7.19448 5.81379 7.55247 4.30484 6.78072C3.06167 6.14422 1.30409 4.39386 1.30409 4.39386C1.30409 4.39386 -0.179125 2.11046 0.0180664 1.41032C0.163817 0.877254 0.258127 0.455573 0.875424 0.216888C1.76708 -0.125229 4.29628 -0.0138428 5.59089 0.216888C6.8855 0.447618 9.02032 1.60919 10.3064 3.00156C11.378 4.5928 10.5207 5.38838 12.0211 5.78619Z',
  ).shift(const Offset(105.25, 137.2));

  /// 分段进度：t ∈ [start,end] 映射 0→1（ease-in-out，对应 CSS ease-in-out）。
  static double _seg(double t, double start, double end) {
    if (t <= start) return 0;
    if (t >= end) return 1;
    return Curves.easeInOut.transform((t - start) / (end - start));
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox);

    Paint gradientPaint() => Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF45AB66), Color(0xFF248752)],
      ).createShader(const Rect.fromLTWH(0, 0, _viewBox, _viewBox));

    const fullRect = Rect.fromLTWH(0, 0, _viewBox, _viewBox);

    /// 带透明度绘制单部件（saveLayer 蒙版，渐变不受影响）。
    void drawPart(Path path, double opacity, VoidCallback transform) {
      canvas.save();
      if (opacity < 1) {
        canvas.saveLayer(
          fullRect,
          Paint()..color = Colors.white.withValues(alpha: opacity),
        );
      }
      transform();
      canvas.drawPath(path, gradientPaint());
      if (opacity < 1) canvas.restore();
      canvas.restore();
    }

    // 整体淡入（0-3%）/淡出（92-100%），对应 .stage。
    final stageOpacity = t < 0.03
        ? t / 0.03
        : t > 0.92
        ? 1 - (t - 0.92) / 0.08
        : 1.0;
    canvas.saveLayer(
      fullRect,
      Paint()..color = Colors.white.withValues(alpha: stageOpacity),
    );

    // 整体呼吸（76-90%，origin 119.5,157.5），对应 .pop。
    final popPulse = t < 0.76 || t > 0.9
        ? 1.0
        : 1 + 0.07 * (1 - (t - 0.84).abs() / 0.06).clamp(0.0, 1.0);
    canvas.translate(119.5, 157.5);
    canvas.scale(popPulse);
    canvas.translate(-119.5, -157.5);

    // 根茎：scaleY 0→1（4-30%）。
    final stemScale = _seg(t, 0.04, 0.30);
    drawPart(_stem, 1, () {
      canvas.translate(119.5, 157.5);
      canvas.scale(1, stemScale);
      canvas.translate(-119.5, -157.5);
    });

    // 左叶：scale(0) rotate(-14°) → 正常（26-46%），26-30% 淡入。
    final leafLp = _seg(t, 0.26, 0.46);
    final leafLOpacity = t < 0.26
        ? 0.0
        : t < 0.30
        ? (t - 0.26) / 0.04
        : 1.0;
    drawPart(_leafL, leafLOpacity, () {
      canvas.translate(121, 137);
      canvas.rotate(-0.24435 * (1 - leafLp)); // 14°
      canvas.scale(leafLp);
      canvas.translate(-121, -137);
    });

    // 右叶：scale(0) rotate(12°) → 正常（40-58%），40-43% 淡入。
    final leafRp = _seg(t, 0.40, 0.58);
    final leafROpacity = t < 0.40
        ? 0.0
        : t < 0.43
        ? (t - 0.40) / 0.03
        : 1.0;
    drawPart(_leafR, leafROpacity, () {
      canvas.translate(122, 137);
      canvas.rotate(0.20944 * (1 - leafRp)); // 12°
      canvas.scale(leafRp);
      canvas.translate(-122, -137);
    });

    // 小叶：0→1.2(68%)→0.96(72%)→1（58-76%，首段 ease-out）。
    final p = ((t - 0.58) / 0.18).clamp(0.0, 1.0);
    final leafSScale = p <= 0
        ? 0.0
        : p < 10 / 18
        ? 1.2 * Curves.easeOut.transform(p / (10 / 18))
        : p < 14 / 18
        ? 1.2 - 0.24 * ((p - 10 / 18) / (4 / 18))
        : 0.96 + 0.04 * ((p - 14 / 18) / (4 / 18));
    drawPart(_leafS, 1, () {
      canvas.translate(116.5, 141);
      canvas.scale(leafSScale);
      canvas.translate(-116.5, -141);
    });

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SproutGrowPainter oldDelegate) => oldDelegate.t != t;
}
