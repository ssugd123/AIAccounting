import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/budget.dart';

class BudgetDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db => _dbHelper.database;

  Future<Budget?> getActive(String type) async {
    final db = await _db;
    final maps = await db.query('budgets',
        where: 'type = ? AND is_active = 1', whereArgs: [type]);
    return maps.isEmpty ? null : Budget.fromMap(maps.first);
  }

  Future<int> upsert(Budget budget) async {
    final db = await _db;
    await db.update('budgets', {'is_active': 0},
        where: 'type = ?', whereArgs: [budget.type]);
    return db.insert('budgets', budget.toMap());
  }

  Future<void> deactivate(String type) async {
    final db = await _db;
    await db.update('budgets', {'is_active': 0},
        where: 'type = ?', whereArgs: [type]);
  }
}
