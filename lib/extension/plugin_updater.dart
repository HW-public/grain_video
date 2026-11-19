import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';

import 'plugin_manager.dart';

/// 在线插件更新：拉清单 → 校验 sha256 + Ed25519 签名 → 安全替换安装。
///
/// 清单来源为 grain_plugins 仓库的 Release 资产（见该仓库 README）；
/// 签名消息固定为 UTF-8 字符串 `{package}|{version}|{sha256}`，
/// 公钥 [defaultPublicKeyHex] 内置宿主，不随清单下发。
class PluginUpdater {
  PluginUpdater({
    this.manifestUrl = defaultManifestUrl,
    this.publicKeyHex = defaultPublicKeyHex,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  /// `releases/latest/download/` 始终指向最新 release 的清单。
  static const String defaultManifestUrl =
      'https://github.com/HW-public/grain_plugins/releases/latest/download/manifest.json';

  /// grain_plugins 签名公钥（Ed25519, 32 字节 hex）。
  static const String defaultPublicKeyHex =
      '0280177a17a8e5bab6b77f36108f21054e9b5be46c064da961ccdd0eb636d867';

  final String manifestUrl;
  final String publicKeyHex;
  final Dio _dio;

  /// 拉取并解析清单（网络/格式错误抛 [PluginUpdateException]）。
  Future<List<PluginRelease>> fetchManifest({Duration? timeout}) async {
    try {
      final resp = await _dio.get<dynamic>(
        manifestUrl,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          receiveTimeout: timeout ?? const Duration(seconds: 20),
        ),
      );
      final data = resp.data;
      final json = data is String ? jsonDecode(data) : data;
      if (json is! Map || json['plugins'] is! List) {
        throw const PluginUpdateException('清单格式无效');
      }
      final releases = <PluginRelease>[];
      for (final e in json['plugins'] as List) {
        final r = PluginRelease.fromJson(e);
        if (r != null) releases.add(r);
      }
      return releases;
    } on PluginUpdateException {
      rethrow;
    } catch (e) {
      throw PluginUpdateException('拉取插件清单失败: $e');
    }
  }

  /// 校验下载字节：sha256 匹配清单，且签名对
  /// `{package}|{version}|{sha256}` 验签通过。
  Future<bool> verifyBytes(PluginRelease release, List<int> bytes) async {
    final sha = crypto.sha256.convert(bytes).toString();
    if (sha != release.sha256.toLowerCase()) return false;
    return verifySignature(release, sha);
  }

  /// 只验签（sha256 已独立核对的场景，如测试）。
  Future<bool> verifySignature(PluginRelease release, String sha256Hex) async {
    try {
      final message = utf8.encode(
        '${release.package}|${release.version}|${sha256Hex.toLowerCase()}',
      );
      final signatureBytes = _hexToBytes(release.signature);
      final publicKey = SimplePublicKey(
        _hexToBytes(publicKeyHex),
        type: KeyPairType.ed25519,
      );
      return await Ed25519().verify(
        message,
        signature: Signature(signatureBytes, publicKey: publicKey),
      );
    } catch (_) {
      return false;
    }
  }

  /// 下载 → 校验 → 安装/更新（失败不改变已安装版本）。
  Future<PluginEntry> installOrUpdate(
    PluginManager manager,
    PluginRelease release, {
    Directory? dir,
    Duration? timeout,
  }) async {
    final List<int> bytes;
    try {
      final resp = await _dio.get<List<int>>(
        release.url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          receiveTimeout: timeout ?? const Duration(seconds: 60),
        ),
      );
      bytes = resp.data ?? const [];
    } catch (e) {
      throw PluginUpdateException('下载 ${release.file} 失败: $e');
    }
    if (bytes.isEmpty) {
      throw PluginUpdateException('下载 ${release.file} 失败: 空响应');
    }
    if (!await verifyBytes(release, bytes)) {
      throw PluginUpdateException(
        '${release.package} 校验失败（sha256 或签名不匹配），已拒绝安装',
      );
    }
    try {
      return await manager.installBytes(
        bytes,
        fileName: release.file,
        dir: dir,
      );
    } catch (e) {
      throw PluginUpdateException('${release.package} 装载失败: $e');
    }
  }

