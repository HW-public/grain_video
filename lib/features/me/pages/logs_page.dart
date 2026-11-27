import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/services/app_logger.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/async_view.dart';

/// 运行日志页（帧 259:2）：级别/tag 双过滤 + 日志卡 + 清空/导出分享。
/// 数据来自 [AppLogger] 内存环（含启动回读的历史错误）。
class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  LogLevel? _level; // null = 全部
  String? _tag; // null = 全部
  final _scroll = ScrollController();

  /// 级别徽标色（语义色，不随主题：E红/W橙/I绿/D灰，帧 259:2）。
  static const _levelColors = {
    LogLevel.error: Color(0xFFE0624C),
    LogLevel.warning: Color(0xFFE8865A),
    LogLevel.info: Color(0xFF1F9E6E),
    LogLevel.debug: Color(0xFF8A938E),
  };

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final text = AppLogger.exportText();
    if (text.isEmpty) return;
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/hehe-logs.txt');
      await file.writeAsString(text);
      await Share.shareXFiles([XFile(file.path)], subject: '禾禾影视运行日志');
    } on Object {
      // 分享取消/失败静默。
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(FlutterI18n.translate(context, 'logs.title'))),
      body: ValueListenableBuilder<int>(
        valueListenable: AppLogger.version,
        builder: (context, _, _) {
          final all = AppLogger.entries;
          final tags = {for (final e in all) e.tag}.toList()..sort();
          final visible = [
            for (final e in all)
              if ((_level == null || e.level == _level) &&
                  (_tag == null || e.tag == _tag))
                e,
          ];
          // 新日志滚到底（帧：时间升序，最新在底部）。
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scroll.hasClients) {
              _scroll.jumpTo(_scroll.position.maxScrollExtent);
            }
          });
          return Column(
            children: [
              // 级别过滤（帧 259:5~13）。
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                    vertical: 8,
                  ),
                  children: [
                    _chip(
                      FlutterI18n.translate(context, 'logs.levelAll'),
                      _level == null,
                      () => setState(() => _level = null),
                    ),
                    _chip(
                      FlutterI18n.translate(context, 'logs.levelInfo'),
                      _level == LogLevel.info,
                      () => setState(() => _level = LogLevel.info),
                    ),
                    _chip(
                      FlutterI18n.translate(context, 'logs.levelWarn'),
                      _level == LogLevel.warning,
                      () => setState(() => _level = LogLevel.warning),
                    ),
                    _chip(
                      FlutterI18n.translate(context, 'logs.levelError'),
                      _level == LogLevel.error,
                      () => setState(() => _level = LogLevel.error),
                    ),
                  ],
                ),
              ),
              // tag 过滤（帧 259:14~23，动态收集）。
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                    vertical: 4,
                  ),
                  children: [
                    _chip(
                      FlutterI18n.translate(context, 'logs.tagAll'),
                      _tag == null,
                      () => setState(() => _tag = null),
                      small: true,
                    ),
                    for (final t in tags)
                      _chip(
                        t,
                        _tag == t,
                        () => setState(() => _tag = t),
                        small: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space2),
              // 日志卡（帧 259:24）。
              Expanded(
                child: visible.isEmpty
                    ? EmptyState(
                        icon: Icons.receipt_long_outlined,
                        message: FlutterI18n.translate(context, 'logs.empty'),
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTokens.space4,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(
                            AppTokens.radiusCard,
                          ),
                        ),
                        child: ListView.separated(
                          controller: _scroll,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space3,
                            vertical: AppTokens.space2,
                          ),
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: Theme.of(context).dividerColor,
                          ),
                          itemBuilder: (context, i) =>
                              _LogRow(entry: visible[i], colors: _levelColors),
                        ),
                      ),
              ),
              // 底栏：清空 / 导出分享（帧 259:72~74）。
              SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.space4,
                    vertical: AppTokens.space2,
                  ),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: () => unawaited(AppLogger.clear()),
                        child: Text(
                          FlutterI18n.translate(context, 'logs.clear'),
                          style: TextStyle(
                            fontSize: 14,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => unawaited(_export()),
                        child: Text(
                          FlutterI18n.translate(context, 'logs.export'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap, {
    bool small = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(small ? 13 : 16),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: small ? 12 : 16,
            vertical: small ? 4 : 6,
          ),
          decoration: BoxDecoration(
            color: selected ? cs.primary.withValues(alpha: 0.15) : cs.surface,
            borderRadius: BorderRadius.circular(small ? 13 : 16),
            border: Border.all(
              color: selected ? cs.primary : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: small ? 11 : 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? cs.primary
                  : cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}

/// 单条日志行（帧行范式）：时间 + 级别徽标 + tag + 消息（至多 3 行）。
class _LogRow extends StatelessWidget {
  const _LogRow({required this.entry, required this.colors});

  final LogEntry entry;
  final Map<LogLevel, Color> colors;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = entry.time;
    final hhmmss =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                hhmmss,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 18,
                height: 16,
                decoration: BoxDecoration(
                  color: colors[entry.level],
                  borderRadius: BorderRadius.circular(4),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.levelLetter,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                entry.tag,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}
