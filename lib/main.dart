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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 启动页先行（品牌露出），初始化完成后切换主应用；保底 900ms 防闪跳。
  final stopwatch = Stopwatch()..start();
  runApp(const ProviderScope(child: SplashPage()));

  final isDesktop =
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  if (isDesktop) {
    // 桌面端必须先亮窗再慢慢初始化——waitUntilReadyToShow 会等就绪才显示，
    // 那时早已切到主应用，启动页将不可见。
    await windowManager.ensureInitialized();
    unawaited(windowManager.show());
    unawaited(windowManager.focus());
  }

  MediaKit.ensureInitialized();
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
    ProviderScope(
      // 首次启动先进引导页，完成引导后写标记，之后冷启动直达首页。
      child: HeHeApp(
        initialLocation: AppSettings.onboardingDone ? null : '/onboarding',
      ),
    ),
  );
}
