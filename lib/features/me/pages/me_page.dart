import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/cache/app_image_cache.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/me_providers.dart';
import '../routes.dart' show MeRoutes;

/// 「我的」一级页（Figma 21:20，无 AppBar，底导由外壳挂载）：
/// 主色圆头像 + 昵称/副标 → 三格数据入口卡（收藏/历史/下载，点击进各自
/// 详情列表，帧内不留预览卡）→ 白卡设置列表（r16、矢量 icon 行、缩进分隔线）。
///
/// 用户拍板（2026-11-23）：AniList 条不画；追番列表入口保留（设置卡一行）；
/// 列表行一律矢量 icon 不用 emoji。
class MePage extends ConsumerWidget {
  const MePage({super.key});

  static const _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          // 帧：头像 y60 = 状态栏 44 + 16；左右 16。
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space4,
            AppTokens.space4,
            AppTokens.space4,
          ),
          children: const [
            _Header(),
            SizedBox(height: AppTokens.space4),
            _EntryCards(),
            SizedBox(height: AppTokens.space4),
            _SettingsCard(appVersion: MePage._appVersion),
          ],
        ),
      ),
    );
  }
}

/// 头部（帧 25:154~25:157）：主色圆 56 + 白色「禾」20/700，
/// 昵称 17/700 textPrimary，副标 12/400 textTertiary。
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
          child: Text(
            '禾',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FlutterI18n.translate(context, 'me.headerName'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              FlutterI18n.translate(context, 'me.headerSubtitle'),
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 三格数据入口卡（帧 223:28~223:46）：白底 r12 高 64、卡距 11，
/// 每卡 矢量 icon 18 置顶 → 名称 13/600 → 数量 11 textTertiary + ›。
/// 点击分别进 收藏/历史/下载 列表页；数量实时取列表长度。
class _EntryCards extends ConsumerWidget {
  const _EntryCards();

  static const _icons = [
    Icons.star_outline,
    Icons.history,
    Icons.download_outlined,
  ];
  static const _nameKeys = [
    'me.tabFavorites',
    'me.tabHistory',
    'me.tabDownloads',
  ];
  static const _routes = [
    MeRoutes.favorites,
    MeRoutes.history,
    MeRoutes.downloads,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = [
      ref.watch(favoritesListProvider).value?.length ?? 0,
      ref.watch(watchHistoryListProvider).value?.length ?? 0,
      // 下载功能未做，数量恒 0。
      0,
    ];
    return Row(
      children: [
        for (var i = 0; i < _icons.length; i++) ...[
          if (i > 0) const SizedBox(width: 11),
          Expanded(
            child: _EntryCard(
              icon: _icons[i],
              name: FlutterI18n.translate(context, _nameKeys[i]),
              count: counts[i],
              onTap: () => context.push(_routes[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.icon,
    required this.name,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String name;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 64,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: cs.onSurface),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$count ›',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 设置白卡（帧 25:177~25:196）：r16 白底；行高 50、矢量 icon 18(textPrimary)
/// + 标签 13/400 + 右侧值 13/400 textTertiary + ›；分隔线左右缩进 16 全不透明。
class _SettingsCard extends ConsumerWidget {
  const _SettingsCard({required this.appVersion});

  final String appVersion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pluginCount = ref.watch(pluginManagerProvider).length;
    final versionLine = FlutterI18n.translate(
      context,
      'me.aboutVersionLine',
      translationParams: {
        'name': FlutterI18n.translate(context, 'appTitle'),
        'version': appVersion,
      },
    );

    // 帧五行 + 用户拍板保留的「追番列表」入口（插在扩展管理后）。
    final rows = <_SettingsRowData>[
      _SettingsRowData(
        icon: Icons.extension_outlined,
        labelKey: 'me.extensions',
        value: FlutterI18n.translate(
          context,
          'me.extensionsCount',
          translationParams: {'count': '$pluginCount'},
        ),
        onTap: () => context.push(AppRoutes.extensions),
      ),
      _SettingsRowData(
        icon: Icons.live_tv_outlined,
        labelKey: 'me.follows',
        onTap: () => context.push(MeRoutes.follows),
      ),
      _SettingsRowData(
        icon: Icons.color_lens_outlined,
        labelKey: 'me.appearanceTitle',
        // 跟随当前所选色板（换肤后右侧值即时更新）。
        value: FlutterI18n.translate(
          context,
          'me.appearanceValue',
          translationParams: {'name': ref.watch(paletteProvider).name},
        ),
        onTap: () => context.push(MeRoutes.settingsAppearance),
      ),
      _SettingsRowData(
        icon: Icons.public,
        labelKey: 'me.proxyTitle',
        value: FlutterI18n.translate(context, 'me.proxyOff'),
        onTap: () => context.push(MeRoutes.settingsProxy),
      ),
      _SettingsRowData(
        icon: Icons.cleaning_services_outlined,
        labelKey: 'me.cacheTitle',
        // 与缓存清理页同源：实时图片缓存占用。
        value: ref
            .watch(imageCacheSizeProvider)
            .when(data: formatBytes, loading: () => '', error: (_, _) => ''),
        onTap: () => context.push(MeRoutes.settingsCache),
      ),
      _SettingsRowData(
        icon: Icons.info_outline,
        labelKey: 'me.about',
        value: versionLine,
        onTap: () => context.push(MeRoutes.about),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space4,
                ),
                child: Container(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
              ),
            _SettingsRow(data: rows[i]),
          ],
        ],
      ),
    );
  }
}

class _SettingsRowData {
  const _SettingsRowData({
    required this.icon,
    required this.labelKey,
    required this.onTap,
    this.value,
  });

  final IconData icon;
  final String labelKey;
  final VoidCallback onTap;
  final String? value;
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.data});

  final _SettingsRowData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: data.onTap,
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Row(
            children: [
              Icon(data.icon, size: 18, color: cs.onSurface),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Text(
                  FlutterI18n.translate(context, data.labelKey),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (data.value != null)
                Flexible(
                  flex: 0,
                  child: Text(
                    data.value!,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(width: AppTokens.space1),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
