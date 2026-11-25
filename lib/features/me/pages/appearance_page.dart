import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/tokens.dart';
import '../widgets/me_list_card.dart';
import '../widgets/theme_preview_card.dart';

/// 设置-外观页（Figma 27:211 改版）：
/// 主题色三卡（薄荷绿默认激活，点击换肤）→ 显示模式三缩略卡
/// （亮色/暗夜/跟随系统，点击切换 ThemeMode）→ 界面区
/// （字号滑条四档 + 圆角三 chips），全部持久化并即时生效。
class AppearancePage extends ConsumerWidget {
  const AppearancePage({super.key});

  static const _palettes = [AppTokens.mint, AppTokens.sakura, AppTokens.coral];

  static const _modes = [
    (mode: ThemeMode.light, icon: Icons.wb_sunny_outlined, key: 'me.modeLight'),
    (mode: ThemeMode.dark, icon: Icons.dark_mode_outlined, key: 'me.modeDark'),
    (
      mode: ThemeMode.system,
      icon: Icons.monitor_outlined,
      key: 'me.modeSystem',
    ),
  ];

  static const _radiusStyles = [
    (value: 'standard', key: 'me.radiusStandard'),
    (value: 'round', key: 'me.radiusRound'),
    (value: 'sharp', key: 'me.radiusSharp'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = ref.watch(paletteProvider);
    final mode = ref.watch(themeModeProvider);
    final fontIndex = ref.watch(fontScaleProvider);
    final radius = ref.watch(radiusStyleProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.appearanceTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          _sectionTitle(
            context,
            FlutterI18n.translate(context, 'me.themeSection'),
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < _palettes.length; i++) ...[
                if (i > 0) const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: Stack(
                    children: [
                      ThemePreviewCard(
                        palette: _palettes[i],
                        selected: _palettes[i].name == palette.name,
                        onTap: () => ref
                            .read(paletteProvider.notifier)
                            .select(_palettes[i]),
                      ),
                      if (_palettes[i].name == palette.name)
                        Positioned(
                          top: AppTokens.space2,
                          right: AppTokens.space2,
                          child: UsingBadge(color: _palettes[i].primary),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          _sectionTitle(
            context,
            FlutterI18n.translate(context, 'me.modeSection'),
          ),
          const SizedBox(height: AppTokens.space3),
          Row(
            children: [
              for (var i = 0; i < _modes.length; i++) ...[
                if (i > 0) const SizedBox(width: AppTokens.space3),
                Expanded(
                  child: _ModeCard(
                    icon: _modes[i].icon,
                    label: FlutterI18n.translate(context, _modes[i].key),
                    selected: mode == _modes[i].mode,
                    onTap: () => ref
                        .read(themeModeProvider.notifier)
                        .select(_modes[i].mode),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          _sectionTitle(
            context,
            FlutterI18n.translate(context, 'me.uiSection'),
          ),
          const SizedBox(height: AppTokens.space3),
          MeListCard(
            children: [
              // 字号：四档滑条（小/标准/大/特大），全局 textScaler 即时生效。
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  AppTokens.space3,
                  AppTokens.space4,
                  AppTokens.space2,
                ),
                child: Row(
                  children: [
                    Text(
                      FlutterI18n.translate(context, 'me.fontSize'),
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                    Expanded(
                      child: Slider(
                        value: fontIndex.toDouble().clamp(
                          0,
                          AppSettings.fontScaleValues.length - 1.0,
                        ),
                        min: 0,
                        max: (AppSettings.fontScaleValues.length - 1)
                            .toDouble(),
                        divisions: AppSettings.fontScaleValues.length - 1,
                        activeColor: palette.primary,
                        onChanged: (value) => ref
                            .read(fontScaleProvider.notifier)
                            .select(value.round()),
                      ),
                    ),
                  ],
                ),
              ),
              // 圆角：三 chips；持久化已接入，全局圆角受 const token 限制暂不变体。
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space4,
                  0,
                  AppTokens.space4,
                  AppTokens.space3,
                ),
                child: Row(
                  children: [
                    Text(
                      FlutterI18n.translate(context, 'me.radius'),
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                    const Spacer(),
                    for (final style in _radiusStyles)
                      Padding(
                        padding: const EdgeInsets.only(left: AppTokens.space2),
                        child: _RadiusChip(
                          label: FlutterI18n.translate(context, style.key),
                          selected: radius == style.value,
                          color: palette.primary,
                          onTap: () => ref
                              .read(radiusStyleProvider.notifier)
                              .select(style.value),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          Text(
            FlutterI18n.translate(context, 'me.appearanceHint'),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// 显示模式缩略卡（帧 227:1173~1189 范式）：图标 + 名称，
/// 选中 2px 主色描边 + 右上对勾圆标。
class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 96,
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? primary : Theme.of(context).dividerColor,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 28,
                      color: selected
                          ? primary
                          : cs.onSurface.withValues(alpha: 0.65),
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected ? primary : cs.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: AppTokens.space2,
                  right: AppTokens.space2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 圆角风格 chip（未选灰底、选中主色浅底主色字）。
class _RadiusChip extends StatelessWidget {
  const _RadiusChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space3,
          vertical: AppTokens.space1,
        ),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
