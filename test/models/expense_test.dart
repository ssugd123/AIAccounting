import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/models/expense.dart';

void main() {
  group('Expense', () {
    final tExpense = Expense(amount: 25.50, categoryId: 1, note: '午餐外卖',
        recordedAt: DateTime(2026, 5, 20, 12, 30), createdAt: DateTime(2026, 5, 20, 12, 35),
        updatedAt: DateTime(2026, 5, 20, 12, 35));

    test('toMap', () {
      final map = tExpense.toMap();
      expect(map['amount'], 25.50);
      expect(map['category_id'], 1);
      expect(map['note'], '午餐外卖');
      expect(map['recorded_at'], '2026-05-20T12:30:00.000');
    });

    test('fromMap', () {
      final map = {'id': 1, 'amount': 8.0, 'category_id': 1, 'note': null,
          'recorded_at': '2026-05-20T08:00:00.000', 'created_at': '2026-05-20T08:05:00.000',
          'updated_at': '2026-05-20T08:05:00.000'};
      final e = Expense.fromMap(map);
      expect(e.id, 1); expect(e.amount, 8.0); expect(e.note, isNull);
    });

    test('copyWith with clearNote', () {
      final updated = tExpense.copyWith(clearNote: true);
      expect(updated.note, isNull);
    });
  });

  group('ExpenseWithCategory', () {
    test('fromMap', () {
      final map = {'id': 1, 'amount': 15.0, 'category_id': 1, 'note': '测试',
          'recorded_at': '2026-05-20T10:00:00.000', 'created_at': '2026-05-20T10:05:00.000',
          'updated_at': '2026-05-20T10:05:00.000', 'category_name': '餐饮',
          'category_color': '#FF6B6B', 'category_icon': 'restaurant'};
      final ewc = ExpenseWithCategory.fromMap(map);
      expect(ewc.categoryName, '餐饮');
      expect(ewc.categoryColor, '#FF6B6B');
    });
  });
}
