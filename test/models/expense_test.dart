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
      expect(e.source, 'manual'); // default
      expect(e.externalId, isNull);
    });

    test('copyWith with clearNote', () {
      final updated = tExpense.copyWith(clearNote: true);
      expect(updated.note, isNull);
    });

    test('source and externalId in toMap', () {
      final e = Expense(amount: 10.0, categoryId: 1,
          recordedAt: DateTime(2026, 5, 20), createdAt: DateTime(2026, 5, 20),
          updatedAt: DateTime(2026, 5, 20), source: 'wechat', externalId: '12345');
      final map = e.toMap();
      expect(map['source'], 'wechat');
      expect(map['external_id'], '12345');
    });

    test('source and externalId in fromMap', () {
      final map = {'id': 2, 'amount': 10.0, 'category_id': 1, 'note': 'test',
          'recorded_at': '2026-05-20T10:00:00.000', 'created_at': '2026-05-20T10:05:00.000',
          'updated_at': '2026-05-20T10:05:00.000', 'source': 'alipay', 'external_id': 'abc'};
      final e = Expense.fromMap(map);
      expect(e.source, 'alipay');
      expect(e.externalId, 'abc');
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
