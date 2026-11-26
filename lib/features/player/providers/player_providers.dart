import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../../core/settings/app_settings.dart';
import '../../../data/db/repositories.dart';
import '../../../extension/models.dart';
import '../../../extension/plugin_manager.dart';

/// 播放页入参（queryParams：ep/src/title/bangumi）。
class PlayerArgs {
  const PlayerArgs({
    this.ep = '',
    this.src = '',
    this.title = '',
    this.bangumi = '',
  });

  /// 剧集 url（插件私有串，原样传给 callWatch）。
  final String ep;

  /// 插件 package。
  final String src;

  /// 条目标题。
  final String title;

  /// 条目 url。
  final String bangumi;

  /// ep + src 齐备才允许发起取流。
  bool get isValid => ep.isNotEmpty && src.isNotEmpty;

  PlayerArgs copyWith({String? ep}) =>
      PlayerArgs(ep: ep ?? this.ep, src: src, title: title, bangumi: bangumi);
}

/// 播放器视图状态（取流/选集维度；播放位置走 [Player] 流）。
class PlayerViewState {
  const PlayerViewState({
    this.args = const PlayerArgs(),
    this.loading = false,
    this.error,
    this.episodes = const [],
    this.currentEpIndex = -1,
    this.description = '',
    this.cover = '',

    /// 真实起播（position > 0 && duration > 0 的首个 tick）。
    this.started = false,
    this.rate = 1.0,

    /// 横屏锁屏（帧 21:21 控制条「锁屏」）：锁定后手势与控制层全部关闭。
    this.locked = false,
  });

  final PlayerArgs args;
  final bool loading;
  final Object? error;
  final List<Episode> episodes;
  final int currentEpIndex;

  /// 条目简介（callDetail 顺带返回；竖屏 body「简介」区）。
  final String description;

  /// 条目封面（callDetail 返回；进度落库时写入历史/追番，首页轮播用）。
  final String cover;
  final bool started;
  final double rate;
  final bool locked;

  bool get hasError => error != null;
  bool get isReady => !loading && error == null && args.isValid;

  PlayerViewState copyWith({
    PlayerArgs? args,
    bool? loading,
    Object? error = _sentinel,
    List<Episode>? episodes,
    int? currentEpIndex,
    String? description,
    String? cover,
    bool? started,
    double? rate,
    bool? locked,
  }) {
    return PlayerViewState(
      args: args ?? this.args,
      loading: loading ?? this.loading,
      error: identical(error, _sentinel) ? this.error : error,
      episodes: episodes ?? this.episodes,
      currentEpIndex: currentEpIndex ?? this.currentEpIndex,
      description: description ?? this.description,
      cover: cover ?? this.cover,
      started: started ?? this.started,
      rate: rate ?? this.rate,
      locked: locked ?? this.locked,
    );
  }

  static const Object _sentinel = Object();
}

/// 预加载解析结果缓存：episodeUrl → StreamInfo。
///
/// 起播当前集后后台 callWatch 下一集（L1），命中后换集免解析等待；
/// 同时把下一集追加进播放单（L2，mpv 预缓冲）。
class PreloadedStreams extends Notifier<Map<String, StreamInfo>> {
  @override
  Map<String, StreamInfo> build() => const {};

  void store(String episodeUrl, StreamInfo info) {
    state = {...state, episodeUrl: info};
  }

  /// 取出并移除（换集消费）。
  StreamInfo? take(String episodeUrl) {
    final info = state[episodeUrl];
    if (info != null) {
      state = Map.of(state)..remove(episodeUrl);
    }
    return info;
  }

  void clear() => state = const {};
}

final preloadedStreamsProvider =
    NotifierProvider<PreloadedStreams, Map<String, StreamInfo>>(
      PreloadedStreams.new,
    );

/// 单例 [Player]：换集只 open()，绝不 dispose 重建
/// （Windows 上重建 VideoController 会挂约 200 秒，见 spike-media-kit）。
final playerProvider = Provider<Player>((ref) {
  final player = Player();
  // 缓冲调优必须在首次 open 之前完成（demuxer 属性只在建流时生效）。
  // 应用启动时 native 初始化快速完成，无起播竞态；失败静默（测试 stub）。
  unawaited(_tuneBuffering(player));
  ref.onDispose(player.dispose);
  return player;
});

/// mpv 缓冲调优：默认 demuxer 前读偏保守，高码率源周期性欠载卡顿。
/// 仅原生端生效（导出层 NativePlayer 是条件桩，dynamic 直达 + 超时兜底）。
Future<void> _tuneBuffering(Player player) async {
  try {
    final native = player as dynamic;
    const timeout = Duration(seconds: 2);
    await native
        .setProperty('demuxer-readahead-secs', '30')
        .timeout(timeout, onTimeout: () {});
    await native
        .setProperty('demuxer-max-bytes', '157286400')
        .timeout(timeout, onTimeout: () {});
    await native
        .setProperty('demuxer-max-back-bytes', '52428800')
        .timeout(timeout, onTimeout: () {});
  } on Object {
    // 测试 stub / 非原生端：跳过调优。
  }
}

