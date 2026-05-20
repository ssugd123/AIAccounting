import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/expense_dao.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../utils/currency_helper.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final int expenseId;
  const ExpenseDetailScreen({super.key, required this.expenseId});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  ExpenseWithCategory? _expense;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final dao = ExpenseDao();
    final e = await dao.getById(widget.expenseId);
    if (mounted) setState(() { _expense = e; _loading = false; });
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ExpenseProvider>().deleteExpense(widget.expenseId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar: AppBar(title: const Text('记录详情')), body: const Center(child: CircularProgressIndicator()));
    if (_expense == null) return Scaffold(appBar: AppBar(title: const Text('记录详情')), body: const Center(child: Text('记录不存在')));

    final e = _expense!;
    final color = Color(int.parse(e.categoryColor.replaceFirst('#', '0xFF')));

    return Scaffold(
      appBar: AppBar(title: const Text('记录详情'), actions: [
        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          CircleAvatar(radius: 36, backgroundColor: color.withAlpha(40),
              child: Text(e.categoryName[0], style: TextStyle(fontSize: 32, color: color, fontWeight: FontWeight.bold))),
          const SizedBox(height: 8),
          Text(e.categoryName, style: TextStyle(fontSize: 16, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          Text(CurrencyHelper.format(e.expense.amount),
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _row('日期', '${e.expense.recordedAt.year}-${e.expense.recordedAt.month.toString().padLeft(2, '0')}-${e.expense.recordedAt.day.toString().padLeft(2, '0')}'),
          _row('时间', '${e.expense.recordedAt.hour.toString().padLeft(2, '0')}:${e.expense.recordedAt.minute.toString().padLeft(2, '0')}'),
          if (e.expense.note != null && e.expense.note!.isNotEmpty) _row('备注', e.expense.note!),
        ]),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
      ]),
    );
  }
}
