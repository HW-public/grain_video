import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/app.dart';
import 'package:grain_video/core/widgets/async_view.dart';

void main() {
  testWidgets('extensions page shows empty state and is reachable', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: HeHeApp()));
    await tester.pumpAndSettle();

    // 首页右上角入口 → 扩展管理页
    await tester.tap(find.byIcon(Icons.extension_outlined));
    await tester.pumpAndSettle();

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.system_update_alt), findsOneWidget);
  });
}
