import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/widgets/app_bottom_nav.dart';
import 'package:grain_video/features/search/pages/search_page.dart';
import 'package:grain_video/features/search/providers/search_providers.dart';

/// search.* i18n key 已合入 assets/l10n（zh/en）。
/// 断言一律经 [tr] 取当前 locale 的真实文案，与语种/文案修改解耦。
void main() {
  Widget buildSubject({ProviderContainer? container}) {
    final app = MaterialApp(
      localizationsDelegates: [
        FlutterI18nDelegate(
          translationLoader: FileTranslationLoader(
            basePath: 'assets/l10n',
            fallbackFile: 'zh',
            useCountryCode: false,
          ),
        ),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
      home: const SearchPage(),
    );
    if (container != null) {
      return UncontrolledProviderScope(container: container, child: app);
    }
    return ProviderScope(child: app);
  }

  String tr(WidgetTester tester, String key) =>
      FlutterI18n.translate(tester.element(find.byType(SearchPage)), key);

  testWidgets('初始态：搜索栏自动聚焦、底部导航 index=1、空历史/空插件', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode?.hasFocus, isTrue);

    final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
    expect(nav.currentIndex, 1);

    // 空历史：历史区隐藏；空插件：源筛选行隐藏。
    expect(find.textContaining(tr(tester, 'search.history')), findsNothing);
    expect(find.textContaining(tr(tester, 'search.filterAll')), findsNothing);
  });

  testWidgets('键盘提交关键词后空插件列表显示无插件提示，不崩溃', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '芙莉莲');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);
  });

  testWidgets('输入 500ms 防抖后自动提交搜索', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '孤独摇滚');
    // 防抖窗口内不触发。
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsNothing);
    // 跨过 500ms 触发提交（空插件 → 无插件提示）。
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);
  });

  testWidgets('点右侧「搜索」按钮提交', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '迷宫饭');
    await tester.pump();
    await tester.tap(find.text(tr(tester, 'search.search')));
    await tester.pumpAndSettle();

    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);
  });

  testWidgets('历史 chip 渲染，点击填入并提交搜索', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(buildSubject(container: container));
    await tester.pumpAndSettle();

    // 初始无历史；写入一条后渲染 pill chip。
    expect(find.textContaining(tr(tester, 'search.history')), findsNothing);
    container.read(searchHistoryProvider.notifier).add('芙莉莲');
    await tester.pump();
    expect(find.textContaining(tr(tester, 'search.history')), findsOneWidget);
    expect(find.text('芙莉莲'), findsOneWidget);

    // 点 chip：填入输入框并提交（空插件 → 无插件提示）。
    await tester.tap(find.text('芙莉莲'));
    await tester.pumpAndSettle();
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, '芙莉莲');
  });
}
