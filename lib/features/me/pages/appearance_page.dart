import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';
import '../widgets/me_list_card.dart';
import '../widgets/theme_preview_card.dart';

/// 设置-外观页（设计稿 27:211）：主题色三卡（粉橘/珊瑚橙/薄荷绿）
/// + 显示模式三行（亮色/暗色/跟随系统），只读展示当前默认
/// （薄荷绿 + 亮色）；换肤与暗色交互后续版本开放。
class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  static const _palettes = [AppTokens.sakura, AppTokens.coral, AppTokens.mint];

  static const _modes = [
    (icon: Icons.wb_sunny_outlined, key: 'me.modeLight', recommended: true),
    (icon: Icons.dark_mode_outlined, key: 'me.modeDark', recommended: false),
    (icon: Icons.monitor_outlined, key: 'me.modeSystem', recommended: false),
  ];

  @override
  Widget build(BuildContext context) {
    // AppPalette 字段为 final 非 const，const 上下文不可访问，提升为局部变量。
    final primaryColor = AppTokens.defaultPalette.primary;
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.appearanceTitle')),
        actions: [
          // 顶栏右侧主题指示圆点（设计稿同款）。
          Padding(
            padding: const EdgeInsets.only(right: AppTokens.space4),
            child: Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          _sectionTitle(FlutterI18n.translate(context, 'me.themeSection')),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              for (var i = 0; i < _palettes.length; i++) ...[
                if (i > 0) const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: ThemePreviewCard(
                    palette: _palettes[i],
                    selected:
                        _palettes[i].name == AppTokens.defaultPalette.name,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          _sectionTitle(FlutterI18n.translate(context, 'me.modeSection')),
          const SizedBox(height: AppTokens.space3),
          MeListCard(
            children: [
              for (final mode in _modes)
                _ModeRow(
                  icon: mode.icon,
                  label: FlutterI18n.translate(context, mode.key),
                  recommended: mode.recommended,
                  selected: mode.recommended,
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          Text(
            FlutterI18n.translate(context, 'me.appearanceHint'),
            style: const TextStyle(fontSize: 12, color: AppTokens.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTokens.textPrimary,
      ),
    );
  }
}

/// 显示模式行：图标 + 名称（+「推荐」标记），选中行名称主色加粗。
class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.icon,
    required this.label,
    required this.recommended,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool recommended;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final primary = AppTokens.defaultPalette.primary;
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: primary),
            const SizedBox(width: AppTokens.space3),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? primary : AppTokens.textPrimary,
              ),
            ),
            if (recommended) ...[
              const SizedBox(width: AppTokens.space2),
              Text(
                FlutterI18n.translate(context, 'me.modeRecommended'),
                style: TextStyle(fontSize: 12, color: primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
