import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/extensions_providers.dart';

/// 单个插件条目行（设计稿：白色圆角卡片，高 64，左 emoji + 名称/包·版本，右侧绿色设置链接）。
class PluginTile extends StatelessWidget {
  const PluginTile({super.key, required this.entry, required this.onOpen});

  final PluginEntry entry;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: AppTokens.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        onTap: onOpen,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          child: Row(
            children: [
              Text(_emojiFor(entry), style: const TextStyle(fontSize: 36)),
              const SizedBox(width: AppTokens.space3),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.info.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppTokens.textPrimary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.info.package} · ${entry.info.version}'
                      '${entry.info.webSite.isNotEmpty ? '' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTokens.textSecondary,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${FlutterI18n.translate(context, 'extensions.settings')} ›',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.defaultPalette.primary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 按内容源给个稳定 emoji（无真实图标字段，用站点名哈希避免频繁变动）。
  static String _emojiFor(PluginEntry entry) {
    const emojis = ['🌸', '📚', '📖', '🎬', '📦', '🍿', '🎞️', '🌙'];
    final site = siteOfEntry(entry);
    var hash = 0;
    for (final code in site.codeUnits) {
      hash = (hash + code) % emojis.length;
    }
    return emojis[hash];
  }
}
