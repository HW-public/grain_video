import 'package:flutter/material.dart';

import '../../../core/theme/tokens.dart';

/// 「我的」/设置/关于页通用白卡容器：
/// 白底、圆角 12、1px 分隔描边（50%），子项之间自动插入全宽分隔线。
///
/// 设计稿行范式见 specs/10（手机基准来自设置页 27:210~27:213）。
class MeListCard extends StatelessWidget {
  const MeListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final dividerColor = Theme.of(context).dividerColor.withValues(alpha: 0.5);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(color: dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Container(height: 1, color: dividerColor),
            children[i],
          ],
        ],
      ),
    );
  }
}
