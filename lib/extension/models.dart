import 'dart:convert';

import 'package:html/parser.dart' as html_parser;

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

/// 剧集：detail 返回的 episodes 元素 `{"title","url"}`。
/// url 为插件私有串（360zy 是直链，bili 是 `bvid|cid|page`），
/// 原样传给 [PluginManager.callWatch]。
class Episode {
  const Episode({required this.title, required this.url});

  static Episode? fromJson(Object? json) {
    if (json is! Map) return null;
    final url = json['url'];
    if (url is! String || url.isEmpty) return null;
    return Episode(
      title: json['title'] is String ? json['title'] as String : '',
      url: url,
    );
  }

  final String title;
  final String url;

  @override
  String toString() => 'Episode($title)';
}

/// 条目详情：detail 结果 `{"title","cover","description","episodes":[...]}`。
class BangumiDetail {
  const BangumiDetail({
    required this.title,
    required this.cover,
    required this.description,
    required this.episodes,
  });

  /// 解析失败（非对象）返回 null，由调用方决定错误呈现。
  static BangumiDetail? parse(String raw) {
    Object? json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (json is! Map) return null;
    final list = json['episodes'];
    return BangumiDetail(
      title: json['title'] is String ? json['title'] as String : '',
      cover: json['cover'] is String ? json['cover'] as String : '',
      // 源站简介常带 HTML 实体（&#39;）与标签（<p>/<br>），
      // 统一解码剥标签后展示（用户真机抓包 360 源 &#39; 原文显示）。
      description: json['description'] is String
          ? _sanitizeText(json['description'] as String)
          : '',
      episodes: list is List
          ? list.map(Episode.fromJson).whereType<Episode>().toList()
          : const [],
    );
  }

  final String title;
  final String cover;
  final String description;
  final List<Episode> episodes;

  @override
  String toString() => 'BangumiDetail($title, ${episodes.length} 集)';
}

/// HTML 实体解码 + 标签剥离（html 包解析取纯文本）。
String _sanitizeText(String raw) {
  final text = html_parser.parse(raw).documentElement?.text ?? raw;
  return text.trim();
}

/// 播放流：watch 结果 `{"url","headers"?}`。
class StreamInfo {
  const StreamInfo({required this.url, this.headers = const {}});

  static StreamInfo? parse(String raw) {
    Object? json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      return null;
    }
    if (json is! Map) return null;
    final url = json['url'];
    if (url is! String || url.isEmpty) return null;
    final headers = <String, String>{};
    final rawHeaders = json['headers'];
    if (rawHeaders is Map) {
      rawHeaders.forEach((k, v) {
        if (k is String && v is String) headers[k] = v;
      });
    }
    return StreamInfo(url: url, headers: headers);
  }

  /// 播放直链（m3u8/mp4/dash）。
  final String url;

  /// 播放所需请求头（UA/Referer 等），注入 media_kit Player。
  final Map<String, String> headers;

  @override
  String toString() => 'StreamInfo($url)';
}
