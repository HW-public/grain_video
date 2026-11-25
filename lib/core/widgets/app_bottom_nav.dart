import 'package:flutter/material.dart';

/// 共享底部导航（设计稿「底部导航」帧 5:67）：首页 / 搜索 / 我的。
///
/// 由 [HeHeAppShell] 统一挂载（三 tab 共用单个，切换不重建），
/// 切 tab 回调走 [onSelect]（shell 转 goBranch）。
/// 帧规格：栏高56（用户拍板，帧原值72） 白底 顶部1px divider；图标20 激活主色/未选textSecondary；
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
        // 顶部 1px 分隔线（跟随主题 dividerColor）。
        Divider(height: 1, color: Theme.of(context).dividerColor),
        SizedBox(
          // 栏高为用户拍板（2026-11-20）：56，帧原值 72。
          height: 56,
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
///
/// 切换动画（用户拍板 2026-11-23，原瞬时切换太生硬）：
/// 交接编排——旧激活项 150ms 快速淡出退场（easeIn），
/// 新激活项 300ms 弹簧入场（easeOutBack 回弹）：
/// - icon/标签颜色渐变；icon 1.0→1.15 回弹放大（退场侧缩回）；
/// - 标签字重 400↔600 连续插值。帧约束激活无背景 pill，不加滑块。
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
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: selected ? 1 : 0),
        // 方向感知：入场弹簧 300ms，退场快淡 150ms。
        duration: Duration(milliseconds: selected ? 300 : 150),
        curve: selected ? Curves.easeOut : Curves.easeIn,
        builder: (context, t, _) {
          final iconColor = Color.lerp(
            cs.onSurface.withValues(alpha: 0.65),
            cs.primary,
            t,
          )!;
          final labelColor = Color.lerp(
            cs.onSurface.withValues(alpha: 0.65),
            cs.onSurface,
            t,
          )!;
          // 回弹：选中时 icon 放大 15% 并带回弹曲线。
          final scale = 1 + 0.15 * Curves.easeOutBack.transform(t);
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.scale(
                scale: scale,
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.lerp(
                    FontWeight.w400,
                    FontWeight.w600,
                    t,
                  ),
                  color: labelColor,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
