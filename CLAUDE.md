# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 构建与开发命令

Flutter SDK 路径: `D:/sgd/soft/Flutter/bin/flutter`

### 测试
```bash
# 全量测试（必须 --concurrency=1，SQLite 用 sqflite_common_ffi）
D:/sgd/soft/Flutter/bin/flutter test --concurrency=1

# 单个测试文件
D:/sgd/soft/Flutter/bin/flutter test --concurrency=1 test/models/expense_test.dart
```

### 代码分析
```bash
D:/sgd/soft/Flutter/bin/flutter analyze
```

### 构建 APK
```bash
# 需要先设置环境变量
export JAVA_HOME="D:/sgd/evn/jdk21.0.7"
export ANDROID_HOME="D:/Android"
export ANDROID_SDK_ROOT="D:/Android"
D:/sgd/soft/Flutter/bin/flutter build apk --debug
```
APK 输出路径: `build/app/outputs/flutter-apk/app-debug.apk`

### 依赖管理
```bash
# 添加依赖后
D:/sgd/soft/Flutter/bin/flutter pub get
```

## 架构

**Provider + 分层架构**，纯本地应用，无后端。

```
lib/
├── main.dart              # MultiProvider 初始化，预加载 Category + Budget
├── app.dart               # MaterialApp，路由表，浅色/深色主题
├── models/                # 数据模型（toMap/fromMap/copyWith）
│   ├── expense.dart       # Expense + ExpenseWithCategory，含 source/externalId 字段
│   ├── category.dart      # Category（预设/自定义，isPreset 标记）
│   └── budget.dart        # Budget（monthly/weekly）
├── db/                    # SQLite 层
│   ├── database_helper.dart  # 单例，建表/迁移（当前 v2），预设分类写入
│   ├── expense_dao.dart   # 12 个方法：CRUD、筛选、聚合、去重导入
│   ├── category_dao.dart  # CRUD + 排序，预设分类保护
│   └── budget_dao.dart    # upsert/deactivate/getActive
├── providers/             # ChangeNotifier 状态管理
│   ├── expense_provider.dart
│   ├── category_provider.dart
│   ├── budget_provider.dart
│   └── theme_provider.dart
├── import/                # 账单导入模块
│   ├── bill_parser.dart       # 入口：检测文件类型，分发解析
│   ├── alipay_parser.dart     # 解析支付宝 CSV（跳过表头，取支出记录）
│   ├── wechat_parser.dart     # 解析微信 XLSX（自动检测列位置）
│   └── category_mapper.dart   # 平台分类 → app 分类映射
├── screens/               # 页面
├── widgets/               # 可复用组件（图表、卡片、选择器等）
└── utils/                 # 常量、日期/货币工具
```

**数据流:** `screens → providers (ChangeNotifier) → db (DAO) → models → SQLite`

## 数据库

SQLite 单文件 `aiaccounting.db`，当前版本 v2。

### 表结构
| 表 | 用途 | 关键字段 |
|---|------|---------|
| categories | 分类 | id, name, color, is_preset, sort_order |
| expenses | 支出记录 | id, amount, category_id, note, recorded_at, source, external_id |
| budgets | 预算 | id, type(weekly/monthly), amount, is_active |

- `expenses.source`: `'manual'` | `'wechat'` | `'alipay'`，默认 `'manual'`
- `expenses.external_id`: 账单订单号，与 source 联合唯一索引实现去重
- 数据库迁移写在 `_onUpgrade` 中

### 测试中的数据库
测试使用 `sqflite_common_ffi`（内存/临时文件 SQLite），必须在 `setUpAll` 中初始化：
```dart
setUpAll(() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
});
```
所有 DB 测试必须加 `--concurrency=1` 避免文件锁冲突。

## 路由

9 个路由，`onGenerateRoute` 注册在 `app.dart`：

| Route | Screen | 参数 |
|-------|--------|------|
| `/` | HomeScreen | 底部导航首页 |
| `/record` | RecordExpenseScreen | 记一笔 |
| `/statistics` | StatisticsScreen | 底部导航统计 |
| `/settings` | SettingsScreen | 底部导航设置 |
| `/expense-detail` | ExpenseDetailScreen | arguments: expenseId (int) |
| `/budget-setting` | BudgetSettingScreen | 预算设置 |
| `/category-manage` | CategoryManageScreen | 分类管理 |
| `/bill-import` | BillImportScreen | 账单导入 |

HomeScreen 内含底部导航栏（首页/统计/设置 3 tab），不是独立路由。

## 关键设计决策

- **纯本地**: 无用户系统、无后端、无网络依赖。所有数据存 SQLite
- **Provider 而非 Riverpod/Bloc**: 项目规模小，Provider 够用，避免过度设计
- **账单导入**: 通过文件导入（用户自行从微信/支付宝下载账单），非通知栏监听。自动检测 CSV/XLSX，根据 source+external_id 去重
- **预设分类保护**: `is_preset=1` 的分类不可删除，DAO 层拦截抛异常
- **主题**: 浅色/深色，种子色 `#45B7D1`，Material 3

## 注意事项

- `D:\sgd\soft\Flutter\bin\flutter` 为 Flutter 完整路径，不要依赖 PATH
- JDK 21 在 `D:/sgd/evn/jdk21.0.7`，Android SDK 在 `D:/Android`
- Gradle 下载用华为镜像，Maven 用阿里云镜像（配置在 `android/settings.gradle.kts` 和 `android/build.gradle.kts`）
- `docs/superpowers/` 目录不提交到 git（在 `.gitignore` 中）
- 首次构建 APK 约需 30 分钟（需下载 Gradle/Maven/CMake），后续构建会快很多
