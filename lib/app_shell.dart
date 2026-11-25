import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/update/update_check.dart';
import 'core/widgets/app_bottom_nav.dart';
import 'core/widgets/app_tab_scope.dart';

/// 一级页面外壳：home / search / me 三个分支共用单个 Scaffold + 底部导航。
///
/// 切换 tab 只换 body（导航栏保持不动），修复整页路由滑入动画导致的
/// 底导「跳动」；分支常驻树中，当前索引经 [AppTabScope] 下发。
class HeHeAppShell extends StatefulWidget {
  const HeHeAppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  State<HeHeAppShell> createState() => _HeHeAppShellState();
}

class _HeHeAppShellState extends State<HeHeAppShell> {
  var _updateChecked = false;

  @override
  void initState() {
    super.initState();
    // 启动后静默检查 App 更新（首帧渲染完再发请求，不拖启动）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_updateChecked || !mounted) return;
      _updateChecked = true;
      checkAppUpdate(context, silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 页面底交给主题 scaffoldBackgroundColor（亮=pageBg / 暗=darkBg）。
      body: AppTabScope(index: widget.shell.currentIndex, child: widget.shell),
      bottomNavigationBar: AppBottomNav(
        currentIndex: widget.shell.currentIndex,
        onSelect: (i) => widget.shell.goBranch(
          i,
          // 重点当前 tab：回到该分支首页。
          initialLocation: i == widget.shell.currentIndex,
        ),
      ),
    );
  }
}
