import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grain_video/core/routes.dart';
import 'package:grain_video/core/widgets/async_view.dart';
import 'package:grain_video/extension/models.dart';
import 'package:grain_video/features/detail/pages/detail_page.dart';
import 'package:grain_video/features/detail/providers/detail_providers.dart';
import 'package:grain_video/features/detail/routes.dart';

const _args = DetailArgs(src: 'com.example.fake', url: 'https://example.com/1');

final _fakeDetail = BangumiDetail(
  title: '测试番剧',
  cover: '',
  description: '这是一段测试简介。',
  episodes: const [
    Episode(title: '第1集', url: 'ep-1'),
    Episode(title: '第2集', url: 'ep-2'),
  ],
);

/// 详情页组件测试：不加载真实插件/数据库，
/// 通过 override family provider 注入假数据。
void main() {
  final i18nDelegate = FlutterI18nDelegate(
    translationLoader: FileTranslationLoader(
      basePath: 'assets/l10n',
      fallbackFile: 'zh',
      useCountryCode: false,
    ),
  );

  List<Override> overrides() => [
    bangumiDetailProvider(_args).overrideWith((ref) async => _fakeDetail),
    favoriteProvider(_args).overrideWith((ref) async => false),
    followProvider(_args).overrideWith((ref) async => null),
  ];

  List<LocalizationsDelegate<dynamic>> delegates() => [
    i18nDelegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: overrides(),
      child: MaterialApp(
        localizationsDelegates: delegates(),
        supportedLocales: const [Locale('zh')],
        home: child,
      ),
    );
  }

  testWidgets('空参数（插件缺失）兜底不崩，展示空态', (tester) async {
    await tester.pumpWidget(wrap(const DetailPage(url: '', src: '')));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
  });

  testWidgets('数据态渲染标题/简介/选集，点集跳播放器带齐参数', (tester) async {
    final router = GoRouter(
      initialLocation:
          '${DetailRoutes.page}?url=${Uri.encodeComponent(_args.url)}'
          '&src=${Uri.encodeComponent(_args.src)}',
      routes: [
        ...detailRoutes,
        GoRoute(
          path: AppRoutes.player,
          builder: (context, state) => const Scaffold(body: Text('PLAYER')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: delegates(),
          supportedLocales: const [Locale('zh')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 封面区 + 标题 + 两个选集 chip。
    expect(find.text('测试番剧'), findsOneWidget);
    expect(find.text('第1集'), findsOneWidget);
    expect(find.text('第2集'), findsOneWidget);

    await tester.tap(find.text('第2集'));
    await tester.pumpAndSettle();

    expect(find.text('PLAYER'), findsOneWidget);
    final loc = router.routerDelegate.currentConfiguration.uri;
    expect(loc.path, AppRoutes.player);
    expect(loc.queryParameters['ep'], 'ep-2');
    expect(loc.queryParameters['src'], _args.src);
    expect(loc.queryParameters['title'], '测试番剧');
    expect(loc.queryParameters['bangumi'], _args.url);
  });
}
