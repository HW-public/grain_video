import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../providers/player_providers.dart';

/// 亮底弹层骨架（选集/倍速共用）：surface 底 + 深色文字，选中=主色。
/// 设计稿「播放设置」弹层范式（帧 86:225）。
Future<T?> showPlayerSheet<T>(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppTokens.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTokens.textPrimary),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                  ),
                ],
              ),
              Flexible(child: child),
            ],
          ),
        ),
      );
    },
  );
}

/// 选集弹层：剧集列表，当前集主色标记，点击换集并关闭。
Future<void> showPlayerEpSheet(BuildContext context) {
  final state = ProviderScope.containerOf(
    context,
  ).read(playerControllerProvider);
  final episodes = state.episodes;
  return showPlayerSheet(
    context,
    title: FlutterI18n.translate(context, 'player.episodes'),
    child: episodes.isEmpty
        ? Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                FlutterI18n.translate(context, 'player.emptyEpisodes'),
                style: const TextStyle(color: AppTokens.textSecondary),
              ),
            ),
          )
        : ListView.builder(
            shrinkWrap: true,
            itemCount: episodes.length,
            itemBuilder: (_, i) {
              final current = i == state.currentEpIndex;
              final title = episodes[i].title.isEmpty
                  ? '${i + 1}'
                  : episodes[i].title;
              return ListTile(
                dense: true,
                title: Text(
                  title,
                  style: TextStyle(
                    color: current
                        ? AppTokens.defaultPalette.primary
                        : AppTokens.textPrimary,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                trailing: current
                    ? Icon(Icons.check, color: AppTokens.defaultPalette.primary)
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(
                    ProviderScope.containerOf(context)
                        .read(playerControllerProvider.notifier)
                        .switchEpisode(episodes[i].url),
                  );
                },
              );
            },
          ),
  );
}

/// 倍速弹层：「播放设置」内 chips 单选（设计稿帧范式），点击立即生效并关闭。
Future<void> showPlayerSpeedSheet(BuildContext context) {
  const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
  final current = ProviderScope.containerOf(
    context,
  ).read(playerControllerProvider).rate;

  return showPlayerSheet(
    context,
    title: FlutterI18n.translate(context, 'player.settings'),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FlutterI18n.translate(context, 'player.speed'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTokens.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final speed in speeds)
              _SpeedChip(
                label: '${speed}x',
                selected: speed == current,
                onTap: () {
                  Navigator.of(context).pop();
                  unawaited(
                    ProviderScope.containerOf(
                      context,
                    ).read(playerControllerProvider.notifier).setRate(speed),
                  );
                },
              ),
          ],
        ),
      ],
    ),
  );
}

class _SpeedChip extends StatelessWidget {
  const _SpeedChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.defaultPalette.primaryContainer
              : AppTokens.surfaceAlt,
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? AppTokens.defaultPalette.primary
                : AppTokens.textSecondary,
          ),
        ),
      ),
    );
  }
}
