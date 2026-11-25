import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/bangumi_card.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/search_providers.dart';
import '../widgets/search_input_bar.dart';

/// 源主页（用户拍板 2026-11-23）：单个插件的「最新 + 搜索」一体页。
///
/// 搜索栏为空 → 该源 latest 分页流（触底翻页）；提交关键词 → 只搜该源。
/// 入口：首页合并分区「更多 ›」（?src=插件 package）。
class SourcePage extends ConsumerStatefulWidget {
  const SourcePage({super.key, required this.package});

  final String package;

  @override
  ConsumerState<SourcePage> createState() => _SourcePageState();
}

class _SourcePageState extends ConsumerState<SourcePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _keyword = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String keyword) {
    final k = keyword.trim();
    _focusNode.unfocus();
    setState(() => _keyword = k);
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(pluginManagerProvider);
    final entry = entries
        .where((e) => e.info.package == widget.package)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(entry?.info.name ?? widget.package)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchInputBar(
              controller: _controller,
              focusNode: _focusNode,
              hint: '在「${entry?.info.name ?? ''}」中搜索…',
              submitLabel: '搜索',
              onSubmitted: _submit,
              // 点清除 × 回该源 latest 流。
              onChanged: (v) {
                if (v.isEmpty && _keyword.isNotEmpty) {
                  setState(() => _keyword = '');
                }
              },
            ),
          ),
          Expanded(
            child: entry == null
                ? EmptyState(
                    icon: Icons.extension_outlined,
                    message: widget.package,
                  )
                : _keyword.isEmpty
                ? _LatestGrid(entry: entry)
                : _SearchResults(keyword: _keyword, package: widget.package),
          ),
        ],
      ),
    );
  }
}

/// 两列成对切行：与首页「最近更新」的 Wrap 逐像素一致
///（卡高=卡片自然高，任意字体缩放不错位）。
List<List<BangumiItem>> _chunkRows(List<BangumiItem> items) => [
  for (var i = 0; i < items.length; i += 2)
    items.sublist(i, i + 2 > items.length ? items.length : i + 2),
];

/// 一行两张卡（右槽可空），列距 10，卡宽均分。
/// 卡宽显式算给 BangumiCard（其封面按 width 定尺寸；不传会回退默认 160，
/// 封面偏窄、列距被撑大——布局与首页不一致的根因）。
Widget _cardRow(
  List<BangumiItem> pair,
  Widget Function(BangumiItem item, double width) card,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: LayoutBuilder(
      builder: (context, constraints) {
        const gap = 10.0;
        final cardWidth = (constraints.maxWidth - gap) / 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card(pair[0], cardWidth)),
            const SizedBox(width: gap),
            Expanded(
              child: pair.length > 1
                  ? card(pair[1], cardWidth)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    ),
  );
}

/// 回到顶部按钮：滚动超过 [threshold] 浮现，点击平滑回顶。
class _BackToTop extends StatelessWidget {
  const _BackToTop({required this.visible, required this.controller});

  final bool visible;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !visible,
        child: Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Material(
              color: AppTokens.darkBg.withValues(alpha: 0.72),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => controller.animateTo(
                  0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_upward,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 无关键词：该源 latest 分页流，触底翻页。
class _LatestGrid extends ConsumerStatefulWidget {
  const _LatestGrid({required this.entry});

  final PluginEntry entry;

  @override
  ConsumerState<_LatestGrid> createState() => _LatestGridState();
}

class _LatestGridState extends ConsumerState<_LatestGrid> {
  final ScrollController _controller = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final show = _controller.offset > 400;
      if (show != _showBackToTop) setState(() => _showBackToTop = show);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(sourceLatestProvider(widget.entry));

    return AsyncView<List<BangumiItem>>(
      value: value,
      builder: (context, items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.video_library_outlined,
            message: widget.entry.info.name,
          );
        }
        final notifier = ref.read(sourceLatestProvider(widget.entry).notifier);
        final hasMore = notifier.hasMore;
        final loadingMore = value.isLoading && items.isNotEmpty;
        final rows = _chunkRows(items);

        final grid = RefreshIndicator(
          // 下拉刷新：重拉该源第一页（分页状态归位由 build 重建保证）。
          onRefresh: () =>
              ref.refresh(sourceLatestProvider(widget.entry).future),
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200 &&
                  hasMore &&
                  !loadingMore) {
                unawaited(notifier.loadMore());
              }
              return false;
            },
            child: ListView.builder(
              controller: _controller,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: rows.length + (hasMore || loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= rows.length) {
                  return Center(
                    child: loadingMore
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const SizedBox(height: 24),
                  );
                }
                return _cardRow(rows[i], (item, width) {
                  return BangumiCard(
                    coverUrl: item.cover,
                    title: item.title,
                    update: item.update,
                    width: width,
                    onTap: () => context.push(
                      '${AppRoutes.detail}?url=${Uri.encodeComponent(item.url)}'
                      '&src=${Uri.encodeComponent(widget.entry.info.package)}',
                    ),
                  );
                });
              },
            ),
          ),
        );
        return Stack(
          children: [
            grid,
            _BackToTop(visible: _showBackToTop, controller: _controller),
          ],
        );
      },
    );
  }
}

class _SearchResults extends ConsumerStatefulWidget {
  const _SearchResults({required this.keyword, required this.package});

  final String keyword;
  final String package;

  @override
  ConsumerState<_SearchResults> createState() => _SearchResultsState();
}

class _SearchResultsState extends ConsumerState<_SearchResults> {
  final ScrollController _controller = ScrollController();
  bool _showBackToTop = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final show = _controller.offset > 400;
      if (show != _showBackToTop) setState(() => _showBackToTop = show);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(
      sourceSearchProvider((keyword: widget.keyword, package: widget.package)),
    );
    return AsyncView<List<BangumiItem>>(
      value: results,
      onRetry: () => ref.invalidate(
        sourceSearchProvider((
          keyword: widget.keyword,
          package: widget.package,
        )),
      ),
      builder: (context, items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.search_off,
            message: '「${widget.keyword}」没有结果',
          );
        }
        final rows = _chunkRows(items);
        final grid = RefreshIndicator(
          // 下拉刷新：重跑该关键词搜索。
          onRefresh: () => ref.refresh(
            sourceSearchProvider((
              keyword: widget.keyword,
              package: widget.package,
            )).future,
          ),
          child: ListView.builder(
            controller: _controller,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: rows.length,
            itemBuilder: (context, i) {
              return _cardRow(rows[i], (item, width) {
                return BangumiCard(
                  coverUrl: item.cover,
                  title: item.title,
                  update: item.update,
                  width: width,
                  onTap: () => context.push(
                    '${AppRoutes.detail}?url=${Uri.encodeComponent(item.url)}'
                    '&src=${Uri.encodeComponent(widget.package)}',
                  ),
                );
              });
            },
          ),
        );
        return Stack(
          children: [
            grid,
            _BackToTop(visible: _showBackToTop, controller: _controller),
          ],
        );
      },
    );
  }
}
