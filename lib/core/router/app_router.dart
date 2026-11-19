import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:go_router/go_router.dart';

/// go_router 配置。
///
/// Phase 2+ 路由在此追加；当前仅一个占位首页（空 Scaffold + AppBar）。
final appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const _PlaceholderHome()),
  ],
);

class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(FlutterI18n.translate(context, 'nav.home'))),
    );
  }
}
