import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/models/budget.dart';

void main() {
  group('Budget', () {
    final tBudget = Budget(type: 'monthly', amount: 5000.0, createdAt: DateTime(2026, 5, 1));

    test('toMap', () {
      final map = tBudget.toMap();
      expect(map['type'], 'monthly');
      expect(map['amount'], 5000.0);
      expect(map['is_active'], 1);
    });

    test('fromMap', () {
      final map = {'id': 1, 'type': 'weekly', 'amount': 1000.0, 'is_active': 0,
          'created_at': '2026-05-20T10:00:00.000'};
      final b = Budget.fromMap(map);
      expect(b.id, 1); expect(b.type, 'weekly'); expect(b.isActive, false);
    });
  });
}
