import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';

/// 设置-外观页主题色卡（Figma 27:211 改版范式）：
/// 156 高白卡，上半=中性灰线框预览（底/头/两行，刻意不用主题色——
/// 主题色与显示模式是两个正交维度，预览不应暗示亮色模式），
/// 下半=三色圆点 32 + 主题名；选中态 2px 主题色描边 + 右上「使用中」徽章。
/// 点击整卡切换主题（paletteProvider）。
class ThemePreviewCard extends StatelessWidget {
  const ThemePreviewCard({
    super.key,
    required this.palette,
    this.selected = false,
    this.onTap,
  });

  final AppPalette palette;
  final bool selected;
  final VoidCallback? onTap;

  /// 中性灰线框预览色（帧 227:1158~1169 定案：预览底/头/行）。
  static const _wireBg = Color(0xFFE1E1E6);
  static const _wireBar = Color(0xFFB4B4BC);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = [
      palette.primary,
      palette.primaryContainer,
      palette.secondary,
    ];
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 156,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected
                  ? palette.primary
                  : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
          padding: const EdgeInsets.all(AppTokens.space3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 线框预览：底 + 头 + 两行（全中性灰）。
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _wireBg,
                    borderRadius: BorderRadius.circular(AppTokens.space2),
                  ),
                  padding: const EdgeInsets.all(AppTokens.space2),
                  child: Column(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: _wireBar,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(height: AppTokens.space2),
                      for (var i = 0; i < 2; i++) ...[
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: _wireBar.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                        if (i == 0) const SizedBox(height: AppTokens.space1),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              Row(
                children: [
                  for (final c in colors)
                    Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  const SizedBox(width: AppTokens.space1),
                  Flexible(
                    child: Text(
                      palette.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? palette.primary : cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 「使用中」徽章（选中卡右上角，主题色底白字）。
class UsingBadge extends StatelessWidget {
  const UsingBadge({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      ),
      child: Text(
        FlutterI18n.translate(context, 'me.using'),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
