import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aiaccounting/app.dart';
import 'package:aiaccounting/providers/theme_provider.dart';
import 'package:aiaccounting/providers/category_provider.dart';
import 'package:aiaccounting/providers/expense_provider.dart';
import 'package:aiaccounting/providers/budget_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App displays AI记账 title', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CategoryProvider()),
          ChangeNotifierProvider(create: (_) => ExpenseProvider()),
          ChangeNotifierProvider(create: (_) => BudgetProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const AIAccountingApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AI记账'), findsOneWidget);
  });
}
