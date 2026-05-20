import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/db/category_dao.dart';
import 'package:aiaccounting/models/category.dart';
import 'package:aiaccounting/providers/category_provider.dart';

void main() {
  late CategoryProvider provider;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  setUp(() async {
    await DatabaseHelper.instance.close();
    // Reset database to get fresh presets
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
    provider = CategoryProvider();
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('CategoryProvider', () {
    test('loadCategories populates list with 7 presets, isLoading = false after',
        () async {
      expect(provider.isLoading, false);
      expect(provider.categories.length, 0);

      await provider.loadCategories();

      expect(provider.categories.length, 7);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
      expect(provider.categories[0].name, '餐饮');
    });

    test('addCategory inserts and refreshes (8 items)', () async {
      await provider.loadCategories();
      expect(provider.categories.length, 7);

      await provider.addCategory('宠物', '#ABCDEF', DateTime.now());
      expect(provider.categories.length, 8);
      expect(provider.categories.any((c) => c.name == '宠物'), isTrue);
    });

    test('deleteCategory throws for preset id', () async {
      await provider.loadCategories();
      final presetId = provider.categories.first.id!;

      expect(
        () => provider.deleteCategory(presetId),
        throwsA(isA<Exception>()),
      );
    });

    test('deleteCategory works for custom id', () async {
      await provider.loadCategories();
      await provider.addCategory('自定义', '#000000', DateTime.now());
      final custom = provider.categories.firstWhere((c) => c.name == '自定义');

      await provider.deleteCategory(custom.id!);
      expect(provider.categories.any((c) => c.name == '自定义'), isFalse);
    });

    test('updateCategory modifies name', () async {
      await provider.loadCategories();
      final original = provider.categories.first;
      final updated = original.copyWith(name: '美食');

      await provider.updateCategory(updated);

      final reloaded = provider.categories.firstWhere((c) => c.id == original.id);
      expect(reloaded.name, '美食');
    });

    test('updateCategory nonexistent id does not throw', () async {
      // Load categories first to establish a baseline
      await provider.loadCategories();
      final count = provider.categories.length;

      final fake = Category(
        id: 99999,
        name: '不存在',
        color: '#000000',
        createdAt: DateTime.now(),
      );

      // Updating a non-existent category should not throw
      await provider.updateCategory(fake);
      // The list should still have the same number of items (no new category added)
      expect(provider.categories.length, count);
    });

    test('reorderCategories changes sort orders', () async {
      await provider.loadCategories();
      final ids = provider.categories.map((c) => c.id!).toList().reversed.toList();
      final typedIds = ids.cast<int>();

      await provider.reorderCategories(typedIds);

      expect(provider.categories.first.sortOrder, 0);
      expect(provider.categories.last.sortOrder, 6);
    });
  });
}
