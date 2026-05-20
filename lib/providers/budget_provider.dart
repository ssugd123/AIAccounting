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
    _isLoading = true;
    notifyListeners();
    try {
      _monthlyBudget = await _dao.getActive('monthly');
      _weeklyBudget = await _dao.getActive('weekly');
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> setBudget(String type, double amount) async {
    await _dao.upsert(
        Budget(type: type, amount: amount, createdAt: DateTime.now()));
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
