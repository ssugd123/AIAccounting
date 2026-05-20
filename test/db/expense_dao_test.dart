import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/db/expense_dao.dart';
import 'package:aiaccounting/models/expense.dart';

void main() {
  late ExpenseDao dao;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  setUp(() async {
    await DatabaseHelper.instance.close();
    // Reset data for clean test state
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
    dao = ExpenseDao();
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  Future<Database> _getDb() async => DatabaseHelper.instance.database;

  /// Helper: insert a test expense referencing the first preset category.
  Future<int> _insert(double amount, DateTime at,
      {String? note, int? categoryId}) async {
    final db = await _getDb();
    final cats = await db.query('categories', limit: 1);
    final id = categoryId ?? (cats.first['id'] as int);
    return dao.insert(Expense(
      amount: amount,
      categoryId: id,
      note: note,
      recordedAt: at,
      createdAt: at,
      updatedAt: at,
    ));
  }

  group('ExpenseDao', () {
    test('insert returns id > 0', () async {
      final id = await _insert(50.0, DateTime(2026, 5, 20));
      expect(id, greaterThan(0));
    });

    test('getAll returns expenses with category info, newest first', () async {
      await _insert(10.0, DateTime(2026, 5, 18));
      await _insert(20.0, DateTime(2026, 5, 20));
      final list = await dao.getAll();
      expect(list.length, 2);
      expect(list.first.expense.amount, 20.0);
      expect(list.first.categoryName, isNotEmpty);
    });

    test('getById returns correct expense', () async {
      final id = await _insert(30.0, DateTime(2026, 5, 20));
      final e = await dao.getById(id);
      expect(e, isNotNull);
      expect(e!.expense.amount, 30.0);
    });

    test('getById returns null for missing', () async {
      expect(await dao.getById(999), isNull);
    });

    test('getByDateRange filters correctly', () async {
      await _insert(10.0, DateTime(2026, 5, 15));
      await _insert(20.0, DateTime(2026, 5, 20));
      await _insert(30.0, DateTime(2026, 5, 25));
      final list = await dao.getByDateRange(
          DateTime(2026, 5, 18), DateTime(2026, 5, 22));
      expect(list.length, 1);
      expect(list.first.expense.amount, 20.0);
    });

    test('getByCategory filters by category', () async {
      final db = await _getDb();
      final cats = await db.query('categories');
      final catId = cats.first['id'] as int;
      await _insert(10.0, DateTime(2026, 5, 20), categoryId: catId);
      final list = await dao.getByCategory(catId);
      expect(list.length, 1);
      expect(list.first.expense.categoryId, catId);
    });

    test('getFiltered combines conditions', () async {
      final db = await _getDb();
      final cats = await db.query('categories');
      final cat1 = cats[0]['id'] as int;
      final cat2 = cats[1]['id'] as int;
      await _insert(10.0, DateTime(2026, 5, 10), categoryId: cat1);
      await _insert(20.0, DateTime(2026, 5, 20), categoryId: cat2);
      await _insert(30.0, DateTime(2026, 5, 30), categoryId: cat1);
      // filter by date range and category
      final list = await dao.getFiltered(
          start: DateTime(2026, 5, 1),
          end: DateTime(2026, 5, 25),
          categoryId: cat1);
      expect(list.length, 1);
      expect(list.first.expense.amount, 10.0);
    });

    test('update modifies amount', () async {
      final id = await _insert(40.0, DateTime(2026, 5, 20));
      final e = await dao.getById(id);
      final updated = e!.expense.copyWith(amount: 99.99);
      expect(await dao.update(updated), 1);
      final reloaded = await dao.getById(id);
      expect(reloaded!.expense.amount, 99.99);
    });

    test('delete removes expense', () async {
      final id = await _insert(50.0, DateTime(2026, 5, 20));
      expect(await dao.delete(id), 1);
      expect(await dao.getById(id), isNull);
    });

    test('getTotalByDateRange sums correctly', () async {
      await _insert(10.0, DateTime(2026, 5, 20));
      await _insert(20.0, DateTime(2026, 5, 21));
      await _insert(30.0, DateTime(2026, 6, 1));
      final total = await dao.getTotalByDateRange(
          DateTime(2026, 5, 1), DateTime(2026, 5, 31));
      expect(total, 30.0);
    });

    test('getSumByCategory groups sums', () async {
      final db = await _getDb();
      final cats = await db.query('categories');
      final cat1 = cats[0]['id'] as int;
      final cat2 = cats[1]['id'] as int;
      final cat1Name = cats[0]['name'] as String;
      final cat2Name = cats[1]['name'] as String;
      await _insert(10.0, DateTime(2026, 5, 20), categoryId: cat1);
      await _insert(20.0, DateTime(2026, 5, 20), categoryId: cat2);
      await _insert(5.0, DateTime(2026, 5, 21), categoryId: cat1);
      final sums = await dao.getSumByCategory(
          DateTime(2026, 5, 1), DateTime(2026, 5, 31));
      expect(sums[cat1Name], 15.0);
      expect(sums[cat2Name], 20.0);
    });

    test('getDailySum returns daily totals', () async {
      await _insert(10.0, DateTime(2026, 5, 20, 10, 0));
      await _insert(20.0, DateTime(2026, 5, 20, 18, 0));
      await _insert(5.0, DateTime(2026, 5, 21));
      final dailies = await dao.getDailySum(
          DateTime(2026, 5, 1), DateTime(2026, 5, 31));
      expect(dailies['2026-05-20'], 30.0);
      expect(dailies['2026-05-21'], 5.0);
    });

    test('deleteByDateRange removes matching', () async {
      await _insert(10.0, DateTime(2026, 5, 10));
      await _insert(20.0, DateTime(2026, 5, 20));
      await _insert(30.0, DateTime(2026, 5, 30));
      await dao.deleteByDateRange(
          DateTime(2026, 5, 15), DateTime(2026, 5, 25));
      final remaining = await dao.getAll();
      expect(remaining.length, 2);
    });

    test('getAll supports limit and offset', () async {
      await _insert(10.0, DateTime(2026, 5, 20));
      await _insert(20.0, DateTime(2026, 5, 21));
      await _insert(30.0, DateTime(2026, 5, 22));
      final page = await dao.getAll(limit: 2, offset: 1);
      expect(page.length, 2);
      expect(page.first.expense.amount, 20.0); // newest first: 22, 21
      expect(page.last.expense.amount, 10.0);
    });
  });
}
