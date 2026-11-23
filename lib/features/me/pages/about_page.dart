import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/update/update_check.dart';
import '../widgets/me_list_card.dart';
import '../widgets/me_list_row.dart';

/// 关于页（spec 02）：品牌区 + 功能列表组 + 底部小字。
///
/// 检查更新已接真实逻辑（GitHub Releases 镜像链）；
/// GitHub/分享等外链依赖 url_launcher/share 插件，接入前为纯展示行。
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
                subtitle: 'HW-public/miru-app',
                showChevron: false,
              ),
              MeListRow(
                icon: Icons.feedback_outlined,
                title: FlutterI18n.translate(context, 'me.aboutFeedback'),
              ),
              MeListRow(
                icon: Icons.description_outlined,
                title: FlutterI18n.translate(context, 'me.aboutLicense'),
              ),
              MeListRow(
                icon: Icons.share_outlined,
                title: FlutterI18n.translate(context, 'me.aboutShare'),
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
        const Text(
          _appVersion,
          style: TextStyle(fontSize: 12, color: AppTokens.textTertiary),
        ),
      ],
    );
  }
}
