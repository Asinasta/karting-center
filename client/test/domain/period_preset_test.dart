import 'package:apex_client/features/slots/domain/period_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 7, 5, 14, 30); // Sunday in 2026? check: July 5 2026 is Sunday

  test('today preset covers start and end of current day', () {
    final range = rangeForPreset(PeriodPreset.today, now);
    expect(range.from, DateTime(2026, 7, 5));
    expect(range.to, DateTime(2026, 7, 5, 23, 59, 59));
  });

  test('tomorrow preset is the next calendar day', () {
    final range = rangeForPreset(PeriodPreset.tomorrow, now);
    expect(range.from, DateTime(2026, 7, 6));
    expect(range.to, DateTime(2026, 7, 6, 23, 59, 59));
  });

  test('weekend on Sunday is only today', () {
    final range = rangeForPreset(PeriodPreset.thisWeekend, now);
    expect(range.from, DateTime(2026, 7, 5));
    expect(range.to, DateTime(2026, 7, 5, 23, 59, 59));
  });

  test('weekend on Monday targets next Saturday and Sunday', () {
    final monday = DateTime(2026, 7, 6, 10);
    final range = rangeForPreset(PeriodPreset.thisWeekend, monday);
    expect(range.from, DateTime(2026, 7, 11));
    expect(range.to, DateTime(2026, 7, 12, 23, 59, 59));
  });

  test('rolling month adds 30 days', () {
    final range = rangeForPreset(PeriodPreset.rollingMonth, now);
    expect(range.from, DateTime(2026, 7, 5));
    expect(range.to, DateTime(2026, 8, 4, 23, 59, 59));
  });

  test('detectPreset treats missing dates as next7Days default', () {
    expect(detectPreset(null, null, now), PeriodPreset.next7Days);

    final defaults = presetToFilterDates(preset: PeriodPreset.next7Days, now: now);
    expect(defaults.dateFrom, isNull);
    expect(defaults.dateTo, isNull);
  });

  test('detectPreset recognizes explicit presets', () {
    final today = presetToFilterDates(preset: PeriodPreset.today, now: now);
    expect(
      detectPreset(today.dateFrom, today.dateTo, now),
      PeriodPreset.today,
    );

    final month = presetToFilterDates(preset: PeriodPreset.rollingMonth, now: now);
    expect(
      detectPreset(month.dateFrom, month.dateTo, now),
      PeriodPreset.rollingMonth,
    );
  });
}
