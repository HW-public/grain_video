import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/exceptions/error_text.dart';
import '../providers/player_providers.dart';
import '../widgets/player_video_area.dart';

/// 播放页：竖屏（视频区 + 标题/剧集信息 body）⇄ 横屏（全屏沉浸）。
///
/// 进入时按 queryParams 取流（ep/src/title/bangumi）；退出（返回）前落库
/// 并恢复方向与系统栏。取流失败显示错误态 + 重试。
class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key, required this.args});

  final PlayerArgs args;

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  bool _immersive = false;
  bool _controlsVisible = false;
  Timer? _progressTimer;

  /// build() 期缓存 notifier，dispose 里禁用 ref（riverpod 3 规则）。
  PlayerController? _controller;

  PlayerController get controller {
    final c = _controller;
    if (c != null) return c;
    // riverpod 3.3 的 WidgetRef 读取 notifier 类型可空，实际 build 期必已初始化。
    return _controller = ref.read(playerControllerProvider.notifier)!;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(controller.load(widget.args));
      }
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    // 退出播放页：先暂停单例 Player（否则返回后视频还在出声），再落库。
    _controller?.pauseOnExit();
    unawaited(_controller?.saveProgress());
    unawaited(_restoreOrientations());
    super.dispose();
  }

  /// 起播后开始 5s 周期落库；出错/未起播时停表。
  void _syncProgressTimer(PlayerViewState state) {
    final active = state.isReady && state.started;
    if (active && _progressTimer == null) {
      _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        unawaited(controller.saveProgress());
      });
    } else if (!active && _progressTimer != null) {
      _progressTimer!.cancel();
      _progressTimer = null;
    }
  }

  Future<void> _enterImmersive() async {
    setState(() {
      _immersive = true;
      _controlsVisible = true;
    });
    await _setOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    ).catchError((Object _) => SystemUiMode.manual);
  }

  Future<void> _exitImmersive() async {
    setState(() => _immersive = false);
    await _restoreOrientations();
  }

  Future<void> _restoreOrientations() async {
    await _setOrientations(const [DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    ).catchError((Object _) => SystemUiMode.manual);
  }

  /// 测试环境下平台通道无响应，吞掉异常即可。
  Future<void> _setOrientations(List<DeviceOrientation> orientations) {
    return SystemChrome.setPreferredOrientations(
      orientations,
    ).catchError((Object _) => <void>[]);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider);
    _syncProgressTimer(state);

    if (state.loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }
    if (state.hasError) return _PlayerErrorView(error: state.error!);

    return _immersive ? _buildLandscape(state) : _buildPortrait(state);
  }

  /// 竖屏：顶部 16:9 视频区（darkBg 留黑，点击浮现控制层）
  /// + 下方标题/剧集信息（亮底 body，圆角顶角）。
  Widget _buildPortrait(PlayerViewState state) {
    final args = state.args;
    final cs = Theme.of(context).colorScheme;
    final episodeTitle = ref
        .read(playerControllerProvider.notifier)
        .currentEpisodeTitle;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: AppTokens.coverRatioVideo,
            child: PlayerVideoArea(
              title: args.title,
              controlsVisible: _controlsVisible,
              onToggleControls: () =>
                  setState(() => _controlsVisible = !_controlsVisible),
              onFullscreen: _enterImmersive,
              // 竖屏顶栏返回（帧 21:18 左上 ‹）。
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          episodeTitle.isEmpty
                              ? args.title
                              : '${args.title} · $episodeTitle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (args.src.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusChip,
                            ),
                          ),
                          child: Text(
                            args.src,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.episodes.isNotEmpty) ...[
                    Text(
                      FlutterI18n.translate(context, 'player.episodes'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _EpisodeGrid(
                      currentIndex: state.currentEpIndex,
                      onSelect: (url) => unawaited(
                        ref
                            .read(playerControllerProvider.notifier)
                            .switchEpisode(url),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (state.description.isNotEmpty) ...[
                    Text(
                      FlutterI18n.translate(context, 'player.synopsis'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.description,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.7,
                        color: cs.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 横屏：全屏视频 + 顶部/底部遮罩控制条，‹ 逐级返回。
  Widget _buildLandscape(PlayerViewState state) {
    return Scaffold(
      backgroundColor: AppTokens.darkBg,
      body: PopScope(
        // 横屏下返回键先退出全屏，再退页面。
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) unawaited(_exitImmersive());
        },
        child: PlayerVideoArea(
          title: state.args.title,
          immersive: true,
          controlsVisible: _controlsVisible,
          onToggleControls: () =>
              setState(() => _controlsVisible = !_controlsVisible),
          onBack: () => unawaited(_exitImmersive()),
        ),
      ),
    );
  }
}

/// 竖屏剧集网格（4 列，当前集=主色字 + 浅绿底，同详情页 EpGrid 范式）。
class _EpisodeGrid extends ConsumerWidget {
  const _EpisodeGrid({required this.currentIndex, required this.onSelect});

  final int currentIndex;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episodes = ref.watch(playerControllerProvider).episodes;
    final cs = Theme.of(context).colorScheme;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 16 / 9,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, i) {
        final current = i == currentIndex;
        return InkWell(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          onTap: () => onSelect(episodes[i].url),
          child: Container(
            decoration: BoxDecoration(
              color: current
                  ? cs.primary.withValues(alpha: 0.15)
                  : cs.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              border: Border.all(
                color: current ? cs.primary : Theme.of(context).dividerColor,
              ),
            ),
            child: Center(
              child: Text(
                episodes[i].title.isEmpty ? '${i + 1}' : episodes[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: current
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 错误态：错误信息 + 重试（取流失败 GrainException 等）。
class _PlayerErrorView extends ConsumerWidget {
  const _PlayerErrorView({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
              const SizedBox(height: 12),
              // 错误文案分层（D5）：友好主文案 + 技术细节小字。
              Text(
                friendlyError(context, error),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => unawaited(
                  ref
                      .read(playerControllerProvider.notifier)
                      .load(ref.read(playerControllerProvider).args),
                ),
                child: Text(FlutterI18n.translate(context, 'common.retry')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
