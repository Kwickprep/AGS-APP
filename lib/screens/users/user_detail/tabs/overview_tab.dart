import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/user_insights_model.dart';
import '../../../../utils/date_formatter.dart';

class OverviewTab extends StatelessWidget {
  final UserInsightsResponse data;

  const OverviewTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final profile = data.profile;
    final stats = data.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + Name + Role
          _buildHeader(profile),
          const SizedBox(height: 20),

          // Stat cards
          _buildStatCards(stats),
          const SizedBox(height: 20),

          // Info fields
          _buildInfoSection(profile),

          // Notes
          if (profile.note.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildNotesSection(profile.note),
          ],

          // Metadata
          const SizedBox(height: 20),
          _buildMetadataSection(profile),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(UserProfile profile) {
    return Center(
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            backgroundImage: profile.profilePicture != null
                ? NetworkImage(profile.profilePicture!)
                : null,
            child: profile.profilePicture == null
                ? Text(
                    profile.initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            profile.fullName,
            style: AppTextStyles.heading2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          // Role badge
          _buildRoleBadge(profile.role),
          const SizedBox(height: 4),
          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: profile.isActive
                  ? AppColors.activeBackground
                  : AppColors.inactiveBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              profile.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: profile.isActive
                    ? AppColors.activeText
                    : AppColors.inactiveText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        bgColor = const Color(0xFFEDE9FE);
        textColor = const Color(0xFF6366F1);
        break;
      case 'EMPLOYEE':
        bgColor = const Color(0xFFDCFCE7);
        textColor = const Color(0xFF22C55E);
        break;
      case 'CUSTOMER':
        bgColor = const Color(0xFFDBEAFE);
        textColor = const Color(0xFF3B82F6);
        break;
      default:
        bgColor = AppColors.background;
        textColor = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatCards(UserStats stats) {
    final items = [
      _StatItem('Inquiries', stats.totalInquiries, Icons.receipt_long_outlined, const Color(0xFF6366F1)),
      _StatItem('Activities', stats.totalActivities, Icons.trending_up, const Color(0xFF22C55E)),
      _StatItem('Messages', stats.totalMessages, Icons.chat_outlined, const Color(0xFFF59E0B)),
      _StatItem('Companies', stats.assignedCompanies, Icons.business_outlined, const Color(0xFF3B82F6)),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.all(10),
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
      }).toList(),
    );
  }

  Widget _buildInfoSection(UserProfile profile) {
    final fields = <MapEntry<String, String>>[
      if (profile.designation.isNotEmpty) MapEntry('Designation', profile.designation),
      if (profile.department.isNotEmpty) MapEntry('Department', profile.department),
      if (profile.division.isNotEmpty) MapEntry('Division', profile.division),
      if (profile.email.isNotEmpty) MapEntry('Email', profile.email),
      if (profile.phone.isNotEmpty) MapEntry('Phone', profile.phone),
      if (profile.company.isNotEmpty) MapEntry('Company', profile.company),
      if (profile.employeeCode.isNotEmpty) MapEntry('Employee Code', profile.employeeCode),
    ];

    if (fields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Information', style: AppTextStyles.heading3),
        const SizedBox(height: 12),
        ...fields.map((f) => _buildInfoField(f.key, f.value)),
      ],
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String note) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: AppTextStyles.heading3),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9C4).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFF176).withValues(alpha: 0.6)),
          ),
          child: Text(note, style: AppTextStyles.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(UserProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.creator.isNotEmpty) ...[
            _metaRow('Created by', profile.creator),
            const SizedBox(height: 6),
          ],
          if (profile.createdAt != null) ...[
            _metaRow('Created at', formatDate(profile.createdAt)),
            const SizedBox(height: 6),
          ],
          if (profile.updatedAt != null)
            _metaRow('Updated at', formatDate(profile.updatedAt)),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}
