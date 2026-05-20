import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../models/category.dart';
import '../widgets/category_picker.dart';

class RecordExpenseScreen extends StatefulWidget {
  const RecordExpenseScreen({super.key});

  @override
  State<RecordExpenseScreen> createState() => _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends State<RecordExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  Category? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  DateTime _selectedTime = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入金额')));
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效金额')));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请选择分类')));
      return;
    }

    setState(() => _saving = true);

    final recordedAt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
        _selectedTime.hour, _selectedTime.minute);
    final now = DateTime.now();
    final expense = Expense(
      amount: amount, categoryId: _selectedCategory!.id!,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      recordedAt: recordedAt, createdAt: now, updatedAt: now,
    );

    try {
      await context.read<ExpenseProvider>().addExpense(expense);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('记录成功'), duration: Duration(seconds: 1)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('记录失败: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context, initialDate: _selectedDate,
      firstDate: DateTime(2020), lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.fromDateTime(_selectedTime),
    );
    if (picked != null) {
      setState(() => _selectedTime = DateTime(
        _selectedTime.year, _selectedTime.month, _selectedTime.day,
        picked.hour, picked.minute,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('记一笔')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Amount input
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(prefixText: '¥ ', hintText: '0.00',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))),
          ),
          const SizedBox(height: 20),

          // Category
          const Text('选择分类', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          CategoryPicker(
            selectedCategoryId: _selectedCategory?.id,
            onSelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 20),

          // Date & Time
          Row(children: [
            Expanded(child: ListTile(
              title: const Text('日期', style: TextStyle(fontSize: 13)),
              subtitle: Text('${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today, size: 20), onTap: _pickDate,
            )),
            Expanded(child: ListTile(
              title: const Text('时间', style: TextStyle(fontSize: 13)),
              subtitle: Text('${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.access_time, size: 20), onTap: _pickTime,
            )),
          ]),
          const SizedBox(height: 16),

          // Note
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: '备注（选填）', hintText: '例如：早餐豆浆油条',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),

          // Save
          SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF45B7D1), foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _saving
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('保存', style: TextStyle(fontSize: 18)),
            ),
          ),
        ]),
      ),
    );
  }
}
