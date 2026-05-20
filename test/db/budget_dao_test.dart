import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/db/budget_dao.dart';
import 'package:aiaccounting/models/budget.dart';

void main() {
  late BudgetDao dao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  setUp(() async {
    await DatabaseHelper.instance.close();
    dao = BudgetDao();
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('BudgetDao', () {
    test('getActive returns null when no budget', () async {
      expect(await dao.getActive('monthly'), isNull);
    });

    test('upsert creates and updates budget', () async {
      final id = await dao.upsert(Budget(
          type: 'monthly', amount: 5000.0, createdAt: DateTime.now()));
      expect(id, greaterThan(0));
      final active = await dao.getActive('monthly');
      expect(active, isNotNull);
      expect(active!.amount, 5000.0);
      // upsert again: deactivates old, inserts new
      final id2 = await dao.upsert(Budget(
          type: 'monthly', amount: 8000.0, createdAt: DateTime.now()));
      expect(id2, greaterThan(id));
      final updated = await dao.getActive('monthly');
      expect(updated!.amount, 8000.0);
    });

    test('deactivate sets is_active = 0', () async {
      await dao.upsert(Budget(
          type: 'weekly', amount: 1000.0, createdAt: DateTime.now()));
      expect(await dao.getActive('weekly'), isNotNull);
      await dao.deactivate('weekly');
      expect(await dao.getActive('weekly'), isNull);
    });

    test('only one active per type', () async {
      await dao.upsert(Budget(
          type: 'monthly', amount: 3000.0, createdAt: DateTime.now()));
      await dao.upsert(Budget(
          type: 'monthly', amount: 5000.0, createdAt: DateTime.now()));
      // Only the newest should be active
      final active = await dao.getActive('monthly');
      expect(active!.amount, 5000.0);
    });

    test('monthly and weekly budgets are independent', () async {
      await dao.upsert(Budget(
          type: 'monthly', amount: 5000.0, createdAt: DateTime.now()));
      await dao.upsert(Budget(
          type: 'weekly', amount: 1000.0, createdAt: DateTime.now()));
      final monthly = await dao.getActive('monthly');
      final weekly = await dao.getActive('weekly');
      expect(monthly!.amount, 5000.0);
      expect(weekly!.amount, 1000.0);
    });
  });
}
