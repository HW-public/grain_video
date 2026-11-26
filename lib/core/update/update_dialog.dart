import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/tokens.dart';
import 'app_release.dart';
import 'app_updater.dart';

/// 更新弹窗（帧 142:128）：居中标题 + 主色版本号 + 圆点更新日志 +
/// 稍后（描边）/ 立即更新（实心）双按钮 + 下载进度。
///
/// 强制更新（release.force）时隐藏「稍后」且禁止点外部关闭。
class AppUpdateDialog extends StatefulWidget {
  const AppUpdateDialog({super.key, required this.release});

  final AppRelease release;

  /// 弹出更新弹窗。
  static Future<void> show(BuildContext context, AppRelease release) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !release.force,
      builder: (_) => AppUpdateDialog(release: release),
    );
  }

  @override
  State<AppUpdateDialog> createState() => _AppUpdateDialogState();
}

class _AppUpdateDialogState extends State<AppUpdateDialog> {
  double? _progress;

  /// release notes 按行拆条（去掉行首 - / · / * 前缀，统一圆点呈现）。
  List<String> get _noteLines => widget.release.notes
      .split('\n')
      .map((l) => l.trim().replaceFirst(RegExp('^[-·*•]\\s*'), ''))
      .where((l) => l.isNotEmpty)
      .toList();

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final downloading = _progress != null;
    final cs = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !release.force,
      child: Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题 + 版本号（帧：居中，版本号主色）。
              Text(
                FlutterI18n.translate(context, 'update.newVersion'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v${release.version}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              if (_noteLines.isNotEmpty) ...[
                const SizedBox(height: 14),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final line in _noteLines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '· ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurface.withValues(alpha: 0.65),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: cs.onSurface.withValues(
                                        alpha: 0.65,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              if (downloading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${((_progress ?? 0) * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // 按钮行（帧：稍后=描边，立即更新=实心主色，等高 44）。
              Row(
                children: [
                  if (!release.force)
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: cs.onSurface,
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusButton,
                            ),
                          ),
                        ),
                        onPressed: downloading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          FlutterI18n.translate(context, 'update.later'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (!release.force) const SizedBox(width: 12),
                  Expanded(
                    flex: release.force ? 1 : 1,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusButton,
                          ),
                        ),
                      ),
                      onPressed: downloading ? null : _downloadAndInstall,
                      child: Text(
                        downloading
                            ? FlutterI18n.translate(
                                context,
                                'update.downloading',
                              )
                            : FlutterI18n.translate(context, 'update.now'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAndInstall() async {
    try {
      final apk = await AppUpdater.downloadApk(
        widget.release,
        onProgress: (p) => setState(() => _progress = p),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await AppUpdater.installApk(apk);
    } on Object catch (e) {
      if (mounted) {
        setState(() => _progress = null);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
