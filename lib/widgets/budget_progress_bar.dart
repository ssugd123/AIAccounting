import 'package:flutter/material.dart';

class BudgetProgressBar extends StatelessWidget {
  final double spent;
  final double budget;
  final String label;

  const BudgetProgressBar({super.key, required this.spent, required this.budget, this.label = '预算'});

  double get _ratio => (spent / budget).clamp(0.0, 1.0);
  bool get _isOver => spent > budget;
  Color get _color => _isOver ? Colors.red : _ratio > 0.8 ? Colors.orange : const Color(0xFF45B7D1);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label ¥${spent.toStringAsFixed(0)} / ¥${budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
            if (_isOver) const Text('超预算!', style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: _ratio, backgroundColor: Colors.grey[200],
              color: _color, minHeight: 8),
        ),
      ],
    );
  }
}
