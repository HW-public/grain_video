import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';
import '../theme/tokens.dart';

/// 共享底部导航（设计稿「底部导航」帧）：首页 / 搜索 / 我的。
///
/// 由 lead 统一提供，三个 tab 页（home/search/me）各自以 currentIndex
/// 0/1/2 引用；feature 之间不互相 import。
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  static const _paths = [AppRoutes.home, AppRoutes.search, AppRoutes.me];

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) => context.go(_paths[i]),
      backgroundColor: AppTokens.surface,
      indicatorColor: AppTokens.defaultPalette.primaryContainer,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          label: FlutterI18n.translate(context, 'nav.home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.search),
          label: FlutterI18n.translate(context, 'nav.search'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          label: FlutterI18n.translate(context, 'nav.me'),
        ),
      ],
    );
  }
}
