import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../models/category.dart';

class CategoryDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  Future<Database> get _db => _dbHelper.database;

  Future<List<Category>> getAll() async {
    final db = await _db;
    final maps = await db.query('categories', orderBy: 'sort_order ASC');
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  Future<Category?> getById(int id) async {
    final db = await _db;
    final maps =
        await db.query('categories', where: 'id = ?', whereArgs: [id]);
    return maps.isEmpty ? null : Category.fromMap(maps.first);
  }

  Future<int> insert(Category category) async {
    final db = await _db;
    try {
      return await db.insert('categories', category.toMap());
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) throw Exception('分类名称已存在');
      rethrow;
    }
  }

  Future<int> update(Category category) async {
    final db = await _db;
    return db.update('categories', category.toMap(),
        where: 'id = ?', whereArgs: [category.id]);
  }

  Future<int> delete(int id) async {
    final cat = await getById(id);
    if (cat == null) return 0;
    if (cat.isPreset) throw Exception('预设分类不可删除');
    final db = await _db;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateSortOrder(List<int> ids) async {
    final db = await _db;
    final batch = db.batch();
    for (int i = 0; i < ids.length; i++) {
      batch.update('categories', {'sort_order': i},
          where: 'id = ?', whereArgs: [ids[i]]);
    }
    await batch.commit(noResult: true);
  }
}
