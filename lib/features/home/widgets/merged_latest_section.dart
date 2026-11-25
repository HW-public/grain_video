import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/bangumi_card.dart';
import '../providers/home_providers.dart';
import 'section_header.dart';

/// 首页「最近更新」合并分区（用户 2026-11-20 定的演进方向）：
/// 全部已安装插件的 latest 第一页并发拉取，按源轮流交错混排，
/// 单分区展示（两列网格、总数封顶 [_maxItems]），不再按源分多个区。
class MergedLatestSection extends ConsumerWidget {
  const MergedLatestSection({super.key});

  /// 合并区总条数（帧未规定，沿用此前每区 12 的上限）。
  static const int _maxItems = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mergedLatestProvider);
    final title = FlutterI18n.translate(context, 'home.recentUpdates');
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
                // 用户拍板：去源主页（该源「最新+搜索」一体），不是搜索页；
                // 默认源 = 首条可见内容的来源。
                onTap: () => context.push(
                  '${AppRoutes.source}?src=${Uri.encodeComponent(gridItems.first.sourcePackage)}',
                ),
                child: Text(
                  FlutterI18n.translate(context, 'home.more'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
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
                      for (final hit in gridItems)
                        BangumiCard(
                          coverUrl: hit.item.cover,
                          title: hit.item.title,
                          update: hit.item.update,
                          width: cardWidth,
                          onTap: () => context.push(
                            '${AppRoutes.detail}?url=${Uri.encodeComponent(hit.item.url)}'
                            '&src=${Uri.encodeComponent(hit.sourcePackage)}',
                          ),
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
            onRetry: () => ref.invalidate(mergedLatestProvider),
          ),
        ],
      ),
    );
  }
}
