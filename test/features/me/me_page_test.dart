import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grain_video/core/theme/app_theme.dart';
import 'package:grain_video/core/theme/tokens.dart';
import 'package:grain_video/core/widgets/app_bottom_nav.dart';
import 'package:grain_video/data/db/database.dart';
import 'package:grain_video/features/me/pages/appearance_page.dart';
import 'package:grain_video/features/me/pages/me_page.dart';
import 'package:grain_video/features/me/pages/settings_page.dart';
import 'package:grain_video/features/me/pages/watch_history_page.dart';
import 'package:grain_video/features/me/providers/me_providers.dart';
import 'package:grain_video/features/me/routes.dart';
import 'package:grain_video/features/me/widgets/me_empty_state.dart';
import 'package:grain_video/features/me/widgets/me_list_row.dart';
import 'package:grain_video/features/me/widgets/theme_preview_card.dart';
import 'package:grain_video/router.dart';

/// 与 lib/app.dart 一致的 i18n 委托（每次新建，避免测试间共享缓存）。
List<LocalizationsDelegate<dynamic>> _localizationsDelegates() {
  final i18nDelegate = FlutterI18nDelegate(
    translationLoader: FileTranslationLoader(
      basePath: 'assets/l10n',
      fallbackFile: 'zh',
      useCountryCode: false,
    ),
  );
  return [
    i18nDelegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

/// 纯展示页（无数据提供者）直接走默认 ProviderScope。
/// 路由用完整外壳（StatefulShellRoute），底部导航由 HeHeAppShell 挂载。
Widget _buildApp({String? initialLocation}) {
  return ProviderScope(
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: buildAppRouter(initialLocation: initialLocation),
      localizationsDelegates: _localizationsDelegates(),
      supportedLocales: const [Locale('zh'), Locale('en')],
    ),
  );
}

void main() {
  testWidgets('me page renders six entries and bottom nav', (tester) async {
    await tester.pumpWidget(_buildApp(initialLocation: MeRoutes.page));
    await tester.pumpAndSettle();

    // 功能列表六项：观看历史 / 我的收藏 / 追番列表 / 扩展管理 / 设置 / 关于。
    expect(find.byType(MeListRow), findsNWidgets(6));
    expect(find.byType(MePage), findsOneWidget);

    // 底部导航（当前项 = 我的，index 2），由外壳统一挂载。
    expect(find.byType(AppBottomNav), findsOneWidget);
    final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
    expect(nav.currentIndex, 2);

    // 设计稿：薄荷页面底（锚定 MePage 的 Scaffold——外壳另有一个）。
    final scaffold = tester.widget<Scaffold>(
      find.descendant(of: find.byType(MePage), matching: find.byType(Scaffold)),
    );
    expect(scaffold.backgroundColor, AppTokens.defaultPalette.pageBg);
  });

  testWidgets('tapping history entry navigates to watch history page', (
    tester,
  ) async {
    final router = GoRouter(initialLocation: MeRoutes.page, routes: meRoutes);
    await tester.pumpWidget(
      ProviderScope(
        // 空历史：避免 widget 测试触真实数据库，且验证空态渲染。
        overrides: [
          watchHistoryListProvider.overrideWith(_EmptyHistoryNotifier.new),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
          localizationsDelegates: _localizationsDelegates(),
          supportedLocales: const [Locale('zh'), Locale('en')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(MeListRow).first);
    await tester.pumpAndSettle();

    expect(find.byType(WatchHistoryPage), findsOneWidget);
    expect(find.byType(MeEmptyState), findsOneWidget);
  });

  testWidgets('settings shell renders three sub-page entries', (tester) async {
    await tester.pumpWidget(_buildApp(initialLocation: MeRoutes.settings));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(MeListRow), findsNWidgets(3));
  });

  testWidgets('appearance page shows three theme cards with mint selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(initialLocation: MeRoutes.settingsAppearance),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppearancePage), findsOneWidget);
    expect(find.byType(ThemePreviewCard), findsNWidgets(3));

    // 只读展示：默认主题（薄荷绿）为唯一选中卡。
    final selectedCards = tester
        .widgetList<ThemePreviewCard>(find.byType(ThemePreviewCard))
        .where((card) => card.selected)
        .toList();
    expect(selectedCards, hasLength(1));
    expect(selectedCards.single.palette.name, AppTokens.defaultPalette.name);
  });
}

/// 空历史 notifier：替代真实数据库读取（AsyncNotifier override 形态）。
class _EmptyHistoryNotifier extends WatchHistoryListNotifier {
  @override
  Future<List<WatchHistory>> build() async => const [];
}
