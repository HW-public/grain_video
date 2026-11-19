import 'dart:convert';

import 'package:grain_engine/grain_engine.dart';

/// 插件信息：grain.metadata 的解析视图（字段缺失时取兜底值）。
class PluginInfo {
  PluginInfo._({
    required this.sourcePath,
    required this.raw,
    required this.name,
    required this.version,
    required this.type,
    required this.package,
    required this.webSite,
    required this.lang,
    required this.nsfw,
  });

  /// 从 [GrainPlugin.metadata]（JSON 字符串）解析。
  factory PluginInfo.fromMetadata(String sourcePath, String raw) {
    Object? json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      json = null;
    }
    final m = json is Map ? json : const {};
    String s(String k) => m[k] is String ? m[k] as String : '';
    return PluginInfo._(
      sourcePath: sourcePath,
      raw: raw,
      name: s('name').isEmpty ? '未知插件' : s('name'),
      version: s('version'),
      type: s('type'),
      package: s('package'),
      webSite: s('webSite'),
      lang: s('lang'),
      nsfw: m['nsfw'] == true,
    );
  }

  /// 插件 .wasm 文件路径（实例标识）。
  final String sourcePath;

  /// 原始 metadata JSON。
  final String raw;

  final String name;
  final String version;

  /// 插件类型：bangumi / manga / novel ……
  final String type;

  /// 包名（反向域名，插件唯一标识）。
  final String package;
  final String webSite;
  final String lang;
  final bool nsfw;

  @override
  String toString() => 'PluginInfo($name $version, $package)';
}

/// 番剧条目：latest/search 返回的 JSON 数组元素
/// `{"cover","title","update","url"}` 的解析视图。
class BangumiItem {
  BangumiItem._({
    required this.cover,
    required this.title,
    required this.update,
    required this.url,
  });

  /// 解析单条 JSON 对象；缺 title 视为无效（返回 null）。
  static BangumiItem? fromJson(Object? json) {
    if (json is! Map) return null;
    final title = json['title'];
    if (title is! String || title.isEmpty) return null;
    return BangumiItem._(
      cover: json['cover'] is String ? json['cover'] as String : '',
      title: title,
      update: json['update'] is String ? json['update'] as String : '',
      url: json['url'] is String ? json['url'] as String : '',
    );
  }

  /// 解析插件返回的 JSON 数组字符串；元素解析失败（如错误信封）跳过。
  static List<BangumiItem> parseList(String raw) {
    Object? json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      json = null;
    }
    if (json is! List) return const [];
    return json.map(fromJson).whereType<BangumiItem>().toList();
  }

  final String cover;
  final String title;
  final String update;

  /// 条目链接或插件私有 ID（detail/watch 调用参数）。
  final String url;

  @override
  String toString() => 'BangumiItem($title)';
}
