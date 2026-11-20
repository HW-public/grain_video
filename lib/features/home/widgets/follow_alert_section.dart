import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../providers/home_providers.dart';

/// 「追更提醒」提示条：追番列表中存在「总集数 > 已看到集数」的条目时显示。
///
/// 初版从简：最多展示 3 条；点击进入搜索页。
class FollowAlertSection extends ConsumerWidget {
  const FollowAlertSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(followsProvider);
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
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.title, required this.episode});

  final String title;
  final int episode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space3 + 2,
        vertical: AppTokens.space3,
      ),
      decoration: BoxDecoration(
        color: AppTokens.mint.primaryContainer,
        border: Border.all(color: AppTokens.mint.primarySoft),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppTokens.mint.secondary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTokens.mint.secondary.withValues(alpha: 0.18),
                  blurRadius: 4,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space2 + 2),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: FlutterI18n.translate(
                      context,
                      'home.followAlertTitle',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: ' · '),
                  TextSpan(
                    text: FlutterI18n.translate(
                      context,
                      'home.followUpdate',
                      translationParams: {
                        'title': title,
                        'episode': '$episode',
                      },
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTokens.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space2),
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
