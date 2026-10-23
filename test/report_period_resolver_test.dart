import 'package:flutter_test/flutter_test.dart';
import 'package:mikiezy/domain/services/report_period_resolver.dart';

void main() {
  const resolver = ReportPeriodResolver();
  final now = DateTime(2026, 7, 13, 10, 30);

  test('resolves today and yesterday with an exclusive end', () {
    final today = resolver.resolve(ReportPeriodType.today, now: now);
    final yesterday = resolver.resolve(ReportPeriodType.yesterday, now: now);

    expect(today.start, DateTime(2026, 7, 13));
    expect(today.end, now);
    expect(today.contains(DateTime(2026, 7, 13)), isTrue);
    expect(today.contains(now), isFalse);
    expect(yesterday.start, DateTime(2026, 7, 12));
    expect(yesterday.end, DateTime(2026, 7, 13));
  });

  test('uses Monday as the start of this week and last week', () {
    final thisWeek = resolver.resolve(ReportPeriodType.thisWeek, now: now);
    final lastWeek = resolver.resolve(ReportPeriodType.lastWeek, now: now);

    expect(thisWeek.start, DateTime(2026, 7, 13));
    expect(thisWeek.end, now);
    expect(lastWeek.start, DateTime(2026, 7, 6));
    expect(lastWeek.end, DateTime(2026, 7, 13));
  });

  test('resolves current and previous month across a month boundary', () {
    final thisMonth = resolver.resolve(ReportPeriodType.thisMonth, now: now);
    final lastMonth = resolver.resolve(ReportPeriodType.lastMonth, now: now);

    expect(thisMonth.start, DateTime(2026, 7));
    expect(thisMonth.end, now);
    expect(lastMonth.start, DateTime(2026, 6));
    expect(lastMonth.end, DateTime(2026, 7));
  });

  test('resolves previous month across a year boundary', () {
    final januaryNow = DateTime(2026, 1, 5, 8);
    final lastMonth = resolver.resolve(
      ReportPeriodType.lastMonth,
      now: januaryNow,
    );

    expect(lastMonth.start, DateTime(2025, 12));
    expect(lastMonth.end, DateTime(2026, 1));
  });

  test('start is inclusive and end is exclusive', () {
    final range = resolver.resolve(ReportPeriodType.yesterday, now: now);

    expect(range.contains(DateTime(2026, 7, 12)), isTrue);
    expect(range.contains(DateTime(2026, 7, 12, 23, 59, 59, 999, 999)), isTrue);
    expect(range.contains(DateTime(2026, 7, 13)), isFalse);
  });

  test('all-time range accepts dates on either side of now', () {
    final range = resolver.resolve(ReportPeriodType.allTime, now: now);

    expect(range.start, isNull);
    expect(range.end, isNull);
    expect(range.contains(DateTime(2000)), isTrue);
    expect(range.contains(DateTime(2030)), isTrue);
  });
}
