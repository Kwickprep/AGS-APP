import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';

class ProductSearchFunnelWidget extends StatelessWidget {
  final WidgetStatus status;
  final ProductSearchFunnel? data;

  const ProductSearchFunnelWidget({super.key, required this.status, this.data});

  static const _stageColors = {
    'INITIAL': Color(0xFF6366F1),
    'THEME_SELECTION': Color(0xFF8B5CF6),
    'CATEGORY_SELECTION': Color(0xFFA855F7),
    'PRICE_RANGE_SELECTION': Color(0xFFD946EF),
    'PRODUCT_SELECTION': Color(0xFFEC4899),
    'COMPLETED': Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Search Funnel',
      icon: Icons.filter_alt_outlined,
      status: status,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (data == null || data!.stages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('No data', style: TextStyle(color: AppColors.grey, fontSize: 13))),
      );
    }

    final maxCount = data!.stages.fold<int>(0, (max, s) => s.count > max ? s.count : max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Metrics row
          Row(
            children: [
              _metric('Total Searches', data!.totalSearches.toString()),
              const SizedBox(width: 16),
              _metric('Completion', '${data!.completionRate.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 16),
          // Funnel bars
          ...data!.stages.map((stage) {
            final color = _stageColors[stage.stage] ?? AppColors.grey;
            final barWidth = maxCount > 0 ? (stage.count / maxCount).clamp(0.05, 1.0) : 0.05;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          stage.stageName,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${stage.count}  (${stage.percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FractionallySizedBox(
                    widthFactor: barWidth,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
          ],
        ),
      ),
    );
  }
}
