import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/bangumi_card.dart';
import '../providers/home_providers.dart';
import 'section_header.dart';

/// 「继续观看」横滑条（数据源 [recentWatchProvider]）。
///
/// 空数据显示设计稿空态文案；点击进入详情页续播。
class ContinueWatchingSection extends ConsumerWidget {
  const ContinueWatchingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(recentWatchProvider);
    return value.when(
      data: (items) => items.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: FlutterI18n.translate(
                    context,
                    'home.continueWatching',
                  ),
                ),
                SectionEmpty(
                  message: FlutterI18n.translate(context, 'home.continueEmpty'),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: FlutterI18n.translate(
                    context,
                    'home.continueWatching',
                  ),
                ),
                SizedBox(
                  height: 132,
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
                      final durationMs = item.durationMs;
                      return BangumiCard(
                        coverUrl: item.cover,
                        title: item.title,
                        update: item.episodeTitle,
                        subtitle: item.sourcePackage,
                        progress: durationMs > 0
                            ? item.positionMs / durationMs
                            : null,
                        width: 168,
                        onTap: () => context.go(
                          '${AppRoutes.detail}'
                          '?url=${Uri.encodeComponent(item.bangumiUrl)}'
                          '&src=${Uri.encodeComponent(item.sourcePackage)}',
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
          SectionHeader(
            title: FlutterI18n.translate(context, 'home.continueWatching'),
          ),
          const SectionLoading(),
        ],
      ),
      error: (error, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: FlutterI18n.translate(context, 'home.continueWatching'),
          ),
          SectionError(
            error: error,
            onRetry: () => ref.invalidate(recentWatchProvider),
          ),
        ],
      ),
    );
  }
}
