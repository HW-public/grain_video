import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/tokens.dart';
import '../widgets/me_list_card.dart';
import '../widgets/me_list_row.dart';
import '../routes.dart' show MeRoutes;

/// 设置外壳页：外观 / 网络代理 / 缓存清理 三个子页入口。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.settingsTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          MeListCard(
            children: [
              MeListRow(
                icon: Icons.palette_outlined,
                title: FlutterI18n.translate(context, 'me.appearanceTitle'),
                subtitle: AppTokens.defaultPalette.name,
                onTap: () {
                  context.push(MeRoutes.settingsAppearance);
                },
              ),
              MeListRow(
                icon: Icons.public_outlined,
                title: FlutterI18n.translate(context, 'me.proxyTitle'),
                subtitle: FlutterI18n.translate(context, 'me.proxyOff'),
                onTap: () {
                  context.push(MeRoutes.settingsProxy);
                },
              ),
              MeListRow(
                icon: Icons.cleaning_services_outlined,
                title: FlutterI18n.translate(context, 'me.cacheTitle'),
                onTap: () {
                  context.push(MeRoutes.settingsCache);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
