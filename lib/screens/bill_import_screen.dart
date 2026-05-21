import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../import/bill_parser.dart';
import '../models/expense.dart';
import '../providers/expense_provider.dart';
import '../providers/category_provider.dart';

class BillImportScreen extends StatefulWidget {
  const BillImportScreen({super.key});
  @override
  State<BillImportScreen> createState() => _BillImportScreenState();
}

class _BillImportScreenState extends State<BillImportScreen> {
  BillParseResult? _result;
  Set<int> _selectedIndices = {};
  bool _loading = false;
  String? _error;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result == null || result.files.isEmpty) return;

    setState(() { _loading = true; _error = null; _result = null; });

    final file = result.files.first;
    final parseResult = BillParser.parse(file.path!, file.name);

    setState(() {
      _loading = false;
      if (parseResult.isSuccess) {
        _result = parseResult;
        _selectedIndices = Set.from(List.generate(parseResult.items.length, (i) => i));
      } else {
        _error = parseResult.error;
      }
    });
  }

  String _getSourceLabel(BillType type) {
    switch (type) {
      case BillType.wechat: return '微信';
      case BillType.alipay: return '支付宝';
      default: return '未知';
    }
  }

  Future<int> _getCategoryId(String categoryName) async {
    final categories = context.read<CategoryProvider>().categories;
    final cat = categories.where((c) => c.name == categoryName).firstOrNull;
    return cat?.id ?? categories.first.id!;
  }

  Future<void> _import() async {
    if (_result == null || _selectedIndices.isEmpty) return;
    setState(() => _loading = true);

    final now = DateTime.now();
    int imported = 0;
    final expenseProv = context.read<ExpenseProvider>();

    for (final idx in _selectedIndices) {
      final item = _result!.items[idx];
      final source = item.billType == BillType.wechat ? 'wechat' : 'alipay';
      final categoryId = await _getCategoryId(item.mappedCategory);

      final expense = Expense(
        amount: item.amount,
        categoryId: categoryId,
        note: '${item.counterparty} - ${item.productDescription}'.trim(),
        recordedAt: item.tradeTime,
        createdAt: now,
        updatedAt: now,
        source: source,
        externalId: item.externalId.isNotEmpty ? item.externalId : null,
      );

      try {
        final id = await expenseProv.addExpense(expense);
        if (id > 0) imported++;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $imported 条记录')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入账单')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _result != null
                  ? _buildPreview()
                  : _buildPicker(),
    );
  }

  Widget _buildPicker() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.upload_file, size: 80, color: Colors.grey[400]),
        const SizedBox(height: 16),
        const Text('导入微信或支付宝账单', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text('支持 .csv（支付宝）和 .xlsx（微信）格式', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.file_open),
          label: const Text('选择文件'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
        ),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
        const SizedBox(height: 16),
        Text(_error!, style: const TextStyle(fontSize: 16, color: Colors.red)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: _pickFile, child: const Text('重新选择')),
      ]),
    );
  }

  Widget _buildPreview() {
    final result = _result!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF45B7D1).withAlpha(25),
          child: Row(children: [
            const Icon(Icons.check_circle, color: Color(0xFF45B7D1)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('已识别: ${_getSourceLabel(result.billType)}账单',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text('共 ${result.items.length} 条支出记录，已选 ${_selectedIndices.length} 条',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ]),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: result.items.length,
            itemBuilder: (context, index) {
              final item = result.items[index];
              final selected = _selectedIndices.contains(index);
              return CheckboxListTile(
                value: selected,
                onChanged: (v) {
                  setState(() {
                    if (v == true) { _selectedIndices.add(index); }
                    else { _selectedIndices.remove(index); }
                  });
                },
                title: Text(item.counterparty.isNotEmpty ? item.counterparty : item.productDescription,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text('${item.tradeTime.toString().substring(0, 16)}  ${item.mappedCategory}',
                    style: const TextStyle(fontSize: 12)),
                secondary: Text('¥${item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _selectedIndices.isEmpty ? null : _import,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF45B7D1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('导入 ${_selectedIndices.length} 条记录', style: const TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
