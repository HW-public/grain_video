import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/settings/app_settings.dart';
import 'core/widgets/splash_page.dart';
import 'features/player/providers/player_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  // 启动页先行（品牌露出），初始化完成后切换主应用；保底 900ms 防闪跳。
  final stopwatch = Stopwatch()..start();
  // 共享容器：splash 与主应用同一 ProviderScope，状态不丢；
  // 启动即创建单例 Player——mpv 缓冲调优须在首次 open 前完成
  // （demuxer 属性只在建流时生效），提前创建消除与起播的竞态。
  final container = ProviderContainer();
  container.read(playerProvider); // 同步触发创建 + 后台调优
  runApp(
    UncontrolledProviderScope(container: container, child: const SplashPage()),
  );

  final isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  if (isDesktop) {
    // 桌面端必须先亮窗再慢慢初始化——waitUntilReadyToShow 会等就绪才显示，
    // 那时早已切到主应用，启动页将不可见。
    await windowManager.ensureInitialized();
    unawaited(windowManager.show());
    unawaited(windowManager.focus());
  }

  await AppSettings.load();

  if (isDesktop) {
    // 窗口参数后台补齐，不阻塞启动页露出。
    unawaited(
      windowManager
          .setSize(const Size(1080, 720))
          .then((_) => windowManager.setMinimumSize(const Size(1080, 720)))
          .then((_) => windowManager.center())
          .then((_) => windowManager.setTitle('禾禾影视')),
    );
  }

  final elapsed = stopwatch.elapsedMilliseconds;
  if (elapsed < 900) {
    await Future<void>.delayed(Duration(milliseconds: 900 - elapsed));
  }
  runApp(
    UncontrolledProviderScope(
      container: container,
      // 首次启动先进引导页，完成引导后写标记，之后冷启动直达首页。
      child: HeHeApp(
        initialLocation: AppSettings.onboardingDone ? null : '/onboarding',
      ),
    ),
  );
}
