import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/proxy_service.dart';
import '../theme/tokens.dart';

/// 轻量设置持久化（shared_preferences）。
///
/// 读取采用「先默认值 + 微任务补读」模式（插件管理器同款），
/// 测试环境无插件实现时保持默认值不报错。
abstract final class AppSettings {
  static const _preloadNextKey = 'preload_next';
  static const _paletteKey = 'palette';
  static const _themeModeKey = 'theme_mode';
  static const _fontScaleKey = 'font_scale_index';
  static const _radiusStyleKey = 'radius_style';
  static const _onboardingDoneKey = 'onboarding_done';
  static const _proxyEnabledKey = 'proxy_enabled';
  static const _proxyModeKey = 'proxy_mode';
  static const _proxyHostKey = 'proxy_host';
  static const _proxyPortKey = 'proxy_port';

  /// 预加载下一集（L1 预解析 + L2 播放列表预缓冲），默认开。
  static bool preloadNext = true;

  /// 网络代理：开关与类型分离（帧 27:212 有独立启用开关）。
  /// mode: http / socks4 / socks5。
  static bool proxyEnabled = false;
  static String proxyMode = 'http';
  static String proxyHost = '';
  static int proxyPort = 0;

  /// 外观：主题色板名 / 显示模式 / 字号档位（0 小 ~ 3 特大，1=标准）/ 圆角风格。
  static String paletteName = AppTokens.defaultPalette.name;
  static ThemeMode themeMode = ThemeMode.light;
  static int fontScaleIndex = 1;
  static String radiusStyle = 'standard';

  /// 首启标记：false = 首次启动，需走引导页。
  static bool onboardingDone = false;

  /// 字号档位 → 全局缩放系数（builder 里包 MediaQuery textScaler）。
  static const fontScaleValues = [0.9, 1.0, 1.1, 1.2];

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      preloadNext = prefs.getBool(_preloadNextKey) ?? true;
      paletteName = prefs.getString(_paletteKey) ?? paletteName;
      themeMode = switch (prefs.getString(_themeModeKey)) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      };
      fontScaleIndex = prefs.getInt(_fontScaleKey) ?? fontScaleIndex;
      radiusStyle = prefs.getString(_radiusStyleKey) ?? radiusStyle;
      onboardingDone = prefs.getBool(_onboardingDoneKey) ?? false;
      proxyEnabled = prefs.getBool(_proxyEnabledKey) ?? proxyEnabled;
      proxyMode = prefs.getString(_proxyModeKey) ?? proxyMode;
      proxyHost = prefs.getString(_proxyHostKey) ?? proxyHost;
      proxyPort = prefs.getInt(_proxyPortKey) ?? proxyPort;
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

  static Future<void> _saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } on Object {
      // 持久化失败不阻塞。
    }
  }

  static Future<void> setPaletteName(String value) async {
    paletteName = value;
    await _saveString(_paletteKey, value);
  }

  static Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _saveString(_themeModeKey, value.name);
  }

  static Future<void> setFontScaleIndex(int value) async {
    fontScaleIndex = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_fontScaleKey, value);
    } on Object {
      // 持久化失败不阻塞。
    }
  }

  static Future<void> setRadiusStyle(String value) async {
    radiusStyle = value;
    await _saveString(_radiusStyleKey, value);
  }

  static Future<void> setOnboardingDone() async {
    onboardingDone = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingDoneKey, true);
    } on Object {
      // 持久化失败不阻塞进入。
    }
  }

  /// 保存代理配置（enabled=false 时保留 mode/host/port 填写值）。
  static Future<void> setProxy({
    required bool enabled,
    required String mode,
    required String host,
    required int port,
  }) async {
    proxyEnabled = enabled;
    proxyMode = mode;
    proxyHost = host;
    proxyPort = port;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_proxyEnabledKey, enabled);
      await prefs.setString(_proxyModeKey, mode);
      await prefs.setString(_proxyHostKey, host);
      await prefs.setInt(_proxyPortKey, port);
    } on Object {
      // 持久化失败不阻塞。
    }
  }
}

/// 按名称取色板（外观设置持久化存名称，回退默认）。
AppPalette paletteByName(String name) {
  for (final p in [AppTokens.sakura, AppTokens.coral, AppTokens.mint]) {
    if (p.name == name) return p;
  }
  return AppTokens.defaultPalette;
}

