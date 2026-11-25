import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';
import '../../../extension/plugin_manager.dart';
import '../../../extension/plugin_updater.dart';
import '../providers/extensions_providers.dart';

/// 单个插件条目卡（Figma 27:210 范式）：白底 r12 高 76，
/// 矢量 icon 36 + 名称 14/600 + 包名 11 + 版本行 11；
/// 有更新时版本行变绿「vA → vB 可更新」，右侧出「更新」描边药丸；
/// 无「设置 ›」入口（配置项随扩展详情页一并取消，操作=左滑删除/点按看日志）。
class PluginTile extends StatelessWidget {
  const PluginTile({
    super.key,
    required this.entry,
    this.release,
    required this.onTap,
    required this.onUpdate,
  });

  final PluginEntry entry;

  /// 清单中可更新的 release；null = 已最新。
  final PluginRelease? release;
  final VoidCallback onTap;
  final VoidCallback onUpdate;

  /// 按内容源给个稳定矢量 icon（无真实图标字段，用站点名哈希避免频繁变动）。
  static const _icons = [
    Icons.movie_outlined,
    Icons.menu_book_outlined,
    Icons.book_outlined,
    Icons.live_tv_outlined,
    Icons.inventory_2_outlined,
    Icons.local_movies_outlined,
    Icons.video_library_outlined,
    Icons.podcasts_outlined,
  ];

  static IconData _iconFor(PluginEntry entry) {
    final site = siteOfEntry(entry);
    var hash = 0;
    for (final code in site.codeUnits) {
      hash = (hash + code) % _icons.length;
    }
    return _icons[hash];
  }

  @override
  Widget build(BuildContext context) {
    final pending = release;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 76,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Icon(_iconFor(entry), size: 28, color: cs.onSurface),
              ),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.info.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.info.package,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      pending == null
                          ? '${entry.info.version} · ${FlutterI18n.translate(context, 'extensions.latest')}'
                          : FlutterI18n.translate(
                              context,
                              'extensions.updatable',
                              translationParams: {
                                'from': entry.info.version,
                                'to': pending.version,
                              },
                            ),
                      style: TextStyle(
                        fontSize: 11,
                        color: pending == null
                            ? cs.onSurface.withValues(alpha: 0.65)
                            : cs.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (pending != null)
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.primary,
                    side: BorderSide(color: cs.primary, width: 1),
                    minimumSize: const Size(64, 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space3,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onUpdate,
                  child: Text(
                    FlutterI18n.translate(context, 'extensions.update'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
