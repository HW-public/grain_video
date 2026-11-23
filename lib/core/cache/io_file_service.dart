import 'dart:async';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 基于 dart:io [HttpClient] 的 FileService 替代。
///
/// 背景：flutter_cache_manager 默认 HttpFileService（package:http）在部分
/// 国内图床（imgzy360/youkupic 等）上请求会无限挂起，而裸 HttpClient
/// 实测正常（200 全量 body）。仅替换传输层，缓存元数据/LRU/过期
/// 仍走 cache_manager 原机制。
class IOFileService extends FileService {
  final HttpClient _client = HttpClient();

  /// 浏览器 UA：部分图床（豆瓣 418 / 各种反盗链）拒绝非浏览器 UA 的裸请求。
  static const _browserUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  /// 反盗链 Referer 例外表：host（后缀匹配） → 期望 Referer。
  /// 只存「要求跨域 referer」的图床（如豆瓣要求 referer 来自豆瓣域）；
  /// 其余图床自动走同源兜底（见 [_refererFor]），新源零配置。
  static const _referers = {'doubanio.com': 'https://www.douban.com/'};

  /// Referer 决策：例外表命中用表值，否则自动同源
  /// （https://图床自身域/）——大部分反盗链查同源即放行。
  static String _refererFor(Uri uri) {
    for (final entry in _referers.entries) {
      if (uri.host.endsWith(entry.key)) return entry.value;
    }
    return '${uri.scheme}://${uri.host}/';
  }

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);
    final request = await _client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, _browserUa);
    request.headers.set(HttpHeaders.refererHeader, _refererFor(uri));
    headers?.forEach(request.headers.add);
    final response = await request.close();
    return _IOGetResponse(response, uri);
  }
}

class _IOGetResponse implements FileServiceResponse {
  _IOGetResponse(this._response, this._uri);

  final HttpClientResponse _response;
  final Uri _uri;
  final DateTime _receivedTime = DateTime.now();

  @override
  Stream<List<int>> get content => _response;

  @override
  int? get contentLength => _response.contentLength;

  @override
  int get statusCode => _response.statusCode;

  @override
  DateTime get validTill {
    // 无 cache-control 时默认保留 7 天（与默认 HttpGetResponse 一致）。
    var age = const Duration(days: 7);
    final control = _response.headers.value(HttpHeaders.cacheControlHeader);
    if (control != null) {
      for (final setting in control.split(',')) {
        final s = setting.trim().toLowerCase();
        if (s == 'no-cache') age = Duration.zero;
        if (s.startsWith('max-age=')) {
          final seconds = int.tryParse(s.split('=')[1]) ?? 0;
          if (seconds > 0) age = Duration(seconds: seconds);
        }
      }
    }
    return _receivedTime.add(age);
  }

  @override
  String? get eTag => _response.headers.value(HttpHeaders.etagHeader);

  @override
  String get fileExtension {
    const typeMap = {
      'image/jpeg': '.jpeg',
      'image/jpg': '.jpg',
      'image/png': '.png',
      'image/gif': '.gif',
      'image/webp': '.webp',
      'image/bmp': '.bmp',
      'image/svg+xml': '.svg',
    };
    final type = _response.headers.value(HttpHeaders.contentTypeHeader);
    if (type != null && typeMap.containsKey(type.toLowerCase())) {
      return typeMap[type.toLowerCase()]!;
    }
    final path = _uri.path.toLowerCase();
    final dot = path.lastIndexOf('.');
    if (dot >= 0 && dot < path.length - 1) {
      final ext = path.substring(dot);
      if (ext.length <= 5) return ext;
    }
    return '.file';
  }
}
