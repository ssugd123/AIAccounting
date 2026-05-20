class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);
}

class DateHelper {
  static DateRange todayRange([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DateRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
    );
  }

  static DateRange weekRange([DateTime? date]) {
    final d = date ?? DateTime.now();
    final start = DateTime(d.year, d.month, d.day - d.weekday + 1);
    return DateRange(
      start,
      DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999),
    );
  }

  static DateRange monthRange(int year, int month) => DateRange(
      DateTime(year, month, 1), DateTime(year, month + 1, 0, 23, 59, 59, 999));

  static DateRange yearRange(int year) => DateRange(
      DateTime(year, 1, 1), DateTime(year, 12, 31, 23, 59, 59, 999));

  static String formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String formatMonth(int year, int month) =>
      '$year年${month.toString().padLeft(2, '0')}月';

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;
}
