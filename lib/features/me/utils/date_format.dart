/// 「我的」列表页日期格式化：yyyy-MM-dd（避免引入 intl 直接依赖）。
String formatMeDate(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

/// 历史条目「看到 mm:ss / h:mm:ss」进度格式化。
String formatPositionClock(int positionMs) {
  final totalSeconds = (positionMs / 1000).round();
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  String two(int value) => value.toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${two(minutes)}:${two(seconds)}';
  }
  return '${two(minutes)}:${two(seconds)}';
}

/// 历史分组标签：今天 / 昨天 / yyyy-MM-dd。
String formatMeGroupLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diffDays = today.difference(day).inDays;
  if (diffDays <= 0) return 'me.today';
  if (diffDays == 1) return 'me.yesterday';
  return formatMeDate(date);
}
