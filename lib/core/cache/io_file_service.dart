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

  @override
  Future<FileServiceResponse> get(
    String url, {
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(url);
    final request = await _client.getUrl(uri);
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
