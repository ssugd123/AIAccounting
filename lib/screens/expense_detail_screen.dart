import 'package:flutter/material.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final int expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Expense Detail #$expenseId')),
    );
  }
}
