import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/models/category.dart';

void main() {
  group('Category', () {
    final tCategory = Category(name: '餐饮', icon: 'restaurant', color: '#FF6B6B',
        sortOrder: 0, isPreset: true, createdAt: DateTime(2026, 5, 20, 10, 0));

    test('toMap returns correct map', () {
      final map = tCategory.toMap();
      expect(map['name'], '餐饮');
      expect(map['icon'], 'restaurant');
      expect(map['color'], '#FF6B6B');
      expect(map['sort_order'], 0);
      expect(map['is_preset'], 1);
      expect(map['created_at'], '2026-05-20T10:00:00.000');
    });

    test('fromMap creates correct Category', () {
      final map = {'id': 1, 'name': '交通', 'icon': 'directions_bus', 'color': '#4ECDC4',
          'sort_order': 1, 'is_preset': 1, 'created_at': '2026-05-20T10:00:00.000'};
      final cat = Category.fromMap(map);
      expect(cat.id, 1);
      expect(cat.name, '交通');
      expect(cat.isPreset, true);
    });

    test('fromMap without id has null id', () {
      final map = {'name': '购物', 'color': '#A29BFE', 'created_at': '2026-05-20T10:00:00.000'};
      expect(Category.fromMap(map).id, isNull);
    });

    test('copyWith returns updated instance', () {
      final updated = tCategory.copyWith(name: '美食');
      expect(updated.name, '美食');
      expect(updated.color, tCategory.color);
    });
  });
}
