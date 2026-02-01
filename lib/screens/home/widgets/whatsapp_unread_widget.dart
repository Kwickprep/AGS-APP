import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_colors.dart';
import '../../../models/dashboard_models.dart';
import '../home_bloc.dart';
import 'dashboard_widget_card.dart';

class WhatsappUnreadWidget extends StatelessWidget {
  final WidgetStatus status;
  final WhatsAppUnreadResponse? data;

  const WhatsappUnreadWidget({super.key, required this.status, this.data});

  @override
  Widget build(BuildContext context) {
    return DashboardWidgetCard(
      title: 'WhatsApp Unread',
      icon: Icons.chat_bubble_outline,
      status: status,
      trailing: data != null
          ? _badge(data!.totalUnreadMessages.toString())
          : null,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    if (data == null || data!.contacts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text('No unread messages', style: TextStyle(color: AppColors.grey, fontSize: 13)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      itemCount: data!.contacts.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (_, i) => _buildItem(data!.contacts[i]),
    );
  }

  Widget _buildItem(WhatsAppUnreadContact contact) {
    String timeStr = '';
    if (contact.lastMessageTime.isNotEmpty) {
      try {
        final date = DateTime.parse(contact.lastMessageTime);
        timeStr = DateFormat('dd MMM, h:mm a').format(date);
      } catch (_) {}
    }

    final displayName = contact.userName.isNotEmpty ? contact.userName : contact.phoneNumber;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.1),
            child: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (timeStr.isNotEmpty)
                  Text(timeStr, style: const TextStyle(fontSize: 11, color: AppColors.grey)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              contact.unreadCount.toString(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF25D366)),
      ),
    );
  }
}
