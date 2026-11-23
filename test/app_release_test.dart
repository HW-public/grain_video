import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/update/app_release.dart';

void main() {
  group('AppRelease.fromGitHubJson', () {
    Map<String, dynamic> json({String body = '修复若干问题'}) => {
      'tag_name': 'v1.1.0',
      'body': body,
      'assets': [
        {'name': 'app-release.apk', 'browser_download_url': 'https://x/a.apk'},
        {'name': 'notes.txt', 'browser_download_url': 'https://x/n.txt'},
      ],
    };

    test('解析版本/notes/APK 资产', () {
      final r = AppRelease.fromGitHubJson(json());
      expect(r, isNotNull);
      expect(r!.tagName, 'v1.1.0');
      expect(r.version, '1.1.0');
      expect(r.notes, '修复若干问题');
      expect(r.apkUrl, 'https://x/a.apk');
      expect(r.force, isFalse);
    });

    test('body 首行 [force] → 强制更新且标记行不进 notes', () {
      final r = AppRelease.fromGitHubJson(json(body: '[force]\n紧急修复'));
      expect(r!.force, isTrue);
      expect(r.notes, '紧急修复');
    });

    test('无 APK 资产返回 null', () {
      final j = json()..['assets'] = [];
      expect(AppRelease.fromGitHubJson(j), isNull);
    });
  });

  group('isNewerVersion', () {
    test('语义版本逐段比较', () {
      expect(isNewerVersion(current: '1.0.0', latest: '1.0.1'), isTrue);
      expect(isNewerVersion(current: '1.0.0', latest: '1.1.0'), isTrue);
      expect(isNewerVersion(current: '1.9.0', latest: '2.0.0'), isTrue);
      expect(isNewerVersion(current: '1.0.0', latest: '1.0.0'), isFalse);
      expect(isNewerVersion(current: '1.0.1', latest: '1.0.0'), isFalse);
      expect(isNewerVersion(current: '2.0.0', latest: '1.9.9'), isFalse);
    });

    test('容忍 v 前缀/缺段/后缀', () {
      expect(isNewerVersion(current: 'v1.0', latest: 'v1.0.1'), isTrue);
      expect(isNewerVersion(current: '1.0.0+build8', latest: '1.0.1'), isTrue);
      expect(isNewerVersion(current: '1.0.0-beta', latest: '1.0.0'), isFalse);
    });
  });
}
