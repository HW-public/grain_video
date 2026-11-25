import 'package:go_router/go_router.dart';

import '../../core/routes.dart';
import 'pages/about_page.dart';
import 'pages/appearance_page.dart';
import 'pages/cache_clear_page.dart';
import 'pages/favorites_page.dart';
import 'pages/follows_page.dart';
import 'pages/licenses_page.dart';
import 'pages/me_page.dart';
import 'pages/network_proxy_page.dart';
import 'pages/settings_page.dart';
import 'pages/watch_history_page.dart';

/// 「我的」feature 路由：一级页挂在 /me 子路径下，由 lib/router.dart 聚合。
/// 二级页（meSubRoutes）与扩展管理同待遇——压栈全屏、无底部导航。
abstract final class MeRoutes {
  static const String page = AppRoutes.me;
  static const String history = '/me/history';
  static const String favorites = '/me/favorites';
  static const String downloads = AppRoutes.downloads;
  static const String follows = '/me/follows';
  static const String settings = '/me/settings';
  static const String settingsAppearance = '/me/settings/appearance';
  static const String settingsProxy = '/me/settings/proxy';
  static const String settingsCache = '/me/settings/cache';
  static const String about = '/me/about';
  static const String licenses = '/me/licenses';
}

/// 一级「我的」页（壳内分支，挂底部导航）。
final List<RouteBase> meRoutes = [
  GoRoute(path: MeRoutes.page, builder: (context, state) => const MePage()),
];

/// 「我的」全部二级页（壳外压栈，无底部导航，与扩展管理一致）。
final List<RouteBase> meSubRoutes = [
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
  GoRoute(
    path: MeRoutes.licenses,
    builder: (context, state) => const LicensesPage(),
  ),
];
