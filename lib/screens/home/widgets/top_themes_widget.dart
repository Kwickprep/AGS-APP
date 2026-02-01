import 'package:flutter/material.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';
import 'top_items_chart.dart';

class TopThemesWidget extends StatelessWidget {
  final WidgetStatus status;
  final TopThemesAnalytics? data;

  const TopThemesWidget({super.key, required this.status, this.data});

  static const _colors = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFA855F7),
    Color(0xFFD946EF),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Top Themes',
      icon: Icons.palette_outlined,
      status: status,
      child: TopItemsChart(
        items: data?.themes ?? [],
        total: data?.totalSelections ?? 0,
        totalLabel: 'Total Selections',
        colors: _colors,
      ),
    );
  }
}
