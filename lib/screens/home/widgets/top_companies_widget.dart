import 'package:flutter/material.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';
import 'top_items_chart.dart';

class TopCompaniesWidget extends StatelessWidget {
  final WidgetStatus status;
  final TopCompaniesAnalytics? data;

  const TopCompaniesWidget({super.key, required this.status, this.data});

  static const _colors = [
    Color(0xFF3B82F6),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Top Companies',
      icon: Icons.business_outlined,
      status: status,
      child: TopItemsChart(
        items: data?.companies ?? [],
        total: data?.totalInquiries ?? 0,
        totalLabel: 'Total Inquiries',
        colors: _colors,
      ),
    );
  }
}
