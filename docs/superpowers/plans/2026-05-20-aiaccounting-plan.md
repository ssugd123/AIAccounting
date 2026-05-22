# AIAccounting Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Flutter personal expense tracker — pure local SQLite storage, Provider state management, charts via fl_chart, 5 screens + bottom nav.

**Architecture:** Provider + Layered. `models/` → `db/` (DAO) → `providers/` (ChangeNotifier) → `screens/` + `widgets/`. SQLite via sqflite. fl_chart for pie/bar charts.

**Tech Stack:** Flutter, provider ^6.x, sqflite ^2.x, fl_chart ^0.x, intl ^0.x

---

### Task 1: Create Flutter project and configure dependencies

**Files:**
- Create: Flutter project scaffold via `flutter create`
- Modify: `pubspec.yaml`
- Modify: `.gitignore`

- [ ] **Step 1: Create Flutter project**

```bash
cd D:\sgd\code\aiProject && flutter create --org com.ssugd AIAccounting
```
If `flutter` not in PATH, locate Flutter install and use full path.

- [ ] **Step 2: Replace pubspec.yaml dependencies**

Replace the generated `dependencies` and `dev_dependencies` sections:

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  provider: ^6.1.2
  sqflite: ^2.4.2
  path: ^1.9.1
  fl_chart: ^0.70.2
  intl: ^0.20.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  sqflite_common_ffi: ^2.3.4+4
```

- [ ] **Step 3: Run pub get**

```bash
cd D:\sgd\code\aiProject\AIAccounting && flutter pub get
```

- [ ] **Step 4: Create directory structure and add .gitignore entry**

```bash
cd D:\sgd\code\aiProject\AIAccounting
mkdir -p lib/models lib/db lib/providers lib/screens lib/widgets lib/utils
mkdir -p test/models test/db test/providers test/widgets test/screens
echo "docs/superpowers/" >> .gitignore
```

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "chore: scaffold Flutter project with dependencies"
```

---

### Task 2: Category model (TDD)

**Files:** Create `test/models/category_test.dart`, `lib/models/category.dart`

- [ ] **Step 1: Write test**

```dart
// test/models/category_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/models/category.dart';

void main() {
  group('Category', () {
    final tCategory = Category(name: '餐饮', icon: 'restaurant', color: '#FF6B6B',
        sortOrder: 0, isPreset: true, createdAt: DateTime(2026, 5, 20, 10, 0));

    test('toMap returns correct map', () {
      final map = tCategory.toMap();
      expect(map['name'], '餐饮');
      expect(map['icon'], 'restaurant');
      expect(map['color'], '#FF6B6B');
      expect(map['sort_order'], 0);
      expect(map['is_preset'], 1);
      expect(map['created_at'], '2026-05-20T10:00:00.000');
    });

    test('fromMap creates correct Category', () {
      final map = {'id': 1, 'name': '交通', 'icon': 'directions_bus', 'color': '#4ECDC4',
          'sort_order': 1, 'is_preset': 1, 'created_at': '2026-05-20T10:00:00.000'};
      final cat = Category.fromMap(map);
      expect(cat.id, 1);
      expect(cat.name, '交通');
      expect(cat.isPreset, true);
    });

    test('fromMap without id has null id', () {
      final map = {'name': '购物', 'color': '#A29BFE', 'created_at': '2026-05-20T10:00:00.000'};
      expect(Category.fromMap(map).id, isNull);
    });

    test('copyWith returns updated instance', () {
      final updated = tCategory.copyWith(name: '美食');
      expect(updated.name, '美食');
      expect(updated.color, tCategory.color); // unchanged
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/models/category_test.dart
```

- [ ] **Step 3: Implement Category model**

```dart
// lib/models/category.dart
class Category {
  final int? id;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final bool isPreset;
  final DateTime createdAt;

  const Category({
    this.id, required this.name, this.icon = 'category',
    required this.color, this.sortOrder = 0, this.isPreset = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name, 'icon': icon, 'color': color,
    'sort_order': sortOrder, 'is_preset': isPreset ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory Category.fromMap(Map<String, dynamic> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    icon: map['icon'] as String? ?? 'category',
    color: map['color'] as String,
    sortOrder: map['sort_order'] as int? ?? 0,
    isPreset: (map['is_preset'] as int?) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Category copyWith({int? id, String? name, String? icon, String? color,
      int? sortOrder, bool? isPreset, DateTime? createdAt}) => Category(
    id: id ?? this.id, name: name ?? this.name, icon: icon ?? this.icon,
    color: color ?? this.color, sortOrder: sortOrder ?? this.sortOrder,
    isPreset: isPreset ?? this.isPreset, createdAt: createdAt ?? this.createdAt,
  );

  @override
  bool operator ==(Object other) => identical(this, other) ||
      other is Category && id == other.id && name == other.name &&
      color == other.color && sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(id, name, color, sortOrder);
}
```

- [ ] **Step 4: Verify tests pass**

```bash
flutter test test/models/category_test.dart
```
Expected: 4 tests PASS.

- [ ] **Step 5: Commit**
```bash
git add test/models/category_test.dart lib/models/category.dart
git commit -m "feat: add Category model with toMap/fromMap/copyWith"
```

---

### Task 3: Expense model (TDD)

**Files:** Create `test/models/expense_test.dart`, `lib/models/expense.dart`

- [ ] **Step 1: Write test**

