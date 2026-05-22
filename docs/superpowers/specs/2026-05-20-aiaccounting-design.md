# AIAccounting Design Spec

Date: 2026-05-20 | Status: Draft | Platform: Flutter (Android + iOS)

## Summary

Lightweight personal expense tracker. Pure local, no backend, no registration. Record expenses fast (≤3 steps), view stats with charts, manage budgets. All data in SQLite.

## Scope

### MVP — In Scope

| Module | Details |
|--------|---------|
| Expense Recording | Quick record, preset + custom categories, amount (required) + note (optional), shortcut templates |
| Query & Stats | Time-sorted list, category color tags, filter by date/category, pie chart + bar chart, daily/weekly/monthly/yearly aggregates |
| Data Management | SQLite local storage, single/batch/period delete, delete confirmation dialog |
| Settings | Currency unit switch, light/dark theme, category add/edit/delete/reorder |
| Budget | Set monthly/weekly budget, budget progress bar, over-budget warning |

### Out of Scope (MVP)

- Excel export
- WeChat/Alipay sync
- Registration/login
- Cloud backup

## Tech Stack

- **Framework:** Flutter
- **State Management:** Provider (ChangeNotifier)
- **Database:** SQLite via sqflite package
- **Charts:** fl_chart
- **Min SDK:** Android API 21+, iOS 12+

## Architecture — Provider + Layered

```
lib/
├── main.dart
├── app.dart
├── models/          # Data models with toMap/fromMap
├── db/              # SQLite helper + DAOs
├── providers/       # ChangeNotifier providers
├── screens/         # Full pages
├── widgets/         # Reusable components
└── utils/           # Constants, helpers
```

Layer dependency: `screens → providers → db → models`. Widgets used by screens, no cross-layer imports.

## Data Model

### categories

| Column | Type | Constraint |
|--------|------|------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| name | TEXT | NOT NULL UNIQUE |
| icon | TEXT | DEFAULT 'category' |
| color | TEXT | NOT NULL (hex) |
| sort_order | INTEGER | DEFAULT 0 |
| is_preset | INTEGER | DEFAULT 0 (1=preset) |
| created_at | TEXT | NOT NULL (ISO8601) |

Preset categories: 餐饮(#FF6B6B), 交通(#4ECDC4), 住房(#45B7D1), 娱乐(#F9CA24), 购物(#A29BFE), 医疗(#FF9FF3), 其他(#DFE6E9)

### expenses

| Column | Type | Constraint |
|--------|------|------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| amount | REAL | NOT NULL |
| category_id | INTEGER | NOT NULL FK → categories |
| note | TEXT | nullable |
| recorded_at | TEXT | NOT NULL (ISO8601) |
| created_at | TEXT | NOT NULL |
| updated_at | TEXT | NOT NULL |

### budgets

| Column | Type | Constraint |
|--------|------|------------|
| id | INTEGER | PRIMARY KEY AUTOINCREMENT |
| type | TEXT | NOT NULL CHECK('weekly','monthly') |
| amount | REAL | NOT NULL |
| is_active | INTEGER | DEFAULT 1 |
| created_at | TEXT | NOT NULL |

## Routes & Navigation

```
/                            HomeScreen          (bottom nav tab 1)
/record                      RecordExpenseScreen (push from home)
/statistics                  StatisticsScreen    (bottom nav tab 2)
/settings                    SettingsScreen      (bottom nav tab 3)
/expense-detail/:id          ExpenseDetailScreen (push from list)
/budget-setting              BudgetSettingScreen (push from settings)
/category-manage             CategoryManageScreen(push from settings)
```

Bottom nav: 首页(home icon), 统计(chart icon), 设置(settings icon)

### HomeScreen Layout

```
┌──────────────────────────┐
│  Total: ¥3,280.50        │
│  Budget remaining: ¥1,720│
├──────────────────────────┤
│      [ 记一笔 ]           │
├──────────────────────────┤
│  Recent records          │
│  🍔 餐饮  Breakfast ¥8   │
│  🚇 交通  Metro     ¥3   │
│  🎬 娱乐  Movie    ¥45   │
└──────────────────────────┘
```

## Data Flow

```
main.dart → MultiProvider
  ├── ExpenseProvider ← ExpenseDao
  ├── CategoryProvider ← CategoryDao
  ├── BudgetProvider ← BudgetDao
  └── ThemeProvider

Screen → context.watch<T>() → rebuild on state change
Screen → context.read<T>().method() → trigger action → DAO → notifyListeners()
```

## Error Handling

- DAO exceptions → Provider catch, set errorMessage → UI SnackBar
- Amount input validation: negative/zero/non-numeric → red hint "请输入有效金额"
- Budget overrun → progress bar in home + SnackBar warning
- Data load failure → empty state widget with "点击重试"
- Delete actions → showDialog confirmation required

## Testing Strategy

| Layer | Type | Target |
|-------|------|--------|
| models | Unit test | toMap/fromMap correctness |
| db | Integration test | CRUD, filters, aggregates |
| providers | Unit test + mock DAO | verify state changes, notifyListeners |
| widgets | Widget test | Rendering, color mapping, empty state |
| screens | Widget test | Form input, button tap, list render |

Coverage target: models + db ≥80%, providers ≥60%, screens: core flows only.

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.x
  sqflite: ^2.x
  path: ^1.x
  fl_chart: ^0.x
  intl: ^0.x

dev_dependencies:
  flutter_test:
    sdk: flutter
  sqflite_common_ffi: ^2.x  # for unit testing DB on desktop
```

## File Checklist (implementation order)

1. `lib/models/` — expense.dart, category.dart, budget.dart
2. `lib/utils/` — constants.dart, date_helper.dart, currency_helper.dart
3. `lib/db/` — database_helper.dart → expense_dao.dart → category_dao.dart → budget_dao.dart
4. `lib/providers/` — category_provider → expense_provider → budget_provider → theme_provider
5. `lib/app.dart` + `lib/main.dart`
6. `lib/widgets/` — bottom-up: amount_display → category_chip → expense_card → category_picker → charts → budget_progress_bar → empty_state
7. `lib/screens/` — home → record_expense → expense_detail → statistics → settings → budget_setting → category_manage
