import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// 共享底部导航（设计稿「底部导航」帧 5:67）：首页 / 搜索 / 我的。
///
/// 由 [HeHeAppShell] 统一挂载（三 tab 共用单个，切换不重建），
/// 切 tab 回调走 [onSelect]（shell 转 goBranch）。
/// 帧规格：栏高72 白底 顶部1px divider；图标20 激活主色/未选textSecondary；
/// 标签11 激活textPrimary 600/未选textSecondary 400；激活无背景 pill。
/// 图标与标签间距为用户拍板（2026-11-20）调近至 4（帧为 10）。
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const _icons = [
    Icons.home_outlined,
    Icons.search,
    Icons.person_outline,
  ];
  static const _labels = ['首页', '搜索', '我的'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 顶部 1px 分隔线（变量 3:27）。
        const Divider(height: 1, color: AppTokens.divider),
        SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Expanded(
                  child: _NavItem(
                    icon: _icons[i],
                    label: _labels[i],
                    selected: i == currentIndex,
                    onTap: () => onSelect(i),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 单个导航项：图标 20 在上、标签 11 在下，间距 4；整列可点。
class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTokens.defaultPalette.primary
        : AppTokens.textSecondary;
    final labelColor = selected
        ? AppTokens.textPrimary
        : AppTokens.textSecondary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
