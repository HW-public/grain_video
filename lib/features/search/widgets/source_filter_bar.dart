import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../extension/plugin_manager.dart';
import '../providers/search_providers.dart';

/// 源筛选 chips 行（Figma 21:19 `.src-chips`）：横向滚动，
/// 首项「全部」+ 每个已安装插件一项（emoji + 源名）。
///
/// 选中=底主色 18% 透明+12/600 主色字；未选=surface 底无描边+12/400
/// 次文字色（onSurface 65%）。chips 高 32 圆角 16、间距 8。
/// 选中经 [searchSourceFilterProvider] 过滤结果区；空插件时整行隐藏。
class SourceFilterBar extends ConsumerWidget {
  const SourceFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(pluginManagerProvider);
    if (entries.isEmpty) return const SizedBox.shrink();

    final selected = ref.watch(searchSourceFilterProvider);

    // 帧纵向间距：搜索栏底→chips 16（栏底 padding 8 + 这里上 8）；
    // chips 底→下一区 22（这里下 10 + 历史标题上 12）。
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
      child: SizedBox(
        height: 32,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
          children: [
            _FilterChip(
              label: FlutterI18n.translate(context, 'search.filterAll'),
              selected: selected == null,
              onTap: () =>
                  ref.read(searchSourceFilterProvider.notifier).select(null),
            ),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(left: AppTokens.space2),
                child: _FilterChip(
                  label: '${emojiOf(entry.info)} ${entry.info.name}',
                  selected: selected == entry.info.package,
                  onTap: () => ref
                      .read(searchSourceFilterProvider.notifier)
                      .select(entry.info.package),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      // 选中底=主色 18% 透明（亮=浅绿底/暗=暗夜主色底），未选=surface。
      color: selected ? scheme.primary.withValues(alpha: 0.15) : scheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}
