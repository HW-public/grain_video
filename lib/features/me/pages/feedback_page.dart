import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/widgets/app_dialog.dart';

/// 问题反馈（帧 142:99）：类型 chips + 描述 + 联系方式 + 提交。
///
/// 无反馈后端——提交跳 GitHub 新建 issue 并预填标题/正文（真实可达）；
/// 帧里的「截图（选填）」未做：没有上传通道，放了也是假入口（偏离记录）。
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  static const _types = ['bug', 'feature', 'ui', 'other'];
  static const _typeKeys = {
    'bug': 'feedback.typeBug',
    'feature': 'feedback.typeFeature',
    'ui': 'feedback.typeUi',
    'other': 'feedback.typeOther',
  };

  var _type = 'bug';
  final _desc = TextEditingController();
  final _contact = TextEditingController();

  @override
  void dispose() {
    _desc.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final desc = _desc.text.trim();
    if (desc.length < 10) {
      showAppToast(
        context,
        FlutterI18n.translate(context, 'feedback.tooShort'),
        icon: Icons.error_outline,
      );
      return;
    }
    final typeLabel = FlutterI18n.translate(context, _typeKeys[_type]!);
    final title =
        '[$typeLabel] ${desc.length > 30 ? '${desc.substring(0, 30)}…' : desc}';
    final buffer = StringBuffer()
      ..writeln(
        '**${FlutterI18n.translate(context, 'feedback.typeLabel')}**: $typeLabel',
      )
      ..writeln()
      ..writeln(desc);
    final contact = _contact.text.trim();
    if (contact.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(
          '**${FlutterI18n.translate(context, 'feedback.contactLabel')}**: $contact',
        );
    }
    final uri = Uri.https('github.com', '/HW-public/grain_video/issues/new', {
      'title': title,
      'body': buffer.toString(),
    });
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(FlutterI18n.translate(context, 'feedback.title')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: [
          _Label(FlutterI18n.translate(context, 'feedback.typeLabel')),
          const SizedBox(height: AppTokens.space2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _types)
                _TypeChip(
                  label: FlutterI18n.translate(context, _typeKeys[t]!),
                  selected: _type == t,
                  onTap: () => setState(() => _type = t),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space4),
          _Label(FlutterI18n.translate(context, 'feedback.descLabel')),
          const SizedBox(height: AppTokens.space2),
          TextField(
            controller: _desc,
            maxLines: 6,
            minLines: 5,
            style: TextStyle(fontSize: 14, color: cs.onSurface),
            decoration: _inputDecoration(
              context,
              FlutterI18n.translate(context, 'feedback.descHint'),
            ),
          ),
          const SizedBox(height: AppTokens.space4),
          _Label(FlutterI18n.translate(context, 'feedback.contactLabel')),
          const SizedBox(height: AppTokens.space2),
          TextField(
            controller: _contact,
            style: TextStyle(fontSize: 14, color: cs.onSurface),
            decoration: _inputDecoration(
              context,
              FlutterI18n.translate(context, 'feedback.contactHint'),
            ),
          ),
          const SizedBox(height: AppTokens.space6),
          Center(
            child: Text(
              FlutterI18n.translate(context, 'feedback.privacy'),
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.space3),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusButton),
              ),
            ),
            onPressed: () => unawaited(_submit()),
            child: Text(
              FlutterI18n.translate(context, 'feedback.submit'),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 13,
        color: cs.onSurface.withValues(alpha: 0.35),
      ),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(AppTokens.space3),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

/// 类型 chip（帧：选中=浅绿底+绿字+绿描边；未选=白底+灰描边）。
class _TypeChip extends StatelessWidget {
  const _TypeChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.15) : cs.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusChip),
          border: Border.all(
            color: selected ? cs.primary : Theme.of(context).dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? cs.primary : cs.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
