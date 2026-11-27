import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/widgets/bangumi_card.dart';

/// 定高网格契约回归：卡片在 gridHeight 预算的紧约束下不得溢出
/// （真机曾抓包：CJK 自然行高 > 预算假设行高，Column 底部溢出 4px）。
void main() {
  Future<void> pumpCard(
    WidgetTester tester, {
    required double width,
    required TextScaler scaler,
    bool withSubtitle = true,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: scaler),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                height: BangumiCard.gridHeight(
                  width,
                  scaler,
                  hasSubtitle: withSubtitle,
                ),
                child: BangumiCard(
                  coverUrl: '',
                  title: '葬送的芙莉莲 第一季',
                  update: '全28话',
                  subtitle: withSubtitle ? '樱花源' : '',
                  width: width,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('标准字号：预算紧约束下无溢出', (tester) async {
    await pumpCard(tester, width: 205, scaler: TextScaler.noScaling);
    expect(tester.takeException(), isNull);
  });

  testWidgets('1.2 倍字号：预算同步缩放无溢出', (tester) async {
    await pumpCard(tester, width: 205, scaler: const TextScaler.linear(1.2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('无副标：预算收紧后仍无溢出', (tester) async {
    await pumpCard(
      tester,
      width: 160,
      scaler: TextScaler.noScaling,
      withSubtitle: false,
    );
    expect(tester.takeException(), isNull);
  });
}
