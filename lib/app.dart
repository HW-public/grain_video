import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/settings/app_settings.dart';
import 'core/theme/app_theme.dart';
import 'router.dart';

/// 应用根组件：外观设置（主题色板/显示模式/字号）从这里全局生效。
class HeHeApp extends ConsumerWidget {
  const HeHeApp({super.key});

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
      routerConfig: appRouter,
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
