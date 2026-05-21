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
import 'screens/bill_import_screen.dart';

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
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
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
              case '/bill-import':
                return MaterialPageRoute(builder: (_) => const BillImportScreen());
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
