import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../db/expense_dao.dart';
import '../providers/category_provider.dart';
import '../utils/date_helper.dart';
import '../widgets/pie_chart_widget.dart';
import '../widgets/bar_chart_widget.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _periodIndex = 2; // default: month
  final _labels = ['今日', '本周', '本月', '今年'];
  Map<String, double> _sumByCategory = {};
  Map<String, double> _dailySum = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  DateRange _getRange() {
    final now = DateTime.now();
    switch (_periodIndex) {
      case 0: return DateHelper.todayRange();
      case 1: return DateHelper.weekRange();
      case 2: return DateHelper.monthRange(now.year, now.month);
      case 3: return DateHelper.yearRange(now.year);
      default: return DateHelper.monthRange(now.year, now.month);
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final dao = ExpenseDao();
    final range = _getRange();
    final catSum = await dao.getSumByCategory(range.start, range.end);
    final daily = await dao.getDailySum(range.start, range.end);
    if (mounted) setState(() { _sumByCategory = catSum; _dailySum = daily; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CategoryProvider>().categories;
    final colors = {for (final c in categories) c.name: c.color};

    return Scaffold(
      appBar: AppBar(title: const Text('统计分析')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SegmentedButton<int>(
                      segments: List.generate(_labels.length, (i) => ButtonSegment(value: i, label: Text(_labels[i]))),
                      selected: {_periodIndex},
                      onSelectionChanged: (s) { _periodIndex = s.first; _loadData(); },
                    ),
                  ),
                  const Text('支出分类占比', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  PieChartWidget(data: _sumByCategory, colors: colors),
                  const SizedBox(height: 32),
                  const Text('每日支出趋势', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  BarChartWidget(data: _dailySum),
                ]),
              ),
            ),
    );
  }
}
