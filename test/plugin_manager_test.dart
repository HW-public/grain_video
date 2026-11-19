import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/extension/plugin_manager.dart';

/// 依赖引擎产物目录（先构建 pdk/rust）：
/// `cargo build --target wasm32-unknown-unknown --release`
/// 并在测试环境注入 wasm_run 原生库：
/// `WASM_RUN_DART_DYNAMIC_LIBRARY=<grain_engine>/native/windows-x64/wasm_run_dart.dll`
/// 产物缺失时跳过（CI 不依赖本机引擎构建）。
void main() {
  final engineDir = Directory(
    r'E:\Flutter\FlutterProject\grain_engine\pdk\rust\target\wasm32-unknown-unknown\release',
  );
  final sample = File(
    '${engineDir.path}${Platform.pathSeparator}plugin_360zy.wasm',
  );
  final available = sample.existsSync();

  test(
    'import, list and remove plugin lifecycle',
    () async {
      if (!available) {
        // 标记跳过而非失败：引擎产物属环境依赖。
        return;
      }
      final tmp = await Directory.systemTemp.createTemp('grain_plugins_');
      addTearDown(() => tmp.delete(recursive: true));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final mgr = container.read(pluginManagerProvider.notifier);

      final entry = await mgr.importPlugin(sample, dir: tmp);
      expect(entry.info.name, isNotEmpty);
      expect(entry.info.package, '360zy.com');
      expect(container.read(pluginManagerProvider), hasLength(1));
      expect(
        File(
          '${tmp.path}${Platform.pathSeparator}plugin_360zy.wasm',
        ).existsSync(),
        isTrue,
      );

      await mgr.removePlugin(entry);
      expect(container.read(pluginManagerProvider), isEmpty);
      expect(
        File(
          '${tmp.path}${Platform.pathSeparator}plugin_360zy.wasm',
        ).existsSync(),
        isFalse,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'installBytes rejects corrupt update and keeps old plugin intact',
    () async {
      if (!available) return;
      final tmp = await Directory.systemTemp.createTemp('grain_update_');
      addTearDown(() => tmp.delete(recursive: true));

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final mgr = container.read(pluginManagerProvider.notifier);

      const name = 'plugin_360zy.wasm';
      final original = await sample.readAsBytes();
      await mgr.installBytes(original, fileName: name, dir: tmp);

      final installed = File('${tmp.path}${Platform.pathSeparator}$name');
      expect(await installed.readAsBytes(), original);

      // 损坏的新版本：装载失败必须回滚，旧文件原样保留，state 不变。
      await expectLater(
        mgr.installBytes(
          const [0x00, 0x61, 0x73, 0x6d, 0xff],
          fileName: name,
          dir: tmp,
        ),
        throwsA(anything),
      );
      expect(await installed.readAsBytes(), original);
      expect(container.read(pluginManagerProvider), hasLength(1));
      expect(
        File('${installed.path}.bak').existsSync(),
        isFalse,
        reason: '回滚后不应残留 .bak',
      );
      expect(
        File('${installed.path}.tmp').existsSync(),
        isFalse,
        reason: '回滚后不应残留 .tmp',
      );

      // 合法更新：同文件重装，state 仍为 1 条（替换而非追加）。
      await mgr.installBytes(original, fileName: name, dir: tmp);
      expect(container.read(pluginManagerProvider), hasLength(1));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
