import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/app.dart';
import 'package:grain_video/core/routes.dart';
import 'package:grain_video/core/theme/tokens.dart';
import 'package:grain_video/core/widgets/async_view.dart';
import 'package:grain_video/features/extensions/pages/extensions_page.dart';
import 'package:grain_video/features/home/pages/home_page.dart';
import 'package:grain_video/router.dart';

void main() {
  testWidgets('entry is home page; extensions page keeps design tokens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HeHeApp()));
    // 首页有常驻加载态（DB/插件异步），不能用 pumpAndSettle。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 启动直达首页（调试入口已撤销）。
    expect(find.byType(HomePage), findsOneWidget);

    // 跳到扩展管理页验证设计 token。
    appRouter.go(AppRoutes.extensions);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(ExtensionsPage), findsOneWidget);
    // 底部主按钮（go_router 叠放，首页的按钮仍在树中，断言至少一个）。
    expect(find.byType(FilledButton), findsWidgets);
    // Scaffold 是 ExtensionsPage 的子节点（页面自建 Scaffold）。
    final scaffold = tester.widget<Scaffold>(
      find.descendant(
        of: find.byType(ExtensionsPage),
        matching: find.byType(Scaffold),
      ),
    );
    expect(scaffold.backgroundColor, AppTokens.defaultPalette.pageBg);
    // 首页无插件时也用 EmptyState（go_router 叠放仍在树中），锚定到 ExtensionsPage。
    expect(
      find.descendant(
        of: find.byType(ExtensionsPage),
        matching: find.byType(EmptyState),
      ),
      findsOneWidget,
    );
  });
}
