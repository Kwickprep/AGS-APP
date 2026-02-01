import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';

class RecentInquiriesWidget extends StatelessWidget {
  final WidgetStatus status;
  final DashboardInquiriesResponse? data;

  const RecentInquiriesWidget({super.key, required this.status, this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Recent Inquiries',
      icon: Icons.request_page_outlined,
      status: status,
      trailing: data != null
          ? _badge(data!.total.toString())
          : null,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    if (data == null || data!.records.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No recent inquiries', style: TextStyle(color: AppColors.grey, fontSize: 13)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      itemCount: data!.records.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) => _buildItem(data!.records[i]),
    );
  }

  Widget _buildItem(DashboardInquiry item) {
    String dateStr = '';
    if (item.createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(item.createdAt);
        dateStr = DateFormat('dd MMM, h:mm a').format(date);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                if (item.companyName.isNotEmpty)
                  Text(
                    item.companyName,
                    style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _statusBadge(item.status),
              if (dateStr.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(dateStr, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    switch (status) {
      case 'Won':
        color = const Color(0xFF22C55E);
        break;
      case 'Lost':
        color = const Color(0xFFEF4444);
        break;
      case 'On Hold':
        color = const Color(0xFFF59E0B);
        break;
      case 'In Progress':
        color = const Color(0xFF3B82F6);
        break;
      case 'Closed':
        color = const Color(0xFF6B7280);
        break;
      default:
        color = const Color(0xFF3B82F6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.isNotEmpty ? status : 'Open',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
      ),
    );
  }
}
