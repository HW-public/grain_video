import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/widgets/app_tab_scope.dart';
import 'package:grain_video/data/db/database.dart';
import 'package:grain_video/data/db/repositories.dart';
import 'package:grain_video/features/search/pages/search_page.dart';
import 'package:grain_video/features/search/providers/search_providers.dart';

/// search.* i18n key 已合入 assets/l10n（zh/en）。
/// 断言一律经 [tr] 取当前 locale 的真实文案，与语种/文案修改解耦。
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

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
      // 底部导航现由 HeHeAppShell 统一挂载；直出页面时由 scope 告知
      // 搜索 tab 可见（触发输入框聚焦）。
      home: const AppTabScope(index: 1, child: SearchPage()),
    );
    // 搜索历史已持久化：默认注入内存数据库。
    final effective =
        container ??
        ProviderContainer(overrides: [databaseProvider.overrideWithValue(db)]);
    return UncontrolledProviderScope(container: effective, child: app);
  }

  String tr(WidgetTester tester, String key) =>
      FlutterI18n.translate(tester.element(find.byType(SearchPage)), key);

  testWidgets('初始态：搜索栏自动聚焦、空历史/空插件', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.focusNode?.hasFocus, isTrue);

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

  testWidgets('结果态：历史区与结果区同屏显示（帧 21:19）', (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(searchHistoryProvider.notifier).add('孤独摇滚');
    await tester.pumpWidget(buildSubject(container: container));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '芙莉莲');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // 已输入关键词后历史区仍在上方，结果区（空插件提示）在其下方。
    expect(find.textContaining(tr(tester, 'search.history')), findsOneWidget);
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);
  });

  testWidgets('输入不自动搜索，点「搜索」按钮才提交（用户拍板去防抖）', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '孤独摇滚');
    // 输入后停留任意时长都不触发搜索。
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsNothing);

    await tester.tap(find.text(tr(tester, 'search.search')));
    await tester.pumpAndSettle();
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);
  });

  testWidgets('输入框清除 icon：清空输入且结果区复位到初始态', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cancel), findsNothing);
    await tester.enterText(find.byType(TextField), '芙莉莲');
    await tester.pump();
    expect(find.byIcon(Icons.cancel), findsOneWidget);

    // 先提交出结果区。
    await tester.tap(find.text(tr(tester, 'search.search')));
    await tester.pumpAndSettle();
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsOneWidget);

    // 点清除：输入清空、结果区回到初始态（提交的词已入历史区）。
    await tester.tap(find.byIcon(Icons.cancel));
    await tester.pumpAndSettle();
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, isEmpty);
    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(find.textContaining(tr(tester, 'search.noPlugins')), findsNothing);
    expect(find.textContaining(tr(tester, 'search.history')), findsOneWidget);
  });

  testWidgets('管理模式：点「管理」chip 出现 ×，点 chip 删除单条，「完成」退出', (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await container.read(searchHistoryProvider.notifier).add('孤独摇滚');
    await container.read(searchHistoryProvider.notifier).add('迷宫饭');
    await tester.pumpWidget(buildSubject(container: container));
    await tester.pumpAndSettle();

    // 进入管理模式：出现「清空」「完成」，两个 chip 各带一个 ×。
    await tester.tap(find.text(tr(tester, 'search.manage')));
    await tester.pumpAndSettle();
    expect(find.text(tr(tester, 'search.clear')), findsOneWidget);
    expect(find.text(tr(tester, 'search.done')), findsOneWidget);
    expect(find.byIcon(Icons.close), findsNWidgets(2));

    // 管理模式点 chip = 删除该条（不触发搜索）。
    await tester.tap(find.text('孤独摇滚'));
    await tester.pumpAndSettle();
    expect(find.text('孤独摇滚'), findsNothing);
    expect(find.text('迷宫饭'), findsOneWidget);

    // 批量清空：确认弹窗 → 历史区整体消失。
    await tester.tap(find.text(tr(tester, 'search.clear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tr(tester, 'common.confirm')));
    await tester.pumpAndSettle();
    expect(find.textContaining(tr(tester, 'search.history')), findsNothing);
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
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
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
