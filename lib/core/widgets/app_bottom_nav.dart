import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';
import '../theme/tokens.dart';

/// 共享底部导航（设计稿「底部导航」帧 5:67）：首页 / 搜索 / 我的。
///
/// 由 lead 统一提供，三个 tab 页（home/search/me）各自以 currentIndex
/// 0/1/2 引用；feature 之间不互相 import。
/// 帧规格：栏高72 白底 顶部1px divider；图标20 激活主色/未选textSecondary；
/// 标签11 激活textPrimary 600/未选textSecondary 400；激活无背景 pill。
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _paths = [AppRoutes.home, AppRoutes.search, AppRoutes.me];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 顶部 1px 分隔线（变量 3:27）。
        const Divider(height: 1, color: AppTokens.divider),
        NavigationBarTheme(
          data: NavigationBarThemeData(
            height: 72,
            backgroundColor: AppTokens.surface,
            // 激活态不加背景色（设计规范铁律）。
            indicatorColor: Colors.transparent,
            iconTheme: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return IconThemeData(
                size: 20,
                color: selected
                    ? AppTokens.defaultPalette.primary
                    : AppTokens.textSecondary,
              );
            }),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppTokens.textPrimary
                    : AppTokens.textSecondary,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: (i) => context.go(_paths[i]),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                label: '首页',
              ),
              NavigationDestination(icon: Icon(Icons.search), label: '搜索'),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                label: '我的',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
