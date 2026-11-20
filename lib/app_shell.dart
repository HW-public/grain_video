import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/tokens.dart';
import 'core/widgets/app_bottom_nav.dart';
import 'core/widgets/app_tab_scope.dart';

/// 一级页面外壳：home / search / me 三个分支共用单个 Scaffold + 底部导航。
///
/// 切换 tab 只换 body（导航栏保持不动），修复整页路由滑入动画导致的
/// 底导「跳动」；分支常驻树中，当前索引经 [AppTabScope] 下发。
class HeHeAppShell extends StatelessWidget {
  const HeHeAppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      body: AppTabScope(index: shell.currentIndex, child: shell),
      bottomNavigationBar: AppBottomNav(
        currentIndex: shell.currentIndex,
        onSelect: (i) => shell.goBranch(
          i,
          // 重点当前 tab：回到该分支首页。
          initialLocation: i == shell.currentIndex,
        ),
      ),
    );
  }
}
