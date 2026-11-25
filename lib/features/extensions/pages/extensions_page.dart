import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/swipe_delete_tile.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/extensions_providers.dart';
import '../routes.dart';
import '../widgets/plugin_log_sheet.dart';
import '../widgets/plugin_tile.dart';

/// 扩展管理（Figma 27:210 范式）：
/// 副标题计数 → 平铺条目卡（无站点分组、无「设置 ›」）→
/// 有更新行内「更新」药丸（进入页面静默检查）→ 左滑删除（确认弹窗）→
/// 列表下「左滑扩展可删除」提示 → 底部通栏安装按钮。
class ExtensionsPage extends ConsumerStatefulWidget {
  const ExtensionsPage({super.key});

  @override
  ConsumerState<ExtensionsPage> createState() => _ExtensionsPageState();
}

class _ExtensionsPageState extends ConsumerState<ExtensionsPage> {
  @override
  void initState() {
    super.initState();
    // 进入页面静默检查一次更新，供行内药丸/可更新状态展示。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pendingUpdatesProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(pluginManagerProvider);
    final pending = ref.watch(pendingUpdatesProvider);
    final controller = ref.watch(extensionsControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'nav.extensions')),
        actions: [
          IconButton(
            tooltip: FlutterI18n.translate(context, 'extensions.reload'),
            icon: const Icon(Icons.refresh),
            onPressed: () => _run(context, () async {
              await controller.reload();
              await ref.read(pendingUpdatesProvider.notifier).refresh();
              if (!context.mounted) return;
              _toast(
                context,
                FlutterI18n.translate(context, 'extensions.reloaded'),
              );
            }),
          ),
        ],
      ),
      body: entries.isEmpty
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
                _summaryBar(entries),
                const SizedBox(height: AppTokens.space3),
                for (final entry in entries) ...[
                  SwipeDeleteTile(
                    confirmTitleKey: 'extensions.delete',
                    confirmHintKey: 'extensions.deleteHint',
                    labelKey: 'extensions.delete',
                    child: PluginTile(
                      entry: entry,
                      release: pending[entry.info.package],
                      onTap: () => PluginLogSheet.show(
                        context,
                        site: siteOfEntry(entry),
                        logs: controller.logsOf(entry),
                      ),
                      onUpdate: () => _run(
                        context,
                        () async {
                          final release = pending[entry.info.package];
                          if (release == null) return;
                          await controller.install(release);
                          await ref
                              .read(pendingUpdatesProvider.notifier)
                              .refresh();
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
                      ),
                    ),
                    onDelete: () => _run(context, () async {
                      await controller.remove(entry);
                      if (!context.mounted) return;
                      _toast(
                        context,
                        FlutterI18n.translate(context, 'extensions.removed'),
                      );
                    }),
                  ),
                  const SizedBox(height: AppTokens.space2),
                ],
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppTokens.space2,
                    left: AppTokens.space1,
                  ),
                  child: Text(
                    FlutterI18n.translate(context, 'extensions.swipeToDelete'),
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
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
              backgroundColor: cs.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
              ),
            ),
            onPressed: () => context.push(ExtensionsRoutes.repo),
            child: Text(
              FlutterI18n.translate(context, 'extensions.installButton'),
              style: TextStyle(color: cs.onPrimary, fontSize: 14),
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryBar(List<PluginEntry> entries) {
    final sites = entries.map(siteOfEntry).toSet();
    return Builder(
      builder: (context) {
        return Text(
          FlutterI18n.translate(
            context,
            'extensions.summary',
            translationParams: {
              'count': '${entries.length}',
              'sites': '${sites.length}',
            },
          ),
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.65),
          ),
        );
      },
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
