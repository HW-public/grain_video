import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/home_page.dart';

/// 首页路由。
abstract final class HomeRoutes {
  static const String page = AppRoutes.home;
}

final List<RouteBase> homeRoutes = [
  GoRoute(path: HomeRoutes.page, builder: (context, state) => const HomePage()),
];
