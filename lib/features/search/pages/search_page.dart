import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_tab_scope.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/bangumi_card.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/search_providers.dart';
import '../widgets/search_input_bar.dart';
import '../widgets/source_filter_bar.dart';

/// 搜索页（一级页，底部导航 index=1，Figma 21:19）。
///
/// 顶部搜索栏自动聚焦；输入 500ms 防抖或键盘提交后跨全部已安装插件
/// 聚合搜索。未输入时展示初始态「历史搜索」chips。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _tab = -1;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 分支常驻树（IndexedStack），仅在搜索 tab 可见时请求输入框焦点，
  /// 避免 App 启动时焦点/键盘被离屏搜索页抢走。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = AppTabScope.of(context);
    if (tab == 1 && _tab != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }
    _tab = tab;
  }

  void _submit(String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return;
    // 用户拍板（2026-11-20）：输入不自动搜索，仅按钮/键盘提交触发。
    _focusNode.unfocus();
    ref.read(searchHistoryProvider.notifier).add(k);
    ref.read(searchKeywordProvider.notifier).update(k);
  }

  void _onChanged(String value) {
    ref.read(searchQueryProvider.notifier).update(value);
  }

  @override
  Widget build(BuildContext context) {
    // 历史 chip 点击会写入 searchQueryProvider，回灌输入框。
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
              submitLabel: _t(context, 'search.search'),
              onChanged: _onChanged,
              onSubmitted: _submit,
              // 用户拍板（2026-11-20）：点清除 × 后结果区也复位到初始态。
              onClear: () {
                ref.read(searchQueryProvider.notifier).update('');
                ref.read(searchKeywordProvider.notifier).update('');
              },
            ),
            const SourceFilterBar(),
            Expanded(
              // 帧 21:19：已输入关键词后「历史搜索」仍显示在结果上方（同屏）。
              child: keyword.isEmpty
                  ? const _HistoryView(scrollable: true)
                  : _ResultStateView(keyword: keyword),
            ),
          ],
        ),
      ),
    );
  }
}

String _t(BuildContext context, String key) =>
    FlutterI18n.translate(context, key);

/// 历史搜索区（21:19 + 用户拍板 2026-11-20）：标题行右侧「管理」，
/// 点管理进入管理模式——chip 带 ×（点按删除单条），
/// 右上角出现「清空」（批量，带确认）与「完成」（退出）。
///
/// 空历史整区隐藏。[scrollable]=true 时独立可滚（初始态）；
/// 结果态经 [_ResultStateView] 直插 Column，占内容高度（≤20 条约数行）。
class _HistoryView extends ConsumerStatefulWidget {
  const _HistoryView({this.scrollable = false});

  final bool scrollable;