  /// 按内容源站点分组（同一站点的多语言实现归为一组）。
  ///
  /// 清单条目带 `site`（内容源）与 `impl`（语言实现）；旧清单无 `site`
  /// 时回退按 package 分组。UI 据此一个站点一行、展开选实现。
  static Map<String, List<PluginRelease>> groupBySite(
    List<PluginRelease> releases,
  ) {
    final groups = <String, List<PluginRelease>>{};
    for (final r in releases) {
      final key = r.site.isEmpty ? r.package : r.site;
      groups.putIfAbsent(key, () => []).add(r);
    }
    return groups;
  }

  /// 从清单里筛出比已安装版本新的条目（按 package 匹配）。
  static List<PluginRelease> pendingUpdates(
    List<PluginRelease> releases,
    List<PluginEntry> installed,
  ) {
    return pendingFromVersions(releases, {
      for (final e in installed)
        if (e.info.package.isNotEmpty) e.info.package: e.info.version,
    });
  }

  /// [pendingUpdates] 的版本表版本（未安装的 package 也算待安装）。
  static List<PluginRelease> pendingFromVersions(
    List<PluginRelease> releases,
    Map<String, String> installedVersions,
  ) {
    return releases.where((r) {
      final local = installedVersions[r.package];
      return local == null || compareVersions(r.version, local) > 0;
    }).toList();
  }

  /// 版本比较（宽松语义版本）：`v1.2.3` 与 `1.2.3` 等价；
  /// 数字段逐段比较，缺段视为 0；非数字后缀（-beta 等）只参与
  /// 兜底字符串比较。无法解析时按字符串比较。
  static int compareVersions(String a, String b) {
    final pa = _segments(a);
    final pb = _segments(b);
    if (pa == null || pb == null) return a.compareTo(b);
    final n = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < n; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x.compareTo(y);
    }
    // 预发布后缀：`1.0.0-beta` < `1.0.0`
    final sa = _suffix(a);
    final sb = _suffix(b);
    if (sa.isEmpty && sb.isEmpty) return 0;
    if (sa.isEmpty) return 1;
    if (sb.isEmpty) return -1;
    return sa.compareTo(sb);
  }

  static List<int>? _segments(String version) {
    final core = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final main = core.split(RegExp(r'[-+]')).first;
    final parts = main.split('.');
    final out = <int>[];
    for (final p in parts) {
      final n = int.tryParse(p);
      if (n == null) return null;
      out.add(n);
    }
    return out;
  }

  static String _suffix(String version) {
    final core = version.trim().replaceFirst(RegExp(r'^[vV]'), '');
    final i = core.indexOf(RegExp(r'[-+]'));
    return i < 0 ? '' : core.substring(i + 1);
  }

  static Uint8List _hexToBytes(String hex) {
    final h = hex.trim();
    if (h.length.isOdd) throw const FormatException('odd hex length');
    final out = Uint8List(h.length ~/ 2);
    for (var i = 0; i < out.length; i++) {
      out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return out;
  }
}

/// 清单中的一条插件发布记录。
class PluginRelease {
  const PluginRelease({
    required this.package,
    required this.name,
    required this.version,
    required this.file,
    required this.url,
    required this.sha256,
    required this.signature,
    this.site = '',
    this.impl = '',
  });

  static PluginRelease? fromJson(Object? json) {
    if (json is! Map) return null;
    String s(String k) => json[k] is String ? json[k] as String : '';
    final pkg = s('package');
    final file = s('file');
    final url = s('url');
    final version = s('version');
    final sha = s('sha256');
    final sig = s('signature');
    if (pkg.isEmpty ||
        file.isEmpty ||
        url.isEmpty ||
        version.isEmpty ||
        sha.isEmpty ||
        sig.isEmpty) {
      return null;
    }
    return PluginRelease(
      package: pkg,
      name: s('name'),
      version: version,
      file: file,
      url: url,
      sha256: sha.toLowerCase(),
      signature: sig.toLowerCase(),
      site: s('site'),
      impl: s('impl'),
    );
  }

  final String package;
  final String name;
  final String version;
  final String file;
  final String url;
  final String sha256;
  final String signature;

  /// 内容源站点（如 `360zy.com`）；同站点可有多语言实现。
  final String site;

  /// 实现语言标识（如 `rust` / `ts`）。
  final String impl;

  @override
  String toString() => 'PluginRelease($package $version)';
}

/// 更新流程异常（网络/格式/校验/装载）。
class PluginUpdateException implements Exception {
  const PluginUpdateException(this.message);

  final String message;

  @override
  String toString() => 'PluginUpdateException: $message';
}
