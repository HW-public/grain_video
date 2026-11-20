import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/app.dart';
import 'package:grain_video/core/theme/tokens.dart';
import 'package:grain_video/core/widgets/async_view.dart';

void main() {
  testWidgets('extensions page is the entry and matches design tokens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HeHeApp()));
    await tester.pumpAndSettle();

    // 空状态 + 底部主按钮（设计稿「＋ 安装扩展 / 浏览仓库」）。
    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(
      find.ancestor(of: find.byType(AppBar), matching: find.byType(Scaffold)),
    );
    // 设计稿：薄荷页面底 + 白色表面。
    expect(scaffold.backgroundColor, AppTokens.defaultPalette.pageBg);
  });
}
