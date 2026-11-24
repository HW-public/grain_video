import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';
import '../widgets/me_empty_state.dart';

/// 下载管理占位页：下载功能未做（Figma 98:6 已画，实现排期见计划），
/// 与「我的」入口卡三格之一对应。
class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.tabDownloads')),
      ),
      body: MeEmptyState(
        icon: Icons.download_outlined,
        title: FlutterI18n.translate(context, 'me.downloadEmpty'),
        hint: '',
      ),
    );
  }
}
