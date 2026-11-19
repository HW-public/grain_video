import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/extension/plugin_updater.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

void main() {
  test('version comparison', () {
    expect(PluginUpdater.compareVersions('v1.2.3', '1.2.3'), 0);
    expect(PluginUpdater.compareVersions('1.2.10', '1.2.9'), greaterThan(0));
    expect(PluginUpdater.compareVersions('v0.0.2', '0.0.10'), lessThan(0));
    expect(PluginUpdater.compareVersions('1.0.0-beta', '1.0.0'), lessThan(0));
    expect(PluginUpdater.compareVersions('1.0', '1.0.0'), 0);
  });

  test('pendingFromVersions filters installed up-to-date packages', () {
    const releases = [
      PluginRelease(
        package: 'a',
        name: 'A',
        version: 'v2.0.0',
        file: 'a.wasm',
        url: 'u',
        sha256: 's',
        signature: 'g',
      ),
      PluginRelease(
        package: 'b',
        name: 'B',
        version: 'v1.0.0',
        file: 'b.wasm',
        url: 'u',
        sha256: 's',
        signature: 'g',
      ),
      PluginRelease(
        package: 'c',
        name: 'C',
        version: 'v1.0.0',
        file: 'c.wasm',
        url: 'u',
        sha256: 's',
        signature: 'g',
      ),
    ];
    final pending = PluginUpdater.pendingFromVersions(releases, {
      'a': 'v1.0.0', // 有新版本
      'b': 'v1.0.0', // 已最新
      // c 未安装 → 待安装
    });
    expect(pending.map((r) => r.package), ['a', 'c']);
  });

  test(
    'Ed25519 signature verification accepts valid, rejects tampered',
    () async {
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final updater = PluginUpdater(publicKeyHex: _hex(publicKey.bytes));

      final bytes = utf8.encode('fake-wasm-content');
      final sha = crypto.sha256.convert(bytes).toString();
      final message = utf8.encode('pkg.example|v1.0.0|$sha');
      final signature = await algorithm.sign(message, keyPair: keyPair);

      final release = PluginRelease(
        package: 'pkg.example',
        name: 'P',
        version: 'v1.0.0',
        file: 'p.wasm',
        url: 'https://example.com/p.wasm',
        sha256: sha,
        signature: _hex(signature.bytes),
      );

      expect(await updater.verifyBytes(release, bytes), isTrue);

      // 篡改内容 → sha256 不匹配
      expect(
        await updater.verifyBytes(release, utf8.encode('fake-wasm-content!')),
        isFalse,
      );

      // 签名错误 → 拒绝
      final bad = PluginRelease(
        package: release.package,
        name: release.name,
        version: release.version,
        file: release.file,
        url: release.url,
        sha256: sha,
        signature: '00' * 64,
      );
      expect(await updater.verifyBytes(bad, bytes), isFalse);

      // 换公钥（模拟未授权发布者）→ 拒绝
      final otherKey = await algorithm.newKeyPair();
      final otherPub = await otherKey.extractPublicKey();
      final otherUpdater = PluginUpdater(publicKeyHex: _hex(otherPub.bytes));
      expect(await otherUpdater.verifyBytes(release, bytes), isFalse);
    },
  );

  test('groupBySite groups language variants of the same site', () {
    const releases = [
      PluginRelease(
        package: '360zy.com',
        name: '360资源',
        version: 'v0.0.2',
        file: 'a.wasm',
        url: 'u',
        sha256: 's',
        signature: 'g',
        site: '360zy.com',
        impl: 'rust',
      ),
      PluginRelease(
        package: '360zy.com.ts',
        name: '360资源 (TS)',
        version: 'v0.0.2',
        file: 'b.wasm',
        url: 'u',
        sha256: 's',
        signature: 'g',
        site: '360zy.com',
        impl: 'ts',
      ),
      PluginRelease(
        package: 'bilibili.com.wbi',
        name: 'B',
        version: 'v0.1.0',
        file: 'c.wasm',
        url: 'u',
        sha256: 's',
        signature: 'g',
        site: 'bilibili.com',
        impl: 'rust',
      ),
    ];
    final groups = PluginUpdater.groupBySite(releases);
    expect(groups.keys.toSet(), {'360zy.com', 'bilibili.com'});
    expect(groups['360zy.com'], hasLength(2));
    expect(
      groups['360zy.com']!.map((r) => r.impl),
      containsAll(['rust', 'ts']),
    );
  });

  test('manifest parsing rejects incomplete entries', () {
    expect(PluginRelease.fromJson({'package': 'p'}), isNull);
    final ok = PluginRelease.fromJson({
      'package': 'p',
      'name': 'n',
      'version': 'v1.0.0',
      'file': 'p.wasm',
      'url': 'https://x/p.wasm',
      'sha256': 'AB' * 32,
      'signature': 'CD' * 64,
    });
    expect(ok, isNotNull);
    expect(ok!.sha256, 'ab' * 32); // 归一为小写
  });
}
