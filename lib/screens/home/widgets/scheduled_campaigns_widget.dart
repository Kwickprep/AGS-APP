import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';

class ScheduledCampaignsWidget extends StatelessWidget {
  final WidgetStatus status;
  final DashboardCampaignsResponse? data;

  const ScheduledCampaignsWidget({super.key, required this.status, this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'Scheduled Campaigns',
      icon: Icons.campaign_outlined,
      status: status,
      trailing: data != null
          ? _badge(data!.total.toString())
          : null,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    if (data == null || data!.campaigns.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No scheduled campaigns', style: TextStyle(color: AppColors.grey, fontSize: 13)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      itemCount: data!.campaigns.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) => _buildItem(data!.campaigns[i]),
    );
  }

  Widget _buildItem(DashboardCampaign item) {
    String dateStr = '';
    if (item.startDateTime.isNotEmpty) {
      try {
        final date = DateTime.parse(item.startDateTime);
        dateStr = DateFormat('dd MMM, h:mm a').format(date);
      } catch (_) {}
    }

    final isRunning = item.status == 'Running';

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
                Row(
                  children: [
                    Icon(Icons.people_outline, size: 13, color: AppColors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${item.contactCount} contacts',
                      style: const TextStyle(fontSize: 12, color: AppColors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (isRunning ? const Color(0xFF22C55E) : const Color(0xFF3B82F6))
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.status.isNotEmpty ? item.status : 'Scheduled',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isRunning ? const Color(0xFF22C55E) : const Color(0xFF3B82F6),
                  ),
                ),
              ),
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
