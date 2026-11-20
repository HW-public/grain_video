import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// 分区标题行（设计稿 4:31）：左主文字标题，右侧可选操作。
/// 字号字重为用户拍板（2026-11-20）：14/500，帧原值 16/700 偏大偏粗。
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space4,
        AppTokens.space4,
        11, // 帧规格：标题 → 卡间距 11。
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTokens.textPrimary,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 分区行内空态（整个分区占位居中显示）。
class SectionEmpty extends StatelessWidget {
  const SectionEmpty({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 12, color: AppTokens.textTertiary),
        ),
      ),
    );
  }
}

/// 分区加载态：横向卡片高度的占位进度条。
class SectionLoading extends StatelessWidget {
  const SectionLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 130,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

/// 分区错误态：错误信息 + 重试。
class SectionError extends StatelessWidget {
  const SectionError({super.key, required this.error, this.onRetry});

  final Object error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error.toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppTokens.danger),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}