  @override
  ConsumerState<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends ConsumerState<_HistoryView> {
  bool _managing = false;

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(searchHistoryProvider);
    if (history.isEmpty) return const SizedBox.shrink();

    final children = <Widget>[
      _SectionHeader(
        title: _t(context, 'search.history'),
        // 非管理态：「管理」；管理态：「清空」（批量，带确认）+「完成」。
        trailing: _managing
            ? Padding(
                // 用户拍板（2026-11-23）：与搜索栏「搜索」按钮文字右缘对齐
                // （屏幕右缘内 34 = 头部边距 16 + 此处 18），两按钮间距 4。
                padding: const EdgeInsets.only(right: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => _confirmClearHistory(context),
                      child: Text(
                        _t(context, 'search.clear'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.mint.primary,
                        ),
                      ),
                    ),
                    // 用户拍板（2026-11-23）：「清空」「完成」间距 4→8。
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () => setState(() => _managing = false),
                      child: Text(
                        _t(context, 'search.done'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.mint.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                // 用户拍板（2026-11-23）：与管理态一致，对齐搜索栏「搜索」按钮。
                padding: const EdgeInsets.only(right: 18),
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => setState(() => _managing = true),
                  child: Text(
                    _t(context, 'search.manage'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.mint.primary,
                    ),
                  ),
                ),
              ),
      ),
      // 帧：标题→pills 9。
      const SizedBox(height: 9),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
        child: Wrap(
          spacing: AppTokens.space2,
          runSpacing: AppTokens.space2,
          children: [
            for (final word in history)
              _HistoryChip(
                label: word,
                managing: _managing,
                onTap: () => _applyKeyword(ref, word),
                onDelete: () =>
                    ref.read(searchHistoryProvider.notifier).remove(word),
              ),
          ],
        ),
      ),
    ];
    if (widget.scrollable) {
      return ListView(padding: EdgeInsets.zero, children: children);
    }
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      children: children,
    );
  }

  static void _applyKeyword(WidgetRef ref, String word) {
    ref.read(searchQueryProvider.notifier).update(word);
    ref.read(searchHistoryProvider.notifier).add(word);
    ref.read(searchKeywordProvider.notifier).update(word);
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
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

class _ResultStateView extends ConsumerWidget {
  const _ResultStateView({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasHistory = ref.watch(searchHistoryProvider).isNotEmpty;
    if (!hasHistory) return _ResultView(keyword: keyword);
    // 历史区只占内容高度（shrinkWrap），结果区吃全部余量——
    // 若用 Flexible(flex:1) 与 Expanded 瓜分，历史短时余量会变死白、
    // 结果区被拦腰截断。
    return Column(
      children: [
        const _HistoryView(),
        Expanded(child: _ResultView(keyword: keyword)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space3,
        AppTokens.space4,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
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

/// 历史 pill（21:19）：高 26、圆角 13、surfaceAlt 底、11/400 弱色灰字。
/// 宽度贴合文字（Container 带 alignment 会撑满可用宽，故用 Padding 包文字）。
/// 管理模式（用户拍板）：点按删除单条，label 旁显示 ×。
class _HistoryChip extends StatelessWidget {
  const _HistoryChip({
    required this.label,
    required this.managing,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final bool managing;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTokens.surfaceAlt,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: managing ? onDelete : onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          child: managing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppTokens.textTertiary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.close,
                      size: 12,
                      color: AppTokens.textTertiary,
                    ),
                  ],
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppTokens.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 结果态：AsyncView 三态 + 聚合网格（BangumiCard 两列，来源走 subtitle）。
class _ResultView extends ConsumerWidget {
  const _ResultView({required this.keyword});

  final String keyword;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(searchResultsProvider(keyword));

    return AsyncView<List<SearchHit>>(
      value: results,
      onRetry: () => ref.invalidate(searchResultsProvider(keyword)),
      builder: (context, hits) {
        final pluginCount = ref.watch(pluginManagerProvider).length;
        if (pluginCount == 0) {
          return EmptyState(message: _t(context, 'search.noPlugins'));
        }
        // 源筛选：null=全部，否则只保留该插件的命中。
        final filter = ref.watch(searchSourceFilterProvider);
        final visible = filter == null
            ? hits
            : hits.where((h) => h.source.package == filter).toList();
        return Column(
          children: [
            _ResultHeader(count: visible.length),
            Expanded(
              child: visible.isEmpty
                  ? EmptyState(message: _t(context, 'search.empty'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // 帧：左右边距 16、列间距 8、行距 15。
                        // GridView.builder 懒构建：滑到才创建卡片/发起封面请求。
                        const padding = AppTokens.space4;
                        const columnGap = AppTokens.space2;
                        final cardWidth =
                            (constraints.maxWidth - padding * 2 - columnGap) /
                            2;
                        // 卡高 = 16:9 封面 + 卡→标题4 + 标题18 + 2 + 副标15。
                        final cardHeight =
                            cardWidth / AppTokens.coverRatioVideo +
                            4 +
                            18 +
                            2 +
                            15;
                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            padding,
                            9,
                            padding,
                            padding,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: cardWidth,
                                mainAxisSpacing: 15,
                                crossAxisSpacing: columnGap,
                                mainAxisExtent: cardHeight,
                              ),
                          itemCount: visible.length,
                          itemBuilder: (context, i) {
                            final hit = visible[i];
                            return BangumiCard(
                              coverUrl: hit.item.cover,
                              title: hit.item.title,
                              update: hit.item.update,
                              subtitle: hit.source.name,
                              width: cardWidth,
                              onTap: () => context.push(
                                '${AppRoutes.detail}?url=${Uri.encodeComponent(hit.item.url)}'
                                '&src=${Uri.encodeComponent(hit.source.package)}',
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// 结果区标题行（21:19）：「搜索结果 · N」16/700 + 右侧「按相关度 ▾」12/600
/// 主色（纯展示，排序能力后续接入）。
class _ResultHeader extends StatelessWidget {
  const _ResultHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 帧：chips 底→结果标题 24；右距 34（已有水平 16）。
      padding: const EdgeInsets.fromLTRB(16, 24, 18, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(
              FlutterI18n.translate(
                context,
                'search.resultCount',
                translationParams: {'count': '$count'},
              ),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary,
              ),
            ),
          ),
          Text(
            '${_t(context, 'search.sortBy')} ▾',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTokens.mint.primary,
            ),
          ),
        ],
      ),
    );
  }
}
