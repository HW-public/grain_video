import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/widgets/app_bottom_nav.dart';
import 'package:grain_video/features/home/pages/home_page.dart';

void main() {
  testWidgets('home page renders app bar, bottom nav and empty state', (
    tester,
  ) async {
    final i18nDelegate = FlutterI18nDelegate(
      translationLoader: FileTranslationLoader(
        basePath: 'assets/l10n',
        fallbackFile: 'zh',
        useCountryCode: false,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
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
    // 数据库在测试环境不可用时异步区会呈现错误态，不影响骨架渲染断言。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(3));

    // 测试环境无已装载插件：显示无插件空态引导（home.* key 已合入，断言中文文案）。
    expect(find.byType(FilledButton), findsOneWidget);
    expect(find.textContaining('还没有安装插件'), findsWidgets);
  });
}
