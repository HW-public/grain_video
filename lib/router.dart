import 'package:go_router/go_router.dart';

import 'features/detail/routes.dart';
import 'features/extensions/routes.dart';
import 'features/home/routes.dart';
import 'features/me/routes.dart';
import 'features/player/routes.dart';
import 'features/search/routes.dart';

/// 路由汇总（app 层）：聚合各 feature 导出的路由列表。
/// core 不得 import features，故聚合点放在 lib 根（app 层）。
final appRouter = GoRouter(
  routes: [
    ...homeRoutes,
    ...searchRoutes,
    ...meRoutes,
    ...detailRoutes,
    ...playerRoutes,
    ...extensionsRoutes,
  ],
);
