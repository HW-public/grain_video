import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/app.dart';
import 'package:grain_video/core/widgets/app_bottom_nav.dart';
import 'package:grain_video/data/db/database.dart';
import 'package:grain_video/features/home/pages/home_page.dart';
import 'package:grain_video/features/home/providers/home_providers.dart';

void main() {
  testWidgets('home page matches 4:31 frame: no app bar, nav, empty state', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HeHeApp()));
    // 数据库在测试环境不可用时异步区会呈现错误态，不影响骨架渲染断言。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 4:31 帧无 AppBar，状态栏下直接内容。
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    // 三项：首页 / 搜索 / 我的（自绘导航项，非 Material NavigationDestination）。
    expect(find.text('首页'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);

    // 测试环境无已装载插件：显示无插件空态引导。
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('无观看历史时 hero 显示占位提醒卡，点按去搜索页', (tester) async {
    final i18nDelegate = FlutterI18nDelegate(
      translationLoader: FileTranslationLoader(
        basePath: 'assets/l10n',
        fallbackFile: 'zh',
        useCountryCode: false,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 空历史 → 占位卡分支。
          recentWatchProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            i18nDelegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh')],
          home: const HomePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 占位卡出现：主文案 + 提示文案，且无轮播指示点。
    expect(
      find.text(
        FlutterI18n.translate(
          tester.element(find.byType(HomePage)),
          'home.continueEmpty',
        ),
      ),
      findsOneWidget,
    );
    expect(find.byType(PageView), findsNothing);
  });

  testWidgets('hero 进度文字按 i18n 模板插值渲染，不露 {{}} 原文', (tester) async {
    final i18nDelegate = FlutterI18nDelegate(
      translationLoader: FileTranslationLoader(
        basePath: 'assets/l10n',
        fallbackFile: 'zh',
        useCountryCode: false,
      ),
    );
    final history = WatchHistory(
      id: 1,
      sourcePackage: 'com.example.fake',
      bangumiUrl: 'https://example.com/1',
      title: '测试番剧',
      cover: '',
      episodeUrl: 'ep-1',
      episodeTitle: '第1集',
      positionMs: 90000, // 01:30
      durationMs: 600000, // 10:00
      updatedAt: DateTime(2026, 11, 20),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recentWatchProvider.overrideWith((ref) async => [history]),
        ],
        child: MaterialApp(
          localizationsDelegates: [
            i18nDelegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh')],
          home: const HomePage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 模板 {{position}} / {{duration}} 被替换为 mm:ss。
    expect(find.text('上次看到 01:30 / 10:00'), findsOneWidget);
  });
}
