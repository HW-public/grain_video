import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 地基阶段冒烟：占位页能正常构建即可。
  // Phase 2+ 各页面落地后在此补真实 widget 测试。
  testWidgets('placeholder scaffold builds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
