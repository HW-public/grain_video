import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// 「状态-空态」帧（86:201）范式：浅绿底托插画 + 主文案 18/700 +
/// 次文案 13/400 + 可选主按钮。
class MeEmptyState extends StatelessWidget {
  const MeEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String hint;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: cs.primary),
            ),
            const SizedBox(height: AppTokens.space5),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTokens.space2),
            Text(
              hint,
              style: TextStyle(
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTokens.space6),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  minimumSize: const Size(200, 44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                  ),
                ),
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyle(color: cs.onPrimary, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