/// 单例 [VideoController]（media_kit_video 2.0.1 无 dispose，随 Player 清理）。
final videoControllerProvider = Provider<VideoController>((ref) {
  return VideoController(ref.watch(playerProvider));
});

/// 播放器控制器：取流、起播、选集、倍速、进度落库。
final playerControllerProvider =
    NotifierProvider<PlayerController, PlayerViewState>(PlayerController.new);

class PlayerController extends Notifier<PlayerViewState> {
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<String>? _errorSub;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Duration _resumePosition = Duration.zero;
  bool _seekApplied = true;

  @override
  PlayerViewState build() {
    ref.onDispose(() {
      unawaited(_positionSub?.cancel());
      unawaited(_errorSub?.cancel());
    });
    // 初始按加载中渲染：load() 在首帧后触发，避免未取流时构建视频区。
    return const PlayerViewState(loading: true);
  }

  /// 进入播放页：校验入参 → 找插件 → callWatch 取流 → callDetail 拉选集
  /// → 读历史进度 → open()。
  Future<void> load(PlayerArgs args) async {
    ref.read(preloadedStreamsProvider.notifier).clear();
    if (!args.isValid) {
      state = PlayerViewState(
        args: args,
        error: StateError('missing player params'),
      );
      return;
    }
    state = PlayerViewState(args: args, loading: true);
    // 下载管理：本地已下载文件直放，不走路插件解析（无选集/不预载）。
    if (File(args.ep).existsSync()) {
      // media_kit/mpv 对本地文件要求 file:// URI（裸绝对路径在 Android
      // 上报 Failed to recognize file format）；Windows 路径转 file:///C:/...
      var localUrl = args.ep.replaceAll('\\', '/');
      if (!localUrl.startsWith('/')) localUrl = '/$localUrl';
      state = state.copyWith(loading: false);
      await _open(StreamInfo(url: 'file://$localUrl'), resumeMs: 0);
      return;
    }
    try {
      final manager = ref.read(pluginManagerProvider.notifier);
      final entries = ref.read(pluginManagerProvider);
      final entry = entries
          .where((e) => e.info.package == args.src)
          .firstOrNull;
      if (entry == null) {
        throw StateError('plugin not installed: ${args.src}');
      }
      final stream = await manager.callWatch(entry, args.ep);
      if (stream == null) {
        throw StateError('plugin returned no stream');
      }

      var episodes = const <Episode>[];
      var index = -1;
      var description = '';
      var cover = '';
      try {
        final detail = await manager.callDetail(entry, args.bangumi);
        if (detail != null) {
          episodes = detail.episodes;
          index = episodes.indexWhere((e) => e.url == args.ep);
          description = detail.description;
          cover = detail.cover;
        }
      } on Object {
        // detail 未实现/失败：选集列表留空，不影响播放。
      }

      final history = await ref
          .read(watchHistoryRepositoryProvider)
          .forBangumi(args.src, args.bangumi);
      var resumeMs = 0;
      for (final h in history) {
        if (h.episodeUrl == args.ep && h.positionMs > resumeMs) {
          resumeMs = h.positionMs;
        }
      }

      state = state.copyWith(
        loading: false,
        episodes: episodes,
        currentEpIndex: index,
        description: description,
        cover: cover,
      );
      await _open(stream, resumeMs: resumeMs);
      // L1/L2：后台预载下一集（不阻塞起播）。
      unawaited(_preloadNext(entry));
    } on Object catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// 换集：复用单例 Player，只重新取流 + open()。
  Future<void> switchEpisode(String episodeUrl) async {
    final args = state.args.copyWith(ep: episodeUrl);
    final index = state.episodes.indexWhere((e) => e.url == episodeUrl);
    state = state.copyWith(
      args: args,
      loading: true,
      error: null,
      currentEpIndex: index,
      started: false,
    );
    try {
      final manager = ref.read(pluginManagerProvider.notifier);
      final entries = ref.read(pluginManagerProvider);
      final entry = entries
          .where((e) => e.info.package == args.src)
          .firstOrNull;
      if (entry == null) {
        throw StateError('plugin not installed: ${args.src}');
      }
      // 预载命中：跳过 callWatch 解析等待。
      final stream =
          ref.read(preloadedStreamsProvider.notifier).take(args.ep) ??
          await manager.callWatch(entry, args.ep);
      if (stream == null) {
        throw StateError('plugin returned no stream');
      }
      state = state.copyWith(loading: false);
      await _open(stream, resumeMs: 0);
      unawaited(_preloadNext(entry));
    } on Object catch (e) {
      state = state.copyWith(loading: false, error: e);
    }
  }

  /// L1+L2 预载下一集：开关开启、有下一集、未预载过时，
  /// 后台 callWatch 解析直链存入缓存，并追加进播放单让 mpv 预缓冲。
  Future<void> _preloadNext(PluginEntry entry) async {
    try {
      if (!ref.read(preloadNextProvider)) return;
      final index = state.currentEpIndex;
      final episodes = state.episodes;
      if (index < 0 || index + 1 >= episodes.length) return;
      final nextUrl = episodes[index + 1].url;
      final cached = ref.read(preloadedStreamsProvider);
      if (cached.containsKey(nextUrl)) return;
      final stream = await ref
          .read(pluginManagerProvider.notifier)
          .callWatch(entry, nextUrl);
      if (stream == null) return;
      ref.read(preloadedStreamsProvider.notifier).store(nextUrl, stream);
      // L2：mpv 默认 prefetch-playlist，播放单中的下一项会被预缓冲。
      await ref
          .read(playerProvider)
          .add(Media(stream.url, httpHeaders: stream.headers));
    } on Object {
      // 预载失败不影响当前播放。
    }
  }

  /// 打开流：open() 后立即推 playing=true（media_kit 行为），
  /// 起播判定只用 position > 0 && duration > 0。
  Future<void> _open(StreamInfo stream, {required int resumeMs}) async {
    final player = ref.read(playerProvider);
    _attachStreamListeners(player);
    _resumePosition = Duration(milliseconds: resumeMs);
    _seekApplied = resumeMs <= 0;
    await _applyProxy(player);
    await player.open(Media(stream.url, httpHeaders: stream.headers));
  }

  /// mpv 是原生 ffmpeg 网络栈，不走 dart:io 全局代理，须单独下发
  /// http-proxy 属性（每次 open 前同步当前设置；失败静默——测试 stub）。
  Future<void> _applyProxy(Player player) async {
    try {
      final proxy = ref.read(proxyProvider);
      final native = player as dynamic;
      await native
          .setProperty('http-proxy', proxy.url ?? '')
          .timeout(const Duration(seconds: 2), onTimeout: () {});
    } on Object {
      // 测试 stub / 非原生端：跳过。
    }
  }

  void _attachStreamListeners(Player player) {
    if (_positionSub != null) return;
    _positionSub = player.stream.position.listen((position) {
      _position = position;
      _duration = player.state.duration;
      if (!state.started &&
          position > Duration.zero &&
          _duration > Duration.zero) {
        state = state.copyWith(started: true);
        if (!_seekApplied) {
          _seekApplied = true;
          unawaited(player.seek(_resumePosition));
        }
      }
    });
    _errorSub = player.stream.error.listen((message) {
      if (message.isNotEmpty && !state.hasError) {
        state = state.copyWith(error: message);
      }
    });
  }

  void toggle() {
    final player = ref.read(playerProvider);
    player.state.playing ? player.pause() : player.play();
  }

  /// 退出播放页：暂停单例 Player（常驻不销毁，再进快启）。
  /// 测试环境 media_kit 未初始化等场景静默忽略。
  void pauseOnExit() {
    try {
      unawaited(ref.read(playerProvider).pause());
    } on Object {
      // 无播放器实例（未起播/测试环境）：无需暂停。
    }
  }

  Future<void> seekTo(Duration position) async {
    _position = position;
    await ref.read(playerProvider).seek(position);
  }

  Future<void> skip(Duration offset) => seekTo(
    _position + offset < Duration.zero ? Duration.zero : _position + offset,
  );

  Future<void> setRate(double rate) async {
    state = state.copyWith(rate: rate);
    await ref.read(playerProvider).setRate(rate);
  }

  /// 横屏锁屏切换（帧 21:21 控制条「锁屏」）。
  void toggleLock() => state = state.copyWith(locked: !state.locked);

  /// 下一集（无下一集时为空操作）。
  Future<void> nextEpisode() async {
    final index = state.currentEpIndex;
    if (index < 0 || index + 1 >= state.episodes.length) return;
    await switchEpisode(state.episodes[index + 1].url);
  }

  String get currentEpisodeTitle {
    final i = state.currentEpIndex;
    if (i < 0 || i >= state.episodes.length) return '';
    return state.episodes[i].title;
  }

  /// 进度落库：观看历史 + 追番进度。由页面 5s 定时器、暂停、退出时触发。
  Future<void> saveProgress() async {
    final args = state.args;
    if (!args.isValid || !state.started) return;
    final positionMs = _position.inMilliseconds;
    final durationMs = _duration.inMilliseconds;
    if (positionMs <= 0) return;
    try {
      await ref
          .read(watchHistoryRepositoryProvider)
          .saveProgress(
            sourcePackage: args.src,
            bangumiUrl: args.bangumi,
            title: args.title,
            cover: state.cover,
            episodeUrl: args.ep,
            episodeTitle: currentEpisodeTitle,
            positionMs: positionMs,
            durationMs: durationMs,
          );
      await ref
          .read(followsRepositoryProvider)
          .setProgress(
            sourcePackage: args.src,
            bangumiUrl: args.bangumi,
            title: args.title,
            cover: state.cover,
            currentEpisode: state.currentEpIndex + 1,
            totalEpisode: state.episodes.length,
          );
    } on Object {
      // 落库失败不阻塞播放/退出。
    }
  }
}
