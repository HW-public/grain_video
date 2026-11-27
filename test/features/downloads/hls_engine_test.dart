import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/features/downloads/providers/hls_engine.dart';

void main() {
  final base = Uri.parse('https://cdn.example.com/vod/abc/hls/index.m3u8');

  group('masterVariantOf', () {
    test('非 master 清单返回 null', () {
      const media = '#EXTM3U\n#EXTINF:2.0,\nseg1.ts\n';
      expect(masterVariantOf(media), isNull);
    });

    test('master 取首个变体 URI', () {
      const master =
          '#EXTM3U\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=800000\n'
          'low/index.m3u8\n'
          '#EXT-X-STREAM-INF:BANDWIDTH=2000000\n'
          'high/index.m3u8\n';
      expect(masterVariantOf(master), 'low/index.m3u8');
    });

    test('master 无变体抛错', () {
      const broken = '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=1\n';
      expect(() => masterVariantOf(broken), throwsStateError);
    });
  });

  group('parseMediaPlaylist', () {
    test('明文分段：keyUri 全 null，相对地址按 base resolve', () {
      const media =
          '#EXTM3U\n'
          '#EXTINF:2.24,\n'
          'a.ts\n'
          '#EXTINF:2.0,\n'
          '/vod/abs/b.ts\n';
      final plan = parseMediaPlaylist(media, base);
      expect(plan.segments, hasLength(2));
      expect(plan.segments[0].url, 'https://cdn.example.com/vod/abc/hls/a.ts');
      expect(plan.segments[1].url, 'https://cdn.example.com/vod/abs/b.ts');
      expect(plan.segments.every((s) => s.keyUri == null), isTrue);
      expect(plan.mapInitUri, isNull);
    });

    test('AES-128 显式 IV：密钥区间内的分段带 keyUri+iv', () {
      const media =
          '#EXTM3U\n'
          '#EXT-X-KEY:METHOD=AES-128,URI="key.key",IV=0x0000000000000000000000000000002a\n'
          '#EXTINF:2.0,\ns1.ts\n#EXTINF:2.0,\ns2.ts\n';
      final plan = parseMediaPlaylist(media, base);
      expect(plan.segments, hasLength(2));
      for (final s in plan.segments) {
        expect(s.keyUri, 'https://cdn.example.com/vod/abc/hls/key.key');
        expect(s.iv, isNotNull);
        expect(s.iv![15], 0x2a);
        expect(s.iv!.sublist(0, 15), everyElement(0));
      }
    });

    test('密钥轮换：AES → NONE → AES（猫武士真实形态）', () {
      const media =
          '#EXTM3U\n'
          '#EXT-X-KEY:METHOD=AES-128,URI="/k/key1.key",IV=0x00000000000000000000000000000000\n'
          '#EXTINF:2.0,\ns1.ts\n'
          '#EXTINF:2.0,\ns2.ts\n'
          '#EXT-X-KEY:METHOD=NONE\n'
          '#EXTINF:2.0,\ns3.ts\n'
          '#EXT-X-KEY:METHOD=AES-128,URI="/k/key2.key"\n'
          '#EXTINF:2.0,\ns4.ts\n';
      final plan = parseMediaPlaylist(media, base);
      expect(plan.segments, hasLength(4));
      expect(plan.segments[0].keyUri, 'https://cdn.example.com/k/key1.key');
      expect(plan.segments[1].keyUri, 'https://cdn.example.com/k/key1.key');
      // NONE 区间：明文段
      expect(plan.segments[2].keyUri, isNull);
      expect(plan.segments[2].iv, isNull);
      // 第二个 KEY 无显式 IV → iv=null（调用方按序号推导）
      expect(plan.segments[3].keyUri, 'https://cdn.example.com/k/key2.key');
      expect(plan.segments[3].iv, isNull);
    });

    test('不支持的密钥方法抛错（SAMPLE-AES/DRM）', () {
      const media =
          '#EXTM3U\n'
          '#EXT-X-KEY:METHOD=SAMPLE-AES,URI="skd://x"\n'
          '#EXTINF:2.0,\ns1.ts\n';
      expect(() => parseMediaPlaylist(media, base), throwsStateError);
    });

    test('空清单抛错', () {
      expect(
        () => parseMediaPlaylist('#EXTM3U\n#EXTINF:2.0,\n', base),
        throwsStateError,
      );
    });

    test('fMP4：EXT-X-MAP init URI 被提取', () {
      const media =
          '#EXTM3U\n'
          '#EXT-X-MAP:URI="init.mp4"\n'
          '#EXTINF:2.0,\ns1.m4s\n';
      final plan = parseMediaPlaylist(media, base);
      expect(plan.mapInitUri, 'init.mp4');
      expect(plan.segments.single.url.endsWith('s1.m4s'), isTrue);
    });
  });

  group('looksLikeMediaSegment', () {
    test('ts 同步字节 0x47 → true', () {
      expect(looksLikeMediaSegment([0x47, 0x00, 0x11]), isTrue);
    });

    test('mp4 系 box（ftyp/styp/moof/mdat）→ true', () {
      for (final box in ['ftyp', 'styp', 'moof', 'mdat']) {
        final bytes = [0, 0, 0, 24, ...box.codeUnits, 0, 0];
        expect(looksLikeMediaSegment(bytes), isTrue, reason: box);
      }
    });

    test('高熵乱码 / 过短 / 空 → false', () {
      expect(
        looksLikeMediaSegment([0xa9, 0x3f, 0x12, 0x88, 1, 2, 3, 4, 5]),
        isFalse,
      );
      expect(looksLikeMediaSegment([0x00, 0x01]), isFalse);
      expect(looksLikeMediaSegment(const []), isFalse);
    });
  });

  group('seqIv / hexToBytes', () {
    test('序号 0 → 全零；1 → 末字节 1；256 → 倒数第二字节 1', () {
      expect(seqIv(0), everyElement(0));
      final one = seqIv(1);
      expect(one[15], 1);
      expect(one.sublist(0, 15), everyElement(0));
      final v256 = seqIv(256);
      expect(v256[14], 1);
      expect(v256[15], 0);
    });

    test('hexToBytes 与 seqIv 一致', () {
      expect(hexToBytes('00000000000000000000000000000100'), seqIv(256));
    });
  });

  group('decryptAes128', () {
    test('与加密端往返一致（PKCS7 去填充）', () {
      final key = Uint8List.fromList(List.generate(16, (i) => i * 7 + 1));
      final iv = seqIv(3);
      // 模拟服务端：ts 分段（0x47 头）+ PKCS7 填充加密
      final plain = Uint8List.fromList(
        List.generate(188 * 2, (i) => i == 0 ? 0x47 : (i * 31) % 256),
      );
      final cipher = enc.Encrypter(
        enc.AES(enc.Key(key), mode: enc.AESMode.cbc),
      ).encryptBytes(plain, iv: enc.IV(iv)).bytes;
      final decrypted = decryptAes128(cipher, key, iv);
      expect(decrypted, plain);
      expect(decrypted[0], 0x47);
    });

    test('错误 IV 解密结果不同（IV 参与运算）', () {
      final key = Uint8List(16);
      final plain = Uint8List.fromList(List.filled(32, 0x47));
      final cipher = enc.Encrypter(
        enc.AES(enc.Key(key), mode: enc.AESMode.cbc),
      ).encryptBytes(plain, iv: enc.IV(seqIv(0))).bytes;
      final wrong = decryptAes128(cipher, key, seqIv(1));
      expect(wrong, isNot(plain));
    });
  });
}
