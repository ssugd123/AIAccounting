import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/expense.dart';

class ExpenseDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db => _dbHelper.database;

  Future<int> insert(Expense e) async {
    final db = await _db;
    return db.insert('expenses', e.toMap());
  }

  Future<int> insertIfNotExists(Expense expense) async {
    final db = await _db;
    // Check dedup
    if (expense.externalId != null && expense.externalId!.isNotEmpty) {
      final existing = await db.rawQuery(
        'SELECT id FROM expenses WHERE source = ? AND external_id = ?',
        [expense.source, expense.externalId],
      );
      if (existing.isNotEmpty) return -1; // already exists, skip
    }
    return db.insert('expenses', expense.toMap());
  }

  Future<int> insertAll(List<Expense> expenses) async {
    int count = 0;
    final db = await _db;
    final batch = db.batch();
    for (final expense in expenses) {
      if (expense.externalId != null && expense.externalId!.isNotEmpty) {
        // Can't easily check per-item in batch — use individual inserts for dedup
        final result = await insertIfNotExists(expense);
        if (result > 0) count++;
      } else {
        batch.insert('expenses', expense.toMap());
        count++;
      }
    }
    await batch.commit(noResult: true);
    return count;
  }

  Future<int> update(Expense e) async {
    final db = await _db;
    return db.update('expenses', e.toMap(),
        where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    return db.delete('expenses',
        where: 'recorded_at >= ? AND recorded_at <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<List<ExpenseWithCategory>> _query(String where, List<dynamic> args,
      {int? limit, int? offset}) async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT e.*, c.name as category_name, c.color as category_color, c.icon as category_icon
      FROM expenses e LEFT JOIN categories c ON e.category_id = c.id
      $where ORDER BY e.recorded_at DESC
      ${limit != null ? 'LIMIT $limit' : ''} ${offset != null ? 'OFFSET $offset' : ''}
    ''', args);
    return maps.map((m) => ExpenseWithCategory.fromMap(m)).toList();
  }

  Future<ExpenseWithCategory?> getById(int id) async {
    final list = await _query('WHERE e.id = ?', [id]);
    return list.isEmpty ? null : list.first;
  }

  Future<List<ExpenseWithCategory>> getAll({int? limit, int? offset}) =>
      _query('', [], limit: limit, offset: offset);

  Future<List<ExpenseWithCategory>> getByDateRange(
          DateTime start, DateTime end) =>
      _query('WHERE e.recorded_at >= ? AND e.recorded_at <= ?',
          [start.toIso8601String(), end.toIso8601String()]);

  Future<List<ExpenseWithCategory>> getByCategory(int categoryId) =>
      _query('WHERE e.category_id = ?', [categoryId]);

  Future<List<ExpenseWithCategory>> getFiltered(
      {DateTime? start, DateTime? end, int? categoryId}) {
    final conds = <String>[];
    final args = <dynamic>[];
    if (start != null) {
      conds.add('e.recorded_at >= ?');
      args.add(start.toIso8601String());
    }
    if (end != null) {
      conds.add('e.recorded_at <= ?');
      args.add(end.toIso8601String());
    }
    if (categoryId != null) {
      conds.add('e.category_id = ?');
      args.add(categoryId);
    }
    return _query(
        conds.isNotEmpty ? 'WHERE ${conds.join(' AND ')}' : '', args);
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE recorded_at >= ? AND recorded_at <= ?',
        [start.toIso8601String(), end.toIso8601String()]);
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getSumByCategory(
      DateTime start, DateTime end) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT c.name, COALESCE(SUM(e.amount), 0) as total
      FROM expenses e JOIN categories c ON e.category_id = c.id
      WHERE e.recorded_at >= ? AND e.recorded_at <= ?
      GROUP BY c.id ORDER BY total DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return {
      for (final row in results)
        row['name'] as String: (row['total'] as num).toDouble()
    };
  }

  Future<Map<String, double>> getDailySum(DateTime start, DateTime end) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT DATE(recorded_at) as day, COALESCE(SUM(amount), 0) as total
      FROM expenses WHERE recorded_at >= ? AND recorded_at <= ?
      GROUP BY DATE(recorded_at) ORDER BY day
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return {
      for (final row in results)
        row['day'] as String: (row['total'] as num).toDouble()
    };
  }
}
