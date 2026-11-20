import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grain_video/core/routes.dart';
import 'package:grain_video/features/player/pages/player_page.dart';
import 'package:grain_video/features/player/providers/player_providers.dart';
import 'package:grain_video/features/player/routes.dart';

Widget _app([String initialLocation = AppRoutes.player]) {
  final delegate = FlutterI18nDelegate(
    translationLoader: FileTranslationLoader(
      basePath: 'assets/l10n',
      fallbackFile: 'zh',
      useCountryCode: false,
    ),
  );
  return ProviderScope(
    child: MaterialApp.router(
      localizationsDelegates: [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      routerConfig: GoRouter(
        initialLocation: initialLocation,
        routes: playerRoutes,
      ),
    ),
  );
}

void main() {
  test('player route is registered at AppRoutes.player', () {
    expect(playerRoutes, hasLength(1));
    final route = playerRoutes.single as GoRoute;
    expect(route.path, AppRoutes.player);
  });

  testWidgets('no params enters error state without crashing', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // 错误态：错误图标 + 重试按钮，不崩。
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });

  testWidgets('plugin not installed shows error state with retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app('${AppRoutes.player}?ep=ep-1&src=pkg.none&title=T&bangumi=bg-1'),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    // 重试仍回到错误态（插件依旧未安装），验证重试链路不崩。
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('PlayerPage built directly with empty args shows error state', (
    tester,
  ) async {
    final delegate = FlutterI18nDelegate(
      translationLoader: FileTranslationLoader(
        basePath: 'assets/l10n',
        fallbackFile: 'zh',
        useCountryCode: false,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: const PlayerPage(args: PlayerArgs()),
          localizationsDelegates: [
            delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('zh'), Locale('en')],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
