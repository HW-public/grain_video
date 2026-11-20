import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/search_page.dart';

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
