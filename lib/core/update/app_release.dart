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
    String? apkUrl;
    for (final a in assets) {
      final name = (a['name'] as String? ?? '').toLowerCase();
      if (name.endsWith('.apk')) {
        apkUrl = a['browser_download_url'] as String?;
        break;
      }
    }
    if (tag.isEmpty || apkUrl == null) return null;
    var body = (json['body'] as String? ?? '').trim();
    var force = false;
    if (body.startsWith('[force]')) {
      force = true;
      body = body.substring('[force]'.length).trimLeft();
    }
    return AppRelease(tagName: tag, notes: body, apkUrl: apkUrl, force: force);
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
