import 'package:go_router/go_router.dart';

import 'pages/onboarding_page.dart';

/// 首次引导路由（壳外全屏，仅首启可见）。
abstract final class OnboardingRoutes {
  static const String page = '/onboarding';
}

final List<RouteBase> onboardingRoutes = [
  GoRoute(
    path: OnboardingRoutes.page,
    builder: (context, state) => const OnboardingPage(),
  ),
];
