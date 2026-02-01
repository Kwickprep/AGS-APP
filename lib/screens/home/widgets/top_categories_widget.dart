import 'package:flutter/material.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';
import 'top_items_chart.dart';

class TopCategoriesWidget extends StatelessWidget {
  final WidgetStatus status;
  final TopCategoriesAnalytics? data;

  const TopCategoriesWidget({super.key, required this.status, this.data});

  static const _colors = [
    Color(0xFF22C55E),
    Color(0xFF10B981),
    Color(0xFF14B8A6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Top Categories',
      icon: Icons.category_outlined,
      status: status,
      child: TopItemsChart(
        items: data?.categories ?? [],
        total: data?.totalSelections ?? 0,
        totalLabel: 'Total Selections',
        colors: _colors,
      ),
    );
  }
}
