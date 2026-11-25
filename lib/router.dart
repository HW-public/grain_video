import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'features/detail/routes.dart';
import 'features/downloads/routes.dart';
import 'features/extensions/routes.dart';
import 'features/home/routes.dart';
import 'features/me/routes.dart';
import 'features/onboarding/routes.dart';
import 'features/player/routes.dart';
import 'features/search/routes.dart';

/// 应用级路由（app 层聚合各 feature 路由）。
///
/// home / search / me 三个一级页包在 [StatefulShellRoute] 里共用
/// [HeHeAppShell]（单个 Scaffold + 底部导航，切换不跳动）；
/// 详情 / 播放器 / 扩展管理 / 「我的」全部二级页为压栈页，无底部导航。
GoRouter buildAppRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          HeHeAppShell(shell: navigationShell),
      branches: [
        StatefulShellBranch(routes: homeRoutes),
        StatefulShellBranch(routes: searchRoutes),
        StatefulShellBranch(routes: meRoutes),
      ],
    ),
    ...sourceRoutes,
    ...detailRoutes,
    ...playerRoutes,
    ...extensionsRoutes,
    ...meSubRoutes,
    ...downloadsRoutes,
    ...onboardingRoutes,
  ],
);

/// 应用默认路由实例。
final appRouter = buildAppRouter();
