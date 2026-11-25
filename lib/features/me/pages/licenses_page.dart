import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../../../core/theme/tokens.dart';

/// 开源许可页（Figma 142:69 范式）：说明行 + 名称/许可证双列清单
/// （左 14/600 名称，右 12 灰许可证，软分隔线）+ 页脚小字。
/// 列表取 pubspec 真实依赖，许可证类型以各仓库为准。
class LicensesPage extends StatelessWidget {
  const LicensesPage({super.key});

  /// 真实依赖清单（名称 → 许可证）。webview_flutter 等已移除依赖不入列。
  static const _entries = [
    ('media_kit', 'MIT'),
    ('drift', 'MIT'),
    ('flutter_riverpod', 'MIT'),
    ('go_router', 'BSD-3-Clause'),
    ('dio', 'MIT'),
    ('cached_network_image', 'MIT'),
    ('shared_preferences', 'BSD-3-Clause'),
    ('screen_brightness', 'MIT'),
    ('flutter_i18n', 'MIT'),
    ('url_launcher', 'BSD-3-Clause'),
    ('share_plus', 'BSD-3-Clause'),
    ('package_info_plus', 'BSD-3-Clause'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final divider = Theme.of(context).dividerColor;
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.aboutLicense')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.space4,
          AppTokens.space3,
          AppTokens.space4,
          AppTokens.space6,
        ),
        children: [
          Text(
            FlutterI18n.translate(context, 'me.licensesDesc'),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          for (var i = 0; i < _entries.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
                child: Container(
                  height: 1,
                  color: cs.onSurface.withValues(alpha: 0.06),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _entries[i].$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Text(
                  _entries[i].$2,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppTokens.space6),
          Text(
            FlutterI18n.translate(context, 'me.licensesFooter'),
            style: TextStyle(fontSize: 11, color: divider),
          ),
        ],
      ),
    );
  }
}
