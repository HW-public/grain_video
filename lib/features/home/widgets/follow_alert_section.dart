import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/home_providers.dart';

/// 「追更提醒」条（设计稿 4:31 / 节点 5:45）：
/// 圆角16、高56、浅薄荷底(变量 3:19)，左橙点(8,变量 3:21) + 更新文案 +
/// 右侧主色「去围观 ›」；存在「总集数 > 已看到集数」的追番时显示，最多 3 条。
class FollowAlertSection extends ConsumerWidget {
  const FollowAlertSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(followsProvider);
    final entries = ref.watch(pluginManagerProvider);
    return value.when(
      data: (follows) {
        final updated = follows
            .where(
              (f) => f.totalEpisode > 0 && f.totalEpisode > f.currentEpisode,
            )
            .take(3)
            .toList();
        if (updated.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space3,
            AppTokens.space4,
            0,
          ),
          child: Column(
            children: [
              for (final follow in updated)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space2),
                  child: _AlertCard(
                    title: follow.title,
                    episode: follow.totalEpisode,
                    source: _sourceName(entries, follow.sourcePackage),
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  static String _sourceName(List<PluginEntry> entries, String package) {
    for (final e in entries) {
      if (e.info.package == package) return e.info.name;
    }
    return package;
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.title,
    required this.episode,
    required this.source,
  });

  final String title;
  final int episode;
  final String source;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 14, right: 40),
      decoration: BoxDecoration(
        // 帧 5:45 底色 = Figma 变量 3:19（AppTokens.mintTint）。
        color: AppTokens.mintTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 橙点 8×8（变量 3:21），垂直居中，无光晕。
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTokens.mint.secondary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          // 文案 (30,20)：12/400 textPrimary。
          Expanded(
            child: Text(
              FlutterI18n.translate(
                context,
                'home.followUpdate',
                translationParams: {
                  'title': title,
                  'source': source,
                  'episode': '$episode',
                },
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => context.go(AppRoutes.search),
            child: Text(
              FlutterI18n.translate(context, 'home.followGo'),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTokens.mint.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
