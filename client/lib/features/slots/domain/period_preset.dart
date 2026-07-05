/// Period presets for BS-001 / LOGIC-005 date filter group.
enum PeriodPreset {
  today,
  tomorrow,
  next7Days,
  thisWeek,
  thisWeekend,
  rollingMonth,
  custom,
}

extension PeriodPresetLabel on PeriodPreset {
  String get label => switch (this) {
        PeriodPreset.today => 'Сегодня',
        PeriodPreset.tomorrow => 'Завтра',
        PeriodPreset.next7Days => 'Ближайшие 7 дней',
        PeriodPreset.thisWeek => 'На этой неделе',
        PeriodPreset.thisWeekend => 'В эти выходные',
        PeriodPreset.rollingMonth => 'Ближайший месяц',
        PeriodPreset.custom => 'Выбрать даты',
      };
}

class PeriodRange {
  const PeriodRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59);

/// Maps a preset to [from, to] using [now] as the reference instant.
///
/// [PeriodPreset.next7Days] and [PeriodPreset.custom] have no fixed range here.
PeriodRange rangeForPreset(PeriodPreset preset, DateTime now) {
  final today = startOfDay(now);

  switch (preset) {
    case PeriodPreset.today:
      return PeriodRange(from: today, to: endOfDay(today));
    case PeriodPreset.tomorrow:
      final day = today.add(const Duration(days: 1));
      return PeriodRange(from: day, to: endOfDay(day));
    case PeriodPreset.next7Days:
      throw ArgumentError('next7Days uses server default (no explicit dates)');
    case PeriodPreset.thisWeek:
      final daysUntilSunday = DateTime.sunday - now.weekday;
      final sunday = today.add(Duration(days: daysUntilSunday));
      return PeriodRange(from: now, to: endOfDay(sunday));
    case PeriodPreset.thisWeekend:
      return _thisWeekendRange(today, now.weekday);
    case PeriodPreset.rollingMonth:
      return PeriodRange(
        from: today,
        to: endOfDay(today.add(const Duration(days: 30))),
      );
    case PeriodPreset.custom:
      throw ArgumentError('custom preset has no fixed range');
  }
}

PeriodRange _thisWeekendRange(DateTime today, int weekday) {
  switch (weekday) {
    case DateTime.saturday:
      final sunday = today.add(const Duration(days: 1));
      return PeriodRange(from: today, to: endOfDay(sunday));
    case DateTime.sunday:
      return PeriodRange(from: today, to: endOfDay(today));
    default:
      final daysUntilSat = DateTime.saturday - weekday;
      final saturday = today.add(Duration(days: daysUntilSat));
      final sunday = saturday.add(const Duration(days: 1));
      return PeriodRange(from: saturday, to: endOfDay(sunday));
  }
}

bool _sameDay(DateTime a, DateTime b) {
  final la = a.toLocal();
  final lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

/// Guesses which preset produced [dateFrom]/[dateTo], or [custom].
PeriodPreset detectPreset(DateTime? dateFrom, DateTime? dateTo, DateTime now) {
  if (dateFrom == null || dateTo == null) {
    return PeriodPreset.next7Days;
  }

  for (final preset in PeriodPreset.values) {
    if (preset == PeriodPreset.custom || preset == PeriodPreset.next7Days) {
      continue;
    }
    final expected = rangeForPreset(preset, now);
    if (preset == PeriodPreset.thisWeek) {
      if (_sameDay(dateTo, expected.to) &&
          !dateFrom.toLocal().isAfter(expected.to)) {
        return PeriodPreset.thisWeek;
      }
      continue;
    }
    if (_sameDay(dateFrom, expected.from) && _sameDay(dateTo, expected.to)) {
      return preset;
    }
  }
  return PeriodPreset.custom;
}

/// Converts UI preset + optional custom bounds into API filter fields.
///
/// [PeriodPreset.next7Days] omits dates so the backend applies its 7-day default.
({DateTime? dateFrom, DateTime? dateTo}) presetToFilterDates({
  required PeriodPreset preset,
  DateTime? customFrom,
  DateTime? customTo,
  required DateTime now,
}) {
  if (preset == PeriodPreset.next7Days) {
    return (dateFrom: null, dateTo: null);
  }
  if (preset == PeriodPreset.custom) {
    return (dateFrom: customFrom, dateTo: customTo);
  }
  final range = rangeForPreset(preset, now);
  return (dateFrom: range.from, dateTo: range.to);
}
