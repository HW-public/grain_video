import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/repositories.dart';
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

/// 源筛选：选中的插件 package；null=全部源。仅作用于结果区。
final searchSourceFilterProvider = NotifierProvider<_SourceFilter, String?>(
  _SourceFilter.new,
);

class _SourceFilter extends Notifier<String?> {
  @override
  String? build() => null;

  /// 再次点选同一源即复位为「全部」。
  void select(String? package) => state = package;
}

/// 源 chips 上的 emoji：取插件 metadata 的 `emoji` 字段，缺省 🧩。
String emojiOf(PluginInfo info) {
  try {
    final json = jsonDecode(info.raw);
    if (json is Map &&
        json['emoji'] is String &&
        (json['emoji'] as String).isNotEmpty) {
      return json['emoji'] as String;
    }
  } on Object {
    // 元数据非法时用兜底图标。
  }
  return '🧩';
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

/// 历史搜索：持久化在 drift `SearchHistories` 表（keyword 去重、上限 20 条），
/// state 为内存镜像——add/clear 先乐观更新 UI 再落库。
final searchHistoryProvider = NotifierProvider<SearchHistory, List<String>>(
  SearchHistory.new,
);

class SearchHistory extends Notifier<List<String>> {
  static const int maxEntries = 20;

  @override
  List<String> build() {
    Future<void>.microtask(() async {
      try {
        final rows = await ref
            .read(searchHistoryRepositoryProvider)
            .recent(limit: maxEntries);
        // 竞态防护：add/clear 可能先于读库完成（微任务交错），
        // 此时 state 非空是用户写入，不能覆盖。
        if (state.isEmpty) state = rows;
      } on Object {
        // 数据库不可用（测试环境）：保持空表。
      }
    });
    return const [];
  }

  Future<void> add(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) return;
    // 乐观置顶。
    state = [k, ...state.where((e) => e != k)].take(maxEntries).toList();
    await ref.read(searchHistoryRepositoryProvider).add(k);
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(searchHistoryRepositoryProvider).clear();
  }

  /// 删除单条（管理模式，用户拍板 2026-11-20）。
  Future<void> remove(String keyword) async {
    state = state.where((e) => e != keyword).toList();
    await ref.read(searchHistoryRepositoryProvider).remove(keyword);
  }
}
