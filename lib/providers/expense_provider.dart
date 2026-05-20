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

  Future<void> loadExpenses(
      {DateTime? start, DateTime? end, int? categoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _expenses =
          await _dao.getFiltered(start: start, end: end, categoryId: categoryId);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
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
    await loadRecentExpenses();
    return id;
  }

  Future<void> updateExpense(Expense expense) async {
    await _dao.update(expense);
    await loadRecentExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _dao.delete(id);
    await loadRecentExpenses();
  }

  Future<void> deleteByDateRange(DateTime start, DateTime end) async {
    await _dao.deleteByDateRange(start, end);
    await loadRecentExpenses();
  }
}
