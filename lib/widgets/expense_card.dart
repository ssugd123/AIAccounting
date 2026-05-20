import 'package:flutter/material.dart';
import '../models/expense.dart';
import 'amount_display.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseWithCategory expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ExpenseCard({super.key, required this.expense, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(expense.categoryColor.replaceFirst('#', '0xFF')));
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap, onLongPress: onLongPress,
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30), radius: 18,
          child: Text(expense.categoryName[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        title: Text(expense.categoryName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: expense.expense.note != null && expense.expense.note!.isNotEmpty
            ? Text(expense.expense.note!, style: const TextStyle(fontSize: 12)) : null,
        trailing: AmountDisplay(amount: expense.expense.amount, fontSize: 16, color: color),
      ),
    );
  }
}
