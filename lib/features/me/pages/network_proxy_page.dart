import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';
import '../widgets/me_empty_state.dart';

/// 设置-网络代理（占位页）：功能将在后续版本提供。
class NetworkProxyPage extends StatelessWidget {
  const NetworkProxyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.defaultPalette.pageBg,
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.proxyTitle')),
      ),
      body: MeEmptyState(
        icon: Icons.public_off,
        title: FlutterI18n.translate(context, 'me.placeholderTitle'),
        hint: FlutterI18n.translate(context, 'me.proxyHint'),
      ),
    );
  }
}
