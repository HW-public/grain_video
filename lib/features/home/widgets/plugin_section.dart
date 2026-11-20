import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/bangumi_card.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/home_providers.dart';
import 'section_header.dart';

/// 单个插件的「emoji 源名 · 最近更新」两列网格分区（设计稿 4:31，数据源
/// [pluginLatestProvider]）。视频卡 168×95(16:9) 圆角12，列间距10；
/// 空数据时整区隐藏（不占位）。
class PluginSection extends ConsumerWidget {
  const PluginSection({super.key, required this.entry});

  final PluginEntry entry;

  /// 网格最多展示的条目数（帧未规定，记为偏离）。
  static const int _maxItems = 12;

  @override
  Widget build(BuildContext context, ref) {
    final value = ref.watch(pluginLatestProvider(entry.info.package));
    final title =
        '${_typeEmoji(entry.info.type)} '
        '${entry.info.name} · '
        '${FlutterI18n.translate(context, 'home.recentUpdates')}';
    return value.when(
      data: (items) {
        final gridItems = items.take(_maxItems).toList();
        if (gridItems.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: title,
              trailing: GestureDetector(
                onTap: () => context.push(AppRoutes.search),
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
            // 分区之间间距 25（上一区标题底 → 下一区标题）：
            // SectionHeader 上 16 + 本区底部 9。
            // 两列网格：卡宽 = (可用宽-列距10)/2，窄屏也保持两列
            // （帧 390 宽下为 168；写死 168 在 360 级窄屏会退化成单列）。
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                0,
                AppTokens.space4,
                9,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  final cardWidth = (constraints.maxWidth - gap) / 2;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final item in gridItems)
                        BangumiCard(
                          coverUrl: item.cover,
                          title: item.title,
                          update: item.update,
                          width: cardWidth,
                          onTap: () => _openDetail(context, item),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
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

  void _openDetail(BuildContext context, BangumiItem item) {
    context.push(
      '${AppRoutes.detail}'
      '?url=${Uri.encodeComponent(item.url)}'
      '&src=${Uri.encodeComponent(entry.info.package)}',
    );
  }

  /// 分区标题 emoji（插件 metadata 无 emoji 字段，按类型映射，偏离已报）。
  static String _typeEmoji(String type) {
    return switch (type) {
      'bangumi' => '📺',
      'manga' => '📚',
      'novel' => '📖',
      _ => '🧩',
    };
  }
}
