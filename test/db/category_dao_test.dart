import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/db/category_dao.dart';
import 'package:aiaccounting/models/category.dart';

void main() {
  late CategoryDao dao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  setUp(() async {
    await DatabaseHelper.instance.close();
    dao = CategoryDao();
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('CategoryDao', () {
    test('getAll returns 7 presets sorted', () async {
      final cats = await dao.getAll();
      expect(cats.length, 7);
      expect(cats[0].name, '餐饮');
    });

    test('insert adds category', () async {
      final id = await dao.insert(Category(
          name: '宠物', color: '#ABCDEF', createdAt: DateTime.now()));
      expect(id, greaterThan(0));
      expect((await dao.getAll()).length, 8);
      // Clean up to avoid affecting subsequent tests
      await dao.delete(id);
    });

    test('insert duplicate name throws', () async {
      await expectLater(
        dao.insert(Category(
            name: '餐饮', color: '#FF0000', createdAt: DateTime.now())),
        throwsA(isA<Exception>()),
      );
    });

    test('update modifies name', () async {
      final cats = await dao.getAll();
      final original = cats.first;
      final updated = original.copyWith(name: '美食');
      expect(await dao.update(updated), 1);
      expect((await dao.getById(original.id!))!.name, '美食');
      // Restore the original name
      await dao.update(original);
    });

    test('delete preset throws', () async {
      final cats = await dao.getAll();
      await expectLater(dao.delete(cats.first.id!), throwsA(isA<Exception>()));
    });

    test('delete custom works', () async {
      final id = await dao.insert(Category(
          name: '自定义', color: '#000000', createdAt: DateTime.now()));
      expect(await dao.delete(id), 1);
      expect(await dao.getById(id), isNull);
    });

    test('updateSortOrder reorders', () async {
      final cats = await dao.getAll();
      expect(cats.length, 7);
      final ids = cats.map((c) => c.id!).toList().reversed.toList();
      await dao.updateSortOrder(ids);
      final reordered = await dao.getAll();
      expect(reordered.first.sortOrder, 0);
      expect(reordered.last.sortOrder, 6);
    });
  });
}
