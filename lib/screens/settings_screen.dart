import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.currency_yuan),
            title: const Text('货币单位'),
            subtitle: const Text('人民币 (¥)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('选择货币'),
                  children: currencySymbols.entries.map((e) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(ctx, e.key),
                    child: Text('${e.value} ${e.key}'),
                  )).toList(),
                ),
              );
            },
          ),
          const Divider(indent: 72),
          Consumer<ThemeProvider>(
            builder: (context, tp, _) => SwitchListTile(
              secondary: Icon(tp.isDark ? Icons.dark_mode : Icons.light_mode),
              title: const Text('深色模式'),
              value: tp.isDark,
              onChanged: (_) => tp.toggleTheme(),
            ),
          ),
          const Divider(indent: 72),
          ListTile(
            leading: const Icon(Icons.category),
            title: const Text('分类管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/category-manage'),
          ),
          const Divider(indent: 72),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet),
            title: const Text('预算设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, '/budget-setting'),
          ),
          const Divider(indent: 72),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('关于'),
            subtitle: Text('AI记账 v1.0.0'),
          ),
        ],
      ),
    );
  }
}
