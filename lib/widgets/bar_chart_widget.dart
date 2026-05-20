import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, double> data;

  const BarChartWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 220, child: Center(child: Text('暂无消费数据', style: TextStyle(color: Colors.grey))));
    }
    final maxY = data.values.reduce((a, b) => a > b ? a : b) * 1.2;
    final entries = data.entries.toList();
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(toY: entries[i].value, color: const Color(0xFF45B7D1),
                  width: 16, borderRadius: BorderRadius.circular(4)),
            ]);
          }),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= entries.length) return const SizedBox.shrink();
                  final label = entries[idx].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(label.length > 5 ? label.substring(5) : label, style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40,
                  getTitlesWidget: (value, meta) =>
                      Text('¥${value.toInt()}', style: const TextStyle(fontSize: 10))),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}
