import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/providers/budget_provider.dart';

void main() {
  late BudgetProvider provider;

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
    provider = BudgetProvider();
  });

  tearDown(() async {
    await DatabaseHelper.instance.close();
  });

  group('BudgetProvider', () {
    test('loadBudgets returns null initially', () async {
      expect(provider.monthlyBudget, isNull);
      expect(provider.weeklyBudget, isNull);

      await provider.loadBudgets();

      expect(provider.monthlyBudget, isNull);
      expect(provider.weeklyBudget, isNull);
      expect(provider.isLoading, false);
    });

    test('setBudget creates and loads budget', () async {
      await provider.setBudget('monthly', 5000.0);

      expect(provider.monthlyBudget, isNotNull);
      expect(provider.monthlyBudget!.amount, 5000.0);
      expect(provider.monthlyBudget!.type, 'monthly');
      expect(provider.monthlyBudget!.isActive, isTrue);
    });

    test('setBudget replaces existing budget same type', () async {
      await provider.setBudget('monthly', 3000.0);
      expect(provider.monthlyBudget!.amount, 3000.0);

      await provider.setBudget('monthly', 8000.0);
      expect(provider.monthlyBudget!.amount, 8000.0);
    });

    test('removeBudget deactivates', () async {
      await provider.setBudget('weekly', 1000.0);
      expect(provider.weeklyBudget, isNotNull);

      await provider.removeBudget('weekly');
      expect(provider.weeklyBudget, isNull);
    });

    test('getBudgetRemaining returns correct value', () async {
      await provider.setBudget('monthly', 5000.0);
      final remaining = provider.getBudgetRemaining('monthly', 2000.0);
      expect(remaining, 3000.0);
    });

    test('isOverBudget returns true when spent > budget', () async {
      await provider.setBudget('monthly', 5000.0);
      expect(provider.isOverBudget('monthly', 6000.0), isTrue);
      expect(provider.isOverBudget('monthly', 3000.0), isFalse);
    });

    test('getBudgetRemaining returns null when no budget', () async {
      expect(provider.getBudgetRemaining('monthly', 1000.0), isNull);
    });

    test('isOverBudget returns false when no budget', () async {
      expect(provider.isOverBudget('monthly', 10000.0), isFalse);
    });
  });
}
