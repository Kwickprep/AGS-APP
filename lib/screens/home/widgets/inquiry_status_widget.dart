import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';

class InquiryStatusWidget extends StatelessWidget {
  final WidgetStatus status;
  final InquiryStatusAnalytics? data;

  const InquiryStatusWidget({super.key, required this.status, this.data});

  Color _parseColor(String hex) {
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Inquiry Status',
      icon: Icons.donut_large_outlined,
      status: status,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (data == null) return const SizedBox.shrink();

    final filtered = data!.distribution.where((d) => d.count > 0).toList();
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
                sections: filtered.map((d) {
                  final color = _parseColor(d.color);
                  return PieChartSectionData(
                    value: d.count.toDouble(),
                    title: '${d.percentage.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                    color: color,
                    radius: 55,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...filtered.map((d) {
            final color = _parseColor(d.color);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d.statusName,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    '${d.count}',
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
