import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// 顶部搜索栏（Figma 21:19 `.searchbar`，390×844）。
///
/// 白底 pill（高 44、圆角 22），无描边无阴影（帧只画单态，不自加聚焦态）。
/// 左侧 🔍 文本 14px 弱色灰、左内边距 16；输入/placeholder 13/400 次文字色；
/// 右侧「搜索」13/600 主色纯文字，右内边距 34。文本变化经 [onChanged] 由页面
/// 防抖，点「搜索」或键盘提交走 [onSubmitted]。
class SearchInputBar extends StatelessWidget {
  const SearchInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.submitLabel,
    this.onChanged,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  /// 右侧「搜索」按钮文案（i18n search.search）。
  final String submitLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        AppTokens.space2,
        AppTokens.space4,
        AppTokens.space2,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(left: AppTokens.space4),
              child: Text(
                '🔍',
                style: TextStyle(fontSize: 14, color: AppTokens.textTertiary),
              ),
            ),
            Expanded(
              // 焦点由 SearchPage 在 tab 可见时请求（见 AppTabScope），
              // 分支常驻树后 autofocus 会抢启动焦点。
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppTokens.textSecondary,
                ),
                cursorColor: primary,
                cursorWidth: 2,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                  ),
                  hintText: hint,
                  hintStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppTokens.textSecondary,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            Padding(
              // 帧右内边距 34（容器外已有水平 16）。
              padding: const EdgeInsets.only(right: 18),
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 44),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => onSubmitted?.call(controller.text),
                child: Text(
                  submitLabel,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
