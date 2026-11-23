import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import 'app_updater.dart';
import 'update_dialog.dart';

/// App 升级检查统一入口。
///
/// [silent]=true（启动自动检查）：失败静默、无新版不打扰；
/// false（关于页手动）：失败/已最新都给 SnackBar 反馈。
Future<void> checkAppUpdate(BuildContext context, {bool silent = false}) async {
  void feedback(String key) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(FlutterI18n.translate(context, key))),
    );
  }

  try {
    final release = await AppUpdater.fetchLatestRelease();
    if (!await AppUpdater.isUpdateAvailable(release)) {
      if (!silent) feedback('me.aboutUpToDate');
      return;
    }
    if (context.mounted) await AppUpdateDialog.show(context, release);
  } on Object {
    if (!silent) feedback('update.checkFailed');
  }
}
