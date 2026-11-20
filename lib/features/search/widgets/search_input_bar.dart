import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// 顶部搜索栏（规格 04 SearchBar 变体：搜索页未聚焦态）。
///
/// 白色胶囊容器 + 999 圆角；聚焦描边主题主色，未聚焦描边分隔线色；
/// 框内搜索图标、清空 ×（有文字时出现）。文本变化经 [onChanged] 回调
/// 由页面防抖，键盘提交走 [onSubmitted]。
class SearchInputBar extends StatelessWidget {
  const SearchInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = focusNode.hasFocus;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space4,
        vertical: AppTokens.space2,
      ),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          border: Border.all(
            color: focused ? scheme.primary : AppTokens.divider,
          ),
          boxShadow: focused
              ? const [
                  BoxShadow(
                    color: Color(0x141F9E6E),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: true,
          textInputAction: TextInputAction.search,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: const TextStyle(fontSize: 13, color: AppTokens.textPrimary),
          cursorColor: scheme.primary,
          cursorWidth: 2,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppTokens.textTertiary,
            ),
            prefixIcon: const Icon(
              Icons.search,
              size: 18,
              color: AppTokens.textTertiary,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 44,
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 16,
                      color: AppTokens.textTertiary,
                    ),
                    onPressed: () {
                      controller.clear();
                      onClear?.call();
                    },
                  ),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}
