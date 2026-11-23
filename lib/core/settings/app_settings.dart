import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 轻量设置持久化（shared_preferences）。
///
/// 读取采用「先默认值 + 微任务补读」模式（插件管理器同款），
/// 测试环境无插件实现时保持默认值不报错。
abstract final class AppSettings {
  static const _preloadNextKey = 'preload_next';

  /// 预加载下一集（L1 预解析 + L2 播放列表预缓冲），默认开。
  static bool preloadNext = true;

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      preloadNext = prefs.getBool(_preloadNextKey) ?? true;
    } on Object {
      // 无插件实现（测试环境）：保持默认。
    }
  }

  static Future<void> setPreloadNext(bool value) async {
    preloadNext = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_preloadNextKey, value);
    } on Object {
      // 持久化失败不阻塞开关。
    }
  }
}

/// 播放器「预加载下一集」开关（state 镜像，UI 用）。
final preloadNextProvider = NotifierProvider<PreloadNext, bool>(PreloadNext.new);

class PreloadNext extends Notifier<bool> {
  @override
  bool build() {
    Future<void>.microtask(() async {
      await AppSettings.load();
      state = AppSettings.preloadNext;
    });
    return AppSettings.preloadNext;
  }

  Future<void> set(bool value) async {
    state = value;
    await AppSettings.setPreloadNext(value);
  }
}
