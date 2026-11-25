import 'package:flutter/widgets.dart';

/// 极简 SVG path 解析（仅支持 M/C/V/L/Z 绝对命令——
/// 品牌小禾苗系矢量导出的全部命令集）。
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(
    '[MCVLZ]',
  ).allMatches(d).map((m) => (m.group(0)!, m.start)).toList();
  double x = 0, y = 0;
  for (var i = 0; i < tokens.length; i++) {
    final cmd = tokens[i].$1;
    final start = tokens[i].$2 + 1;
    final end = i + 1 < tokens.length ? tokens[i + 1].$2 : d.length;
    final nums = RegExp(
      r'-?\d*\.?\d+(?:e-?\d+)?',
    ).allMatches(d.substring(start, end)).map((m) => m.group(0)!).toList();
    switch (cmd) {
      case 'M':
        x = double.parse(nums[0]);
        y = double.parse(nums[1]);
        path.moveTo(x, y);
      case 'C':
        for (var j = 0; j + 5 < nums.length; j += 6) {
          path.cubicTo(
            double.parse(nums[j]),
            double.parse(nums[j + 1]),
            double.parse(nums[j + 2]),
            double.parse(nums[j + 3]),
            double.parse(nums[j + 4]),
            double.parse(nums[j + 5]),
          );
          x = double.parse(nums[j + 4]);
          y = double.parse(nums[j + 5]);
        }
      case 'V':
        y = double.parse(nums[0]);
        path.lineTo(x, y);
      case 'L':
        x = double.parse(nums[0]);
        y = double.parse(nums[1]);
        path.lineTo(x, y);
      case 'Z':
        path.close();
    }
  }
  return path;
}
