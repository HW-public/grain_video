import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/theme/app_theme.dart';
import 'package:grain_video/core/theme/tokens.dart';
import 'package:grain_video/core/widgets/app_bottom_nav.dart';
import 'package:grain_video/core/widgets/async_view.dart';
import 'package:grain_video/data/db/database.dart';
import 'package:grain_video/data/db/repositories.dart';
import 'package:grain_video/features/me/pages/appearance_page.dart';
import 'package:grain_video/features/me/pages/me_page.dart';
import 'package:grain_video/features/me/pages/settings_page.dart';
import 'package:grain_video/features/me/routes.dart';
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

late AppDatabase db;

/// 路由用完整外壳（StatefulShellRoute），底部导航由 HeHeAppShell 挂载。
/// 「我的」页分段器读收藏/历史数据库：默认注入内存库，避免测试环境挂起。
Widget _buildApp({
  String? initialLocation,
  // riverpod 3 的 Override 是未导出 sealed 类型，签名只能用 dynamic。
  List<dynamic> overrides = const [],
}) {
  return ProviderScope(
    overrides: [databaseProvider.overrideWithValue(db), ...overrides],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: buildAppRouter(initialLocation: initialLocation),
      localizationsDelegates: _localizationsDelegates(),
      // 只钉 zh：断言用中文硬编码，平台默认 locale 是 en 会加载 en.json。
      supportedLocales: const [Locale('zh')],
    ),
  );
}

void main() {
  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  testWidgets('me page matches 21:20 frame: header, tabs, settings rows, nav', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(initialLocation: MeRoutes.page));
    await tester.pumpAndSettle();

    expect(find.byType(MePage), findsOneWidget);

    // 头部：昵称 + 副标。
    expect(
      find.text(
        FlutterI18n.translate(
          tester.element(find.byType(MePage)),
          'me.headerName',
        ),
      ),
      findsOneWidget,
    );

    // 分段器三项：收藏 / 历史 / 下载（矢量 icon + 文字，断言文字）。
    for (final tab in ['收藏', '历史', '下载']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }

    // 设置列表（帧五行 + 用户拍板保留的追番列表 = 六行）。
    // emoji 与标签是两个 Text，这里断言标签文本。
    for (final label in ['扩展管理', '追番列表', '外观', '网络代理', '缓存清理', '关于']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }

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

  testWidgets('tapping 历史 tab shows inline history grid empty state', (
    tester,
  ) async {
    await tester.pumpWidget(_buildApp(initialLocation: MeRoutes.page));
    await tester.pumpAndSettle();

    // 新结构：历史是分段器 tab，网格内嵌展示（不再跳独立页）。
    await tester.tap(find.text('历史'));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(
      find.text(
        FlutterI18n.translate(
          tester.element(find.byType(MePage)),
          'me.emptyHistoryTitle',
        ),
      ),
      findsOneWidget,
    );
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
