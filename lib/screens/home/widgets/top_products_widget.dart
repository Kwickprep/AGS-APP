import 'package:flutter/material.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';
import 'top_items_chart.dart';

class TopProductsWidget extends StatelessWidget {
  final WidgetStatus status;
  final TopProductsAnalytics? data;

  const TopProductsWidget({super.key, required this.status, this.data});

  static const _colors = [
    Color(0xFFF59E0B),
    Color(0xFFF97316),
    Color(0xFFEF4444),
    Color(0xFFEC4899),
    Color(0xFFD946EF),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Top Products',
      icon: Icons.inventory_2_outlined,
      status: status,
      child: TopItemsChart(
        items: data?.products ?? [],
        total: data?.totalCompletions ?? 0,
        totalLabel: 'Total Completions',
        colors: _colors,
      ),
    );
  }
}
