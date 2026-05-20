import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';
import 'category_chip.dart';

class CategoryPicker extends StatelessWidget {
  final int? selectedCategoryId;
  final Function(Category) onSelected;

  const CategoryPicker({super.key, this.selectedCategoryId, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: categories.map((cat) => CategoryChip(
        category: cat, selected: cat.id == selectedCategoryId,
        onTap: () => onSelected(cat),
      )).toList(),
    );
  }
}