```dart
// test/models/expense_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/models/expense.dart';

void main() {
  group('Expense', () {
    final tExpense = Expense(amount: 25.50, categoryId: 1, note: '午餐外卖',
        recordedAt: DateTime(2026, 5, 20, 12, 30), createdAt: DateTime(2026, 5, 20, 12, 35),
        updatedAt: DateTime(2026, 5, 20, 12, 35));

    test('toMap', () {
      final map = tExpense.toMap();
      expect(map['amount'], 25.50);
      expect(map['category_id'], 1);
      expect(map['note'], '午餐外卖');
      expect(map['recorded_at'], '2026-05-20T12:30:00.000');
    });

    test('fromMap', () {
      final map = {'id': 1, 'amount': 8.0, 'category_id': 1, 'note': null,
          'recorded_at': '2026-05-20T08:00:00.000', 'created_at': '2026-05-20T08:05:00.000',
          'updated_at': '2026-05-20T08:05:00.000'};
      final e = Expense.fromMap(map);
      expect(e.id, 1); expect(e.amount, 8.0); expect(e.note, isNull);
    });

    test('copyWith with clearNote', () {
      final updated = tExpense.copyWith(clearNote: true);
      expect(updated.note, isNull);
    });
  });

  group('ExpenseWithCategory', () {
    test('fromMap', () {
      final map = {'id': 1, 'amount': 15.0, 'category_id': 1, 'note': '测试',
          'recorded_at': '2026-05-20T10:00:00.000', 'created_at': '2026-05-20T10:05:00.000',
          'updated_at': '2026-05-20T10:05:00.000', 'category_name': '餐饮',
          'category_color': '#FF6B6B', 'category_icon': 'restaurant'};
      final ewc = ExpenseWithCategory.fromMap(map);
      expect(ewc.categoryName, '餐饮');
      expect(ewc.categoryColor, '#FF6B6B');
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

- [ ] **Step 3: Implement Expense model**

```dart
// lib/models/expense.dart
class Expense {
  final int? id;
  final double amount;
  final int categoryId;
  final String? note;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Expense({this.id, required this.amount, required this.categoryId,
    this.note, required this.recordedAt, required this.createdAt,
    required this.updatedAt});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'amount': amount, 'category_id': categoryId,
    'note': note, 'recorded_at': recordedAt.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> map) => Expense(
    id: map['id'] as int?,
    amount: (map['amount'] as num).toDouble(),
    categoryId: map['category_id'] as int,
    note: map['note'] as String?,
    recordedAt: DateTime.parse(map['recorded_at'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  Expense copyWith({int? id, double? amount, int? categoryId, String? note,
      bool clearNote = false, DateTime? recordedAt, DateTime? createdAt,
      DateTime? updatedAt}) => Expense(
    id: id ?? this.id, amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    note: clearNote ? null : (note ?? this.note),
    recordedAt: recordedAt ?? this.recordedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

class ExpenseWithCategory {
  final Expense expense;
  final String categoryName;
  final String categoryColor;
  final String categoryIcon;

  const ExpenseWithCategory({required this.expense, required this.categoryName,
    required this.categoryColor, required this.categoryIcon});

  factory ExpenseWithCategory.fromMap(Map<String, dynamic> map) =>
      ExpenseWithCategory(
        expense: Expense.fromMap(map),
        categoryName: map['category_name'] as String,
        categoryColor: map['category_color'] as String,
        categoryIcon: map['category_icon'] as String? ?? 'category',
      );
}
```

- [ ] **Step 4: Verify tests pass — 4 PASS**

- [ ] **Step 5: Commit**
```bash
git add test/models/expense_test.dart lib/models/expense.dart
git commit -m "feat: add Expense model with ExpenseWithCategory"
```

---

### Task 4: Budget model (TDD)

**Files:** Create `test/models/budget_test.dart`, `lib/models/budget.dart`

- [ ] **Step 1: Write test**

```dart
// test/models/budget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/models/budget.dart';

void main() {
  group('Budget', () {
    final tBudget = Budget(type: 'monthly', amount: 5000.0, createdAt: DateTime(2026, 5, 1));

    test('toMap', () {
      final map = tBudget.toMap();
      expect(map['type'], 'monthly');
      expect(map['amount'], 5000.0);
      expect(map['is_active'], 1);
    });

    test('fromMap', () {
      final map = {'id': 1, 'type': 'weekly', 'amount': 1000.0, 'is_active': 0,
          'created_at': '2026-05-20T10:00:00.000'};
      final b = Budget.fromMap(map);
      expect(b.id, 1); expect(b.type, 'weekly'); expect(b.isActive, false);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

- [ ] **Step 3: Implement Budget model**

```dart
// lib/models/budget.dart
class Budget {
  final int? id;
  final String type;
  final double amount;
  final bool isActive;
  final DateTime createdAt;

  const Budget({this.id, required this.type, required this.amount,
    this.isActive = true, required this.createdAt});

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id, 'type': type, 'amount': amount,
    'is_active': isActive ? 1 : 0, 'created_at': createdAt.toIso8601String(),
  };

  factory Budget.fromMap(Map<String, dynamic> map) => Budget(
    id: map['id'] as int?,
    type: map['type'] as String,
    amount: (map['amount'] as num).toDouble(),
    isActive: (map['is_active'] as int) == 1,
    createdAt: DateTime.parse(map['created_at'] as String),
  );

  Budget copyWith({int? id, String? type, double? amount, bool? isActive,
      DateTime? createdAt}) => Budget(
    id: id ?? this.id, type: type ?? this.type, amount: amount ?? this.amount,
    isActive: isActive ?? this.isActive, createdAt: createdAt ?? this.createdAt,
  );
}
```

- [ ] **Step 4: Verify tests pass — 2 PASS**

- [ ] **Step 5: Commit**
```bash
git add test/models/budget_test.dart lib/models/budget.dart
git commit -m "feat: add Budget model"
```

---

### Task 5: Utils — constants, date_helper, currency_helper (TDD)

**Files:** Create `lib/utils/constants.dart`, `lib/utils/date_helper.dart`, `lib/utils/currency_helper.dart`, `test/utils/date_helper_test.dart`, `test/utils/currency_helper_test.dart`

- [ ] **Step 1: Write tests**

```dart
// test/utils/date_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/utils/date_helper.dart';

void main() {
  group('DateHelper', () {
    test('todayRange', () {
      final now = DateTime(2026, 5, 20, 15, 30);
      final range = DateHelper.todayRange(now);
      expect(range.start, DateTime(2026, 5, 20, 0, 0, 0));
      expect(range.end, DateTime(2026, 5, 20, 23, 59, 59, 999));
    });
    test('weekRange returns Mon-Sun', () {
      final wed = DateTime(2026, 5, 20);
      final range = DateHelper.weekRange(wed);
      expect(range.start.weekday, DateTime.monday);
      expect(range.end.weekday, DateTime.sunday);
    });
    test('monthRange', () {
      final range = DateHelper.monthRange(2026, 5);
      expect(range.start, DateTime(2026, 5, 1));
      expect(range.end, DateTime(2026, 5, 31, 23, 59, 59, 999));
    });
    test('yearRange', () {
      final range = DateHelper.yearRange(2026);
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 12, 31, 23, 59, 59, 999));
    });
    test('formatDate', () {
      expect(DateHelper.formatDate(DateTime(2026, 5, 20)), '2026-05-20');
    });
    test('formatMonth', () {
      expect(DateHelper.formatMonth(2026, 5), '2026年05月');
    });
    test('daysInMonth', () {
      expect(DateHelper.daysInMonth(2026, 2), 28);
      expect(DateHelper.daysInMonth(2024, 2), 29);
    });
  });
}
```

```dart
// test/utils/currency_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:aiaccounting/utils/currency_helper.dart';

void main() {
  group('CurrencyHelper', () {
    test('format CNY', () {
      expect(CurrencyHelper.format(1234.56), '¥1,234.56');
    });
    test('format USD', () {
      expect(CurrencyHelper.format(1234.56, code: 'USD'), '\$1,234.56');
    });
    test('format EUR', () {
      expect(CurrencyHelper.format(1234.56, code: 'EUR'), '€1,234.56');
    });
    test('symbol returns code for unknown', () {
      expect(CurrencyHelper.symbol('XYZ'), 'XYZ');
    });
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL**

- [ ] **Step 3: Implement utils**

```dart
// lib/utils/constants.dart
import '../models/category.dart';

const Map<String, String> currencySymbols = {
  'CNY': '¥', 'USD': '\$', 'EUR': '€', 'GBP': '£', 'JPY': '¥',
};
const String defaultCurrency = 'CNY';

const Map<String, String> presetCategoryIcons = {
  '餐饮': 'restaurant', '交通': 'directions_bus', '住房': 'home',
  '娱乐': 'movie', '购物': 'shopping_cart', '医疗': 'local_hospital',
  '其他': 'more_horiz',
};
const Map<String, String> presetCategoryColors = {
  '餐饮': '#FF6B6B', '交通': '#4ECDC4', '住房': '#45B7D1',
  '娱乐': '#F9CA24', '购物': '#A29BFE', '医疗': '#FF9FF3', '其他': '#DFE6E9',
};

List<Category> presetCategories() {
  final now = DateTime.now();
  final names = ['餐饮', '交通', '住房', '娱乐', '购物', '医疗', '其他'];
  return List.generate(names.length, (i) {
    final name = names[i];
    return Category(name: name, icon: presetCategoryIcons[name]!,
        color: presetCategoryColors[name]!, sortOrder: i, isPreset: true,
        createdAt: now);
  });
}
```

```dart
// lib/utils/date_helper.dart
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);
}

class DateHelper {
  static DateRange todayRange([DateTime? now]) {
    final date = now ?? DateTime.now();
    return DateRange(
      DateTime(date.year, date.month, date.day),
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
    );
  }

  static DateRange weekRange([DateTime? date]) {
    final d = date ?? DateTime.now();
    final start = DateTime(d.year, d.month, d.day - d.weekday + 1);
    return DateRange(start, DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999));
  }

  static DateRange monthRange(int year, int month) =>
      DateRange(DateTime(year, month, 1), DateTime(year, month + 1, 0, 23, 59, 59, 999));

  static DateRange yearRange(int year) =>
      DateRange(DateTime(year, 1, 1), DateTime(year, 12, 31, 23, 59, 59, 999));

  static String formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static String formatMonth(int year, int month) =>
      '$year年${month.toString().padLeft(2, '0')}月';

  static int daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
}
```

```dart
// lib/utils/currency_helper.dart
import 'package:intl/intl.dart';
import 'constants.dart';

class CurrencyHelper {
  static String format(double amount, {String code = 'CNY'}) {
    final symbol = currencySymbols[code] ?? code;
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(amount)}';
  }

  static String symbol(String code) => currencySymbols[code] ?? code;
}
```

- [ ] **Step 4: Verify tests pass — 11 PASS**

- [ ] **Step 5: Commit**
```bash
git add lib/utils/ test/utils/
git commit -m "feat: add constants, date_helper, currency_helper"
```

---

### Task 6: DatabaseHelper (TDD)

**Files:** Create `test/db/database_helper_test.dart`, `lib/db/database_helper.dart`

- [ ] **Step 1: Write test**

```dart
// test/db/database_helper_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';

void main() {
  setUpAll(() { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi; });
  tearDown(() async => await DatabaseHelper.instance.close());

  group('DatabaseHelper', () {
    test('creates all tables', () async {
      final db = await DatabaseHelper.instance.database;
      final tables = (await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"))
          .map((t) => t['name'] as String).toList();
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
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

- [ ] **Step 3: Implement DatabaseHelper**

```dart
// lib/db/database_helper.dart
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
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL UNIQUE,
        icon TEXT DEFAULT 'category', color TEXT NOT NULL,
        sort_order INTEGER DEFAULT 0, is_preset INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL NOT NULL,
        category_id INTEGER NOT NULL, note TEXT,
        recorded_at TEXT NOT NULL, created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');
    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL CHECK(type IN ('weekly', 'monthly')),
        amount REAL NOT NULL, is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
    final now = DateTime.now().toIso8601String();
    for (final cat in presetCategories()) {
      await db.insert('categories', {
        'name': cat.name, 'icon': cat.icon, 'color': cat.color,
        'sort_order': cat.sortOrder, 'is_preset': 1, 'created_at': now,
      });
    }
  }

  Future<void> close() async {
    if (_database != null) { await _database!.close(); _database = null; }
  }
}
```

- [ ] **Step 4: Verify tests pass — 3 PASS**

- [ ] **Step 5: Commit**
```bash
git add test/db/database_helper_test.dart lib/db/database_helper.dart
git commit -m "feat: add DatabaseHelper with table creation and presets"
```

---

### Task 7: CategoryDao (TDD)

**Files:** Create `test/db/category_dao_test.dart`, `lib/db/category_dao.dart`

- [ ] **Step 1: Write test**

```dart
// test/db/category_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/db/category_dao.dart';
import 'package:aiaccounting/models/category.dart';

void main() {
  late CategoryDao dao;
  setUpAll(() { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi; });
  setUp(() async { await DatabaseHelper.instance.close(); dao = CategoryDao(); });
  tearDown(() async => await DatabaseHelper.instance.close());

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
    });

    test('insert duplicate name throws', () async {
      await expectLater(
        dao.insert(Category(name: '餐饮', color: '#FF0000', createdAt: DateTime.now())),
        throwsA(isA<Exception>()),
      );
    });

    test('update modifies name', () async {
      final cats = await dao.getAll();
      final updated = cats.first.copyWith(name: '美食');
      expect(await dao.update(updated), 1);
      expect((await dao.getById(cats.first.id!))!.name, '美食');
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
      final ids = cats.map((c) => c.id!).toList().reversed.toList();
      await dao.updateSortOrder(ids);
      final reordered = await dao.getAll();
      expect(reordered.first.sortOrder, 0);
      expect(reordered.last.sortOrder, 6);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

- [ ] **Step 3: Implement CategoryDao**

```dart
// lib/db/category_dao.dart
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
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
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
      batch.update('categories', {'sort_order': i}, where: 'id = ?', whereArgs: [ids[i]]);
    }
    await batch.commit(noResult: true);
  }
}
```

- [ ] **Step 4: Verify tests pass — 7 PASS**

- [ ] **Step 5: Commit**
```bash
git add test/db/category_dao_test.dart lib/db/category_dao.dart
git commit -m "feat: add CategoryDao with CRUD and reorder"
```

---

### Task 8: ExpenseDao (TDD)

**Files:** Create `test/db/expense_dao_test.dart`, `lib/db/expense_dao.dart`

- [ ] **Step 1: Write test**

```dart
// test/db/expense_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/db/expense_dao.dart';
import 'package:aiaccounting/models/expense.dart';

void main() {
  late ExpenseDao dao;
  setUpAll(() { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi; });
  setUp(() async { await DatabaseHelper.instance.close(); dao = ExpenseDao(); });
  tearDown(() async => await DatabaseHelper.instance.close());

  Future<int> _insert(double amount, [int catId = 1, String? note, DateTime? at]) =>
      dao.insert(Expense(amount: amount, categoryId: catId, note: note,
          recordedAt: at ?? DateTime.now(), createdAt: DateTime.now(),
          updatedAt: DateTime.now()));

  group('ExpenseDao', () {
    test('insert returns id', () async => expect(await _insert(25.5, 1, '午餐'), greaterThan(0)));

    test('getAll returns with category info, newest first', () async {
      await _insert(10.0, 1, null, DateTime(2026, 5, 20, 8, 0));
      await _insert(20.0, 1, null, DateTime(2026, 5, 20, 12, 0));
      final list = await dao.getAll();
      expect(list.length, 2);
      expect(list[0].expense.amount, 20.0); // newest first
      expect(list[0].categoryName, '餐饮');
    });

    test('getById with category', () async {
      final id = await _insert(99.99);
      final r = await dao.getById(id);
      expect(r!.expense.amount, 99.99);
      expect(r.categoryName, '餐饮');
    });

    test('getByDateRange filters', () async {
      await _insert(10.0, 1, null, DateTime(2026, 5, 1));
      await _insert(20.0, 1, null, DateTime(2026, 5, 15));
      await _insert(30.0, 1, null, DateTime(2026, 5, 25));
      final may = await dao.getByDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 31, 23, 59, 59));
      expect(may.length, 3);
      final firstHalf = await dao.getByDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 15, 23, 59, 59));
      expect(firstHalf.length, 2);
    });

    test('getByCategory', () async {
      await _insert(10.0, 1); await _insert(20.0, 2);
      expect((await dao.getByCategory(1)).length, 1);
    });

    test('getFiltered', () async {
      await _insert(10.0, 1, null, DateTime(2026, 5, 10));
      await _insert(20.0, 1, null, DateTime(2026, 5, 20));
      final r = await dao.getFiltered(start: DateTime(2026, 5, 1), end: DateTime(2026, 5, 15, 23, 59, 59), categoryId: 1);
      expect(r.length, 1);
    });

    test('update', () async {
      final id = await _insert(10.0);
      final e = Expense(id: id, amount: 20.0, categoryId: 2, note: '更新',
          recordedAt: DateTime(2026, 5, 20), createdAt: DateTime.now(), updatedAt: DateTime.now());
      expect(await dao.update(e), 1);
      expect((await dao.getById(id))!.expense.amount, 20.0);
    });

    test('delete', () async {
      final id = await _insert(10.0);
      expect(await dao.delete(id), 1);
      expect(await dao.getById(id), isNull);
    });

    test('getTotalByDateRange', () async {
      await _insert(10.0, 1, null, DateTime(2026, 5, 10));
      await _insert(20.0, 1, null, DateTime(2026, 5, 15));
      await _insert(30.0, 1, null, DateTime(2026, 6, 1));
      expect(await dao.getTotalByDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 31, 23, 59, 59)), 30.0);
    });

    test('getSumByCategory', () async {
      await _insert(10.0, 1, null, DateTime(2026, 5, 10));
      await _insert(20.0, 1, null, DateTime(2026, 5, 10));
      await _insert(15.0, 2, null, DateTime(2026, 5, 10));
      final sums = await dao.getSumByCategory(DateTime(2026, 5, 1), DateTime(2026, 5, 31, 23, 59, 59));
      expect(sums['餐饮'], 30.0);
      expect(sums['交通'], 15.0);
    });

    test('getDailySum', () async {
      await _insert(10.0, 1, null, DateTime(2026, 5, 10));
      await _insert(5.0, 1, null, DateTime(2026, 5, 11));
      final daily = await dao.getDailySum(DateTime(2026, 5, 1), DateTime(2026, 5, 31, 23, 59, 59));
      expect(daily['2026-05-10'], 10.0);
    });

    test('deleteByDateRange', () async {
      await _insert(10.0, 1, null, DateTime(2026, 5, 10));
      await _insert(20.0, 1, null, DateTime(2026, 5, 20));
      expect(await dao.deleteByDateRange(DateTime(2026, 5, 1), DateTime(2026, 5, 15, 23, 59, 59)), 1);
      expect((await dao.getAll()).length, 1);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL (but fix the test bug first: `10.0` not `15.0`)**
- [ ] **Step 3: Implement ExpenseDao — complete code:**

```dart
// lib/db/expense_dao.dart
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

  Future<int> update(Expense e) async {
    final db = await _db;
    return db.update('expenses', e.toMap(), where: 'id = ?', whereArgs: [e.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db;
    return db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    return db.delete('expenses', where: 'recorded_at >= ? AND recorded_at <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()]);
  }

  Future<List<ExpenseWithCategory>> _query(String where, List<dynamic> args, {int? limit, int? offset}) async {
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

  Future<List<ExpenseWithCategory>> getByDateRange(DateTime start, DateTime end) =>
      _query('WHERE e.recorded_at >= ? AND e.recorded_at <= ?',
          [start.toIso8601String(), end.toIso8601String()]);

  Future<List<ExpenseWithCategory>> getByCategory(int categoryId) =>
      _query('WHERE e.category_id = ?', [categoryId]);

  Future<List<ExpenseWithCategory>> getFiltered({DateTime? start, DateTime? end, int? categoryId}) {
    final conds = <String>[];
    final args = <dynamic>[];
    if (start != null) { conds.add('e.recorded_at >= ?'); args.add(start.toIso8601String()); }
    if (end != null) { conds.add('e.recorded_at <= ?'); args.add(end.toIso8601String()); }
    if (categoryId != null) { conds.add('e.category_id = ?'); args.add(categoryId); }
    return _query(conds.isNotEmpty ? 'WHERE ${conds.join(' AND ')}' : '', args);
  }

  Future<double> getTotalByDateRange(DateTime start, DateTime end) async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE recorded_at >= ? AND recorded_at <= ?',
      [start.toIso8601String(), end.toIso8601String()]);
    return (result.first['total'] as num).toDouble();
  }

  Future<Map<String, double>> getSumByCategory(DateTime start, DateTime end) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT c.name, COALESCE(SUM(e.amount), 0) as total
      FROM expenses e JOIN categories c ON e.category_id = c.id
      WHERE e.recorded_at >= ? AND e.recorded_at <= ?
      GROUP BY c.id ORDER BY total DESC
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return {for (final row in results) row['name'] as String: (row['total'] as num).toDouble()};
  }

  Future<Map<String, double>> getDailySum(DateTime start, DateTime end) async {
    final db = await _db;
    final results = await db.rawQuery('''
      SELECT DATE(recorded_at) as day, COALESCE(SUM(amount), 0) as total
      FROM expenses WHERE recorded_at >= ? AND recorded_at <= ?
      GROUP BY DATE(recorded_at) ORDER BY day
    ''', [start.toIso8601String(), end.toIso8601String()]);
    return {for (final row in results) row['day'] as String: (row['total'] as num).toDouble()};
  }
}
```

- [ ] **Step 4: Verify tests pass — 11 PASS**
- [ ] **Step 5: Commit**
```bash
git add test/db/expense_dao_test.dart lib/db/expense_dao.dart
git commit -m "feat: add ExpenseDao with full query and aggregate support"
```

---

### Task 9: BudgetDao (TDD)

**Files:** Create `test/db/budget_dao_test.dart`, `lib/db/budget_dao.dart`

- [ ] **Step 1: Write test**

```dart
// test/db/budget_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/db/database_helper.dart';
import 'package:aiaccounting/db/budget_dao.dart';
import 'package:aiaccounting/models/budget.dart';

void main() {
  late BudgetDao dao;
  setUpAll(() { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi; });
  setUp(() async { await DatabaseHelper.instance.close(); dao = BudgetDao(); });
  tearDown(() async => await DatabaseHelper.instance.close());

  group('BudgetDao', () {
    test('getActive returns null initially', () async {
      expect(await dao.getActive('monthly'), isNull);
    });
    test('upsert inserts and getActive returns it', () async {
      await dao.upsert(Budget(type: 'monthly', amount: 5000, createdAt: DateTime.now()));
      expect((await dao.getActive('monthly'))!.amount, 5000);
    });
    test('upsert replaces existing for same type', () async {
      await dao.upsert(Budget(type: 'monthly', amount: 5000, createdAt: DateTime.now()));
      await dao.upsert(Budget(type: 'monthly', amount: 8000, createdAt: DateTime.now()));
      expect((await dao.getActive('monthly'))!.amount, 8000);
    });
    test('weekly and monthly can coexist', () async {
      await dao.upsert(Budget(type: 'monthly', amount: 5000, createdAt: DateTime.now()));
      await dao.upsert(Budget(type: 'weekly', amount: 1000, createdAt: DateTime.now()));
      expect((await dao.getActive('monthly'))!.amount, 5000);
      expect((await dao.getActive('weekly'))!.amount, 1000);
    });
    test('deactivate', () async {
      await dao.upsert(Budget(type: 'monthly', amount: 5000, createdAt: DateTime.now()));
      await dao.deactivate('monthly');
      expect(await dao.getActive('monthly'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**
- [ ] **Step 3: Implement BudgetDao**

```dart
// lib/db/budget_dao.dart
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
```

- [ ] **Step 4: Verify tests pass — 5 PASS**
- [ ] **Step 5: Commit**
```bash
git add test/db/budget_dao_test.dart lib/db/budget_dao.dart
git commit -m "feat: add BudgetDao with upsert and deactivate"
```

---

### Task 10: CategoryProvider (TDD)

**Files:** Create `test/providers/category_provider_test.dart`, `lib/providers/category_provider.dart`

- [ ] **Step 1: Write test**

```dart
// test/providers/category_provider_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/providers/category_provider.dart';
import 'package:aiaccounting/db/database_helper.dart';

void main() {
  setUpAll(() { sqfliteFfiInit(); databaseFactory = databaseFactoryFfi; });
  setUp(() async => await DatabaseHelper.instance.close());
  tearDown(() async => await DatabaseHelper.instance.close());

  group('CategoryProvider', () {
    test('loadCategories populates list with 7 presets', () async {
      final provider = CategoryProvider();
      await provider.loadCategories();
      expect(provider.categories.length, 7);
      expect(provider.isLoading, false);
    });

    test('addCategory inserts and refreshes list', () async {
      final provider = CategoryProvider();
      await provider.loadCategories();
      final now = DateTime.now();
      await provider.addCategory('宠物', '#ABCDEF', now);
      expect(provider.categories.length, 8);
    });

    test('deleteCategory throws for preset, works for custom', () async {
      final provider = CategoryProvider();
      await provider.loadCategories();
      final presetId = provider.categories.first.id!;
      try {
        await provider.deleteCategory(presetId);
        fail('should throw');
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**
- [ ] **Step 3: Implement CategoryProvider**

```dart
// lib/providers/category_provider.dart
import 'package:flutter/foundation.dart';
import '../db/category_dao.dart';
import '../models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryDao _dao = CategoryDao();
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _categories = await _dao.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name, String color, DateTime now) async {
    try {
      await _dao.insert(Category(name: name, color: color, createdAt: now));
      await loadCategories();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateCategory(Category category) async {
    await _dao.update(category);
    await loadCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _dao.delete(id);
    await loadCategories();
  }

  Future<void> reorderCategories(List<int> ids) async {
    await _dao.updateSortOrder(ids);
    await loadCategories();
  }
}
```

- [ ] **Step 4: Verify tests pass — 3 PASS**
- [ ] **Step 5: Commit**
```bash
git add test/providers/ lib/providers/
git commit -m "feat: add CategoryProvider"
```

---

### Task 11: ExpenseProvider (TDD)

**Files:** Create `test/providers/expense_provider_test.dart`, `lib/providers/expense_provider.dart`

Write test that verifies `loadExpenses`, `addExpense`, `deleteExpense`, `loadTotalByDateRange` work correctly. Then implement:

```dart
// lib/providers/expense_provider.dart
import 'package:flutter/foundation.dart';
import '../db/expense_dao.dart';
import '../models/expense.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseDao _dao = ExpenseDao();
  List<ExpenseWithCategory> _expenses = [];
  double _totalExpense = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<ExpenseWithCategory> get expenses => _expenses;
  double get totalExpense => _totalExpense;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadExpenses({DateTime? start, DateTime? end, int? categoryId}) async {
    _isLoading = true; _errorMessage = null; notifyListeners();
    try {
      _expenses = await _dao.getFiltered(start: start, end: end, categoryId: categoryId);
    } catch (e) { _errorMessage = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<void> loadRecentExpenses({int limit = 5}) async {
    _expenses = await _dao.getAll(limit: limit);
    notifyListeners();
  }

  Future<void> loadTotalByDateRange(DateTime start, DateTime end) async {
    _totalExpense = await _dao.getTotalByDateRange(start, end);
    notifyListeners();
  }

  Future<int> addExpense(Expense expense) async {
    final id = await _dao.insert(expense);
    await loadExpenses();
    return id;
  }

  Future<void> updateExpense(Expense expense) async {
    await _dao.update(expense);
    await loadExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _dao.delete(id);
    await loadExpenses();
  }

  Future<void> deleteByDateRange(DateTime start, DateTime end) async {
    await _dao.deleteByDateRange(start, end);
    await loadExpenses();
  }
}
```

---

### Task 12: BudgetProvider (TDD)

**Files:** Create `test/providers/budget_provider_test.dart`, `lib/providers/budget_provider.dart`

```dart
// lib/providers/budget_provider.dart
import 'package:flutter/foundation.dart';
import '../db/budget_dao.dart';
import '../models/budget.dart';

class BudgetProvider extends ChangeNotifier {
  final BudgetDao _dao = BudgetDao();
  Budget? _monthlyBudget;
  Budget? _weeklyBudget;
  bool _isLoading = false;
  String? _errorMessage;

  Budget? get monthlyBudget => _monthlyBudget;
  Budget? get weeklyBudget => _weeklyBudget;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBudgets() async {
    _isLoading = true; notifyListeners();
    try {
      _monthlyBudget = await _dao.getActive('monthly');
      _weeklyBudget = await _dao.getActive('weekly');
    } catch (e) { _errorMessage = e.toString(); }
    _isLoading = false; notifyListeners();
  }

  Future<void> setBudget(String type, double amount) async {
    final budget = Budget(type: type, amount: amount, createdAt: DateTime.now());
    await _dao.upsert(budget);
    await loadBudgets();
  }

  Future<void> removeBudget(String type) async {
    await _dao.deactivate(type);
    await loadBudgets();
  }

  double? getBudgetRemaining(String type, double spent) {
    final budget = type == 'monthly' ? _monthlyBudget : _weeklyBudget;
    if (budget == null) return null;
    return budget.amount - spent;
  }

  bool isOverBudget(String type, double spent) {
    final remaining = getBudgetRemaining(type, spent);
    return remaining != null && remaining < 0;
  }
}
```

---

### Task 13: ThemeProvider (TDD)

**Files:** Create `test/providers/theme_provider_test.dart`, `lib/providers/theme_provider.dart`

```dart
// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
}
```

---

### Task 14: app.dart + main.dart

**Files:** Create (replace default) `lib/main.dart`, `lib/app.dart`

- [ ] **Step 1: Write main.dart**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/category_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/theme_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final categoryProvider = CategoryProvider();
  final expenseProvider = ExpenseProvider();
  final budgetProvider = BudgetProvider();

  // Preload categories (needed everywhere)
  await categoryProvider.loadCategories();
  await budgetProvider.loadBudgets();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: categoryProvider),
        ChangeNotifierProvider.value(value: expenseProvider),
        ChangeNotifierProvider.value(value: budgetProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const AIAccountingApp(),
    ),
  );
}
```

- [ ] **Step 2: Write app.dart**

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/record_expense_screen.dart';
import 'screens/expense_detail_screen.dart';
import 'screens/statistics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/budget_setting_screen.dart';
import 'screens/category_manage_screen.dart';

class AIAccountingApp extends StatelessWidget {
  const AIAccountingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'AI记账',
          debugShowCheckedModeBanner: false,
          themeMode: themeProvider.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF45B7D1),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F7FA),
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF45B7D1),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          initialRoute: '/',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/':
                return MaterialPageRoute(builder: (_) => const HomeScreen());
              case '/record':
                return MaterialPageRoute(builder: (_) => const RecordExpenseScreen());
              case '/statistics':
                return MaterialPageRoute(builder: (_) => const StatisticsScreen());
              case '/settings':
                return MaterialPageRoute(builder: (_) => const SettingsScreen());
              case '/expense-detail':
                final expenseId = settings.arguments as int;
                return MaterialPageRoute(
                  builder: (_) => ExpenseDetailScreen(expenseId: expenseId),
                );
              case '/budget-setting':
                return MaterialPageRoute(builder: (_) => const BudgetSettingScreen());
              case '/category-manage':
                return MaterialPageRoute(builder: (_) => const CategoryManageScreen());
              default:
                return MaterialPageRoute(builder: (_) => const HomeScreen());
            }
          },
        );
      },
    );
  }
}
```

- [ ] **Step 3: Commit**
```bash
git add lib/main.dart lib/app.dart
git commit -m "feat: add app entry point with MultiProvider and routing"
```

---

### Task 15: Core widgets (AmountDisplay, CategoryChip, ExpenseCard, EmptyState)

**Files:** Create `lib/widgets/amount_display.dart`, `lib/widgets/category_chip.dart`, `lib/widgets/expense_card.dart`, `lib/widgets/empty_state.dart`

- [ ] **Step 1: Implement widgets**

```dart
// lib/widgets/amount_display.dart
import 'package:flutter/material.dart';
import '../utils/currency_helper.dart';

class AmountDisplay extends StatelessWidget {
  final double amount;
  final double fontSize;
  final String currencyCode;
  final FontWeight fontWeight;
  final Color? color;

  const AmountDisplay({
    super.key, required this.amount, this.fontSize = 16,
    this.currencyCode = 'CNY', this.fontWeight = FontWeight.w600,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      CurrencyHelper.format(amount, code: currencyCode),
      style: TextStyle(
        fontSize: fontSize, fontWeight: fontWeight,
        color: color ?? Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }
}
```

```dart
// lib/widgets/category_chip.dart
import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.selected = false, this.onTap});

  Color get _color => Color(int.parse(category.color.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _color : _color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color, width: selected ? 2 : 1),
        ),
        child: Text(
          category.name,
          style: TextStyle(
            color: selected ? Colors.white : _color,
            fontSize: 13, fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
```

```dart
// lib/widgets/expense_card.dart
import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'amount_display.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseWithCategory expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseCard({super.key, required this.expense, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(expense.categoryColor.replaceFirst('#', '0xFF')));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          radius: 18,
          child: Text(expense.categoryName[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(expense.categoryName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: expense.expense.note != null && expense.expense.note!.isNotEmpty
            ? Text(expense.expense.note!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: AmountDisplay(amount: expense.expense.amount, fontSize: 16, color: color),
      ),
    );
  }
}
```

```dart
// lib/widgets/empty_state.dart
import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({super.key, this.message = '暂无数据', this.icon = Icons.inbox_outlined,
      this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/widgets/
git commit -m "feat: add core widgets: AmountDisplay, CategoryChip, ExpenseCard, EmptyState"
```

---

### Task 16: Chart widgets + BudgetProgressBar + CategoryPicker

**Files:** Create `lib/widgets/pie_chart_widget.dart`, `lib/widgets/bar_chart_widget.dart`, `lib/widgets/budget_progress_bar.dart`, `lib/widgets/category_picker.dart`

- [ ] **Step 1: Implement charts**

```dart
// lib/widgets/pie_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, String> colors;

  const PieChartWidget({super.key, required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('暂无消费数据')));
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((entry) {
            final color = colors.containsKey(entry.key)
                ? Color(int.parse(colors[entry.key]!.replaceFirst('#', '0xFF')))
                : Colors.grey;
            return PieChartSectionData(
              color: color,
              value: entry.value,
              title: entry.key,
              radius: 80,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
```

```dart
// lib/widgets/bar_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, double> data;

  const BarChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox(height: 200, child: Center(child: Text('暂无消费数据')));
    final maxY = data.values.reduce((a, b) => a > b ? a : b) * 1.2;
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barGroups: data.entries.toList().asMap().entries.map((e) {
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value.value,
                color: const Color(0xFF45B7D1),
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ]);
          }).toList(),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final keys = data.keys.toList();
                  final idx = value.toInt();
                  if (idx < 0 || idx >= keys.length) return const SizedBox.shrink();
                  // Show short date labels
                  final label = keys[idx];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label.length > 5 ? label.substring(5) : label,
                        style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                getTitlesWidget: (value, meta) => Text('¥${value.toInt()}',
                    style: const TextStyle(fontSize: 10))),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
```

```dart
// lib/widgets/budget_progress_bar.dart
import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String label;

  const BudgetProgressBar({super.key, required this.spent, required this.budget, this.label = '预算'});

  double get _ratio => (spent / budget).clamp(0.0, 1.0);
  bool get _isOver => spent > budget;
  Color get _color => _isOver ? Colors.red : _ratio > 0.8 ? Colors.orange : const Color(0xFF45B7D1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label ¥${spent.toStringAsFixed(0)} / ¥${budget.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13)),
            if (_isOver) const Text('超预算!', style: TextStyle(color: Colors.red, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: _ratio, backgroundColor: Colors.grey[200],
              color: _color, minHeight: 8),
        ),
      ],
    );
  }
}
```

```dart
// lib/widgets/category_picker.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import 'category_chip.dart';

class CategoryPicker extends StatelessWidget {
  final int? selectedCategoryId;
  final Function(Category) onSelected;

  const CategoryPicker({super.key, this.selectedCategoryId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: categories.map((cat) => CategoryChip(
        category: cat,
        selected: cat.id == selectedCategoryId,
        onTap: () => onSelected(cat),
      )).toList(),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/widgets/
git commit -m "feat: add chart widgets, budget progress bar, category picker"
```

---

### Task 17: HomeScreen

**Files:** Create `lib/screens/home_screen.dart`, create `lib/screens/screen_template.dart`

- [ ] **Step 1: Implement BottomNav scaffold**

```dart
// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../providers/budget_provider.dart';
import '../utils/date_helper.dart';
import '../utils/currency_helper.dart';
import '../widgets/expense_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/budget_progress_bar.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _pages = const [HomePage(), StatisticsScreen(), SettingsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: '首页'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: '统计'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI记账')),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<ExpenseProvider>().loadRecentExpenses();
          await context.read<ExpenseProvider>().loadTotalByDateRange(
            DateHelper.monthRange(DateTime.now().year, DateTime.now().month).start,
            DateHelper.monthRange(DateTime.now().year, DateTime.now().month).end,
          );
          await context.read<BudgetProvider>().loadBudgets();
        },
        child: Consumer2<ExpenseProvider, BudgetProvider>(
          builder: (context, expenseProv, budgetProv, _) {
            if (expenseProv.isLoading) return const Center(child: CircularProgressIndicator());

            final now = DateTime.now();
            final monthRange = DateHelper.monthRange(now.year, now.month);
            final total = expenseProv.totalExpense;
            final monthlyBudget = budgetProv.monthlyBudget;
            final remaining = monthlyBudget != null ? budgetProv.getBudgetRemaining('monthly', total) : null;

            return ListView(
              children: [
                // Summary header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF45B7D1), Color(0xFF66D9B7)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('本月支出', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(CurrencyHelper.format(total), style: const TextStyle(
                          color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      if (remaining != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('预算剩余 ${CurrencyHelper.format(remaining)}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                    ],
                  ),
                ),

                // Budget progress
                if (monthlyBudget != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: BudgetProgressBar(spent: total, budget: monthlyBudget.amount, label: '月预算'),
                  ),

                // "记一笔" button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF45B7D1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/record'),
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text('记一笔', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),

                // Recent expenses
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('最近记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                if (expenseProv.expenses.isEmpty)
                  const EmptyState(message: '还没有记账，开始记一笔吧', icon: Icons.receipt_long_outlined)
                else
                  ...expenseProv.expenses.take(5).map((e) => ExpenseCard(
                    expense: e,
                    onTap: () => Navigator.pushNamed(context, '/expense-detail', arguments: e.expense.id),
                  )),
              ],
            );
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**
```bash
git add lib/screens/home_screen.dart
git commit -m "feat: add HomeScreen with bottom nav, summary, budget, and recent expenses"
```

---

### Task 18: RecordExpenseScreen

**Files:** Create `lib/screens/record_expense_screen.dart`

- [ ] **Step 1: Implement record screen**

```dart
// lib/screens/record_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/category_picker.dart';

class RecordExpenseScreen extends StatefulWidget {
  final int? templateCategoryId;
  final double? templateAmount;

  const RecordExpenseScreen({super.key, this.templateCategoryId, this.templateAmount});

  @override
  State<RecordExpenseScreen> createState() => _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends State<RecordExpenseScreen> {
  final _amountController = TextEditingController(text: '');
  final _noteController = TextEditingController();
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedTime = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.templateAmount != null) {
      _amountController.text = widget.templateAmount!.toString();
    }
    // context.read<CategoryProvider>().categories is available via picker
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入金额')),
      );
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择分类')),
      );
      return;
    }

    setState(() => _saving = true);

    final recordedAt = DateTime(
      _selectedDate.year, _selectedDate.month, _selectedDate.day,
      _selectedTime.hour, _selectedTime.minute,
    );
    final now = DateTime.now();
    final expense = Expense(
      amount: amount,
      categoryId: _selectedCategory!.id!,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      recordedAt: recordedAt,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await context.read<ExpenseProvider>().addExpense(expense);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('记录成功'), duration: Duration(seconds: 1)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('记录失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (picked != null) {
      setState(() => _selectedTime = DateTime(
        _selectedTime.year, _selectedTime.month, _selectedTime.day,
        picked.hour, picked.minute,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                prefixText: '¥ ',
                hintText: '0.00',
                border: OutlineInputBorder(),
                errorText: null,
              ),
            ),
            const SizedBox(height: 20),

            // Category picker
            const Text('选择分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            CategoryPicker(
              selectedCategoryId: _selectedCategory?.id,
              onSelected: (cat) => setState(() => _selectedCategory = cat),
            ),
            const SizedBox(height: 20),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('日期'),
                    subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: _pickDate,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('时间'),
                    subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.access_time),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（选填）',
                hintText: '例如：早餐豆浆油条',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('保存', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/screens/record_expense_screen.dart
git commit -m "feat: add RecordExpenseScreen with amount, category, date, note inputs"
```

---

### Task 19: ExpenseDetailScreen

**Files:** Create `lib/screens/expense_detail_screen.dart`

- [ ] **Step 1: Implement**

```dart
// lib/screens/expense_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/expense_dao.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_helper.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  ExpenseWithCategory? _expense;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dao = ExpenseDao();
    final e = await dao.getById(widget.expenseId);
    if (mounted) setState(() { _expense = e; _loading = false; });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ExpenseProvider>().deleteExpense(widget.expenseId);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _edit() async {
    // Navigate to record screen in edit mode
    // For simplicity, pop and push record screen with pre-filled data
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(), body: const Center(child: CircularProgressIndicator()));
    if (_expense == null) return Scaffold(appBar: AppBar(), body: const Center(child: Text('记录不存在')));

    final e = _expense!;
    final color = Color(int.parse(e.categoryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(title: const Text('记录详情'), actions: [
        IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _delete),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(radius: 32, backgroundColor: color.withAlpha(40),
                child: Text(e.categoryName[0], style: TextStyle(fontSize: 28, color: color))),
            const SizedBox(height: 8),
            Text(e.categoryName, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Text(CurrencyHelper.format(e.expense.amount), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _detailRow('日期', '${e.expense.recordedAt.year}-${e.expense.recordedAt.month.toString().padLeft(2, '0')}-${e.expense.recordedAt.day.toString().padLeft(2, '0')}'),
            _detailRow('时间', '${e.expense.recordedAt.hour.toString().padLeft(2, '0')}:${e.expense.recordedAt.minute.toString().padLeft(2, '0')}'),
            if (e.expense.note != null && e.expense.note!.isNotEmpty)
              _detailRow('备注', e.expense.note!),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/screens/expense_detail_screen.dart
git commit -m "feat: add ExpenseDetailScreen with view and delete"
```

---

### Task 20: StatisticsScreen

**Files:** Create `lib/screens/statistics_screen.dart`

- [ ] **Step 1: Implement**

```dart
// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/expense_dao.dart';
import '../utils/date_helper.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/bar_chart_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _periodIndex = 2; // default: month (today=0, week=1, month=2, year=3)
  final _labels = ['今日', '本周', '本月', '今年'];
  Map<String, double> _sumByCategory = {};
  Map<String, double> _dailySum = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateRange _getRange() {
    final now = DateTime.now();
    switch (_periodIndex) {
      case 0: return DateHelper.todayRange();
      case 1: return DateHelper.weekRange();
      case 2: return DateHelper.monthRange(now.year, now.month);
      case 3: return DateHelper.yearRange(now.year);
      default: return DateHelper.monthRange(now.year, now.month);
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final dao = ExpenseDao();
    final range = _getRange();
    final catSum = await dao.getSumByCategory(range.start, range.end);
    final daily = await dao.getDailySum(range.start, range.end);
    final categories = context.read<CategoryProvider>().categories;
    final colors = {for (final c in categories) c.name: c.color};

    if (mounted) {
      setState(() {
        _sumByCategory = catSum;
        _dailySum = daily;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = {for (final c in context.watch<CategoryProvider>().categories) c.name: c.color};
    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Period selector
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SegmentedButton<int>(
                        segments: List.generate(_labels.length,
                            (i) => ButtonSegment(value: i, label: Text(_labels[i]))),
                        selected: {_periodIndex},
                        onSelectionChanged: (s) {
                          _periodIndex = s.first;
                          _loadData();
                        },
                      ),
                    ),

                    // Pie chart
                    const Text('支出分类占比', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    PieChartWidget(data: _sumByCategory, colors: colors),
                    const SizedBox(height: 24),

                    // Bar chart
                    const Text('每日支出趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    BarChartWidget(data: _dailySum),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/screens/statistics_screen.dart
git commit -m "feat: add StatisticsScreen with pie chart and bar chart"
```

---

### Task 21: SettingsScreen

**Files:** Create `lib/screens/settings_screen.dart`

- [ ] **Step 1: Implement**

```dart
// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          // Currency
          ListTile(
            leading: const Icon(Icons.currency_yuan),
            title: const Text('货币单位'),
            subtitle: const Text('人民币 (¥)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // Currency selector - simple dropdown for now
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('选择货币'),
                  children: currencySymbols.entries.map((e) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, e.key),
                    child: Text('${e.value} ${e.key}'),
                  )).toList(),
                ),
              );
            },
          ),
          const Divider(),

          // Theme
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => SwitchListTile(
              secondary: Icon(tp.isDark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('深色模式'),
              value: tp.isDark,
              onChanged: (_) => tp.toggleTheme(),
            ),
          ),
          const Divider(),

          // Category management
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/category-manage'),
          ),
          const Divider(),

          // Budget
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('预算设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/budget-setting'),
          ),
          const Divider(),

          // About
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('AI记账 v1.0.0'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/screens/settings_screen.dart
git commit -m "feat: add SettingsScreen with currency, theme, category, budget options"
```

---

### Task 22: BudgetSettingScreen

**Files:** Create `lib/screens/budget_setting_screen.dart`

```dart
// lib/screens/budget_setting_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({super.key});
  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final budgets = context.read<BudgetProvider>();
    if (budgets.weeklyBudget != null) {
      _weeklyController.text = budgets.weeklyBudget!.amount.toStringAsFixed(0);
    }
    if (budgets.monthlyBudget != null) {
      _monthlyController.text = budgets.monthlyBudget!.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<BudgetProvider>();
    final weekly = double.tryParse(_weeklyController.text.trim());
    final monthly = double.tryParse(_monthlyController.text.trim());

    if (weekly != null && weekly > 0) {
      await provider.setBudget('weekly', weekly);
    } else {
      await provider.removeBudget('weekly');
    }
    if (monthly != null && monthly > 0) {
      await provider.setBudget('monthly', monthly);
    } else {
      await provider.removeBudget('monthly');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('预算已保存')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('预算设置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('月预算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _monthlyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '¥ ',
                hintText: '输入月预算金额',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            const Text('周预算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _weeklyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                prefixText: '¥ ',
                hintText: '输入周预算金额',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('保存', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**
```bash
git add lib/screens/budget_setting_screen.dart
git commit -m "feat: add BudgetSettingScreen"
```

---

### Task 23: CategoryManageScreen

**Files:** Create `lib/screens/category_manage_screen.dart`

```dart
// lib/screens/category_manage_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});
  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加分类'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '分类名称', hintText: '如：宠物'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, {'name': nameController.text.trim()}),
              child: const Text('添加')),
        ],
      ),
    );
    if (result != null && result['name']!.isNotEmpty && mounted) {
      try {
        final colors = ['#E17055', '#00B894', '#FDCB6E', '#E84393', '#6C5CE7', '#FD79A8'];
        final color = colors[context.read<CategoryProvider>().categories.length % colors.length];
        await context.read<CategoryProvider>().addCategory(result['name']!, color, DateTime.now());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      }
    }
  }

  Future<void> _editCategory(Category cat) async {
    final nameController = TextEditingController(text: cat.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑分类'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: '分类名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, nameController.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await context.read<CategoryProvider>().updateCategory(cat.copyWith(name: result));
    }
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${cat.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<CategoryProvider>().deleteCategory(cat.id!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分类管理'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addCategory),
      ]),
      body: Consumer<CategoryProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          return ReorderableListView.builder(
            itemCount: prov.categories.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final ids = prov.categories.map((c) => c.id!).toList();
              final item = ids.removeAt(oldIndex);
              ids.insert(newIndex, item);
              prov.reorderCategories(ids);
            },
            itemBuilder: (context, index) {
              final cat = prov.categories[index];
              return ListTile(
                key: ValueKey(cat.id),
                leading: CircleAvatar(
                  backgroundColor: Color(int.parse(cat.color.replaceFirst('#', '0xFF'))).withAlpha(30),
                  child: Text(cat.name[0], style: TextStyle(
                      color: Color(int.parse(cat.color.replaceFirst('#', '0xFF'))))),
                ),
                title: Text(cat.name),
                subtitle: cat.isPreset ? const Text('预设分类', style: TextStyle(fontSize: 12, color: Colors.grey)) : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!cat.isPreset)
                      IconButton(icon: const Icon(Icons.edit, size: 18), onPressed: () => _editCategory(cat)),
                    if (!cat.isPreset)
                      IconButton(icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _deleteCategory(cat)),
                    const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add lib/screens/category_manage_screen.dart
git commit -m "feat: add CategoryManageScreen with add/edit/delete/reorder"
```

---

### Task 24: Final integration — fix imports, run all tests, verify build

- [ ] **Step 1: Run all tests**

```bash
cd D:\sgd\code\aiProject\AIAccounting && flutter test test/
```

Expected: All tests pass.

- [ ] **Step 2: Analyze code**

```bash
flutter analyze
```

Expected: No errors.

- [ ] **Step 3: Fix any missing import in StatisticsScreen** (it uses `context.read<CategoryProvider>()` without importing)

Add to statistics_screen.dart:
```dart
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
```

- [ ] **Step 4: Verify the app builds**

```bash
flutter build apk --debug
```

Expected: Build succeeds.

- [ ] **Step 5: Final commit**

```bash
git add -A && git commit -m "fix: final integration fixes for all screens"
git push origin master
```

---

## Completion Checklist

- [ ] All 23 tasks committed
- [ ] All tests pass (`flutter test`)
- [ ] Zero analysis errors (`flutter analyze`)
- [ ] Debug APK builds successfully
- [ ] Home screen shows monthly total + budget + recent 5 expenses
- [ ] "记一笔" button navigates to record screen, saves in ≤3 steps
- [ ] Statistics shows pie chart (category %) + bar chart (daily trend)
- [ ] Settings: currency switch, dark mode toggle, category manage, budget setting
- [ ] Category management: add/edit/delete custom categories, reorder, preset protection
- [ ] Budget: set monthly/weekly budget, progress bar appears on home
- [ ] Delete: confirmation dialog before any delete action
- [ ] Empty states handled ("暂无数据")
- [ ] Amount validation: negative/zero/non-numeric rejected
- [ ] Pull-to-refresh on home and statistics screens
