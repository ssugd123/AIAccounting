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
