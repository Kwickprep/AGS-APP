import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';

class ActivityAnalyticsWidget extends StatelessWidget {
  final WidgetStatus status;
  final ActivityTypeAnalytics? data;

  const ActivityAnalyticsWidget({super.key, required this.status, this.data});

  static const _colors = [
    Color(0xFF6366F1),
    Color(0xFF22C55E),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFFEF4444),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Activity Analytics',
      icon: Icons.pie_chart_outline,
      status: status,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (data == null) return const SizedBox.shrink();

    final filtered = data!.stats.where((s) => s.count > 0).toList();
    if (filtered.isEmpty) {
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
            height: 180,
            child: PieChart(
              PieChartData(
                sections: filtered.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  return PieChartSectionData(
                    value: s.count.toDouble(),
                    title: '${s.percentage.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                    color: _colors[i % _colors.length],
                    radius: 55,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.activityTypeName,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${s.count}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
