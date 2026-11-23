import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/search_page.dart';
import 'pages/source_page.dart';

/// 搜索路由（一级页，底部导航 currentIndex=1）。
abstract final class SearchRoutes {
  static const String page = AppRoutes.search;
}

final List<RouteBase> searchRoutes = [
  GoRoute(
    path: SearchRoutes.page,
    builder: (context, state) => const SearchPage(),
  ),
];

/// 源主页（单插件「最新 + 搜索」一体）：外壳顶层压栈二级页（?src=插件 package）。
final List<RouteBase> sourceRoutes = [
  GoRoute(
    path: AppRoutes.source,
    builder: (context, state) =>
        SourcePage(package: state.uri.queryParameters['src'] ?? ''),
  ),
];
