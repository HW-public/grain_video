import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// 确认对话框（帧 86:247 范式）：居中粗标题 + 居中灰副标 + 分隔线 +
/// 双文字按钮（取消灰 / 确认主色粗体，危险操作传 danger）。
/// 返回 true=确认，false/null=取消。
Future<bool?> showAppConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String cancelLabel,
  required String confirmLabel,
  bool danger = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;
      return Dialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 6),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ),
            if (message != null && message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
            Divider(height: 1, color: Theme.of(dialogContext).dividerColor),
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppTokens.radiusCard),
                      ),
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Center(
                        child: Text(
                          cancelLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: Theme.of(dialogContext).dividerColor,
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(AppTokens.radiusCard),
                      ),
                      onTap: () => Navigator.of(dialogContext).pop(true),
                      child: Center(
                        child: Text(
                          confirmLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: danger ? AppTokens.danger : cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// 轻提示 Toast（帧 86:247 底部范式）：深色胶囊 + 前置图标，2s 自动消失。
/// 用于收藏/清理等轻量反馈，替代默认 SnackBar 的直角长条。
void showAppToast(
  BuildContext context,
  String message, {
  IconData icon = Icons.check,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (toastContext) => Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(toastContext).size.height * 0.18,
      child: Center(
        child: _ToastPill(message: message, icon: icon),
      ),
    ),
  );
  overlay.insert(entry);
  Future<void>.delayed(const Duration(seconds: 2), entry.remove);
}

class _ToastPill extends StatelessWidget {
  const _ToastPill({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2A26).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
