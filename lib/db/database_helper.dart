import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'aiaccounting.db');
    return openDatabase(path, version: 2, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        icon TEXT DEFAULT 'category',
        color TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0,
        is_preset INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category_id INTEGER NOT NULL,
        note TEXT,
        recorded_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        source TEXT DEFAULT 'manual',
        external_id TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_expenses_dedup ON expenses(source, external_id) WHERE external_id IS NOT NULL');
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('weekly', 'monthly')),
        amount REAL NOT NULL,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    final now = DateTime.now().toIso8601String();
    for (final cat in presetCategories()) {
      await db.insert('categories', {
        'name': cat.name,
        'icon': cat.icon,
        'color': cat.color,
        'sort_order': cat.sortOrder,
        'is_preset': 1,
        'created_at': now,
      });
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE expenses ADD COLUMN source TEXT DEFAULT 'manual'");
      await db.execute('ALTER TABLE expenses ADD COLUMN external_id TEXT');
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_expenses_dedup ON expenses(source, external_id) WHERE external_id IS NOT NULL');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
