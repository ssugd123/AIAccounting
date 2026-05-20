import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/budget_provider.dart';

class BudgetSettingScreen extends StatefulWidget {
  const BudgetSettingScreen({super.key});
  @override
  State<BudgetSettingScreen> createState() => _BudgetSettingScreenState();
}

class _BudgetSettingScreenState extends State<BudgetSettingScreen> {
  final _weeklyController = TextEditingController();
  final _monthlyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final budgets = context.read<BudgetProvider>();
    if (budgets.weeklyBudget != null) {
      _weeklyController.text = budgets.weeklyBudget!.amount.toStringAsFixed(0);
    }
    if (budgets.monthlyBudget != null) {
      _monthlyController.text = budgets.monthlyBudget!.amount.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _weeklyController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final provider = context.read<BudgetProvider>();
    final weekly = double.tryParse(_weeklyController.text.trim());
    final monthly = double.tryParse(_monthlyController.text.trim());

    if (weekly != null && weekly > 0) {
      await provider.setBudget('weekly', weekly);
    } else {
      await provider.removeBudget('weekly');
    }
    if (monthly != null && monthly > 0) {
      await provider.setBudget('monthly', monthly);
    } else {
      await provider.removeBudget('monthly');
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('预算已保存')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('预算设置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('月预算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _monthlyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '¥ ', hintText: '输入月预算金额',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
          ),
          const SizedBox(height: 24),
          const Text('周预算', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _weeklyController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(prefixText: '¥ ', hintText: '输入周预算金额',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
          ),
          const SizedBox(height: 32),
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF45B7D1), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('保存', style: TextStyle(fontSize: 18)),
            ),
          ),
        ]),
      ),
    );
  }
}
