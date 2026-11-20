/// 「我的」列表页日期格式化：yyyy-MM-dd（避免引入 intl 直接依赖）。
String formatMeDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}
