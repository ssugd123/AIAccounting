import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';
import '../models/category.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});
  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen> {
  final _colorOptions = const ['#E17055', '#00B894', '#FDCB6E', '#E84393', '#6C5CE7', '#FD79A8', '#2D3436', '#0984E3'];

  Future<void> _addCategory() async {
    final nameController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加分类'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: '分类名称', hintText: '如：宠物'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, nameController.text.trim()), child: const Text('添加')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      try {
        final color = _colorOptions[context.read<CategoryProvider>().categories.length % _colorOptions.length];
        await context.read<CategoryProvider>().addCategory(result, color, DateTime.now());
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _editCategory(Category cat) async {
    final nameController = TextEditingController(text: cat.name);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑分类'),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: '分类名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, nameController.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      await context.read<CategoryProvider>().updateCategory(cat.copyWith(name: result));
    }
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除分类"${cat.name}"吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<CategoryProvider>().deleteCategory(cat.id!);
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('分类管理'), actions: [
        IconButton(icon: const Icon(Icons.add), onPressed: _addCategory),
      ]),
      body: Consumer<CategoryProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading) return const Center(child: CircularProgressIndicator());
          return ReorderableListView.builder(
            itemCount: prov.categories.length,
            onReorderItem: (oldIndex, newIndex) {
              final ids = prov.categories.map((c) => c.id!).toList();
              final item = ids.removeAt(oldIndex);
              ids.insert(newIndex, item);
              prov.reorderCategories(ids);
            },
            itemBuilder: (context, index) {
              final cat = prov.categories[index];
              final color = Color(int.parse(cat.color.replaceFirst('#', '0xFF')));
              return ListTile(
                key: ValueKey(cat.id),
                leading: CircleAvatar(
                  backgroundColor: color.withAlpha(40),
                  radius: 18,
                  child: Text(cat.name[0], style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
                title: Text(cat.name),
                subtitle: cat.isPreset
                    ? const Text('预设分类', style: TextStyle(fontSize: 12, color: Colors.grey))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!cat.isPreset)
                      IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _editCategory(cat)),
                    if (!cat.isPreset)
                      IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _deleteCategory(cat)),
                    const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
