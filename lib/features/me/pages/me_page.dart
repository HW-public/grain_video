import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/cache/app_image_cache.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../data/db/database.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/me_providers.dart';
import '../routes.dart' show MeRoutes;

/// 「我的」一级页（Figma 21:20，无 AppBar，底导由外壳挂载）：
/// 主色圆头像 + 昵称/副标 → 分段器（收藏/历史/下载，下载占位）
/// → 白卡设置列表（r16、矢量 icon 行、缩进分隔线）。
///
/// 用户拍板（2026-11-23）：AniList 条不画；追番列表入口保留（设置卡一行）；
/// 分段器与列表行一律矢量 icon 不用 emoji；恢复列表行的想法撤回，仍按帧分段器。
class MePage extends ConsumerStatefulWidget {
  const MePage({super.key});

  static const _appVersion = 'v1.0.0';

  @override
  ConsumerState<MePage> createState() => _MePageState();
}

class _MePageState extends ConsumerState<MePage> {
  static const _tabIcons = [
    Icons.star_outline,
    Icons.history,
    Icons.download_outlined,
  ];
  static const _tabKeys = [
    'me.tabFavorites',
    'me.tabHistory',
    'me.tabDownloads',
  ];

  int _tab = 0;

  /// 三个 tab 内容区统一高度（= 一行海报实测高：162 封面 + 6 + 标题 18
  /// + 2 + 副标 15），空态/有数据同高，切换 tab 不跳动；
  /// 数据超出内部滚动。
  static const double _tabContentHeight = 204;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      body: SafeArea(
        child: ListView(
          // 帧：头像 y60 = 状态栏 44 + 16；左右 16。
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space4,
            AppTokens.space4,
            AppTokens.space4,
          ),
          children: [
            const _Header(),
            const SizedBox(height: AppTokens.space4),
            _buildSegment(),
            const SizedBox(height: AppTokens.space4),
            _buildTabContent(),
            const SizedBox(height: AppTokens.space4),
            const _SettingsCard(appVersion: MePage._appVersion),
          ],
        ),
      ),
    );
  }

  /// 分段器（帧 25:160~25:164）：灰紫底(surfaceAlt) r12 高36，
  /// 激活段白 pill r9，矢量 icon 14 + 文字 12：
  /// 激活 600 textPrimary / 未选 400 textSecondary。
  Widget _buildSegment() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppTokens.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          for (var i = 0; i < _tabIcons.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 30,
                  decoration: BoxDecoration(
                    color: _tab == i ? AppTokens.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _tabIcons[i],
                        size: 14,
                        color: _tab == i
                            ? AppTokens.textPrimary
                            : AppTokens.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        FlutterI18n.translate(context, _tabKeys[i]),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: _tab == i
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _tab == i
                              ? AppTokens.textPrimary
                              : AppTokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    final content = switch (_tab) {
      0 => const _FavoritesGrid(),
      1 => const _HistoryGrid(),
      _ => const _DownloadsPlaceholder(),
    };
    return SizedBox(height: _tabContentHeight, child: content);
  }
}

/// 头部（帧 25:154~25:157）：主色圆 56 + 白色「禾」20/700，
/// 昵称 17/700 textPrimary，副标 12/400 textTertiary。
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTokens.defaultPalette.primary,
            shape: BoxShape.circle,
          ),
          child: const Text(
            '禾',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space3),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FlutterI18n.translate(context, 'me.headerName'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              FlutterI18n.translate(context, 'me.headerSubtitle'),
              style: const TextStyle(
                fontSize: 12,
                color: AppTokens.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 收藏 tab：三列竖海报网格（帧 25:165~25:176 范式）。
/// 副标取追番进度「看到 第N集」，无进度则留空。
class _FavoritesGrid extends ConsumerWidget {
  const _FavoritesGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesListProvider);
    final follows = ref.watch(followsListProvider).value ?? const <Follow>[];
    final progress = <String, int>{
      for (final f in follows)
        '${f.sourcePackage}|${f.bangumiUrl}': f.currentEpisode,
    };
    return AsyncView<List<Favorite>>(
      value: favorites,
      builder: (context, items) {
        if (items.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.star_outline,
              message: FlutterI18n.translate(context, 'me.emptyFavoritesTitle'),
            ),
          );
        }
        return _PosterGrid(
          children: [
            for (final item in items)
              _PosterCard(
                coverUrl: item.cover,
                title: item.title,
                subtitle: _progressLabel(context, progress, item),
                onTap: () => context.push(
                  '${AppRoutes.detail}?url=${Uri.encodeComponent(item.bangumiUrl)}'
                  '&src=${Uri.encodeComponent(item.sourcePackage)}',
                ),
              ),
          ],
        );
      },
    );
  }

  String _progressLabel(
    BuildContext context,
    Map<String, int> progress,
    Favorite item,
  ) {
    final ep = progress['${item.sourcePackage}|${item.bangumiUrl}'] ?? 0;
    if (ep <= 0) return '';
    return FlutterI18n.translate(
      context,
      'me.followEpisode',
      translationParams: {'n': '$ep'},
    );
  }
}

