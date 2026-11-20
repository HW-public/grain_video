import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';

/// 搜索页状态编排。
///
/// 输入框文本（[searchQueryProvider]）与已提交关键词
/// （[searchKeywordProvider]）分离：输入经 500ms 防抖或键盘提交后
/// 才写入关键词，触发 [searchResultsProvider] 重新搜索。

/// 输入框当前文本（未提交）。
final searchQueryProvider = NotifierProvider<_QueryHolder, String>(
  _QueryHolder.new,
);

class _QueryHolder extends Notifier<String> {
  @override
  String build() => '';

  /// 外部写入（riverpod 3 中 [state] setter 为受保护成员）。
  void update(String value) => state = value;
}

/// 已提交、正在搜索的关键词；空串表示未搜索（展示初始态）。
final searchKeywordProvider = NotifierProvider<_KeywordHolder, String>(
  _KeywordHolder.new,
);

class _KeywordHolder extends Notifier<String> {
  @override
  String build() => '';

  /// 外部写入（riverpod 3 中 [state] setter 为受保护成员）。
  void update(String value) => state = value;
}

/// 一条聚合结果：番剧条目 + 来源插件（元数据）。
class SearchHit {
  const SearchHit({required this.item, required this.source});

  final BangumiItem item;
  final PluginInfo source;

  @override
  String toString() => 'SearchHit(${item.title} @ ${source.name})';
}

/// 跨全部已安装插件并发 callSearch 并聚合。
///
/// 单插件失败（超时/trap/解析失败）跳过，不影响其它插件结果；
/// 插件非空但全部失败时抛错，由页面呈现错误态。
final searchResultsProvider = FutureProvider.autoDispose
    .family<List<SearchHit>, String>((ref, keyword) async {
      if (keyword.isEmpty) return const [];

      final manager = ref.watch(pluginManagerProvider.notifier);
      final entries = ref.watch(pluginManagerProvider);

      var failed = 0;
      Future<List<SearchHit>> probe(PluginEntry entry) async {
        try {
          final items = await manager.callSearch(entry, keyword);
          return [
            for (final item in items) SearchHit(item: item, source: entry.info),
          ];
        } on Object {
          failed++;
          return const [];
        }
      }

      final groups = await Future.wait(entries.map(probe));
      if (entries.isNotEmpty && failed == entries.length) {
        throw StateError('all plugins failed for "$keyword"');
      }
      return [for (final g in groups) ...g];
    });

/// 历史搜索：会话内内存态（新增在前、去重、上限 20 条）。
///
/// 持久化（shared_preferences）等 pubspec 解锁后再接。
final searchHistoryProvider = NotifierProvider<SearchHistory, List<String>>(
  SearchHistory.new,
);

class SearchHistory extends Notifier<List<String>> {
  static const int maxEntries = 20;

  @override
  List<String> build() => const [];

  void add(String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return;
    state = [k, ...state.where((e) => e != k)].take(maxEntries).toList();
  }

  void clear() => state = const [];
}

/// 热门搜索占位：设计稿「大家都在搜」示例榜。
///
/// 插件协议暂无 hotSearch 能力，先静态呈现设计稿榜单。
const hotSearchSeed = [
  (rank: 1, word: '葬送的芙莉莲 第二季', hot: true, fresh: false),
  (rank: 2, word: '孤独摇滚 剧场版', hot: true, fresh: false),
  (rank: 3, word: '蓝色监狱 第二季', hot: false, fresh: false),
  (rank: 4, word: '迷宫饭 第二季', hot: false, fresh: true),
  (rank: 5, word: '狩龙人拉格纳', hot: false, fresh: false),
];
