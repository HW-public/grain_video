import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

import '../theme/tokens.dart';
import 'app_dialog.dart';

/// 左滑露出式删除壳（Figma 27:210 / 233:1298 交互语义）：
/// 拖动只把行内容向左推开，露出右侧红色「删除」按钮并停住；
/// 点按钮才弹二次确认框，确认后由 [onDelete] 真正删除。
///
/// 不用 Dismissible——它的 confirmDismiss 是「滑满脱手后」才询问，
/// 不符合「露出按钮 → 点击 → 确认」的设计。
class SwipeDeleteTile extends StatefulWidget {
  const SwipeDeleteTile({
    super.key,
    required this.child,
    required this.onDelete,
    required this.confirmTitleKey,
    required this.confirmHintKey,
    this.labelKey = 'me.delete',
  });

  final Widget child;
  final Future<void> Function() onDelete;

  /// 确认框标题/内容文案的 l10n key（不同业务传各自命名空间的键）。
  final String confirmTitleKey;
  final String confirmHintKey;

  /// 红色按钮内「删除」标签的 l10n key。
  final String labelKey;

  @override
  State<SwipeDeleteTile> createState() => _SwipeDeleteTileState();
}

class _SwipeDeleteTileState extends State<SwipeDeleteTile> {
  /// 删除按钮宽度，行内容最大推距。
  static const _actionWidth = 76.0;

  final _offset = ValueNotifier(0.0);
  var _open = false;

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final next = (_offset.value + details.delta.dx).clamp(-_actionWidth, 0.0);
    _offset.value = next;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // 超过半程吸附打开，否则回弹关闭。
    final shouldOpen = _offset.value < -_actionWidth / 2;
    _open = shouldOpen;
    _offset.value = shouldOpen ? -_actionWidth : 0.0;
  }

  Future<void> _confirmAndDelete() async {
    final ok = await showAppConfirmDialog(
      context,
      title: FlutterI18n.translate(context, widget.confirmTitleKey),
      message: FlutterI18n.translate(context, widget.confirmHintKey),
      cancelLabel: FlutterI18n.translate(context, 'common.cancel'),
      confirmLabel: FlutterI18n.translate(context, 'common.confirm'),
      danger: true,
    );
    if (ok == true) await widget.onDelete();
    // 无论成败先把行收回（条目若被删除会随父级重建出树）。
    _open = false;
    _offset.value = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: Stack(
        children: [
          // 底层：右侧红色删除按钮（圆角与卡片一致，视觉上融为一体）。
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTokens.danger,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppTokens.space4 + 4),
              child: InkWell(
                onTap: _confirmAndDelete,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppTokens.space1),
                    Text(
                      FlutterI18n.translate(context, widget.labelKey),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 前景：行内容随拖动横移。包一层不透明白底/页面底——
          // 行本身若是透明 InkWell，红层会从底下整行渗出来。
          ValueListenableBuilder<double>(
            valueListenable: _offset,
            builder: (context, offset, child) {
              return GestureDetector(
                onHorizontalDragUpdate: _onHorizontalDragUpdate,
                onHorizontalDragEnd: _onHorizontalDragEnd,
                onTap: _open
                    ? () {
                        // 打开态点行内容 = 收回。
                        _open = false;
                        _offset.value = 0.0;
                      }
                    : null,
                child: Transform.translate(
                  offset: Offset(offset, 0),
                  child: ColoredBox(
                    // 跟随主题页面底（亮=pageBg / 暗=darkBg）。
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: child,
                  ),
                ),
              );
            },
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
