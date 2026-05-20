import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final Map<String, String> colors;

  const PieChartWidget({super.key, required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('暂无消费数据', style: TextStyle(color: Colors.grey))));
    }
    return SizedBox(
      height: 220,
      child: PieChart(
        PieChartData(
          sections: data.entries.map((entry) {
            final hexColor = colors[entry.key] ?? '#999999';
            final color = Color(int.parse(hexColor.replaceFirst('#', '0xFF')));
            return PieChartSectionData(
              color: color, value: entry.value, title: entry.key, radius: 80,
              titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }).toList(),
          sectionsSpace: 2, centerSpaceRadius: 40,
        ),
      ),
    );
  }
}
