import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// 设置页行范式（specs/02 第 4 节）：
/// 行高 56、图标 22（主色描边）、标题 15/500、
/// 右侧副文案 12/400 弱提示 + 18 箭头。
class MeListRow extends StatelessWidget {
  const MeListRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  /// 是否显示右侧箭头；外链类行（如 GitHub 副文案）可关。
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Row(
            children: [
              Icon(icon, size: 22, color: cs.primary),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle != null)
                Flexible(
                  flex: 0,
                  child: Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (showChevron) ...[
                const SizedBox(width: AppTokens.space1),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
