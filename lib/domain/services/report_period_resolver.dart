enum ReportPeriodType {
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  allTime,
}

extension ReportPeriodTypeLabel on ReportPeriodType {
  String get label => switch (this) {
    ReportPeriodType.today => 'hari ini',
    ReportPeriodType.yesterday => 'kemarin',
    ReportPeriodType.thisWeek => 'minggu ini',
    ReportPeriodType.lastWeek => 'minggu lalu',
    ReportPeriodType.thisMonth => 'bulan ini',
    ReportPeriodType.lastMonth => 'bulan lalu',
    ReportPeriodType.allTime => 'sepanjang waktu',
  };
}

class ReportPeriodRange {
  const ReportPeriodRange({required this.type, this.start, this.end});

  final ReportPeriodType type;
  final DateTime? start;
  final DateTime? end;

  bool contains(DateTime value) {
    final startValue = start;
    if (startValue != null && value.isBefore(startValue)) return false;
    final endValue = end;
    if (endValue != null && !value.isBefore(endValue)) return false;
    return true;
  }
}

class ReportPeriodResolver {
  const ReportPeriodResolver();

  ReportPeriodRange resolve(ReportPeriodType period, {required DateTime now}) {
    final localNow = now.isUtc ? now.toLocal() : now;
    final today = DateTime(localNow.year, localNow.month, localNow.day);
    final thisWeek = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final thisMonth = DateTime(localNow.year, localNow.month);

    return switch (period) {
      ReportPeriodType.today => ReportPeriodRange(
        type: period,
        start: today,
        end: localNow,
      ),
      ReportPeriodType.yesterday => ReportPeriodRange(
        type: period,
        start: today.subtract(const Duration(days: 1)),
        end: today,
      ),
      ReportPeriodType.thisWeek => ReportPeriodRange(
        type: period,
        start: thisWeek,
        end: localNow,
      ),
      ReportPeriodType.lastWeek => ReportPeriodRange(
        type: period,
        start: thisWeek.subtract(const Duration(days: 7)),
        end: thisWeek,
      ),
      ReportPeriodType.thisMonth => ReportPeriodRange(
        type: period,
        start: thisMonth,
        end: localNow,
      ),
      ReportPeriodType.lastMonth => ReportPeriodRange(
        type: period,
        start: DateTime(localNow.year, localNow.month - 1),
        end: thisMonth,
      ),
      ReportPeriodType.allTime => ReportPeriodRange(type: period),
    };
  }
}
