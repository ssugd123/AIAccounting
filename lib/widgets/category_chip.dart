import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final bool selected;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.selected = false, this.onTap});

  Color get _color => Color(int.parse(category.color.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _color : _color.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _color, width: selected ? 2 : 1),
        ),
        child: Text(category.name,
            style: TextStyle(color: selected ? Colors.white : _color, fontSize: 13, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
