import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/services/app_logger.dart';
import 'core/services/proxy_service.dart';
import 'core/settings/app_settings.dart';
import 'core/widgets/splash_page.dart';
import 'extension/plugin_manager.dart';
import 'features/home/providers/home_providers.dart';
import 'features/player/providers/player_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // 全局代理覆盖尽早安装（须在任何 HttpClient 创建之前）。
  ProxyService.install();
  // 日志系统：回读历史错误日志（重启后可查）。
  unawaited(AppLogger.init());

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
  ProxyService.update(
    AppSettings.proxyEnabled ? AppSettings.proxyMode : 'direct',
    AppSettings.proxyHost,
    AppSettings.proxyPort,
  );

  // 启动页真加载（用户拍板 2026-11-26，主流 App 同款）：插件装载 +
  // 首页首屏数据预取（合并流 + hero 轮播的历史/追更），进首页即见内容；
  // 上限 3s，弱网不卡启动页。单项失败静默（首页自走错误态）。
  Future<void> quiet(Future<Object?> f) =>
      f.then((_) {}, onError: (Object _) {});
  final preload = Future.wait([
    quiet(
      container
          .read(pluginManagerProvider.notifier)
          .load()
          .then((_) => container.read(mergedLatestProvider.future)),
    ),
    quiet(container.read(recentWatchProvider.future)),
    quiet(container.read(followsProvider.future)),
  ]);
  await Future.any([preload, Future<void>.delayed(const Duration(seconds: 3))]);

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
