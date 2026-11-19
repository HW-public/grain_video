import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// 应用根组件。
class HeHeApp extends StatelessWidget {
  const HeHeApp({super.key});

  static final _i18nDelegate = FlutterI18nDelegate(
    translationLoader: FileTranslationLoader(
      basePath: 'assets/l10n',
      fallbackFile: 'zh',
      useCountryCode: false,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '禾禾影视',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
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
