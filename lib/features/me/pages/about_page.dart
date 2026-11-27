import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import '../../../core/theme/tokens.dart';
import '../../../core/update/update_check.dart';
import '../../../core/update/app_updater.dart';
import '../routes.dart' show MeRoutes;
import '../widgets/me_list_card.dart';
import '../widgets/me_list_row.dart';
import '../../../core/widgets/sprout_logo.dart';

/// 关于页（spec 02）：品牌区 + 功能列表组 + 底部小字。
///
/// 检查更新 / GitHub / 反馈 / 许可 / 分享 全部接真实逻辑。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.aboutTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space6,
          AppTokens.space4,
          AppTokens.space6,
        ),
        children: [
          _buildBrand(context),
          const SizedBox(height: AppTokens.space6),
          MeListCard(
            children: [
              MeListRow(
                icon: Icons.sync,
                title: FlutterI18n.translate(context, 'me.aboutCheckUpdate'),
                subtitle: FlutterI18n.translate(context, 'me.aboutUpToDate'),
                onTap: () => checkAppUpdate(context),
              ),
              MeListRow(
                icon: Icons.code,
                title: FlutterI18n.translate(context, 'me.aboutGithub'),
                subtitle: 'HW-public/grain_video',
                showChevron: false,
                onTap: () => unawaited(
                  launchUrl(
                    Uri.parse('https://github.com/HW-public/grain_video'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              MeListRow(
                icon: Icons.feedback_outlined,
                title: FlutterI18n.translate(context, 'me.aboutFeedback'),
                // 帧 142:99：应用内反馈表单（提交跳 GitHub 预填 issue）。
                onTap: () => context.push(MeRoutes.feedback),
              ),
              MeListRow(
                icon: Icons.description_outlined,
                title: FlutterI18n.translate(context, 'me.aboutLicense'),
                onTap: () => context.push(MeRoutes.licenses),
              ),
              MeListRow(
                icon: Icons.receipt_long_outlined,
                title: FlutterI18n.translate(context, 'me.aboutLogs'),
                onTap: () => context.push(MeRoutes.logs),
              ),
              MeListRow(
                icon: Icons.share_outlined,
                title: FlutterI18n.translate(context, 'me.aboutShare'),
                onTap: () => unawaited(
                  Share.share(
                    '禾禾影视 · 追番一个 App 就够了 '
                    'https://github.com/HW-public/grain_video',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space6),
          Text(
            FlutterI18n.translate(context, 'me.aboutSlogan'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: AppTokens.space1),
          Text(
            FlutterI18n.translate(context, 'me.aboutCopyright'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }

  /// 品牌区（帧 131:96~131:139）：品牌浅绿托 #E4F1EC r24 + 小禾苗矢量，
  /// 应用名 20/700 + 版本号 12 灰。
  Widget _buildBrand(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            // 品牌色托：两主题保持品牌浅绿（品牌识别，不随暗夜反转）。
            color: const Color(0xFFE4F1EC),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Center(child: SproutLogo()),
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          FlutterI18n.translate(context, 'appTitle'),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppTokens.space1),
        // 真实版本经 package_info 异步补读（AppUpdater.currentVersion）。
        FutureBuilder<String>(
          future: AppUpdater.currentVersion(),
          builder: (context, snapshot) => Text(
            snapshot.data == null ? _appVersion : 'v${snapshot.data}',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ),
      ],
    );
  }
}
