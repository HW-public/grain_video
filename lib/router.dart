import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:go_router/go_router.dart';

import 'features/extensions/pages/extensions_page.dart';
import 'features/extensions/routes.dart';

/// 路由汇总（app 层）：聚合各 feature 导出的路由列表。
/// core 不得 import features，故聚合点放在 lib 根（app 层）。
final appRouter = GoRouter(
  routes: [
    /// 调试入口：启动后直达扩展管理页（features/home 落地后恢复 '/'）。
    GoRoute(path: '/', builder: (context, state) => const ExtensionsPage()),
    GoRoute(
      path: '/home',
      builder: (context, state) => const _PlaceholderHome(),
    ),
    ...extensionsRoutes,
  ],
);

/// 临时首页：Phase 5 由 features/home 替换。
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'nav.home')),
        actions: [
          IconButton(
            tooltip: FlutterI18n.translate(context, 'nav.extensions'),
            icon: const Icon(Icons.extension_outlined),
            onPressed: () => context.go(ExtensionsRoutes.page),
          ),
        ],
      ),
    );
  }
}
