import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/extension/plugin_updater.dart';

/// 端到端：用宿主内置公钥验证本地构建的 grain_plugins 清单与签名产物。
/// 目录不存在时跳过（CI 无兄弟仓库场景）。
void main() {
  final dist = Directory('../grain_plugins/dist');
  final manifestFile = File('${dist.path}/manifest.json');

  test(
    'real signed manifest and wasm verify with embedded public key',
    () async {
      if (!manifestFile.existsSync()) return;

      final json = jsonDecode(await manifestFile.readAsString()) as Map;
      final plugins = (json['plugins'] as List)
          .map(PluginRelease.fromJson)
          .whereType<PluginRelease>()
          .toList();
      expect(plugins, isNotEmpty);

      final updater = PluginUpdater(); // 默认内置公钥
      for (final release in plugins) {
        final wasm = File('${dist.path}/${release.file}');
        expect(wasm.existsSync(), isTrue, reason: release.file);
        final bytes = await wasm.readAsBytes();
        expect(
          await updater.verifyBytes(release, bytes),
          isTrue,
          reason: '${release.package} 签名/sha256 验证失败',
        );

        // 篡改一个字节必须被拒绝
        final tampered = List<int>.from(bytes);
        tampered[tampered.length ~/ 2] ^= 0xFF;
        expect(
          await updater.verifyBytes(release, tampered),
          isFalse,
          reason: '${release.package} 篡改内容未被拒绝',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 1)),
  );
}
