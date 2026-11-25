import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/home_providers.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/merged_latest_section.dart';

/// 首页（设计稿「首页」4:31，无 AppBar）：
/// 继续观看 hero → 追更提醒 → 各插件「最近更新」两列网格 → 底部导航。
///
/// 数据源常驻缓存：切底部 tab 不重新拉取，下拉手势统一刷新。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// 下拉刷新：继续观看 + 追更提醒 + 合并「最近更新」并发重拉。
  Future<void> _refresh(WidgetRef ref) async {
    await Future.wait([
      ref.refresh(recentWatchProvider.future),
      ref.refresh(followsProvider.future),
      ref.refresh(mergedLatestProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginManagerProvider);

    return Scaffold(
      // 页面底交给主题 scaffoldBackgroundColor（亮=pageBg / 暗=darkBg）。
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () => _refresh(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            top: AppTokens.space2,
            bottom: AppTokens.space6,
          ),
          children: [
            // 用户拍板（2026-11-24）：追更提醒并入继续观看轮播（徽标形态），不再单列。
            const ContinueWatchingSection(),
            if (plugins.isEmpty)
              const _NoPlugins()
            else
              // 用户拍板：多源合并为单一「最近更新」分区（不再按源分多个区）。
              const MergedLatestSection(),
          ],
        ),
      ),
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
