import '../models/category.dart';

const Map<String, String> currencySymbols = {
  'CNY': '¥',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
};
const String defaultCurrency = 'CNY';

const Map<String, String> presetCategoryIcons = {
  '餐饮': 'restaurant',
  '交通': 'directions_bus',
  '住房': 'home',
  '娱乐': 'movie',
  '购物': 'shopping_cart',
  '医疗': 'local_hospital',
  '其他': 'more_horiz',
};
const Map<String, String> presetCategoryColors = {
  '餐饮': '#FF6B6B',
  '交通': '#4ECDC4',
  '住房': '#45B7D1',
  '娱乐': '#F9CA24',
  '购物': '#A29BFE',
  '医疗': '#FF9FF3',
  '其他': '#DFE6E9',
};

List<Category> presetCategories() {
  final now = DateTime.now();
  final names = ['餐饮', '交通', '住房', '娱乐', '购物', '医疗', '其他'];
  return List.generate(
      names.length,
      (i) {
        final name = names[i];
        return Category(
          name: name,
          icon: presetCategoryIcons[name]!,
          color: presetCategoryColors[name]!,
          sortOrder: i,
          isPreset: true,
          createdAt: now,
        );
      });
}
