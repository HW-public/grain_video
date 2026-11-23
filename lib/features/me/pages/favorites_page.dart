import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/async_view.dart';
import '../../../data/db/database.dart';
import '../utils/date_format.dart';
import '../providers/me_providers.dart';
import '../widgets/me_empty_state.dart';

/// 我的收藏列表：2:3 封面行 + 空态（「状态-空态」帧范式）。
///
/// 点击跳详情（src/url 参数为假定契约，待详情页定稿对齐）。
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesListProvider);
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.favoritesTitle')),
      ),
      body: AsyncView(
        value: favorites,
        builder: (context, items) {
          if (items.isEmpty) {
            return MeEmptyState(
              icon: Icons.star_outline,
              title: FlutterI18n.translate(context, 'me.emptyFavoritesTitle'),
              hint: FlutterI18n.translate(context, 'me.emptyFavoritesHint'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppTokens.space4),
            itemCount: items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppTokens.space3),
            itemBuilder: (context, index) => _FavoriteItem(
              item: items[index],
              onTap: () => _openDetail(context, items[index]),
            ),
          );
        },
      ),
    );
  }

  void _openDetail(BuildContext context, Favorite item) {
    context.push(
      '${AppRoutes.detail}?src=${Uri.encodeComponent(item.sourcePackage)}'
      '&url=${Uri.encodeComponent(item.bangumiUrl)}',
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  const _FavoriteItem({required this.item, required this.onTap});

  final Favorite item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      onTap: onTap,
      child: Row(
        children: [
          _Poster(url: item.cover),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTokens.space1),
                Text(
                  '${FlutterI18n.translate(context, 'me.favoritedAt')}'
                  ' ${formatMeDate(item.createdAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppTokens.textTertiary,
          ),
        ],
      ),
    );
  }
}

/// 2:3 封面占位：无图时用浅绿底 + 图标。
class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const width = 64.0;
    const height = width / AppTokens.coverRatioComic;
    final radius = BorderRadius.circular(AppTokens.space2);
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppTokens.defaultPalette.primaryContainer,
          borderRadius: radius,
        ),
        child: Icon(
          Icons.image_outlined,
          size: 24,
          color: AppTokens.defaultPalette.primary,
        ),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedImage(url: url, width: width, height: height),
    );
  }
}
