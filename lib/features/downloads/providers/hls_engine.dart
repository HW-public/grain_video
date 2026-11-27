import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

/// HLS 下载引擎的纯函数部分（A1 拆分：与调度/IO 解耦，表驱动单测覆盖）。
///
/// 覆盖：master 变体选择、媒体清单有序解析（#EXT-X-KEY 状态机）、
/// IV 缺省推导、AES-128-CBC 解密、分段格式校验、fMP4 init 提取。
/// 本文件禁止引入 Flutter/IO 依赖——输入文本与字节，输出计划与结果。

/// HLS 分段的解析态：URL + 生效密钥（null=明文段）。
class HlsSegment {
  const HlsSegment({required this.url, this.keyUri, this.iv});

  final String url;
  final String? keyUri;
  final Uint8List? iv;
}

/// 媒体清单解析结果：分段序列 + 可选 fMP4 init 段 URI（原文，未 resolve）。
class HlsMediaPlan {
  const HlsMediaPlan({required this.segments, this.mapInitUri});

  final List<HlsSegment> segments;
  final String? mapInitUri;
}

/// master 清单的首个变体 URI（非 master 返回 null；master 但无变体抛错）。
String? masterVariantOf(String playlist) {
  if (!playlist.contains('#EXT-X-STREAM-INF')) return null;
  final variant = RegExp(r'^(?!#).+$', multiLine: true).firstMatch(playlist);
  final uri = variant?.group(0)?.trim();
  if (uri == null || uri.isEmpty) {
    throw StateError('empty master playlist');
  }
  return uri;
}

/// fMP4 的 EXT-X-MAP init 段 URI（无则 null）。
String? mapInitUriOf(String playlist) {
  return RegExp(r'#EXT-X-MAP:URI="([^"]+)"').firstMatch(playlist)?.group(1);
}

/// 按行有序解析媒体清单：#EXT-X-KEY 推进当前密钥状态（METHOD=NONE 解除），
/// 分段仅在其声明的密钥区间内解密；IV 缺省（分段 iv=null）由调用方按
/// 分段序号用 [seqIv] 推导（HLS 规范）。相对 URI 基于 [base] resolve。
HlsMediaPlan parseMediaPlaylist(String playlist, Uri base) {
  final segments = <HlsSegment>[];
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
        curIv = ivHex != null ? hexToBytes(ivHex) : null;
      } else {
        throw StateError('unsupported key method: $method');
      }
    } else if (line.isNotEmpty && !line.startsWith('#')) {
      segments.add(
        HlsSegment(
          url: base.resolve(line).toString(),
          keyUri: curKeyUri,
          iv: curIv,
        ),
      );
    }
  }
  if (segments.isEmpty) throw StateError('empty media playlist');
  return HlsMediaPlan(segments: segments, mapInitUri: mapInitUriOf(playlist));
}

/// 分段是否像媒体数据：ts（0x47 同步字节）或 mp4 系 box（ftyp/styp/moof/mdat）。
bool looksLikeMediaSegment(List<int> bytes) {
  if (bytes.isEmpty) return false;
  if (bytes[0] == 0x47) return true;
  if (bytes.length <= 8) return false;
  final boxType = String.fromCharCodes(bytes.sublist(4, 8));
  return boxType == 'ftyp' ||
      boxType == 'styp' ||
      boxType == 'moof' ||
      boxType == 'mdat';
}

/// AES-128-CBC 解密（PKCS7 去填充）。
List<int> decryptAes128(List<int> data, Uint8List key, Uint8List iv) {
  final encrypter = Encrypter(
    AES(Key(Uint8List.fromList(key)), mode: AESMode.cbc),
  );
  return encrypter.decryptBytes(
    Encrypted(Uint8List.fromList(data)),
    iv: IV(iv),
  );
}

/// IV 缺省 = 分段序号 16 字节大端（HLS 规范，序号含 MEDIA-SEQUENCE 偏移时
/// 由调用方传入最终序号）。
Uint8List seqIv(int sequence) {
  final iv = Uint8List(16);
  final hex = sequence.toRadixString(16).padLeft(32, '0');
  for (var i = 0; i < 16; i++) {
    iv[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return iv;
}

/// 十六进制串 → 字节（IV 解析用）。
Uint8List hexToBytes(String hex) {
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}
