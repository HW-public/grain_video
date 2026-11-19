import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../extension/plugin_manager.dart';
import '../providers/extensions_providers.dart';

/// 一个内容源的分组卡片：站点名 + 多语言实现列表 + 操作菜单。
class PluginGroupTile extends StatelessWidget {
  const PluginGroupTile({
    super.key,
    required this.group,
    required this.onLogs,
    required this.onRemove,
  });

  final SiteGroup group;
  final VoidCallback onLogs;
  final ValueChanged<PluginEntry> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.site, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 6),
                  for (final entry in group.variants)
                    _VariantRow(entry: entry, onRemove: () => onRemove(entry)),
                ],
              ),
            ),
            IconButton(
              tooltip: FlutterI18n.translate(context, 'extensions.logs'),
              onPressed: onLogs,
              icon: const Icon(Icons.receipt_long_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariantRow extends StatelessWidget {
  const _VariantRow({required this.entry, required this.onRemove});

  final PluginEntry entry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final impl = implOfEntry(entry);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(impl, style: theme.textTheme.labelSmall),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.info.name,
              style: theme.textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            entry.info.version,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          IconButton(
            tooltip: FlutterI18n.translate(context, 'extensions.delete'),
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}
