import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/widgets/app_bottom_nav.dart';
import 'package:grain_video/features/search/pages/search_page.dart';

/// search.* i18n key 已合入 assets/l10n（zh/en）。
/// 断言一律经 [tr] 取当前 locale 的真实文案，与语种/文案修改解耦。
void main() {
  Widget buildSubject() {
    return ProviderScope(
      child: MaterialApp(
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
      ),
    );
  }

  String tr(WidgetTester tester, String key) =>
      FlutterI18n.translate(tester.element(find.byType(SearchPage)), key);

  testWidgets('初始态渲染搜索栏、底部导航(index=1)与热门榜，空插件不崩', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // 搜索输入框自动聚焦。
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode?.hasFocus, isTrue);

    // 底部导航 currentIndex=1。
    final nav = tester.widget<AppBottomNav>(find.byType(AppBottomNav));
    expect(nav.currentIndex, 1);

    // 初始态：大家都在搜榜（5 行）渲染，历史区无记录时隐藏。
    expect(find.textContaining(tr(tester, 'search.hot')), findsOneWidget);
    expect(find.text('葬送的芙莉莲 第二季'), findsOneWidget);
    expect(find.textContaining(tr(tester, 'search.history')), findsNothing);
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

  testWidgets('点热门词填入并提交搜索', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('葬送的芙莉莲 第二季'));
    await tester.pumpAndSettle();

    // 关键词已写入输入框，且进入搜索态。
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, '葬送的芙莉莲 第二季');
  });

  testWidgets('输入后清空按钮恢复初始态', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '迷宫饭');
    await tester.pump();
    expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.cancel_outlined));
    await tester.pumpAndSettle();

    expect(find.textContaining(tr(tester, 'search.hot')), findsOneWidget);
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsNothing);
  });
}
