import 'package:flutter/widgets.dart';

/// 外壳下发的当前底部导航索引（0 首页 / 1 搜索 / 2 我的）。
///
/// StatefulShellRoute 三分支常驻树中（IndexedStack），离屏分支靠它
/// 判断自己是否可见——搜索页据此决定何时请求输入框焦点，
/// 避免 App 启动时键盘被离屏搜索页抢走。
class AppTabScope extends InheritedWidget {
  const AppTabScope({super.key, required this.index, required super.child});

  final int index;

  /// 当前索引；不在外壳内（单测直出页面）时回退 0。
  static int of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTabScope>()?.index ?? 0;

  @override
  bool updateShouldNotify(AppTabScope oldWidget) => oldWidget.index != index;
}
