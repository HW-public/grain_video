import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/app_settings.dart';
import '../../core/update/app_updater.dart';

/// 启动页（Figma 82:136）：薄荷渐变底 + 品牌图标 + 名称标语 +
/// 底部加载条与版本号。初始化完成后由 main 切换到 HeHeApp。
/// 图标/强调色跟随当前主题色板（三主题各一套品牌图标资产）。
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;

  static const _appVersion = 'v1.0.0';

  /// 色板名 → 品牌图标资产（与 32:316 品牌图标分区同源）。
  static const _brandIcons = {
    '薄荷绿': 'assets/brand/mint.png',
    '粉橘': 'assets/brand/sakura.png',
    '珊瑚橙': 'assets/brand/coral.png',
  };

  @override
  void initState() {
    super.initState();
    // 加载条：0 → 90% 循环推进的确定性动画（剩余 10% 留给真实初始化接管）。
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ref.watch(paletteProvider);
    final brandIcon = _brandIcons[palette.name] ?? _brandIcons['薄荷绿']!;
    // 启动阶段无外层 MaterialApp（main 先 runApp 本页），自包一层提供
    // Directionality/主题基础设施；配色显式取自色板，不依赖 ThemeData。
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          // 帧渐变：页面底 → primaryContainer（顶浅底深）。
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [palette.pageBg, palette.primaryContainer],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(44),
                      child: Image.asset(
                        brandIcon,
                        width: 192,
                        height: 192,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      '禾禾影视',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        // 深绿主文字（亮主题可读；暗夜下 primarySoft 偏浅，
                        // 用 onSurface 保证对比度）。
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : const Color(0xFF1F9E6E),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '追剧 · 追番 · 追漫',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),
              // 底部加载条 + 版本号。
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 72),
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, _) {
                      return Container(
                        width: 120,
                        height: 4,
                        decoration: BoxDecoration(
                          color: palette.primaryContainer,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.15 + _progress.value * 0.7,
                          child: Container(
                            decoration: BoxDecoration(
                              color: palette.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: FutureBuilder<String>(
                    future: AppUpdater.currentVersion(),
                    builder: (context, snapshot) => Text(
                      '禾禾影视 ${snapshot.data == null ? _appVersion : 'v${snapshot.data}'}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