/// 历史 tab：观看历史同风格网格（帧未画该态，按收藏网格镜像，记偏离）。
/// 点按直跳播放器续播。
class _HistoryGrid extends ConsumerWidget {
  const _HistoryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(watchHistoryListProvider);
    return AsyncView<List<WatchHistory>>(
      value: history,
      builder: (context, items) {
        if (items.isEmpty) {
          return Center(
            child: EmptyState(
              icon: Icons.history,
              message: FlutterI18n.translate(context, 'me.emptyHistoryTitle'),
            ),
          );
        }
        return _PosterGrid(
          children: [
            for (final item in items)
              _PosterCard(
                coverUrl: item.cover,
                title: item.title,
                subtitle: item.episodeTitle,
                onTap: () => context.push(
                  '${AppRoutes.player}?ep=${Uri.encodeComponent(item.episodeUrl)}'
                  '&src=${Uri.encodeComponent(item.sourcePackage)}'
                  '&title=${Uri.encodeComponent(item.title)}'
                  '&bangumi=${Uri.encodeComponent(item.bangumiUrl)}',
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 下载 tab 占位：下载功能未做（用户拍板 2026-11-23）。
class _DownloadsPlaceholder extends StatelessWidget {
  const _DownloadsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.download_outlined,
        message: FlutterI18n.translate(context, 'me.downloadEmpty'),
      ),
    );
  }
}

/// 三列竖海报网格（帧 25:165：卡 108×162 即 2:3、列距 10、
/// 卡→标题 6、标题 13/600、标题→副标 2、副标 11/400 textTertiary）。
class _PosterGrid extends StatelessWidget {
  const _PosterGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // GridView.builder 懒构建：滑到才创建卡片/发起封面请求。
        const gap = 10.0;
        final cardWidth = (constraints.maxWidth - gap * 2) / 3;
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: cardWidth,
            mainAxisSpacing: AppTokens.space4,
            crossAxisSpacing: gap,
            // 卡高 = 162 封面 + 6 + 标题18 + 2 + 副标15（与 _PosterCard 一致）。
            mainAxisExtent: 204,
          ),
          itemCount: children.length,
          itemBuilder: (context, i) => children[i],
        );
      },
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({
    required this.coverUrl,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String coverUrl;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            child: coverUrl.isEmpty
                ? const ColoredBox(
                    color: AppTokens.surfaceAlt,
                    child: SizedBox(
                      width: double.infinity,
                      height: 162,
                      child: Icon(
                        Icons.image_outlined,
                        color: AppTokens.textTertiary,
                      ),
                    ),
                  )
                : CachedImage(
                    url: coverUrl,
                    width: double.infinity,
                    height: 162,
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTokens.textPrimary,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTokens.textTertiary,
              ),
            ),
          ],
        ],
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
        value: FlutterI18n.translate(
          context,
          'me.appearanceValue',
          translationParams: {'name': AppTokens.defaultPalette.name},
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
        color: AppTokens.surface,
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
                child: Container(height: 1, color: AppTokens.divider),
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
    return InkWell(
      onTap: data.onTap,
      child: SizedBox(
        height: 50,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Row(
            children: [
              Icon(data.icon, size: 18, color: AppTokens.textPrimary),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Text(
                  FlutterI18n.translate(context, data.labelKey),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTokens.textPrimary,
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
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTokens.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const SizedBox(width: AppTokens.space1),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: AppTokens.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
