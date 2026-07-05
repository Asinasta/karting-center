const _months = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

String _two(int value) => value.toString().padLeft(2, '0');

/// «4 июля, 18:30»
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]}, '
      '${_two(local.hour)}:${_two(local.minute)}';
}

/// «сб, 4 июля, 18:30»
String formatDateTimeWithWeekday(DateTime value) {
  final local = value.toLocal();
  return '${_weekdays[local.weekday - 1]}, ${formatDateTime(value)}';
}

/// «4 июля»
String formatDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day} ${_months[local.month - 1]}';
}

/// «04.07.2026»
String formatShortDate(DateTime value) {
  final local = value.toLocal();
  return '${_two(local.day)}.${_two(local.month)}.${local.year}';
}
