import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';

class SummaryCardsWidget extends StatelessWidget {
  final WidgetStatus status;
  final DashboardSummary? data;

  const SummaryCardsWidget({super.key, required this.status, this.data});

  @override
  Widget build(BuildContext context) {
    if (status == WidgetStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (status == WidgetStatus.error || data == null) {
      return const SizedBox.shrink();
    }

    final items = [
      _CardData(
        'Admins',
        data!.totalAdmins,
        Icons.admin_panel_settings_outlined,
        const Color(0xFF6366F1),
      ),
      _CardData(
        'Employees',
        data!.totalEmployees,
        Icons.people_outline,
        const Color(0xFF22C55E),
      ),
      _CardData(
        'Companies',
        data!.totalCompanies,
        Icons.business_outlined,
        const Color(0xFFF59E0B),
      ),
      _CardData(
        'Customers',
        data!.totalCustomers,
        Icons.group_outlined,
        const Color(0xFF3B82F6),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
        children: items.map((item) => _buildCard(item)).toList(),
      ),
    );
  }

  Widget _buildCard(_CardData item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon, size: 20, color: item.color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: item.color,
                ),
              ),
              Text(
                item.label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardData {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _CardData(this.label, this.value, this.icon, this.color);
}
