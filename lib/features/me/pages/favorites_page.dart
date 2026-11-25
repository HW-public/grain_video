import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/async_view.dart';
import '../../../data/db/database.dart';
import '../../../data/db/repositories.dart';
import '../utils/date_format.dart';
import '../providers/me_providers.dart';
import '../widgets/me_empty_state.dart';

/// 我的收藏列表，按 Figma 帧 233:1264「我的-收藏」还原：
/// 副标题计数 + 封面行（来源/收藏时间/⋮）+ 编辑多选删除 + 本机保存页脚。
class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage> {
  /// 编辑模式与选中集合（按 bangumiUrl 去重键）。
  var _editMode = false;
  final _selected = <String>{};

  void _toggleEdit() {
    setState(() {
      _editMode = !_editMode;
      _selected.clear();
    });
  }

  Future<void> _removeSelected(List<Favorite> items) async {
    final repo = ref.read(favoritesRepositoryProvider);
    final targets = items
        .where((e) => _selected.contains(e.bangumiUrl))
        .toList();
    for (final item in targets) {
      await repo.toggle(
        sourcePackage: item.sourcePackage,
        bangumiUrl: item.bangumiUrl,
        title: item.title,
        cover: item.cover,
      );
    }
    ref.invalidate(favoritesListProvider);
    _toggleEdit();
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesListProvider);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.favoritesTitle')),
        actions: [
          favorites.maybeWhen(
            data: (items) => items.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: _toggleEdit,
                    child: Text(
                      FlutterI18n.translate(
                        context,
                        _editMode ? 'me.done' : 'me.edit',
                      ),
                      style: TextStyle(fontSize: 14, color: cs.primary),
                    ),
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: _editMode && _selected.isNotEmpty
          ? _DeleteBar(
              count: _selected.length,
              onDelete: () => favorites.whenData(_removeSelected),
            )
          : null,
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
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space4,
              vertical: AppTokens.space2,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: AppTokens.space1,
                  bottom: AppTokens.space2,
                ),
                child: Text(
                  FlutterI18n.translate(
                    context,
                    'me.totalFavorites',
                    translationParams: {'count': '${items.length}'},
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
              for (final item in items)
                _FavoriteItem(
                  item: item,
                  editMode: _editMode,
                  selected: _selected.contains(item.bangumiUrl),
                  onTap: () {
                    if (_editMode) {
                      setState(() {
                        if (!_selected.remove(item.bangumiUrl)) {
                          _selected.add(item.bangumiUrl);
                        }
                      });
                    } else {
                      _openDetail(context, item);
                    }
                  },
                  onRemove: () async {
                    await ref
                        .read(favoritesRepositoryProvider)
                        .toggle(
                          sourcePackage: item.sourcePackage,
                          bangumiUrl: item.bangumiUrl,
                          title: item.title,
                          cover: item.cover,
                        );
                    ref.invalidate(favoritesListProvider);
                  },
                ),
              const SizedBox(height: AppTokens.space6),
              Padding(
                padding: const EdgeInsets.only(left: AppTokens.space1),
                child: Text(
                  FlutterI18n.translate(context, 'me.onlyLocalFavorites'),
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ),
            ],
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

/// 编辑模式下底部的删除条。
class _DeleteBar extends StatelessWidget {
  const _DeleteBar({required this.count, required this.onDelete});

  final int count;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppTokens.danger,
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: onDelete,
          child: Text(
            FlutterI18n.translate(
              context,
              'me.deleteSelected',
              translationParams: {'count': '$count'},
            ),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _FavoriteItem extends StatelessWidget {
  const _FavoriteItem({
    required this.item,
    required this.editMode,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final Favorite item;
  final bool editMode;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
        child: Row(
          children: [
            if (editMode)
              Padding(
                padding: const EdgeInsets.only(right: AppTokens.space2),
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            _Poster(url: item.cover),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    item.sourcePackage,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTokens.space1),
                  Text(
                    '${FlutterI18n.translate(context, 'me.favoritedAt')} '
                    '${formatMeDate(item.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (!editMode)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
                onSelected: (_) => onRemove(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'remove',
                    child: Text(
                      FlutterI18n.translate(context, 'me.removeFavorite'),
                    ),
                  ),
                ],
              ),
          ],
        ),
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
    const width = 56.0;
    const height = 76.0;
    final radius = BorderRadius.circular(AppTokens.space2);
    if (url.isEmpty) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: cs.primary.withValues(alpha: 0.15),
          borderRadius: radius,
        ),
        child: Icon(Icons.image_outlined, size: 24, color: cs.primary),
      );
    }
    return ClipRRect(
      borderRadius: radius,
      child: CachedImage(url: url, width: width, height: height),
    );
  }
}
