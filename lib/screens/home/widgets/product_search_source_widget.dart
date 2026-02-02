import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';

class ProductSearchSourceWidget extends StatelessWidget {
  final WidgetStatus status;
  final ProductSearchSourceAnalytics? data;

  const ProductSearchSourceWidget({super.key, required this.status, this.data});

  static const _sourceColors = {
    'dashboard': Color(0xFF6366F1),
    'whatsapp': Color(0xFF25D366),
    'application': Color(0xFF3B82F6),
    'mobile_customer': Color(0xFF14B8A6),
    'mobile_employee': Color(0xFFF97316),
    'mobile_admin': Color(0xFFEC4899),
  };

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Search Sources',
      icon: Icons.source_outlined,
      status: status,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (data == null || data!.sources.isEmpty) {
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
                sections: data!.sources.map((s) {
                  final color = _sourceColors[s.source] ?? AppColors.grey;
                  return PieChartSectionData(
                    value: s.count.toDouble(),
                    title: '${s.percentage.toStringAsFixed(0)}%',
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                    color: color,
                    radius: 50,
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 25,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...data!.sources.map((s) {
            final color = _sourceColors[s.source] ?? AppColors.grey;
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
                    child: Text(s.sourceName, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ),
                  Text('${s.count}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
