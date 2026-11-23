import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/tokens.dart';
import 'app_release.dart';
import 'app_updater.dart';

/// 更新弹窗：版本信息 + release notes + 下载进度 + 安装。
///
/// 强制更新（release.force）时隐藏「以后再说」且禁止点外部关闭。
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
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    // 当前版本异步补读（弹窗先弹出版本对比占位）。
    AppUpdater.currentVersion().then((v) {
      if (mounted) setState(() => _currentVersion = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final release = widget.release;
    final downloading = _progress != null;
    return PopScope(
      canPop: !release.force,
      child: AlertDialog(
        title: Text(FlutterI18n.translate(context, 'update.newVersion')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FlutterI18n.translate(
                context,
                'update.versionLine',
                translationParams: {
                  'current': _currentVersion.isEmpty ? '…' : _currentVersion,
                  'latest': release.version,
                },
              ),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTokens.textPrimary,
              ),
            ),
            if (release.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    release.notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
            if (downloading) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 4),
              Text(
                '${((_progress ?? 0) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTokens.textTertiary,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!release.force)
            TextButton(
              onPressed: downloading ? null : () => Navigator.of(context).pop(),
              child: Text(FlutterI18n.translate(context, 'update.later')),
            ),
          FilledButton(
            onPressed: downloading ? null : _downloadAndInstall,
            child: Text(
              downloading
                  ? FlutterI18n.translate(context, 'update.downloading')
                  : FlutterI18n.translate(context, 'update.now'),
            ),
          ),
        ],
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
