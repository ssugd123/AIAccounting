import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/models/expense.dart';
import 'package:aiaccounting/providers/expense_provider.dart';

void main() {
  late ExpenseProvider provider;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
  });

  setUp(() async {
    await DatabaseHelper.instance.close();
    final dbPath = join(await getDatabasesPath(), 'aiaccounting.db');
    await databaseFactoryFfi.deleteDatabase(dbPath);
    provider = ExpenseProvider();
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  Future<int> _getFirstCategoryId() async {
    final db = await DatabaseHelper.instance.database;
    final cats = await db.query('categories', limit: 1);
    return cats.first['id'] as int;
  }

  Future<int> _insert(ExpenseProvider p, double amount, DateTime at,
      {String? note}) async {
    final catId = await _getFirstCategoryId();
    return p.addExpense(Expense(
      amount: amount,
      categoryId: catId,
      note: note,
      recordedAt: at,
      createdAt: at,
      updatedAt: at,
    ));
  }

  group('ExpenseProvider', () {
    test('loadExpenses returns expenses with category info', () async {
      await _insert(provider, 50.0, DateTime(2026, 5, 20));
      await _insert(provider, 30.0, DateTime(2026, 5, 18));

      await provider.loadExpenses();

      expect(provider.expenses.length, 2);
      expect(provider.expenses.first.expense.amount, 50.0);
      expect(provider.expenses.first.categoryName, isNotEmpty);
      expect(provider.isLoading, false);
      expect(provider.errorMessage, isNull);
    });

    test('loadExpenses with date filter returns filtered results', () async {
      await _insert(provider, 10.0, DateTime(2026, 5, 15));
      await _insert(provider, 20.0, DateTime(2026, 5, 20));
      await _insert(provider, 30.0, DateTime(2026, 5, 25));

      await provider.loadExpenses(
        start: DateTime(2026, 5, 18),
        end: DateTime(2026, 5, 22),
      );

      expect(provider.expenses.length, 1);
      expect(provider.expenses.first.expense.amount, 20.0);
    });

    test('loadExpenses with category filter returns filtered results', () async {
      final catId = await _getFirstCategoryId();
      final catId2 = await _getFirstCategoryId() + 1; // second preset

      await provider.addExpense(Expense(
        amount: 10.0, categoryId: catId, recordedAt: DateTime(2026, 5, 20),
        createdAt: DateTime(2026, 5, 20), updatedAt: DateTime(2026, 5, 20),
      ));
      await provider.addExpense(Expense(
        amount: 20.0, categoryId: catId, recordedAt: DateTime(2026, 5, 21),
        createdAt: DateTime(2026, 5, 21), updatedAt: DateTime(2026, 5, 21),
      ));

      await provider.loadExpenses(categoryId: catId);

      expect(provider.expenses.length, 2);
      expect(provider.expenses.every((e) => e.expense.categoryId == catId), isTrue);
    });

    test('loadRecentExpenses limits to N items', () async {
      await _insert(provider, 10.0, DateTime(2026, 5, 20));
      await _insert(provider, 20.0, DateTime(2026, 5, 21));
      await _insert(provider, 30.0, DateTime(2026, 5, 22));

      await provider.loadRecentExpenses(limit: 2);

      expect(provider.expenses.length, 2);
      expect(provider.expenses.first.expense.amount, 30.0); // newest first
    });

    test('addExpense inserts and refreshes list', () async {
      final id = await _insert(provider, 99.99, DateTime(2026, 5, 20));

      expect(id, greaterThan(0));
      expect(provider.expenses.isNotEmpty, isTrue);
      expect(provider.expenses.any((e) => e.expense.amount == 99.99), isTrue);
    });

    test('loadTotalByDateRange returns correct sum', () async {
      await _insert(provider, 10.0, DateTime(2026, 5, 20));
      await _insert(provider, 20.0, DateTime(2026, 5, 21));
      await _insert(provider, 30.0, DateTime(2026, 6, 1));

      await provider.loadTotalByDateRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 31),
      );

      expect(provider.totalExpense, 30.0);
    });

    test('updateExpense modifies and refreshes', () async {
      await _insert(provider, 40.0, DateTime(2026, 5, 20));
      final original = provider.expenses.first.expense;
      final updated = original.copyWith(amount: 88.88);

      await provider.updateExpense(updated);

      final reloaded = provider.expenses
          .firstWhere((e) => e.expense.id == original.id);
      expect(reloaded.expense.amount, 88.88);
    });

    test('deleteExpense removes and refreshes', () async {
      await _insert(provider, 50.0, DateTime(2026, 5, 20));
      final id = provider.expenses.first.expense.id!;

      await provider.deleteExpense(id);

      expect(provider.expenses.any((e) => e.expense.id == id), isFalse);
    });

    test('deleteByDateRange removes matching items', () async {
      await _insert(provider, 10.0, DateTime(2026, 5, 10));
      await _insert(provider, 20.0, DateTime(2026, 5, 20));
      await _insert(provider, 30.0, DateTime(2026, 5, 30));

      await provider.deleteByDateRange(
        DateTime(2026, 5, 15),
        DateTime(2026, 5, 25),
      );

      expect(provider.expenses.length, 2);
      expect(provider.expenses.any((e) => e.expense.amount == 20.0), isFalse);
    });
  });
}
