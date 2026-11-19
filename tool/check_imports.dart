// 分层依赖校验：按 docs/architecture.md 的依赖矩阵检查 lib/ 下的 import。
//
// 用法：dart run tool/check_imports.dart   （违规时退出码 1）
//
// 规则：
//   core       → 仅 core（+ Dart/Flutter/pub 包）
//   data       → core, data
//   extension  → core, extension（+ package:grain_engine）
//   features/x → core, data, extension, features/x（禁止跨 feature）
//   main/app   → 任意
import 'dart:io';

const _packageName = 'grain_video';

void main() {
  final lib = Directory('lib');
  if (!lib.existsSync()) {
    stderr.writeln('check_imports: lib/ not found (run from project root)');
    exit(2);
  }

  final violations = <String>[];
  final files = lib
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final rel = _normalize(file.path.substring('lib'.length + 1));
    final from = _layerOf(rel);
    if (from == null) continue; // 未知层不检查（新目录先补文档）

    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final target = _importTarget(lines[i]);
      if (target == null) continue;

      final resolved = _resolve(rel, target);
      if (resolved == null) continue; // 外部包
      final to = _layerOf(resolved);
      if (to == null) continue;

      if (!_allowed(from, to)) {
        violations.add('lib/$rel:${i + 1}: $from 不允许 import $to（$target）');
      }
    }
  }

  if (violations.isEmpty) {
    stdout.writeln('check_imports: OK');
    return;
  }
  for (final v in violations) {
    stderr.writeln(v);
  }
  stderr.writeln('check_imports: ${violations.length} violation(s)');
  exit(1);
}

String _normalize(String path) => path.replaceAll('\\', '/');

String? _importTarget(String line) {
  final t = line.trimLeft();
  if (!t.startsWith('import ')) return null;
  final m = RegExp(r'''^import\s+['"]([^'"]+)['"]''').firstMatch(t);
  return m?.group(1);
}

/// 返回 lib 相对路径（如 features/home/pages/home_page.dart）；外部包返回 null。
String? _resolve(String fromRel, String target) {
  if (target.startsWith('dart:') ||
      target.startsWith('package:flutter') ||
      target.startsWith('package:go_router') ||
      target.startsWith('package:grain_engine') ||
      (target.startsWith('package:') &&
          !target.startsWith('package:$_packageName/'))) {
    return null;
  }
  if (target.startsWith('package:$_packageName/')) {
    return _normalize(target.substring('package:$_packageName/'.length));
  }
  // 相对路径：从当前文件目录解析
  final parts = fromRel.split('/')..removeLast();
  for (final seg in target.split('/')) {
    if (seg == '.' || seg.isEmpty) continue;
    if (seg == '..') {
      if (parts.isNotEmpty) parts.removeLast();
    } else {
      parts.add(seg);
    }
  }
  return parts.join('/');
}

/// 层标识：core / data / extension / `features/<name>` / app / null
String? _layerOf(String rel) {
  final seg = rel.split('/');
  if (seg.length == 1) return 'app'; // main.dart / app.dart
  switch (seg.first) {
    case 'core':
      return 'core';
    case 'data':
      return 'data';
    case 'extension':
      return 'extension';
    case 'features':
      if (seg.length >= 2) return 'features/${seg[1]}';
      return 'features';
    default:
      return null;
  }
}

bool _allowed(String from, String to) {
  if (from == 'app') return true;
  if (from == to) return true;
  if (from == 'core') return false; // core 只能 import core
  if (from == 'data') return to == 'core';
  if (from == 'extension') return to == 'core';
  if (from.startsWith('features/')) {
    if (to == 'core' || to == 'data' || to == 'extension') return true;
    return to == from; // 同 feature；跨 feature 一律禁止
  }
  return false;
}
