import 'package:go_router/go_router.dart';

import 'pages/extensions_page.dart';
import 'pages/extensions_repo_page.dart';

/// 扩展管理路由。
abstract final class ExtensionsRoutes {
  static const String page = '/extensions';
  static const String repo = '/extensions/repo';
}

final List<RouteBase> extensionsRoutes = [
  GoRoute(
    path: ExtensionsRoutes.page,
    builder: (context, state) => const ExtensionsPage(),
  ),
  GoRoute(
    path: ExtensionsRoutes.repo,
    builder: (context, state) => const ExtensionsRepoPage(),
  ),
];
