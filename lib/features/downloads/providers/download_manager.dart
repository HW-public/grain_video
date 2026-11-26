import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../data/db/database.dart';
import '../../../core/services/download_gateway.dart';
import '../../../data/db/repositories.dart';
import '../../../extension/plugin_manager.dart';

/// 下载引擎（riverpod 3 Notifier）：队列 + HLS 分段/直连文件双模式 +
/// 暂停/续下/重试/删除 + 全部暂停/开始。文件存应用文档 downloads/。
///
/// 续传为整任务重下（不做 Range 断点）；HLS 输出拼接 .ts（mpv 可直放）。
/// 进度写库做 300ms 节流。
class DownloadManager extends Notifier<List<Download>> {
  final _dio = Dio();
  final _tokens = <int, CancelToken>{};
  var _activeCount = 0;
  DateTime _lastWrite = DateTime.fromMillisecondsSinceEpoch(0);

  static const _activeStates = {'queued', 'downloading'};

  DownloadsRepository get _repo => ref.read(downloadsRepositoryProvider);

  @override
  List<Download> build() {
    // 注册跨 feature 入队网关（播放器选集弹层经此触发，见 DownloadGateway）。
    DownloadGateway.enqueue = enqueueFromQuery;
    DownloadGateway.isEnqueued = (package, episodeUrl) => state.any(
      (d) =>
          d.sourcePackage == package &&
          d.episodeUrl == episodeUrl &&
          d.status != 'failed',
    );
    Future<void>.microtask(() async {
      state = await _repo.list();
    });
    return const [];
  }

  Future<void> _fail(int id, String message) async {
    debugPrint('[download] #$id failed: $message');
    await _repo.updateStatus(id, 'failed', errorMsg: message);
    _patch(id, status: 'failed', errorMsg: message);
  }

  void _patch(
    int id, {
    String? status,
    String? errorMsg,
    int? receivedBytes,
    int? totalBytes,
    int? doneSegments,
    int? totalSegments,
    String? localPath,
  }) {
    state = [
      for (final d in state)
        if (d.id == id)
          Download(
            id: d.id,
            sourcePackage: d.sourcePackage,
            bangumiUrl: d.bangumiUrl,
            episodeUrl: d.episodeUrl,
            title: d.title,
            cover: d.cover,
            episodeTitle: d.episodeTitle,
            streamUrl: d.streamUrl,
            headersJson: d.headersJson,
            localPath: localPath ?? d.localPath,
            status: status ?? d.status,
            totalBytes: totalBytes ?? d.totalBytes,
            receivedBytes: receivedBytes ?? d.receivedBytes,
            totalSegments: totalSegments ?? d.totalSegments,
            doneSegments: doneSegments ?? d.doneSegments,
            createdAt: d.createdAt,
            errorMsg: errorMsg ?? d.errorMsg,
          )
        else
          d,
    ];
    DownloadGateway.version.value++;
  }

  Future<void> _throttledProgress(
    int id, {
    int? receivedBytes,
    int? totalBytes,
    int? doneSegments,
    int? totalSegments,
  }) {
    final now = DateTime.now();
    if (now.difference(_lastWrite).inMilliseconds < 300) {
      _patch(
        id,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes,
        doneSegments: doneSegments,
        totalSegments: totalSegments,
      );
      return Future.value();
    }
    _lastWrite = now;
    return _repo.updateProgress(
      id: id,
      receivedBytes: receivedBytes,
      totalBytes: totalBytes,
      doneSegments: doneSegments,
      totalSegments: totalSegments,
    );
  }

  /// 入队：已存在则按状态续下/忽略；否则 callWatch 解析后入库并开下。
  Future<void> enqueue({
    required String sourcePackage,
    required String bangumiUrl,
    required String episodeUrl,
    required String title,
    String cover = '',
    String episodeTitle = '',
  }) async {
    final existing = await _repo.findByEpisode(sourcePackage, episodeUrl);
    if (existing != null) {
      if (existing.status == 'paused' || existing.status == 'failed') {
        return resume(existing.id);
      }
      return; // queued/downloading/done 直接去列表。
    }
    final entries = ref.read(pluginManagerProvider);
    final entry = entries
        .where((e) => e.info.package == sourcePackage)
        .firstOrNull;
    if (entry == null) throw StateError('plugin not installed');
    final stream = await ref
        .read(pluginManagerProvider.notifier)
        .callWatch(entry, episodeUrl);
    if (stream == null) throw StateError('plugin returned no stream');
    final row = await _repo.insert(
      sourcePackage: sourcePackage,
      bangumiUrl: bangumiUrl,
      episodeUrl: episodeUrl,
      title: title,
      cover: cover,
      episodeTitle: episodeTitle,
      streamUrl: stream.url,
      headersJson: jsonEncode(stream.headers),
    );
    state = [row, ...state];
    DownloadGateway.version.value++;
    debugPrint('[download] #${row.id} enqueued: ${row.streamUrl}');
    unawaited(_start(row));
  }

