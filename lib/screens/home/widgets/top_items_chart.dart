import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';

class TopItemsChart extends StatelessWidget {
  final List<RankedItem> items;
  final int total;
  final String totalLabel;
  final List<Color> colors;

  const TopItemsChart({
    super.key,
    required this.items,
    required this.total,
    required this.totalLabel,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No data', style: TextStyle(color: AppColors.grey, fontSize: 13))),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                sections: items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return PieChartSectionData(
                    value: item.count.toDouble(),
                    title: '${item.percentage.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                    color: colors[i % colors.length],
                    radius: 50,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 25,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Ranked list
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length].withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.rank}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: colors[i % colors.length]),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${item.count}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$totalLabel: ',
                  style: const TextStyle(fontSize: 11, color: AppColors.grey),
                ),
                Text(
                  '$total',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
