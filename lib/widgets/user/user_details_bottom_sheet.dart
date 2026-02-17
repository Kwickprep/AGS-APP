import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/user_screen_model.dart';
import '../../services/user_service.dart';
import '../../utils/date_formatter.dart';

class UserDetailsBottomSheet extends StatefulWidget {
  final UserScreenModel user;

  const UserDetailsBottomSheet({super.key, required this.user});

  static void show({
    required BuildContext context,
    required UserScreenModel user,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailsBottomSheet(user: user),
    );
  }

  @override
  State<UserDetailsBottomSheet> createState() => _UserDetailsBottomSheetState();
}

class _UserDetailsBottomSheetState extends State<UserDetailsBottomSheet> {
  Map<String, dynamic>? _insights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final data = await UserService().getUserInsights(widget.user.id);
      if (mounted) {
        setState(() {
          _insights = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'User Details',
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverviewSection(),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          _buildErrorBanner(),
                        ],
                        if (_insights != null) ...[
                          _buildStatsSection(),
                          _buildInquiriesSection(),
                          _buildActivitiesSection(),
                          _buildWhatsAppSection(),
                          _buildProductSearchesSection(),
                          _buildAssignmentsSection(),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Could not load insights data',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final user = widget.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar and name
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage: user.profilePictureUrl != null
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: user.profilePictureUrl == null
                  ? Text(
                      _getInitials(user.firstName, user.lastName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildBadge(user.role, AppColors.primary),
                      const SizedBox(width: 8),
                      _buildBadge(
                        user.isActive == 'Active' ? 'Active' : 'Inactive',
                        user.isActive == 'Active' ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Detail fields
        if (user.designation.isNotEmpty && user.designation != '-')
          _buildDetailRow('Designation', user.designation),
        if (user.department.isNotEmpty && user.department != '-')
          _buildDetailRow('Department', user.department),
        if (user.division.isNotEmpty && user.division != '-')
          _buildDetailRow('Division', user.division),
        if (user.email.isNotEmpty && user.email != '-')
          _buildDetailRow('Email', user.email),
        if (user.phone.isNotEmpty && user.phone != '-')
          _buildDetailRow('Phone', user.phone),
        if (user.company.isNotEmpty && user.company != '-')
          _buildDetailRow('Company', user.company),
        if (user.employeeCode.isNotEmpty && user.employeeCode != '-')
          _buildDetailRow('Employee Code', user.employeeCode),
        if (user.createdInfo.isNotEmpty && user.createdInfo != '-')
          _buildDetailRow('Created', user.createdInfo),
        if (user.createdInfo.isEmpty || user.createdInfo == '-') ...[
          _buildDetailRow('Created By', user.createdBy),
          _buildDetailRow('Created Date', formatDate(user.createdAt)),
        ],
        if (user.updatedInfo != null && user.updatedInfo!.isNotEmpty && user.updatedInfo != '-')
          _buildDetailRow('Updated', user.updatedInfo!),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = _insights!['stats'] as Map<String, dynamic>? ?? {};
    final inquiries = stats['inquiries'] ?? 0;
    final activities = stats['activities'] ?? 0;
    final messages = stats['messages'] ?? 0;
    final companies = stats['companies'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionHeader('Statistics'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Inquiries', '$inquiries', AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Activities', '$activities', Colors.blue)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard('Messages', '$messages', Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Companies', '$companies', Colors.purple)),
          ],
        ),
        if (_insights!['notes'] != null && _insights!['notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDetailRow('Notes', _insights!['notes'].toString()),
        ],
      ],
    );
  }

  Widget _buildInquiriesSection() {
    final inquiries = _insights!['recentInquiries'] as List<dynamic>? ?? [];
    final statusCounts = _insights!['inquiryStatusCounts'] as Map<String, dynamic>? ?? {};
    if (inquiries.isEmpty && statusCounts.isEmpty) return const SizedBox.shrink();

    return _buildExpansionSection(
      'Inquiries',
      Icons.question_answer_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (statusCounts.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: statusCounts.entries.map((e) {
                return _buildChip('${e.key} (${e.value})');
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],
          ...inquiries.take(10).map((inq) {
            final map = inq as Map<String, dynamic>;
            return _buildListTile(
              map['name']?.toString() ?? 'N/A',
              subtitle: map['company']?.toString(),
              trailing: map['status']?.toString(),
              date: map['createdAt']?.toString(),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivitiesSection() {
    final activities = _insights!['recentActivities'] as List<dynamic>? ?? [];
    if (activities.isEmpty) return const SizedBox.shrink();

    return _buildExpansionSection(
      'Activities',
      Icons.timeline_outlined,
      Column(
        children: activities.take(10).map((act) {
          final map = act as Map<String, dynamic>;
          return _buildListTile(
            map['type']?.toString() ?? map['name']?.toString() ?? 'Activity',
            subtitle: map['company']?.toString(),
            trailing: map['inquiry']?.toString(),
            date: map['createdAt']?.toString(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWhatsAppSection() {
    final whatsapp = _insights!['whatsapp'] as Map<String, dynamic>? ?? {};
    if (whatsapp.isEmpty) return const SizedBox.shrink();

    final sent = whatsapp['sent'] ?? 0;
    final received = whatsapp['received'] ?? 0;
    final unread = whatsapp['unread'] ?? 0;
    final lastActive = whatsapp['lastActive']?.toString();
    final recentMessages = whatsapp['recentMessages'] as List<dynamic>? ?? [];

    return _buildExpansionSection(
      'WhatsApp',
      Icons.chat_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Sent', '$sent', AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Received', '$received', Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Unread', '$unread', Colors.orange)),
            ],
          ),
          if (lastActive != null && lastActive.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Last active: ${formatDate(lastActive)}',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
          if (recentMessages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...recentMessages.take(10).map((msg) {
              final map = msg as Map<String, dynamic>;
              final direction = map['direction']?.toString() ?? '';
              final content = map['content']?.toString() ?? '';
              return _buildListTile(
                content.length > 60 ? '${content.substring(0, 60)}...' : content,
                subtitle: direction,
                date: map['createdAt']?.toString(),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildProductSearchesSection() {
    final searches = _insights!['productSearches'] as Map<String, dynamic>? ?? {};
    if (searches.isEmpty) return const SizedBox.shrink();

    final total = searches['total'] ?? 0;
    final completed = searches['completed'] ?? 0;
    final rate = searches['completionRate']?.toString() ?? 'N/A';

    return _buildExpansionSection(
      'Product Searches',
      Icons.search_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total', '$total', AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Completed', '$completed', AppColors.success)),
              const SizedBox(width: 8),
              Expanded(child: _buildStatCard('Rate', rate, Colors.blue)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection() {
    final assignedCompanies = _insights!['assignedCompanies'] as List<dynamic>? ?? [];
    final assignedGroups = _insights!['assignedGroups'] as List<dynamic>? ?? [];
    if (assignedCompanies.isEmpty && assignedGroups.isEmpty) return const SizedBox.shrink();

    return _buildExpansionSection(
      'Assignments',
      Icons.assignment_outlined,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (assignedCompanies.isNotEmpty) ...[
            Text('Companies', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...assignedCompanies.map((c) {
              final name = c is Map ? (c['name']?.toString() ?? c.toString()) : c.toString();
              return _buildListTile(name);
            }),
          ],
          if (assignedGroups.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Groups', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            ...assignedGroups.map((g) {
              final name = g is Map ? (g['name']?.toString() ?? g.toString()) : g.toString();
              return _buildListTile(name);
            }),
          ],
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildExpansionSection(String title, IconData icon, Widget content) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        children: [content],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    if (text.isEmpty || text == '-') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    if (value.isEmpty || value == '-') return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textLight, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildListTile(String title, {String? subtitle, String? trailing, String? date}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              if (trailing != null && trailing.isNotEmpty)
                _buildBadge(trailing, AppColors.primary),
            ],
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
          if (date != null && date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(formatDate(date), style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          ],
        ],
      ),
    );
  }

  String _getInitials(String first, String last) {
    final f = first.isNotEmpty ? first[0].toUpperCase() : '';
    final l = last.isNotEmpty ? last[0].toUpperCase() : '';
    return '$f$l';
  }
}