  /// 动作路由入口：播放器选集弹层带参跳入时由页面调用。
  Future<void> enqueueFromQuery(Map<String, String> query) async {
    await enqueue(
      sourcePackage: query['pkg'] ?? '',
      bangumiUrl: query['bangumi'] ?? '',
      episodeUrl: query['ep'] ?? '',
      title: query['title'] ?? '',
      cover: query['cover'] ?? '',
      episodeTitle: query['eptitle'] ?? '',
    );
  }

  Future<void> _start(Download row) async {
    // 简单并发闸：同时只下 2 个，其余排队等待。
    while (_activeCount >= 2) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final latest = await _byId(row.id);
      if (latest == null || !_activeStates.contains(latest.status)) return;
    }
    _activeCount++;
    final token = CancelToken();
    _tokens[row.id] = token;
    await _repo.updateStatus(row.id, 'downloading');
    _patch(row.id, status: 'downloading');
    try {
      final dir = Directory(
        '${(await getApplicationDocumentsDirectory()).path}/downloads',
      )..createSync(recursive: true);
      final isHls = row.streamUrl.contains('.m3u8');
      String ext;
      if (isHls) {
        ext = 'ts';
      } else {
        final p = Uri.parse(row.streamUrl).path;
        final dot = p.lastIndexOf('.');
        ext = dot >= 0 && dot < p.length - 1 ? p.substring(dot + 1) : 'mp4';
      }
      final file = File('${dir.path}/${row.id}.$ext');
      final headers =
          (jsonDecode(row.headersJson.isEmpty ? '{}' : row.headersJson) as Map)
              .cast<String, String>();
      debugPrint(
        "[download] #${row.id} start (${isHls ? 'hls' : 'file'})-> ${file.path}",
      );
      if (isHls) {
        await _downloadHls(row, file, headers, token);
      } else {
        await _downloadFile(row, file, headers, token);
      }
      if (!token.isCancelled) {
        await _repo.markDone(row.id, file.path);
        _patch(row.id, status: 'done', localPath: file.path);
        debugPrint('[download] #${row.id} done: ${file.lengthSync()} bytes');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        debugPrint('[download] #${row.id} paused');
        await _repo.updateStatus(row.id, 'paused');
        _patch(row.id, status: 'paused');
      } else {
        await _fail(row.id, 'network: ${e.message}');
      }
    } on Object catch (e) {
      await _fail(row.id, '$e');
    } finally {
      _tokens.remove(row.id);
      _activeCount--;
    }
  }

  Future<void> _downloadFile(
    Download row,
    File file,
    Map<String, String> headers,
    CancelToken token,
  ) async {
    // Range 断点续传：按已有文件长度请求续段；服务器不支持（200≠206）
    // 则删文件整下重试一次。
    var start = file.existsSync() ? file.lengthSync() : 0;
    for (var attempt = 0; attempt < 2; attempt++) {
      final reqHeaders = Map<String, String>.of(headers);
      if (start > 0) reqHeaders['range'] = 'bytes=$start-';
      final response = await _dio.download(
        row.streamUrl,
        file.path,
        fileAccessMode: start > 0
            ? FileAccessMode.append
            : FileAccessMode.write,
        options: Options(
          headers: reqHeaders,
          receiveTimeout: const Duration(minutes: 2),
        ),
        cancelToken: token,
        onReceiveProgress: (received, total) => unawaited(
          _throttledProgress(
            row.id,
            receivedBytes: start + received,
            totalBytes: total > 0 ? start + total : null,
          ),
        ),
      );
      if (start > 0 && response.statusCode != 206) {
        file.deleteSync();
        start = 0;
        continue;
      }
      break;
    }
    await _repo.updateProgress(id: row.id, receivedBytes: file.lengthSync());
    _patch(row.id, receivedBytes: file.lengthSync());
  }

  /// HLS：拉播放列表（master 取首个变体）→ 顺序下载分段（AES-128 解密）拼接。
  ///
  /// 清单按行有序解析：#EXT-X-KEY 推进当前密钥状态（METHOD=NONE 解除），
  /// 分段仅在其声明的密钥区间内解密；IV 缺省用分段序号（HLS 规范）。
  Future<void> _downloadHls(
    Download row,
    File file,
    Map<String, String> headers,
    CancelToken token,
  ) async {
    var playlistUrl = row.streamUrl;
    var playlist = (await _dio.get<String>(
      playlistUrl,
      options: Options(
        headers: headers,
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 30),
      ),
      cancelToken: token,
    )).data!;
    if (!playlist.contains('#EXTM3U')) {
      throw StateError('playlist fetch returned non-m3u8 content');
    }
    if (playlist.contains('#EXT-X-STREAM-INF')) {
      final variant = RegExp(
        r'^(?!#).+$',
        multiLine: true,
      ).firstMatch(playlist)?.group(0);
      if (variant == null) throw StateError('empty master playlist');
      playlistUrl = Uri.parse(playlistUrl).resolve(variant).toString();
      playlist = (await _dio.get<String>(
        playlistUrl,
        options: Options(
          headers: headers,
          responseType: ResponseType.plain,
          receiveTimeout: const Duration(seconds: 30),
        ),
        cancelToken: token,
      )).data!;
    }
    final base = Uri.parse(playlistUrl);
    final segments = <_HlsSegment>[];
    String? curKeyUri;
    Uint8List? curIv;
    for (final raw in playlist.split('\n')) {
      final line = raw.trim();
      if (line.startsWith('#EXT-X-KEY')) {
        final method = RegExp(r'METHOD=([^,]+)').firstMatch(line)?.group(1);
        final uri = RegExp(r'URI="([^"]*)"').firstMatch(line)?.group(1);
        final ivHex = RegExp(r'IV=0x([0-9a-fA-F]+)').firstMatch(line)?.group(1);
        if (method == 'NONE' || uri == null) {
          curKeyUri = null;
          curIv = null;
        } else if (method == 'AES-128') {
          curKeyUri = base.resolve(uri).toString();
          curIv = ivHex != null ? _hexToBytes(ivHex) : null;
        } else {
          throw StateError('unsupported key method: $method');
        }
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        segments.add(
          _HlsSegment(
            url: base.resolve(line).toString(),
            keyUri: curKeyUri,
            iv: curIv,
          ),
        );
      }
    }
    if (segments.isEmpty) throw StateError('empty media playlist');
    debugPrint('[download] #${row.id} hls: ${segments.length} segments');
    // 断点续传：文件在则跳过已下分段追加，文件丢则整下。
    var skip = row.doneSegments;
    if (!file.existsSync()) skip = 0;
    await _repo.updateProgress(
      id: row.id,
      totalSegments: segments.length,
      totalBytes: 0,
    );
    _patch(row.id, totalSegments: segments.length);

    final keyCache = <String, Uint8List>{};
    Future<Uint8List> keyOf(String uri) async {
      final cached = keyCache[uri];
      if (cached != null) return cached;
      final key = (await _dio.get<List<int>>(
        uri,
        options: Options(
          headers: headers,
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 30),
        ),
        cancelToken: token,
      )).data!;
      if (key.length != 16) {
        throw StateError('bad AES key length ${key.length}');
      }
      final fixed = Uint8List.fromList(key);
      keyCache[uri] = fixed;
      return fixed;
    }

    // fMP4：EXT-X-MAP init 段必须前置。
    final mapInit = RegExp(
      r'#EXT-X-MAP:URI="([^"]+)"',
    ).firstMatch(playlist)?.group(1);

    final sink = file.openWrite(mode: FileMode.writeOnlyAppend);
    var received = skip > 0 ? file.lengthSync() : 0;
    try {
      if (mapInit != null && skip == 0) {
        final initBytes = (await _dio.get<List<int>>(
          base.resolve(mapInit).toString(),
          options: Options(
            headers: headers,
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 2),
          ),
          cancelToken: token,
        )).data!;
        sink.add(initBytes);
        received += initBytes.length;
      }
      for (var i = skip; i < segments.length; i++) {
        var bytes = (await _dio.get<List<int>>(
          segments[i].url,
          options: Options(
            headers: headers,
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(minutes: 2),
          ),
          cancelToken: token,
        )).data!;
        if (bytes.isEmpty) throw StateError('empty segment #${i + 1}');
        if (segments[i].keyUri != null) {
          final key = await keyOf(segments[i].keyUri!);
          // IV 缺省 = 分段序号 16 字节大端（HLS 规范）。
          final iv = segments[i].iv ?? _seqIv(i);
          bytes = _decryptAes128(bytes, key, iv);
        } else {
          final head = bytes[0];
          final boxType = bytes.length > 8
              ? String.fromCharCodes(bytes.sublist(4, 8))
              : '';
          final looksTs = head == 0x47;
          final looksMp4 =
              boxType == 'ftyp' ||
              boxType == 'styp' ||
              boxType == 'moof' ||
              boxType == 'mdat';
          if (!looksTs && !looksMp4 && i == 0) {
            final hex = bytes
                .take(32)
                .map((b) => b.toRadixString(16).padLeft(2, '0'))
                .join(' ');
            throw StateError(
              'segment #1 not ts/mp4 (head 0x${head.toRadixString(16)}): '
              'hex[$hex] url[${segments[i].url}]',
            );
          }
        }
        sink.add(bytes);
        received += bytes.length;
        await _throttledProgress(
          row.id,
          doneSegments: i + 1,
          receivedBytes: received,
        );
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
    await _repo.updateProgress(
      id: row.id,
      doneSegments: segments.length,
      receivedBytes: received,
    );
    _patch(row.id, doneSegments: segments.length, receivedBytes: received);
  }

  /// AES-128-CBC 解密（PKCS7 去填充）。
  List<int> _decryptAes128(List<int> data, Uint8List key, Uint8List iv) {
    final encrypter = Encrypter(
      AES(Key(Uint8List.fromList(key)), mode: AESMode.cbc),
    );
    return encrypter.decryptBytes(
      Encrypted(Uint8List.fromList(data)),
      iv: IV(iv),
    );
  }

  Uint8List _seqIv(int sequence) {
    final iv = Uint8List(16);
    final hex = sequence.toRadixString(16).padLeft(32, '0');
    for (var i = 0; i < 16; i++) {
      iv[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return iv;
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return bytes;
  }

  Future<Download?> _byId(int id) async {
    final all = await _repo.list();
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  void pause(int id) {
    _tokens[id]?.cancel();
  }

  Future<void> resume(int id) async {
    final row = await _byId(id);
    if (row == null || row.status == 'done') return;
    // 断点续传：保留进度，_download* 按文件长度/已下分段续下。
    await _repo.updateStatus(id, 'queued', errorMsg: '');
    _patch(id, status: 'queued', errorMsg: '');
    unawaited(_start(row));
  }

  Future<void> retry(int id) => resume(id);

  Future<void> remove(int id) async {
    _tokens[id]?.cancel();
    final row = state.where((d) => d.id == id).firstOrNull;
    if (row != null && row.localPath.isNotEmpty) {
      try {
        File(row.localPath).deleteSync();
      } on Object {
        // 文件已不存在可忽略。
      }
    }
    await _repo.remove(id);
    state = state.where((d) => d.id != id).toList();
    DownloadGateway.version.value++;
  }

  Future<void> pauseAll() async {
    for (final token in _tokens.values) {
      token.cancel();
    }
    for (final d in state.where((d) => _activeStates.contains(d.status))) {
      await _repo.updateStatus(d.id, 'paused');
      _patch(d.id, status: 'paused');
    }
  }

  Future<void> startAll() async {
    for (final d in state.where(
      (d) => d.status == 'paused' || d.status == 'failed',
    )) {
      await resume(d.id);
    }
  }

  Future<void> refresh() async {
    state = await _repo.list();
  }
}

final downloadManagerProvider =
    NotifierProvider<DownloadManager, List<Download>>(DownloadManager.new);

/// HLS 分段的解析态：URL + 生效密钥（null=明文段）。
class _HlsSegment {
  const _HlsSegment({required this.url, this.keyUri, this.iv});

  final String url;
  final String? keyUri;
  final Uint8List? iv;
}
