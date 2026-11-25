import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';
import '../../../extension/plugin_manager.dart';
import '../../../extension/plugin_updater.dart';
import '../providers/extensions_providers.dart';

/// 扩展仓库（Figma 131:146 范式）：搜索 pill + 仓库清单卡
/// （icon 48/名称/作者·版本/右侧状态药丸：安装/更新/已安装/安装中）。
///
/// 帧内分类 chips 与评分/简介行未实现——清单 manifest 无分类/评分/简介
/// 字段（记偏离）；搜索按名称/包名/站点过滤为真功能。
class ExtensionsRepoPage extends ConsumerStatefulWidget {
  const ExtensionsRepoPage({super.key});

  @override
  ConsumerState<ExtensionsRepoPage> createState() => _ExtensionsRepoPageState();
}

class _ExtensionsRepoPageState extends ConsumerState<ExtensionsRepoPage> {
  final _query = ValueNotifier('');

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// 导入本地 `.wasm`（管理页顶栏按设计稿只留刷新，导入入口移到这里）。
  Future<void> _importDialog(BuildContext context) async {
    final controller = ref.read(extensionsControllerProvider);
    final path = await showDialog<String>(
      context: context,
      builder: (_) => const _ImportPathDialog(),
    );
    final trimmed = path?.trim() ?? '';
    if (trimmed.isEmpty || !context.mounted) return;
    // 异步前取好 messenger 与文案前缀，后续不再跨 gap 用 context。
    final messenger = ScaffoldMessenger.of(context);
    final importedPrefix = FlutterI18n.translate(
      context,
      'extensions.imported',
    );
    final failedPrefix = FlutterI18n.translate(
      context,
      'extensions.importFailed',
    );
    String message;
    try {
      final imported = await controller.importWasm(trimmed);
      ref.invalidate(pluginManagerProvider);
      ref.invalidate(repoManifestProvider);
      message =
          '$importedPrefix: ${imported.info.name} '
          '${imported.info.version}';
    } catch (e) {
      message = '$failedPrefix: $e';
    }
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _install(PluginRelease release) async {
    final controller = ref.read(extensionsControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    final installedPrefix = FlutterI18n.translate(
      context,
      'extensions.installed',
    );
    final failedPrefix = FlutterI18n.translate(
      context,
      'extensions.updateFailed',
    );
    String message;
    try {
      await controller.install(release);
      ref.invalidate(repoManifestProvider);
      ref.invalidate(pendingUpdatesProvider);
      ref.invalidate(pluginManagerProvider);
      message = '$installedPrefix: ${release.version}';
    } catch (e) {
      message = '$failedPrefix: $e';
    }
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final manifest = ref.watch(repoManifestProvider);
    final installed = ref.watch(pluginManagerProvider);
    final pending = ref.watch(pendingUpdatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'extensions.repoTitle')),
        actions: [
          // 本地 .wasm 导入入口（管理页顶栏已按设计稿只留刷新）。
          IconButton(
            tooltip: FlutterI18n.translate(context, 'extensions.import'),
            icon: const Icon(Icons.upload_file_outlined),
            onPressed: () => _importDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.space4,
              AppTokens.space2,
              AppTokens.space4,
              AppTokens.space3,
            ),
            child: ValueListenableBuilder<String>(
              valueListenable: _query,
              builder: (context, query, _) {
                return TextField(
                  onChanged: (value) => _query.value = value,
                  decoration: InputDecoration(
                    hintText: FlutterI18n.translate(
                      context,
                      'extensions.repoSearchHint',
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppTokens.space3,
                      vertical: AppTokens.space3,
                    ),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => _query.value = '',
                          ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: AsyncView<List<PluginRelease>>(
              value: manifest,
              builder: (context, releases) {
                final query = _query.value.trim().toLowerCase();
                final visible = query.isEmpty
                    ? releases
                    : releases
                          .where(
                            (r) =>
                                r.name.toLowerCase().contains(query) ||
                                r.package.toLowerCase().contains(query) ||
                                r.site.toLowerCase().contains(query),
                          )
                          .toList();
                if (visible.isEmpty) {
                  return EmptyState(
                    icon: Icons.inventory_2_outlined,
                    message: FlutterI18n.translate(
                      context,
                      'extensions.repoEmpty',
                    ),
                  );
                }
                final installedPkgs = installed
                    .map((e) => e.info.package)
                    .toSet();
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppTokens.space4,
                    0,
                    AppTokens.space4,
                    AppTokens.space6,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppTokens.space3),
                  itemBuilder: (context, index) {
                    final release = visible[index];
                    final isInstalled = installedPkgs.contains(release.package);
                    return _RepoCard(
                      release: release,
                      installed: isInstalled,
                      // pendingUpdates 含未安装项：只有已安装才算可更新。
                      updatable:
                          isInstalled && pending.containsKey(release.package),
                      onInstall: () => _install(release),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 仓库卡（帧 131:168 范式）：白 r12 高 96，icon 48 r12（品牌绿按包名哈希），
/// 名称 14/600 + 站点·版本 12 muted，右侧 80×36 r999 状态药丸。
class _RepoCard extends StatefulWidget {
  const _RepoCard({
    required this.release,
    required this.installed,
    required this.updatable,
    required this.onInstall,
  });

  final PluginRelease release;

  /// 同包名已安装（任意版本）。
  final bool installed;

  /// 已安装且清单版本更高。
  final bool updatable;
  final Future<void> Function() onInstall;

  @override
  State<_RepoCard> createState() => _RepoCardState();
}

class _RepoCardState extends State<_RepoCard> {
  var _installing = false;

  static const _iconColors = [
    Color(0xFF9CE4B4),
    Color(0xFF6CE5B0),
    Color(0xFF45AB66),
    Color(0xFF2FAE7E),
  ];

  Color get _iconColor {
    final pkg = widget.release.package;
    var hash = 0;
    for (final code in pkg.codeUnits) {
      hash = (hash + code) % _iconColors.length;
    }
    return _iconColors[hash];
  }

  Future<void> _tap() async {
    setState(() => _installing = true);
    try {
      await widget.onInstall();
    } finally {
      if (mounted) setState(() => _installing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4 - 4),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _iconColor,
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            ),
            child: const Icon(
              Icons.extension_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  release.name.isEmpty ? release.package : release.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${release.site.isEmpty ? release.package : release.site} · '
                  'v${release.version}',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _buildButton(),
        ],
      ),
    );
  }

  /// 状态药丸：安装中(转圈) > 更新(主色描边) > 已安装(灰底) > 安装(主色底)。
  Widget _buildButton() {
    final cs = Theme.of(context).colorScheme;
    if (_installing) {
      return const SizedBox(
        width: 80,
        height: 36,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (widget.updatable) {
      return OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary),
          minimumSize: const Size(80, 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          ),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: _tap,
        child: Text(
          FlutterI18n.translate(context, 'extensions.update'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      );
    }
    if (widget.installed) {
      return Container(
        width: 80,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: cs.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        ),
        child: Text(
          FlutterI18n.translate(context, 'extensions.installedBadge'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      );
    }
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        minimumSize: const Size(80, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: _tap,
      child: Text(
        FlutterI18n.translate(context, 'extensions.install'),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 导入路径输入弹窗：TextEditingController 随元素创建/销毁。
/// 控制器若由调用方在外部 dispose，弹窗 pop 后元素尚未卸载，
/// dispose 触发的置空通知会让仍挂载的 InputDecorator 带着 dirty 状态
/// 被 deactivate（framework 断言「Tried to build dirty widget in the
/// wrong build scope」）；交给 State 生命周期后 dispose 发生在卸载流程内，
/// 时序安全。
class _ImportPathDialog extends StatefulWidget {
  const _ImportPathDialog();

  @override
  State<_ImportPathDialog> createState() => _ImportPathDialogState();
}

class _ImportPathDialogState extends State<_ImportPathDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(FlutterI18n.translate(context, 'extensions.import')),
      content: TextField(
        controller: _controller,
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
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(FlutterI18n.translate(context, 'common.confirm')),
        ),
      ],
    );
  }
}
