import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // Start each test suite with a clean database
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('DatabaseHelper', () {
    test('creates all tables', () async {
      final db = await DatabaseHelper.instance.database;
      final tables = (await db
              .rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"))
          .map((t) => t['name'] as String)
          .toList();
      expect(tables, containsAll(['categories', 'expenses', 'budgets']));
    });

    test('inserts 7 preset categories on create', () async {
      final db = await DatabaseHelper.instance.database;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'));
      expect(count, 7);
    });

    test('onCreate does not re-fire on re-open', () async {
      await DatabaseHelper.instance.close();
      final db = await DatabaseHelper.instance.database;
      final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM categories'));
      expect(count, 7);
    });

    test('expenses table has source and external_id columns', () async {
      final db = await DatabaseHelper.instance.database;
      final cols = await db.rawQuery('PRAGMA table_info(expenses)');
      final colNames = cols.map((c) => c['name'] as String).toList();
      expect(colNames, contains('source'));
      expect(colNames, contains('external_id'));
    });
  });
}
