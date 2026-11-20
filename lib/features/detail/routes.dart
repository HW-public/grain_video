import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/detail_page.dart';

/// 详情页路由。
abstract final class DetailRoutes {
  static const String page = AppRoutes.detail;
}

final List<RouteBase> detailRoutes = [
  GoRoute(
    path: DetailRoutes.page,
    builder: (context, state) => DetailPage(
      url: state.uri.queryParameters['url'] ?? '',
      src: state.uri.queryParameters['src'] ?? '',
    ),
  ),
];
