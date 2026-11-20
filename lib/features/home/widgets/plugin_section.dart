import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/bangumi_card.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/home_providers.dart';
import 'section_header.dart';

/// 单个插件的「<插件名> · 最近更新」横滑分区（数据源 [pluginLatestProvider]）。
///
/// 空数据时整区隐藏（不占位）。
class PluginSection extends ConsumerWidget {
  const PluginSection({super.key, required this.entry});

  final PluginEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(pluginLatestProvider(entry.info.package));
    final title =
        '${entry.info.name} · '
        '${FlutterI18n.translate(context, 'home.recentUpdates')}';
    return value.when(
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: title,
                  trailing: GestureDetector(
                    onTap: () => context.go(AppRoutes.search),
                    child: Text(
                      FlutterI18n.translate(context, 'home.more'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.mint.primary,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 124,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space4,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: AppTokens.space3),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return BangumiCard(
                        coverUrl: item.cover,
                        title: item.title,
                        update: item.update,
                        width: 152,
                        onTap: () => context.push(
                          '${AppRoutes.detail}'
                          '?url=${Uri.encodeComponent(item.url)}'
                          '&src=${Uri.encodeComponent(entry.info.package)}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SectionLoading(),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          SectionError(
            error: error,
            onRetry: () =>
                ref.invalidate(pluginLatestProvider(entry.info.package)),
          ),
        ],
      ),
    );
  }
}