/// 播放器「预加载下一集」开关（state 镜像，UI 用）。
final preloadNextProvider = NotifierProvider<PreloadNext, bool>(
  PreloadNext.new,
);

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

/// 网络代理配置（值对象：enabled/mode/host/port）。
class ProxyConfig {
  const ProxyConfig({
    this.enabled = false,
    this.mode = 'http',
    this.host = '',
    this.port = 0,
  });

  /// 启用开关（帧 27:212 独立开关，关闭时保留填写值）。
  final bool enabled;

  /// http / socks5（SOCKS4 底层网络栈不支持，设计稿已移除）。
  final String mode;
  final String host;
  final int port;

  bool get valid => host.isNotEmpty && port > 0;

  /// 实际生效 = 开关开 + 地址完整。
  bool get active => enabled && valid;

  /// dio/mpv 通用的代理 URL（http://host:port 或 socks5://host:port）。
  /// 未生效返回 null。
  String? get url => active ? '$mode://$host:$port' : null;
}

/// 网络代理设置（state 镜像，UI 用；生效接线在 ProxyService / 播放器）。
final proxyProvider = NotifierProvider<ProxySetting, ProxyConfig>(
  ProxySetting.new,
);

class ProxySetting extends Notifier<ProxyConfig> {
  @override
  ProxyConfig build() {
    Future<void>.microtask(() async {
      await AppSettings.load();
      state = _current();
    });
    return _current();
  }

  ProxyConfig _current() => ProxyConfig(
    enabled: AppSettings.proxyEnabled,
    mode: AppSettings.proxyMode,
    host: AppSettings.proxyHost,
    port: AppSettings.proxyPort,
  );

  Future<void> save({
    required bool enabled,
    required String mode,
    required String host,
    required int port,
  }) async {
    state = ProxyConfig(enabled: enabled, mode: mode, host: host, port: port);
    ProxyService.update(enabled ? mode : 'direct', host, port);
    await AppSettings.setProxy(
      enabled: enabled,
      mode: mode,
      host: host,
      port: port,
    );
  }
}

/// 外观-主题色板。
final paletteProvider = NotifierProvider<PaletteSetting, AppPalette>(
  PaletteSetting.new,
);

class PaletteSetting extends Notifier<AppPalette> {
  @override
  AppPalette build() {
    Future<void>.microtask(() async {
      await AppSettings.load();
      state = paletteByName(AppSettings.paletteName);
    });
    return paletteByName(AppSettings.paletteName);
  }

  Future<void> select(AppPalette palette) async {
    state = palette;
    await AppSettings.setPaletteName(palette.name);
  }
}

/// 外观-显示模式（亮色/暗色/跟随系统）。
final themeModeProvider = NotifierProvider<ThemeModeSetting, ThemeMode>(
  ThemeModeSetting.new,
);

class ThemeModeSetting extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    Future<void>.microtask(() async {
      await AppSettings.load();
      state = AppSettings.themeMode;
    });
    return AppSettings.themeMode;
  }

  Future<void> select(ThemeMode mode) async {
    state = mode;
    await AppSettings.setThemeMode(mode);
  }
}

/// 外观-字号档位（0 小 ~ 3 特大）。
final fontScaleProvider = NotifierProvider<FontScaleSetting, int>(
  FontScaleSetting.new,
);

class FontScaleSetting extends Notifier<int> {
  @override
  int build() {
    Future<void>.microtask(() async {
      await AppSettings.load();
      state = AppSettings.fontScaleIndex;
    });
    return AppSettings.fontScaleIndex;
  }

  Future<void> select(int index) async {
    state = index;
    await AppSettings.setFontScaleIndex(index);
  }
}

/// 外观-圆角风格（standard/round/sharp；当前仅持久化，
/// 全局圆角由 const token 承载，后续接入时读取）。
final radiusStyleProvider = NotifierProvider<RadiusStyleSetting, String>(
  RadiusStyleSetting.new,
);

class RadiusStyleSetting extends Notifier<String> {
  @override
  String build() {
    Future<void>.microtask(() async {
      await AppSettings.load();
      state = AppSettings.radiusStyle;
    });
    return AppSettings.radiusStyle;
  }

  Future<void> select(String style) async {
    state = style;
    await AppSettings.setRadiusStyle(style);
  }
}
