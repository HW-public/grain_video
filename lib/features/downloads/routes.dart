import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/downloads_page.dart';

/// 下载管理路由（壳外压栈）。
abstract final class DownloadsRoutes {
  static const String page = AppRoutes.downloads;
}

final List<RouteBase> downloadsRoutes = [
  GoRoute(
    path: DownloadsRoutes.page,
    builder: (context, state) =>
        DownloadsPage(enqueueQuery: state.uri.queryParameters),
  ),
];
