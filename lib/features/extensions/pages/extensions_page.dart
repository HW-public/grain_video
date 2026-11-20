import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../extension/plugin_manager.dart';
import '../../../extension/plugin_updater.dart';
import '../providers/extensions_providers.dart';
import '../widgets/plugin_log_sheet.dart';
import '../widgets/plugin_tile.dart';

/// 扩展管理（对齐设计稿「设置-扩展管理」）：
/// 薄荷页面底 + 白色圆角条目卡 + 右侧绿色设置链接 + 底部通栏主按钮。
class ExtensionsPage extends ConsumerWidget {
  const ExtensionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(installedGroupsProvider);
    final controller = ref.watch(extensionsControllerProvider);

    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        backgroundColor: AppTokens.defaultPalette.pageBg,
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
        ],
      ),
      body: groups.isEmpty
          ? EmptyState(
              icon: Icons.extension_outlined,
              message: FlutterI18n.translate(context, 'extensions.empty'),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.space4,
                AppTokens.space2,
                AppTokens.space4,
                AppTokens.space6,
              ),
              children: [
                _summaryBar(groups: groups),
                const SizedBox(height: AppTokens.space3),
                for (final group in groups) ...[
                  for (final entry in group.variants) ...[
                    PluginTile(
                      entry: entry,
                      onOpen: () =>
                          _openPluginMenu(context, controller, group, entry),
                    ),
                    const SizedBox(height: AppTokens.space2),
                  ],
                ],
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space2,
            AppTokens.space4,
            AppTokens.space4,
          ),
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.defaultPalette.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
              ),
            ),
            onPressed: () => _installMenu(context, controller),
            child: Text(
              FlutterI18n.translate(context, 'extensions.installButton'),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryBar({required List<SiteGroup> groups}) {
    final count = groups.fold<int>(0, (sum, g) => sum + g.variants.length);
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final sites = groups.map((g) => g.site).toSet();
        return Text(
          FlutterI18n.translate(
            context,
            'extensions.summary',
            translationParams: {'count': '$count', 'sites': '${sites.length}'},
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTokens.textSecondary,
            fontSize: 12,
          ),
        );
      },
    );
  }

  /// 条目设置菜单：日志 / 更新（若有）/ 删除。
  Future<void> _openPluginMenu(
    BuildContext context,
    ExtensionsController controller,
    SiteGroup group,
    PluginEntry entry,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(FlutterI18n.translate(context, 'extensions.logs')),
              onTap: () => Navigator.of(sheetContext).pop('logs'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(FlutterI18n.translate(context, 'extensions.delete')),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    switch (action) {
      case 'logs':
        PluginLogSheet.show(
          context,
          site: group.site,
          logs: controller.logsOfGroup(group),
        );
      case 'delete':
        await _confirmRemove(context, controller, entry);
    }
  }

  /// 底部主按钮菜单：导入本地 / 检查更新。
  Future<void> _installMenu(
    BuildContext context,
    ExtensionsController controller,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(FlutterI18n.translate(context, 'extensions.import')),
              onTap: () => Navigator.of(sheetContext).pop('import'),
            ),
            ListTile(
              leading: const Icon(Icons.system_update_alt),
              title: Text(
                FlutterI18n.translate(context, 'extensions.checkUpdates'),
              ),
              onTap: () => Navigator.of(sheetContext).pop('updates'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;

    switch (action) {
      case 'import':
        await _importDialog(context, controller);
      case 'updates':
        await _checkUpdates(context, controller);
    }
  }

  Future<void> _importDialog(
    BuildContext context,
    ExtensionsController controller,
  ) async {
    final pathController = TextEditingController();
    final path = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(FlutterI18n.translate(context, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(pathController.text),
            child: Text(FlutterI18n.translate(context, 'common.confirm')),
          ),
        ],
      ),
    );
    pathController.dispose();
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;

    await _run(
      context,
      () async {
        final imported = await controller.importWasm(trimmed);
        if (!context.mounted) return;
        _toast(
          context,
          '${FlutterI18n.translate(context, 'extensions.imported')}: '
          '${imported.info.name} ${imported.info.version}',
        );
      },
      errorPrefix: FlutterI18n.translate(context, 'extensions.importFailed'),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    ExtensionsController controller,
    PluginEntry entry,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(FlutterI18n.translate(context, 'extensions.delete')),
        content: Text(FlutterI18n.translate(context, 'extensions.deleteHint')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(FlutterI18n.translate(context, 'common.cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
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
