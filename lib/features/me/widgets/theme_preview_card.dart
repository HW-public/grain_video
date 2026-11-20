import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// 设置-外观页主题色卡（设计稿 27:211）：色板圆点 + 主题名，
/// 选中态 2px 主题色描边 + 右上 check 角标。
///
/// 当前为只读展示（默认薄荷绿选中），换肤交互后续版本开放。
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.palette,
    this.selected = false,
  });

  final AppPalette palette;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: AppTokens.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: selected
              ? palette.primary
              : AppTokens.divider.withValues(alpha: 0.5),
          width: selected ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: palette.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: AppTokens.space2),
                Text(
                  palette.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? palette.primary : AppTokens.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: AppTokens.space2,
              right: AppTokens.space2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: palette.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
