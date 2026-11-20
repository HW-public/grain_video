import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes.dart';
import '../../../core/theme/tokens.dart';
import '../widgets/me_list_card.dart';
import '../widgets/me_list_row.dart';
import '../routes.dart' show MeRoutes;

/// 「我的」一级页：头像/应用名/版本头部 + 功能列表 + 底部导航（第 3 项）。
class MePage extends StatelessWidget {
  const MePage({super.key});

  static const _appVersion = 'v1.0.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.space4,
            AppTokens.space6,
            AppTokens.space4,
            AppTokens.space4,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: AppTokens.space6),
            MeListCard(
              children: [
                MeListRow(
                  icon: Icons.history,
                  title: FlutterI18n.translate(context, 'me.history'),
                  onTap: () {
                    context.push(MeRoutes.history);
                  },
                ),
                MeListRow(
                  icon: Icons.star_outline,
                  title: FlutterI18n.translate(context, 'me.favorites'),
                  onTap: () {
                    context.push(MeRoutes.favorites);
                  },
                ),
                MeListRow(
                  icon: Icons.live_tv_outlined,
                  title: FlutterI18n.translate(context, 'me.follows'),
                  onTap: () {
                    context.push(MeRoutes.follows);
                  },
                ),
                MeListRow(
                  icon: Icons.extension_outlined,
                  title: FlutterI18n.translate(context, 'me.extensions'),
                  onTap: () {
                    context.push(AppRoutes.extensions);
                  },
                ),
                MeListRow(
                  icon: Icons.settings_outlined,
                  title: FlutterI18n.translate(context, 'me.settings'),
                  onTap: () {
                    context.push(MeRoutes.settings);
                  },
                ),
                MeListRow(
                  icon: Icons.info_outline,
                  title: FlutterI18n.translate(context, 'me.about'),
                  subtitle: FlutterI18n.translate(
                    context,
                    'me.aboutVersionLine',
                    translationParams: {
                      'name': FlutterI18n.translate(context, 'appTitle'),
                      'version': _appVersion,
                    },
                  ),
                  onTap: () {
                    context.push(MeRoutes.about);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 头部（设计稿「我的」帧）：头像占位 + 用户昵称 + 本地模式说明。
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTokens.defaultPalette.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.eco_outlined,
            size: 28,
            color: AppTokens.defaultPalette.primary,
          ),
        ),
        const SizedBox(width: AppTokens.space3 + 2),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FlutterI18n.translate(context, 'me.headerName'),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTokens.textPrimary,
              ),
            ),
            const SizedBox(height: AppTokens.space1 - 1),
            Text(
              FlutterI18n.translate(context, 'me.headerSubtitle'),
              style: const TextStyle(
                fontSize: 12,
                color: AppTokens.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
