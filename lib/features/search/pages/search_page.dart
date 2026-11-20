import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/bangumi_card.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/search_providers.dart';
import '../widgets/search_input_bar.dart';

/// 搜索页（一级页，底部导航 index=1）。
///
/// 顶部搜索栏自动聚焦；输入 500ms 防抖或键盘提交后跨全部已安装插件
/// 聚合搜索。未输入时展示设计稿初始态（历史搜索 chips + 大家都在搜榜）。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  static const Duration _debounce = Duration(milliseconds: 500);

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return;
    _debounceTimer?.cancel();
    _focusNode.unfocus();
    ref.read(searchHistoryProvider.notifier).add(k);
    ref.read(searchKeywordProvider.notifier).update(k);
  }

  void _onChanged(String value) {
    ref.read(searchQueryProvider.notifier).update(value);
    // 清空按钮显隐随文本变化。
    setState(() {});
    _debounceTimer?.cancel();
    if (value.trim().isEmpty) return;
    _debounceTimer = Timer(_debounce, () => _submit(value));
  }

  void _onClear() {
    // 取消未触发的防抖，避免清空后搜索又自动提交。
    _debounceTimer?.cancel();
    ref.read(searchQueryProvider.notifier).update('');
    ref.read(searchKeywordProvider.notifier).update('');
  }

  @override
  Widget build(BuildContext context) {
    // 历史 chip / 热门词点击会写入 searchQueryProvider，回灌输入框。
    ref.listen(searchQueryProvider, (_, next) {
      if (_controller.text != next) _controller.text = next;
    });
    final keyword = ref.watch(searchKeywordProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SearchInputBar(
              controller: _controller,
              focusNode: _focusNode,
              hint: _t(context, 'search.hint'),
              onChanged: _onChanged,
              onSubmitted: _submit,
              onClear: _onClear,
            ),
            Expanded(
              child: keyword.isEmpty
                  ? const _InitialView()
                  : _ResultView(keyword: keyword),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

String _t(BuildContext context, String key) =>
    FlutterI18n.translate(context, key);

/// 初始态：历史搜索 chips（灰底，规格 04）+ 大家都在搜榜。
class _InitialView extends ConsumerWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(searchHistoryProvider);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
      children: [
        if (history.isNotEmpty) ...[
          _SectionHeader(
            title: _t(context, 'search.history'),
            trailing: IconButton(
              tooltip: _t(context, 'search.clearHistory'),
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: AppTokens.textTertiary,
              ),
              onPressed: () => _confirmClearHistory(context, ref),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
            child: Wrap(
              spacing: AppTokens.space2,
              runSpacing: 10,
              children: [
                for (final word in history)
                  _HistoryChip(
                    label: word,
                    onTap: () => _applyKeyword(ref, word),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.space5),
        ],
        _SectionHeader(title: _t(context, 'search.hot')),
        const SizedBox(height: AppTokens.space2),
        for (final entry in hotSearchSeed)
          _HotRankTile(
            entry: entry,
            onTap: () => _applyKeyword(ref, entry.word),
          ),
      ],
    );
  }

  static void _applyKeyword(WidgetRef ref, String word) {
    ref.read(searchQueryProvider.notifier).update(word);
    ref.read(searchHistoryProvider.notifier).add(word);
    ref.read(searchKeywordProvider.notifier).update(word);
  }

  static Future<void> _confirmClearHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_t(context, 'search.clearHistory')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(_t(context, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(_t(context, 'common.confirm')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(searchHistoryProvider.notifier).clear();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surfaceAlt,
      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: AppTokens.space2,
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: AppTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

typedef HotEntry = ({int rank, String word, bool hot, bool fresh});

class _HotRankTile extends StatelessWidget {
  const _HotRankTile({required this.entry, required this.onTap});

  final HotEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                child: Text(
                  '${entry.rank}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: entry.rank <= 3
                        ? scheme.primary
                        : AppTokens.textTertiary,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Text(
                  entry.word,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textPrimary,
                  ),
                ),
              ),
              if (entry.hot)
                _RankTag(
                  label: _t(context, 'search.tagHot'),
                  kind: _TagKind.hot,
                ),
              if (entry.fresh)
                _RankTag(
                  label: _t(context, 'search.tagNew'),
                  kind: _TagKind.fresh,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TagKind { hot, fresh }

class _RankTag extends StatelessWidget {
  const _RankTag({required this.label, required this.kind});

  final String label;
  final _TagKind kind;

  @override
  Widget build(BuildContext context) {
    final bg = kind == _TagKind.hot
        ? AppTokens.danger
        : AppTokens.defaultPalette.primarySoft;
    final fg = kind == _TagKind.hot ? Colors.white : AppTokens.darkBg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// 结果态：聚合网格（BangumiCard 两列，来源插件名走 subtitle 标注）。
class _ResultView extends ConsumerWidget {
  const _ResultView({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(keyword));

    return results.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _SearchFailure(
        message: _t(context, 'search.failed'),
        onRetry: () => ref.invalidate(searchResultsProvider(keyword)),
      ),
      data: (hits) {
        final pluginCount = ref.watch(pluginManagerProvider).length;
        if (pluginCount == 0) {
          return _SearchFailure(message: _t(context, 'search.noPlugins'));
        }
        if (hits.isEmpty) {
          return _SearchFailure(
            message: _t(context, 'search.empty'),
            hint: _t(context, 'search.emptyHint'),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            // 与 GridView 的 padding/spacing 保持一致，反推单元格宽高比。
            const padding = AppTokens.space4;
            const spacing = AppTokens.space3;
            final cellWidth =
                (constraints.maxWidth - padding * 2 - spacing) / 2;
            // 卡高 = 16:9 封面 + 标题行 + 间距（与 BangumiCard 内部结构对齐）。
            final cellHeight =
                cellWidth / AppTokens.coverRatioVideo + 6 + 18 + 2;
            return GridView.count(
              padding: const EdgeInsets.all(padding),
              crossAxisCount: 2,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: cellWidth / cellHeight,
              children: [
                for (final hit in hits)
                  BangumiCard(
                    coverUrl: hit.item.cover,
                    title: hit.item.title,
                    update: hit.item.update,
                    subtitle: hit.source.name,
                    onTap: () => context.push(
                      '${AppRoutes.detail}?url=${Uri.encodeComponent(hit.item.url)}'
                      '&src=${Uri.encodeComponent(hit.source.package)}',
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 失败/空态：按设计稿状态-加载失败帧风格（图标 + 文案 + 可选重试）。
class _SearchFailure extends StatelessWidget {
  const _SearchFailure({required this.message, this.hint, this.onRetry});

  final String message;
  final String? hint;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.wifi_tethering_error_outlined,
              size: 48,
              color: AppTokens.textTertiary,
            ),
            const SizedBox(height: AppTokens.space3),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTokens.textPrimary,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: AppTokens.space1),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTokens.textTertiary,
                ),
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppTokens.space3),
              FilledButton.tonal(
                onPressed: onRetry,
                child: Text(_t(context, 'common.retry')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
