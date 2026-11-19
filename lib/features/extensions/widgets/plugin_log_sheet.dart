import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../extension/plugin_manager.dart';

/// 插件日志底部面板：guest 日志与宿主事件统一时间线（引擎日志环）。
class PluginLogSheet extends StatelessWidget {
  const PluginLogSheet({super.key, required this.site, required this.logs});

  final String site;
  final List<LogEntry> logs;

  static Future<void> show(
    BuildContext context, {
    required String site,
    required List<LogEntry> logs,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: PluginLogSheet(site: site, logs: logs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            '${FlutterI18n.translate(context, 'extensions.logs')} · $site',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Text(
                    FlutterI18n.translate(context, 'extensions.noLogs'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: logs.length,
                  itemBuilder: (context, i) {
                    final log = logs[i];
                    return ListTile(
                      dense: true,
                      leading: _levelBadge(theme, log.level),
                      title: Text(log.msg),
                      subtitle: Text(
                        [
                          _time(log.ts),
                          if (log.error != null && log.error!.isNotEmpty)
                            log.error!,
                        ].join('  '),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static String _time(DateTime ts) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(ts.hour)}:${two(ts.minute)}:${two(ts.second)}';
  }

  static Widget _levelBadge(ThemeData theme, int level) {
    const labels = ['D', 'I', 'W', 'E'];
    final idx = level.clamp(0, 3);
    final color = switch (idx) {
      3 => theme.colorScheme.error,
      2 => Colors.orange,
      _ => theme.colorScheme.outline,
    };
    return CircleAvatar(
      radius: 12,
      backgroundColor: color.withValues(alpha: 0.15),
      child: Text(
        labels[idx],
        style: theme.textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
