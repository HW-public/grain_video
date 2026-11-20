/// 全应用路由路径常量（core 层，纯字符串无业务依赖）。
///
/// 规则：feature 页面之间跳转一律用这里的常量，禁止 import 其它 feature
/// 的 routes.dart（check_imports 会拦）。feature 只导出自己的
/// `xxxRoutes` 列表，由 lib/router.dart（app 层）聚合。
abstract final class AppRoutes {
  static const home = '/';
  static const search = '/search';
  static const detail = '/detail';
  static const player = '/player';
  static const me = '/me';
  static const extensions = '/extensions';
}
