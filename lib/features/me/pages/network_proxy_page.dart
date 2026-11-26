import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/tokens.dart';

/// 设置-网络代理（帧 27:212）：启用开关 + 代理类型单选（HTTP/SOCKS5）
/// + 服务器地址/端口输入 + 底部提示。保存即生效（dart:io 全局指令
/// 每次请求现读；mpv 每次 open 前下发）。
class NetworkProxyPage extends ConsumerStatefulWidget {
  const NetworkProxyPage({super.key});

  @override
  ConsumerState<NetworkProxyPage> createState() => _NetworkProxyPageState();
}

class _NetworkProxyPageState extends ConsumerState<NetworkProxyPage> {
  late final TextEditingController _host;
  late final TextEditingController _port;

  @override
  void initState() {
    super.initState();
    final cfg = ref.read(proxyProvider);
    _host = TextEditingController(text: cfg.host);
    _port = TextEditingController(text: cfg.port > 0 ? '${cfg.port}' : '');
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _save({bool? enabled, String? mode}) {
    final cfg = ref.read(proxyProvider);
    ref
        .read(proxyProvider.notifier)
        .save(
          enabled: enabled ?? cfg.enabled,
          mode: mode ?? cfg.mode,
          host: _host.text.trim(),
          port: int.tryParse(_port.text.trim()) ?? 0,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cfg = ref.watch(proxyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'me.proxyTitle')),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppTokens.space4),
        children: [
          // 启用代理 + 开关（帧 27:274~276）。
          SizedBox(
            height: 56,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    FlutterI18n.translate(context, 'me.proxyEnable'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                Switch(
                  value: cfg.enabled,
                  onChanged: (v) => _save(enabled: v),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          const SizedBox(height: AppTokens.space4),
          // 代理类型（帧 27:278~285；SOCKS4 底层不支持已移除）。
          _SectionTitle(FlutterI18n.translate(context, 'me.proxyType')),
          const SizedBox(height: AppTokens.space2),
          for (final mode in ['http', 'socks5'])
            _TypeRow(
              label: mode.toUpperCase(),
              selected: cfg.mode == mode,
              onTap: () => _save(mode: mode),
            ),
          const SizedBox(height: AppTokens.space4),
          _SectionTitle(FlutterI18n.translate(context, 'me.proxyHost')),
          const SizedBox(height: AppTokens.space2),
          _Input(
            controller: _host,
            hint: '10.43.28.12',
            keyboardType: TextInputType.url,
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: AppTokens.space4),
          _SectionTitle(FlutterI18n.translate(context, 'me.proxyPort')),
          const SizedBox(height: AppTokens.space2),
          _Input(
            controller: _port,
            hint: '7890',
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => _save(),
          ),
          const SizedBox(height: AppTokens.space5),
          // 底部提示（帧 27:292）。
          Text(
            FlutterI18n.translate(context, 'me.proxyScopeHint'),
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// 单选行（帧 27:279~285 范式）：20 外圈 + 选中内点 + 15 文字。
class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.space3),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppTokens.space3),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: selected
                    ? cs.onSurface
                    : cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 输入框（帧 27:287/290 范式）：白底 r12 高 48，无描边。
class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: cs.onSurface.withValues(alpha: 0.35),
        ),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space4,
          vertical: 14,
        ),
      ),
    );
  }
}
