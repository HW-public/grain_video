import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'features/downloads/providers/download_manager.dart';
import 'router.dart';

/// 应用根组件：外观设置（主题色板/显示模式/字号）从这里全局生效。
class HeHeApp extends ConsumerWidget {
  const HeHeApp({super.key, this.initialLocation});

  /// 首启引导：main 依 AppSettings.onboardingDone 决定是否指向 /onboarding。
  final String? initialLocation;

  static final _i18nDelegate = FlutterI18nDelegate(
    translationLoader: FileTranslationLoader(
      basePath: 'assets/l10n',
      fallbackFile: 'zh',
      useCountryCode: false,
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    // 常驻：提前实例化下载管理器，注册 DownloadGateway（播放器入队依赖）。
    ref.watch(downloadManagerProvider);
    final mode = ref.watch(themeModeProvider);
    final fontIndex = ref
        .watch(fontScaleProvider)
        .clamp(0, AppSettings.fontScaleValues.length - 1);
    final textScaler = TextScaler.linear(
      AppSettings.fontScaleValues[fontIndex],
    );
    return MaterialApp.router(
      title: '禾禾影视',
      theme: AppTheme.light(palette),
      darkTheme: AppTheme.dark(palette),
      themeMode: mode,
      builder: (context, child) {
        // 外观-字号：全局文字缩放（帧 27:211 界面区字号条）。
        final data = MediaQuery.of(context);
        return MediaQuery(
          data: data.copyWith(textScaler: textScaler),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: initialLocation == null
          ? appRouter
          : buildAppRouter(initialLocation: initialLocation),
      localizationsDelegates: [
        _i18nDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('zh'), Locale('en')],
    );
  }
}
