# Bill Import Design Spec

Date: 2026-05-21 | Status: Draft | Platform: Flutter

## Summary

Import WeChat and Alipay bill files (downloaded by user from respective apps) into the expense tracker. Parse XLSX/CSV, map categories, deduplicate, store as expenses with source tracking.

## Scope

### In Scope

| Item | Details |
|------|---------|
| File import button | Settings screen entry, file picker (system file browser) |
| Format detection | Identify WeChat XLSX vs Alipay CSV vs unsupported |
| WeChat parser | Parse XLSX bill, extract: time, type, counterparty, product, amount, order ID |
| Alipay parser | Parse CSV bill, skip header section, extract same fields |
| Category mapping | Map platform transaction categories to app's 7 categories |
| Deduplication | Skip expenses with same source + same external order ID |
| Preview | Show parsed results before confirm import, allow deselect |
| Error handling | Unsupported format → clear error message |

### Out of Scope

- Auto-sync (notification monitoring)
- OCR from screenshots
- Bank statements (only WeChat + Alipay)
- Cloud upload

## Data Model Changes

### expenses table — add 2 columns

| Column | Type | Constraint |
|--------|------|------------|
| source | TEXT | DEFAULT 'manual' CHECK(source IN ('manual','wechat','alipay')) |
| external_id | TEXT | nullable, unique per source |

```sql
ALTER TABLE expenses ADD COLUMN source TEXT DEFAULT 'manual';
ALTER TABLE expenses ADD COLUMN external_id TEXT;
CREATE UNIQUE INDEX idx_expenses_dedup ON expenses(source, external_id) WHERE external_id IS NOT NULL;
```

### Expense model — add 2 fields

```dart
class Expense {
  // ... existing fields ...
  final String source;       // 'manual' | 'wechat' | 'alipay'
  final String? externalId;  // order ID from the bill, for dedup
}
```

## Architecture

```
lib/
├── import/
│   ├── bill_parser.dart       # Top-level: detect format, dispatch, return List<ParsedBillItem>
│   ├── alipay_parser.dart     # Parse Alipay CSV
│   ├── wechat_parser.dart     # Parse WeChat XLSX (uses 'excel' package)
│   └── category_mapper.dart   # Map platform categories → app categories
├── screens/
│   └── bill_import_screen.dart # New: preview parsed items, confirm import
```

### BillParser interface

```dart
class ParsedBillItem {
  final DateTime tradeTime;
  final String platformCategory;   // original category from platform
  final String counterparty;
  final String productDescription;
  final double amount;
  final String externalId;         // order ID for dedup
  final String source;             // 'wechat' or 'alipay'
}

class BillParser {
  /// Returns null if format not recognized
  static List<ParsedBillItem>? parse(String filePath, String fileName) {
    if (fileName.endsWith('.csv')) return AlipayParser.parse(filePath);
    if (fileName.endsWith('.xlsx')) return WechatParser.parse(filePath);
    return null; // unsupported format
  }
}
```

### Category mapping

```dart
// category_mapper.dart
const Map<String, String> alipayCategoryMap = {
  '餐饮美食': '餐饮',
  '文化休闲': '娱乐',
  '交通出行': '交通',
  '充值缴费': '住房',
  '日用百货': '购物',
  '医疗健康': '医疗',
  // ... fallback → '其他'
};

const Map<String, String> wechatCategoryMap = {
  '餐饮': '餐饮',
  '交通': '交通',
  '生活服务': '住房',
  '娱乐': '娱乐',
  '购物': '购物',
  '医疗': '医疗',
  // ... fallback → '其他'
};
```

## Parsing Logic

### Alipay CSV

1. Read file as UTF-8 text
2. Find the header line starting with `交易时间,交易分类,...`
3. Parse subsequent CSV lines (skip empty/separator lines)
4. For each line: extract fields by CSV columns
5. Filter: only `支出` records, skip `收入` and `不计入`
6. Map `交易分类` → app category via `alipayCategoryMap`

### WeChat XLSX

1. Open XLSX with `excel` package
2. Read first sheet, skip rows until header row found
3. Header columns: `交易时间,交易类型,交易对方,商品,金额(元),...`
4. Parse data rows
5. Filter: only `支出` records
6. Map `交易类型` → app category via `wechatCategoryMap`

### Deduplication

Before insert, check `SELECT COUNT(*) FROM expenses WHERE source = ? AND external_id = ?`. Skip if exists.

## Dependencies (add to pubspec.yaml)

```yaml
dependencies:
  excel: ^4.0.6          # XLSX parsing
  file_picker: ^8.1.7    # System file picker
  csv: ^6.0.0            # CSV parsing (optional, can do manually)
```

## Routes

| Route | Screen | Description |
|-------|--------|-------------|
| `/bill-import` | BillImportScreen | Preview parsed items, confirm import |

Added to app.dart routing, triggered from Settings screen "导入账单" button.

## BillImportScreen Layout

```
┌──────────────────────────────┐
│  ← 导入账单                  │
├──────────────────────────────┤
│  已识别: 微信账单             │
│  共 25 条支出记录            │
├──────────────────────────────┤
│  ☑ 05-15 美团外卖    ¥15.70 │
│  ☑ 05-12 水费       ¥149.82│
│  ☑ 05-09 超市       ¥0.70  │
│  ☐ 05-08 话费充值   ¥100.00│  ← 可取消勾选
│  ...                         │
├──────────────────────────────┤
│  [ 导入 24 条记录 ]          │
└──────────────────────────────┘
```

## Error Handling

| Scenario | Behavior |
|----------|----------|
| Unsupported file extension | SnackBar: "文件类型不支持，请导入微信(.xlsx)或支付宝(.csv)账单文件" |
| CSV/XLSX parse failure | SnackBar: "文件解析失败，请确认文件未损坏" |
| Header row not found | SnackBar: "无法识别账单格式，请确认是微信或支付宝官方账单" |
| No expense records in file | SnackBar: "文件中未找到支出记录" |
| All records already imported | SnackBar: "所有记录已导入，无新数据" |

## Testing

| Layer | What | Type |
|-------|------|------|
| AlipayParser | Parse sample CSV, verify item count + field extraction | Unit (use sample file) |
| WechatParser | Parse sample XLSX, verify item count + field extraction | Unit (use sample file) |
| BillParser | Detect format, dispatch correctly, reject unknown | Unit |
| CategoryMapper | Map known + unknown categories correctly | Unit |
| ExpenseDao | Dedup logic: insert same externalId twice → skip second | Integration |

## File Checklist (implementation order)

1. Add `excel`, `file_picker`, `csv` to pubspec.yaml
2. DB migration: add `source` + `external_id` columns to expenses table
3. Update Expense model with new fields
4. `lib/import/category_mapper.dart`
5. `lib/import/alipay_parser.dart`
6. `lib/import/wechat_parser.dart`
7. `lib/import/bill_parser.dart`
8. `lib/screens/bill_import_screen.dart`
9. Update ExpenseDao with `insertAll` + dedup logic
10. Add "导入账单" button to SettingsScreen
11. Add route in app.dart
12. Tests with sample files from `zhangdan/`
