import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/async_view.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/home_providers.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/follow_alert_section.dart';
import '../widgets/plugin_section.dart';

/// 首页（设计稿「首页」4:31，无 AppBar）：
/// 继续观看 hero → 追更提醒 → 各插件「最近更新」两列网格 → 底部导航。
///
/// 数据源常驻缓存：切底部 tab 不重新拉取，下拉手势统一刷新。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// 下拉刷新：继续观看 + 追更提醒 + 全部插件分区并发重拉。
  Future<void> _refresh(WidgetRef ref) async {
    final plugins = ref.read(pluginManagerProvider);
    await Future.wait([
      ref.refresh(recentWatchProvider.future),
      ref.refresh(followsProvider.future),
      for (final e in plugins)
        ref.refresh(pluginLatestProvider(e.info.package).future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginManagerProvider);

    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      body: RefreshIndicator(
        color: AppTokens.mint.primary,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppTokens.space2,
            bottom: AppTokens.space6,
          ),
          children: [
            const ContinueWatchingSection(),
            const FollowAlertSection(),
            if (plugins.isEmpty)
              const _NoPlugins()
            else
              for (final entry in plugins) PluginSection(entry: entry),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

/// 无插件空态（帧 4:31 无此态，按 lead 指示复用 core EmptyState 86:201 范式）。
class _NoPlugins extends StatelessWidget {
  const _NoPlugins();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space6,
        AppTokens.space4,
        AppTokens.space4,
      ),
      child: Column(
        children: [
          EmptyState(
            icon: Icons.extension_outlined,
            message: FlutterI18n.translate(context, 'home.noPlugins'),
          ),
          const SizedBox(height: AppTokens.space4),
          FilledButton.tonal(
            onPressed: () => context.push(AppRoutes.extensions),
            child: Text(FlutterI18n.translate(context, 'home.goExtensions')),
          ),
        ],
      ),
    );
  }
}
