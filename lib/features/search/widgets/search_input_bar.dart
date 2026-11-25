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
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;

  /// 右侧「搜索」按钮文案（i18n search.search）。
  final String submitLabel;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// 点按清除 ×：清空输入并复位结果区（回到初始态）。
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = cs.primary;
    final weakColor = cs.onSurface.withValues(alpha: 0.45);
    final subColor = cs.onSurface.withValues(alpha: 0.65);

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
          color: cs.surface,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: AppTokens.space4),
              child: Text(
                '🔍',
                style: TextStyle(fontSize: 14, color: weakColor),
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: subColor,
                ),
                cursorColor: primary,
                cursorWidth: 2,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space2,
                  ),
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: subColor,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            // 有内容时显示清除 ×（用户要求；帧未画此 icon）。
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: AppTokens.space1),
                  child: GestureDetector(
                    onTap: () {
                      controller.clear();
                      onChanged?.call('');
                      onClear?.call();
                    },
                    child: Icon(Icons.cancel, size: 16, color: weakColor),
                  ),
                );
              },
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
