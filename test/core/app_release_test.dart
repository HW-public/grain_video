import 'package:flutter_test/flutter_test.dart';
import 'package:grain_video/core/update/app_release.dart';

void main() {
  const apks = {
    'app-armeabi-v7a-release.apk': 'u/v7a',
    'app-arm64-v8a-release.apk': 'u/arm64',
    'app-x86_64-release.apk': 'u/x64',
  };

  group('AppRelease.pickApkAsset（split-per-abi 资产选择）', () {
    test('按设备 ABI 精确匹配', () {
      expect(AppRelease.pickApkAsset(apks, abiTag: 'x86_64'), 'u/x64');
      expect(AppRelease.pickApkAsset(apks, abiTag: 'arm64-v8a'), 'u/arm64');
      expect(AppRelease.pickApkAsset(apks, abiTag: 'armeabi-v7a'), 'u/v7a');
    });

    test('ABI 无匹配（如 x86 模拟器只有三 abi 包）：arm64 兜底', () {
      expect(AppRelease.pickApkAsset(apks, abiTag: 'x86'), 'u/arm64');
    });

    test('单 universal 包（历史 release）：任意返回', () {
      expect(
        AppRelease.pickApkAsset({'app-release.apk': 'u/all'}, abiTag: 'x86_64'),
        'u/all',
      );
    });

    test('空资产表：null', () {
      expect(AppRelease.pickApkAsset(const {}, abiTag: 'arm64-v8a'), isNull);
    });
  });

  group('fromGitHubJson ABI 选择集成', () {
    test('多 abi 资产时选中当前设备（测试机为桌面/移动其一，断言命中其一）', () {
      final release = AppRelease.fromGitHubJson({
        'tag_name': 'v9.9.9',
        'body': 'notes',
        'assets': [
          for (final e in apks.entries)
            {'name': e.key, 'browser_download_url': e.value},
        ],
      });
      expect(release, isNotNull);
      expect(apks.values, contains(release!.apkUrl));
    });
  });
}
