import 'package:flutter/widgets.dart';

/// 设计 token 单一来源。
///
/// 色值来自 Figma「禾禾影视」设计稿与桌面设计工作区的规格文件
/// （specs/01/06/08/09/10），
/// 与 Figma 本地变量集合（粉橘 2:2 / 珊瑚橙 2:3 / 薄荷绿 2:4 / 中性色 2:5）一致。
/// 任何页面/组件禁止自行硬编码色值，一律引用本文件。
abstract final class AppTokens {
  // ---- 主题色板（设置-外观页三主题，薄荷绿为默认） ----

  /// 粉橘 Sakura：暖春粉橘，柔和治愈（预览顶条 #FDAFA6）。
  static const AppPalette sakura = AppPalette(
    name: '粉橘',
    primary: Color(0xFFFDAFA6),
    primarySoft: Color(0xFFF6CFC4),
    primaryContainer: Color(0xFFFBE0D8),
    secondary: Color(0xFF7CB342),
    pageBg: Color(0xFFFFF9F7),
  );

  /// 珊瑚橙 Coral：活力珊瑚，暖阳氛围（预览顶条 #FA8469）。
  static const AppPalette coral = AppPalette(
    name: '珊瑚橙',
    primary: Color(0xFFFA8469),
    primarySoft: Color(0xFFF5C4B2),
    primaryContainer: Color(0xFFFBD9CC),
    secondary: Color(0xFF7CB342),
    pageBg: Color(0xFFFFF8F5),
  );

  /// 薄荷绿 Mint：清新薄荷，默认主题（预览顶条 #6DE4B4）。
  static const AppPalette mint = AppPalette(
    name: '薄荷绿',
    primary: Color(0xFF6DE4B4),
    primarySoft: Color(0xFF6CE5B0),
    primaryContainer: Color(0xFFD5F5E7),
    secondary: Color(0xFFE8A33D),
    pageBg: Color(0xFFF4FCF8),
  );

  /// 默认色板。
  static const AppPalette defaultPalette = mint;

  // ---- 中性色（所有主题共享，Figma 变量 3:24~3:29） ----

  /// 主文字（Figma 变量 3:24 text）。
  static const Color textPrimary = Color(0xFF202725);

  /// 次文字：图标、副文案。
  static const Color textSecondary = Color(0xFF6E6373);

  /// 弱文字：时间戳、辅助信息。
  static const Color textTertiary = Color(0xFF9C93A1);

  /// 分隔线（Figma 变量 3:27，规格要求 50~60% 透明度使用）。
  static const Color divider = Color(0xFFE8E0EC);

  /// 危险/删除/失败。
  static const Color danger = Color(0xFFE0624C);

  // ---- 表面（中性色集合） ----

  /// 卡片/浮层表面。
  static const Color surface = Color(0xFFFFFFFF);

  /// 次级表面：菜单组底、浅灰紫块。
  static const Color surfaceAlt = Color(0xFFF6F1FA);

  // ---- 暗夜（规格 07/09 播放器暗夜稿，各主题共用） ----

  /// 暗夜页面/视频留黑底。
  static const Color darkBg = Color(0xFF16241F);

  /// 暗夜表面：选集抽屉、弹层。
  static const Color darkSurface = Color(0xFF1B2B25);

  /// 暗夜分隔线（#FFFFFF 12%）。
  static const Color darkDivider = Color(0x1FFFFFFF);

  // ---- 圆角 ----

  /// 卡片圆角。
  static const double radiusCard = 12;

  /// 按钮圆角。
  static const double radiusButton = 12;

  /// chip / 胶囊圆角。
  static const double radiusChip = 999;

  // ---- 间距阶梯 ----

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;

  // ---- 封面比例 ----

  /// 视频封面 16:9。
  static const double coverRatioVideo = 16 / 9;

  /// 漫画封面 2:3（宽/高）。
  static const double coverRatioComic = 2 / 3;
}

/// 单套主题色板：设置-外观页三主题各自的家族色。
///
/// 中性色/暗夜色所有主题共享（见 [AppTokens]）。
class AppPalette {
  const AppPalette({
    required this.name,
    required this.primary,
    required this.primarySoft,
    required this.primaryContainer,
    required this.secondary,
    required this.pageBg,
  });

  /// 主题名（粉橘/珊瑚橙/薄荷绿）。
  final String name;

  /// 深主色：激活文字、图标、进度 100%、主题卡预览顶条。
  final Color primary;

  /// 软色：强调填充、进度条填充、chip 选中描边、暗夜模式主色。
  final Color primarySoft;

  /// 浅底：空态底托、浅色块。
  final Color primaryContainer;

  /// 第二强调色（Figma 变量 secondary）。
  final Color secondary;

  /// 页面底。
  final Color pageBg;
}
