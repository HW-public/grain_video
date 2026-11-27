import 'dart:ffi' show Abi;

/// GitHub Release 解析与版本比较。
class AppRelease {
  const AppRelease({
    required this.tagName,
    required this.notes,
    required this.apkUrl,
    required this.force,
  });

  /// 原始 tag（如 v1.0.1）。
  final String tagName;

  /// Release notes（body 去掉 [force] 标记行）。
  final String notes;

  /// APK 资产下载地址。
  final String apkUrl;

  /// 是否强制更新（release body 以 `[force]` 行开头，release 侧按版本控制）。
  final bool force;

  /// 去掉 v 前缀的版本号。
  String get version =>
      tagName.startsWith('v') ? tagName.substring(1) : tagName;

  /// 从 GitHub releases/latest API JSON 解析；无 APK 资产/无 tag 返回 null。
  static AppRelease? fromGitHubJson(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').trim();
    final assets = (json['assets'] as List? ?? const []);
    // 收集全部 APK 资产（split-per-abi 后每个 ABI 一个），按设备 ABI 挑。
    final apkAssets = <String, String>{};
    for (final a in assets) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      final url = a['browser_download_url'] as String?;
      if (name.endsWith('.apk') && url != null) apkAssets[name] = url;
    }
    final apkUrl = pickApkAsset(apkAssets);
    if (tag.isEmpty || apkUrl == null) return null;
    var body = (json['body'] as String? ?? '').trim();
    var force = false;
    if (body.startsWith('[force]')) {
      force = true;
      body = body.substring('[force]'.length).trimLeft();
    }
    return AppRelease(tagName: tag, notes: body, apkUrl: apkUrl, force: force);
  }

  /// 当前设备 ABI 对应的 Android abi 名（dart:ffi，零插件依赖）。
  static String? deviceAbiTag() => switch (Abi.current()) {
    Abi.androidArm64 => 'arm64-v8a',
    Abi.androidArm => 'armeabi-v7a',
    Abi.androidX64 => 'x86_64',
    Abi.androidIA32 => 'x86',
    _ => null,
  };

  /// 从 APK 资产表挑当前设备的包：ABI 精确匹配 → arm64 兜底 → 任意。
  /// [abiTag] 测试注入用，缺省取设备 ABI。
  static String? pickApkAsset(Map<String, String> apks, {String? abiTag}) {
    if (apks.isEmpty) return null;
    final tag = abiTag ?? deviceAbiTag();
    if (tag != null) {
      for (final e in apks.entries) {
        if (e.key.contains('-$tag-')) return e.value;
      }
    }
    for (final e in apks.entries) {
      if (e.key.contains('-arm64-v8a-')) return e.value;
    }
    return apks.values.first;
  }
}

/// 三段语义版本解析（缺段补 0，容忍 v 前缀与 -suffix）。
List<int> parseVersion(String raw) {
  var s = raw.trim();
  if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
  s = s.split('-').first.split('+').first;
  final parts = s.split('.');
  return [
    for (var i = 0; i < 3; i++)
      i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0,
  ];
}

/// latest 是否比 current 新（按语义版本逐段比较）。
bool isNewerVersion({required String current, required String latest}) {
  final c = parseVersion(current);
  final l = parseVersion(latest);
  for (var i = 0; i < 3; i++) {
    if (l[i] != c[i]) return l[i] > c[i];
  }
  return false;
}
