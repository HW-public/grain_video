import 'package:flutter/material.dart';

import 'tokens.dart';

/// 亮/暗两套 ThemeData，按主题色板 [AppPalette] 生成。
///
/// ColorScheme 全部手动映射，不用 fromSeed 跑色，
/// 保证端上颜色与设计稿逐值一致。
/// Typography 用 Material 3 默认字号体系，不在此覆盖。
abstract final class AppTheme {
  /// 亮色主题。不传 [palette] 时用默认（薄荷绿）。
  static ThemeData light([AppPalette palette = AppTokens.defaultPalette]) {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: palette.primary,
      onPrimary: Colors.white,
      secondary: palette.primarySoft,
      // 规格 04：浅绿底上的深绿字。
      onSecondary: AppTokens.darkBg,
      error: AppTokens.danger,
      onError: Colors.white,
      surface: AppTokens.surface,
      onSurface: AppTokens.textPrimary,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.pageBg,
      dividerColor: AppTokens.divider,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.pageBg,
        foregroundColor: AppTokens.textPrimary,
      ),
    );
  }

  /// 暗夜：参考 Figma 阅读器/播放器暗夜稿（规格 07/09），各主题共用一套暗夜。
  /// 暗夜完整规格后续单出，本套先保证播放器与阅读场景可用。
  static ThemeData dark([AppPalette palette = AppTokens.defaultPalette]) {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: palette.primarySoft,
      onPrimary: AppTokens.darkBg,
      secondary: palette.primary,
      onSecondary: Colors.white,
      error: AppTokens.danger,
      onError: Colors.white,
      surface: AppTokens.darkSurface,
      onSurface: const Color(0xFFEFF5F1),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppTokens.darkBg,
      dividerColor: AppTokens.darkDivider,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.darkBg,
        foregroundColor: Color(0xFFEFF5F1),
      ),
    );
  }
}
