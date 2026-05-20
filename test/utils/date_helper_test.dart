import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/utils/date_helper.dart';

void main() {
  group('DateHelper', () {
    test('todayRange', () {
      final now = DateTime(2026, 5, 20, 15, 30);
      final range = DateHelper.todayRange(now);
      expect(range.start, DateTime(2026, 5, 20, 0, 0, 0));
      expect(range.end, DateTime(2026, 5, 20, 23, 59, 59, 999));
    });

    test('weekRange returns Mon-Sun', () {
      final wed = DateTime(2026, 5, 20);
      final range = DateHelper.weekRange(wed);
      expect(range.start.weekday, DateTime.monday);
      expect(range.end.weekday, DateTime.sunday);
    });

    test('monthRange', () {
      final range = DateHelper.monthRange(2026, 5);
      expect(range.start, DateTime(2026, 5, 1));
      expect(range.end, DateTime(2026, 5, 31, 23, 59, 59, 999));
    });

    test('yearRange', () {
      final range = DateHelper.yearRange(2026);
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 12, 31, 23, 59, 59, 999));
    });

    test('formatDate', () {
      expect(DateHelper.formatDate(DateTime(2026, 5, 20)), '2026-05-20');
    });

    test('formatMonth', () {
      expect(DateHelper.formatMonth(2026, 5), '2026年05月');
    });

    test('daysInMonth', () {
      expect(DateHelper.daysInMonth(2026, 2), 28);
      expect(DateHelper.daysInMonth(2024, 2), 29);
    });
  });
}
