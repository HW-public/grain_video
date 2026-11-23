import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:async';

import '../../../core/theme/tokens.dart';
import '../../../core/update/update_check.dart';
import '../../../core/update/app_updater.dart';
import '../widgets/me_list_card.dart';
import '../widgets/me_list_row.dart';

/// 关于页（spec 02）：品牌区 + 功能列表组 + 底部小字。
///
/// 检查更新 / GitHub / 反馈 / 许可 / 分享 全部接真实逻辑。
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
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
                onTap: () => unawaited(
                  launchUrl(
                    Uri.parse(
                      'https://github.com/HW-public/grain_video/issues',
                    ),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              MeListRow(
                icon: Icons.description_outlined,
                title: FlutterI18n.translate(context, 'me.aboutLicense'),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: FlutterI18n.translate(context, 'appTitle'),
                ),
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
            style: const TextStyle(fontSize: 12, color: AppTokens.textTertiary),
          ),
          const SizedBox(height: AppTokens.space1),
          Text(
            FlutterI18n.translate(context, 'me.aboutCopyright'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppTokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  /// 品牌区：浅绿底托 logo 占位 + 应用名 + 版本号。
  Widget _buildBrand(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: AppTokens.defaultPalette.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(
            Icons.eco_outlined,
            size: 40,
            color: AppTokens.defaultPalette.primary,
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        Text(
          FlutterI18n.translate(context, 'appTitle'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTokens.textPrimary,
          ),
        ),
        const SizedBox(height: AppTokens.space1),
        // 真实版本经 package_info 异步补读（AppUpdater.currentVersion）。
        FutureBuilder<String>(
          future: AppUpdater.currentVersion(),
          builder: (context, snapshot) => Text(
            snapshot.data == null ? _appVersion : 'v${snapshot.data}',
            style: const TextStyle(fontSize: 12, color: AppTokens.textTertiary),
          ),
        ),
      ],
    );
  }
}
