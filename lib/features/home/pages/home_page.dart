import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../extension/plugin_manager.dart';
import '../widgets/continue_watching_section.dart';
import '../widgets/follow_alert_section.dart';
import '../widgets/plugin_section.dart';

/// 首页（设计稿「首页」4:31）：
/// 搜索入口 → 继续观看 → 追更提醒 → 各插件「最近更新」横滑分区 → 底部导航。
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(pluginManagerProvider);

    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'home.title')),
        actions: [
          IconButton(
            tooltip: FlutterI18n.translate(context, 'nav.extensions'),
            icon: const Icon(Icons.extension_outlined),
            onPressed: () => context.push(AppRoutes.extensions),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppTokens.space6),
        children: [
          const _SearchEntry(),
          const ContinueWatchingSection(),
          const FollowAlertSection(),
          if (plugins.isEmpty)
            const _NoPlugins()
          else
            for (final entry in plugins) PluginSection(entry: entry),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}

/// 顶部搜索入口（整框点击 → 搜索页；设计稿 IA：搜索栏 → 横幅 → 分区）。
class _SearchEntry extends StatelessWidget {
  const _SearchEntry();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: InkWell(
        onTap: () => context.go(AppRoutes.search),
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            border: Border.all(color: AppTokens.divider),
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 20, color: AppTokens.textTertiary),
              const SizedBox(width: AppTokens.space2),
              Text(
                FlutterI18n.translate(context, 'home.searchHint'),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 无插件空态：引导去扩展页安装。
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
          const Icon(
            Icons.extension_outlined,
            size: 48,
            color: AppTokens.textTertiary,
          ),
          const SizedBox(height: AppTokens.space3),
          Text(
            FlutterI18n.translate(context, 'home.noPlugins'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTokens.textSecondary,
            ),
          ),
          const SizedBox(height: AppTokens.space1),
          Text(
            FlutterI18n.translate(context, 'home.noPluginsHint'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTokens.textTertiary),
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
