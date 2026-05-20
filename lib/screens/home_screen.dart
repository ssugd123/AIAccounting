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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final expenseProv = context.read<ExpenseProvider>();
    final now = DateTime.now();
    final monthRange = DateHelper.monthRange(now.year, now.month);
    await Future.wait([
      expenseProv.loadRecentExpenses(),
      expenseProv.loadTotalByDateRange(monthRange.start, monthRange.end),
      context.read<BudgetProvider>().loadBudgets(),
    ]);
  }

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
          final expenseProv = context.read<ExpenseProvider>();
          final now = DateTime.now();
          final monthRange = DateHelper.monthRange(now.year, now.month);
          await Future.wait([
            expenseProv.loadRecentExpenses(),
            expenseProv.loadTotalByDateRange(monthRange.start, monthRange.end),
            context.read<BudgetProvider>().loadBudgets(),
          ]);
        },
        child: Consumer2<ExpenseProvider, BudgetProvider>(
          builder: (context, expenseProv, budgetProv, _) {
            if (expenseProv.isLoading && expenseProv.expenses.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final total = expenseProv.totalExpense;
            final monthlyBudget = budgetProv.monthlyBudget;
            final remaining = monthlyBudget != null ? budgetProv.getBudgetRemaining('monthly', total) : null;

            return ListView(
              padding: const EdgeInsets.only(bottom: 32),
              children: [
                // Summary header
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF45B7D1), Color(0xFF66D9B7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF45B7D1).withAlpha(80), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      const Text('本月支出', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(CurrencyHelper.format(total),
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                      if (remaining != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('预算剩余 ${CurrencyHelper.format(remaining)}',
                              style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14)),
                        ),
                    ],
                  ),
                ),

                // Budget progress
                if (monthlyBudget != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: BudgetProgressBar(spent: total, budget: monthlyBudget.amount, label: '月预算'),
                  ),
                const SizedBox(height: 8),

                // "记一笔" button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF45B7D1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/record'),
                      icon: const Icon(Icons.add_circle_outline, size: 24),
                      label: const Text('记一笔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),

                // Recent expenses
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('最近记录', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (expenseProv.expenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: EmptyState(message: '还没有记账，开始记一笔吧', icon: Icons.receipt_long_outlined),
                  )
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
