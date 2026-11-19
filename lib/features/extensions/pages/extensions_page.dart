import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_view.dart';
import '../../../extension/plugin_manager.dart';
import '../../../extension/plugin_updater.dart';
import '../providers/extensions_providers.dart';
import '../widgets/plugin_group_tile.dart';
import '../widgets/plugin_log_sheet.dart';

/// 扩展管理：按内容源分组展示已安装插件，支持导入、删除、检查更新、查看日志。
class ExtensionsPage extends ConsumerWidget {
  const ExtensionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(installedGroupsProvider);
    final controller = ref.watch(extensionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'nav.extensions')),
        actions: [
          IconButton(
            tooltip: FlutterI18n.translate(context, 'extensions.reload'),
            icon: const Icon(Icons.refresh),
            onPressed: () => _run(context, () async {
              await controller.reload();
              if (!context.mounted) return;
              _toast(
                context,
                FlutterI18n.translate(context, 'extensions.reloaded'),
              );
            }),
          ),
          IconButton(
            tooltip: FlutterI18n.translate(context, 'extensions.checkUpdates'),
            icon: const Icon(Icons.system_update_alt),
            onPressed: () => _checkUpdates(context, controller),
          ),
          IconButton(
            tooltip: FlutterI18n.translate(context, 'extensions.import'),
            icon: const Icon(Icons.add),
            onPressed: () => _importDialog(context, controller),
          ),
        ],
      ),
      body: groups.isEmpty
          ? EmptyState(
              icon: Icons.extension_outlined,
              message: FlutterI18n.translate(context, 'extensions.empty'),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final group = groups[i];
                return PluginGroupTile(
                  group: group,
                  onLogs: () => PluginLogSheet.show(
                    context,
                    site: group.site,
                    logs: controller.logsOfGroup(group),
                  ),
                  onRemove: (entry) =>
                      _confirmRemove(context, controller, group, entry),
                );
              },
            ),
    );
  }

  Future<void> _importDialog(
    BuildContext context,
    ExtensionsController controller,
  ) async {
    final pathController = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(context, 'extensions.import')),
        content: TextField(
          controller: pathController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: FlutterI18n.translate(context, 'extensions.importHint'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(FlutterI18n.translate(context, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(pathController.text),
            child: Text(FlutterI18n.translate(context, 'common.confirm')),
          ),
        ],
      ),
    );
    pathController.dispose();
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty) return;
    if (!context.mounted) return;

    await _run(
      context,
      () async {
        final entry = await controller.importWasm(trimmed);
        if (!context.mounted) return;
        _toast(
          context,
          '${FlutterI18n.translate(context, 'extensions.imported')}: '
          '${entry.info.name} ${entry.info.version}',
        );
      },
      errorPrefix: FlutterI18n.translate(context, 'extensions.importFailed'),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    ExtensionsController controller,
    SiteGroup group,
    PluginEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(FlutterI18n.translate(context, 'extensions.delete')),
        content: Text(FlutterI18n.translate(context, 'extensions.deleteHint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(FlutterI18n.translate(context, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(FlutterI18n.translate(context, 'common.confirm')),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await _run(context, () async {
      await controller.remove(entry);
      if (!context.mounted) return;
      _toast(context, FlutterI18n.translate(context, 'extensions.removed'));
    });
  }

  Future<void> _checkUpdates(
    BuildContext context,
    ExtensionsController controller,
  ) async {
    await _run(
      context,
      () async {
        final pending = await controller.checkUpdates();
        if (!context.mounted) return;
        if (pending.isEmpty) {
          _toast(
            context,
            FlutterI18n.translate(context, 'extensions.upToDate'),
          );
          return;
        }
        await _showUpdates(context, controller, pending);
      },
      errorPrefix: FlutterI18n.translate(
        context,
        'extensions.checkUpdatesFailed',
      ),
    );
  }

  Future<void> _showUpdates(
    BuildContext context,
    ExtensionsController controller,
    List<PluginRelease> pending,
  ) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          FlutterI18n.translate(dialogContext, 'extensions.updatesTitle'),
        ),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final release in pending)
                ListTile(
                  title: Text(
                    release.name.isEmpty ? release.package : release.name,
                  ),
                  subtitle: Text('${release.package} · ${release.version}'),
                  trailing: FilledButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      if (!context.mounted) return;
                      await _run(
                        context,
                        () async {
                          await controller.install(release);
                          if (!context.mounted) return;
                          _toast(
                            context,
                            '${FlutterI18n.translate(context, 'extensions.installed')}: '
                            '${release.version}',
                          );
                        },
                        errorPrefix: FlutterI18n.translate(
                          context,
                          'extensions.updateFailed',
                        ),
                      );
                    },
                    child: Text(
                      FlutterI18n.translate(context, 'extensions.install'),
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(FlutterI18n.translate(context, 'common.cancel')),
          ),
        ],
      ),
    );
  }

  /// 统一执行 + 出错 SnackBar，避免异常击穿 UI。
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action, {
    String? errorPrefix,
  }) async {
    try {
      await action();
    } catch (e) {
      if (!context.mounted) return;
      final prefix =
          errorPrefix ?? FlutterI18n.translate(context, 'common.retry');
      _toast(context, '$prefix: $e');
    }
  }

  void _toast(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
