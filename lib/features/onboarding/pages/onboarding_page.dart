import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/widgets/sprout_grow_logo.dart';

/// 首次引导（Figma 133:257~291 四屏）：欢迎/聚合搜索/扩展生态/追番同步。
/// 横向滑动或「下一步」翻页，最后一屏「立即开始」（或任意屏「跳过」）
/// 写入首启标记并进入首页；之后冷启动不再出现。
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pager = PageController();
  var _index = 0;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppSettings.setOnboardingDone();
    if (mounted) context.go(AppRoutes.home);
  }

  void _next() {
    if (_index >= _pageCount - 1) {
      _finish();
    } else {
      _pager.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // 帧按钮渐变：#2EE2AE → #6FF2BE（欢迎/末屏）。
    const buttonGradient = LinearGradient(
      colors: [Color(0xFF2EE2AE), Color(0xFF6FF2BE)],
    );
    final solidButton = const Color(0xFF2FAE7E);

    final pages = [
      // S1 欢迎：小禾苗 + 名称标语 + 下一步 + 跳过。
      _OnboardPane(
        // 用户拍板：欢迎页插画用禾苗生长动画（08-sprout-grow.svg 移植）。
        // 内容水平范围 79~161、中心恰为 120，天然与下方文字居中对齐，无需平移。
        art: const SproutGrowLogo(size: 240),
        title: FlutterI18n.translate(context, 'appTitle'),
        titleSize: 28,
        desc: FlutterI18n.translate(context, 'me.aboutSlogan'),
        showSkip: true,
        onSkip: _finish,
        buttonText: FlutterI18n.translate(context, 'onboarding.next'),
        buttonGradient: buttonGradient,
        onButton: _next,
      ),
      // S2 聚合搜索。
      _OnboardPane(
        art: _ArtCircle(icon: Icons.search),
        title: FlutterI18n.translate(context, 'onboarding.s2Title'),
        desc: FlutterI18n.translate(context, 'onboarding.s2Desc'),
        showSkip: true,
        onSkip: _finish,
        buttonText: FlutterI18n.translate(context, 'onboarding.next'),
        buttonColor: solidButton,
        onButton: _next,
      ),
      // S3 扩展生态。
      _OnboardPane(
        art: _ArtCircle(icon: Icons.extension_outlined),
        title: FlutterI18n.translate(context, 'onboarding.s3Title'),
        desc: FlutterI18n.translate(context, 'onboarding.s3Desc'),
        showSkip: true,
        onSkip: _finish,
        buttonText: FlutterI18n.translate(context, 'onboarding.next'),
        buttonGradient: buttonGradient,
        onButton: _next,
      ),
      // S4 追番同步（帧无跳过；用户拍板末屏按钮=开始使用）。
      _OnboardPane(
        art: _ArtCircle(icon: Icons.live_tv_outlined),
        title: FlutterI18n.translate(context, 'onboarding.s4Title'),
        desc: FlutterI18n.translate(context, 'onboarding.s4Desc'),
        showSkip: false,
        buttonText: FlutterI18n.translate(context, 'onboarding.start'),
        buttonGradient: buttonGradient,
        onButton: _finish,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pager,
              itemCount: _pageCount,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => pages[i],
            ),
            // 指示点（帧 y760：激活 24×8，未选 8×8 r4）。
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 76),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pageCount; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _index
                              ? cs.primary
                              : Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 单屏骨架：插画区 + 标题 + 描述 + 底部主按钮（+次按钮/跳过）。
class _OnboardPane extends StatelessWidget {
  const _OnboardPane({
    required this.art,
    required this.title,
    required this.desc,
    required this.buttonText,
    required this.onButton,
    this.titleSize = 22,
    this.buttonGradient,
    this.buttonColor,
    this.showSkip = false,
    this.onSkip,
  });

  final Widget art;
  final String title;
  final String desc;
  final String buttonText;
  final VoidCallback onButton;
  final double titleSize;
  final Gradient? buttonGradient;
  final Color? buttonColor;
  final bool showSkip;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerRight,
              child: showSkip
                  ? GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        FlutterI18n.translate(context, 'onboarding.skip'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: cs.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 76),
          SizedBox(height: 240, child: Center(child: art)),
          const SizedBox(height: 40),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const Spacer(),
          // 主按钮：帧规格 h52 r24，渐变或实底（深绿 #2FAE7E）。
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: buttonGradient,
              color: buttonGradient == null ? buttonColor : null,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onButton,
                child: Center(
                  child: Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 104),
        ],
      ),
    );
  }
}

/// S2~S4 插画：品牌浅绿圆托 240 + 白色主区 120 图标。
class _ArtCircle extends StatelessWidget {
  const _ArtCircle({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 240,
      height: 240,
      decoration: const BoxDecoration(
        // 品牌浅绿托（帧 s2/s3/s4-art-bg #E4F1EC，品牌识别不随暗夜反转）。
        color: Color(0xFFE4F1EC),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: cs.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 52, color: const Color(0xFF1F9E6E)),
        ),
      ),
    );
  }
}
