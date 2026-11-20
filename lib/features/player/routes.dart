import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/player_page.dart';
import 'providers/player_providers.dart';

/// 播放器路由。入参走 queryParams：
/// ep（剧集 url）、src（插件 package）、title（条目标题）、bangumi（条目 url）。
abstract final class PlayerRoutes {
  static const String player = AppRoutes.player;
}

final List<RouteBase> playerRoutes = [
  GoRoute(
    path: PlayerRoutes.player,
    builder: (context, state) {
      final q = state.uri.queryParameters;
      return PlayerPage(
        args: PlayerArgs(
          ep: q['ep'] ?? '',
          src: q['src'] ?? '',
          title: q['title'] ?? '',
          bangumi: q['bangumi'] ?? '',
        ),
      );
    },
  ),
];
