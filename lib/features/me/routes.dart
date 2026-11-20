import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/about_page.dart';
import 'pages/appearance_page.dart';
import 'pages/cache_clear_page.dart';
import 'pages/favorites_page.dart';
import 'pages/follows_page.dart';
import 'pages/me_page.dart';
import 'pages/network_proxy_page.dart';
import 'pages/settings_page.dart';
import 'pages/watch_history_page.dart';

/// 「我的」feature 路由：全部挂在 /me 子路径下，由 lib/router.dart 聚合。
abstract final class MeRoutes {
  static const String page = AppRoutes.me;
  static const String history = '/me/history';
  static const String favorites = '/me/favorites';
  static const String follows = '/me/follows';
  static const String settings = '/me/settings';
  static const String settingsAppearance = '/me/settings/appearance';
  static const String settingsProxy = '/me/settings/proxy';
  static const String settingsCache = '/me/settings/cache';
  static const String about = '/me/about';
}

final List<RouteBase> meRoutes = [
  GoRoute(path: MeRoutes.page, builder: (context, state) => const MePage()),
  GoRoute(
    path: MeRoutes.history,
    builder: (context, state) => const WatchHistoryPage(),
  ),
  GoRoute(
    path: MeRoutes.favorites,
    builder: (context, state) => const FavoritesPage(),
  ),
  GoRoute(
    path: MeRoutes.follows,
    builder: (context, state) => const FollowsPage(),
  ),
  GoRoute(
    path: MeRoutes.settings,
    builder: (context, state) => const SettingsPage(),
  ),
  GoRoute(
    path: MeRoutes.settingsAppearance,
    builder: (context, state) => const AppearancePage(),
  ),
  GoRoute(
    path: MeRoutes.settingsProxy,
    builder: (context, state) => const NetworkProxyPage(),
  ),
  GoRoute(
    path: MeRoutes.settingsCache,
    builder: (context, state) => const CacheClearPage(),
  ),
  GoRoute(path: MeRoutes.about, builder: (context, state) => const AboutPage()),
];
