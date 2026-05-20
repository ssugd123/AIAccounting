import 'package:flutter/foundation.dart' hide Category;
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
