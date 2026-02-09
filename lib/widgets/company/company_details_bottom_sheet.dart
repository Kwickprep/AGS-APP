import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/company_model.dart';
import '../../services/company_service.dart';
import '../../utils/date_formatter.dart';

class CompanyDetailsBottomSheet extends StatefulWidget {
  final CompanyModel company;

  const CompanyDetailsBottomSheet({super.key, required this.company});

  static void show({
    required BuildContext context,
    required CompanyModel company,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanyDetailsBottomSheet(company: company),
    );
  }

  @override
  State<CompanyDetailsBottomSheet> createState() => _CompanyDetailsBottomSheetState();
}

class _CompanyDetailsBottomSheetState extends State<CompanyDetailsBottomSheet> {
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
      final data = await CompanyService().getCompanyInsights(widget.company.id);
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
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Company Details',
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
                          _buildContactsSection(),
                          _buildAssignedEmployeesSection(),
                          _buildInquiriesSection(),
                          _buildActivitiesSection(),
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
            child: Text('Could not load insights data',
                style: TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final company = widget.company;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company icon and name
        Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                company.name.isNotEmpty ? company.name[0].toUpperCase() : 'C',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  _buildBadge(
                    company.isActive == 'Active' ? 'Active' : 'Inactive',
                    company.isActive == 'Active' ? AppColors.success : AppColors.error,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (company.email.isNotEmpty && company.email != '-')
          _buildDetailRow('Email', company.email),
        if (company.website.isNotEmpty && company.website != '-')
          _buildDetailRow('Website', company.website),
        if (company.industry.isNotEmpty && company.industry != '-')
          _buildDetailRow('Industry', company.industry),
        if (company.employees.isNotEmpty && company.employees != '-')
          _buildDetailRow('Employees', company.employees),
        if (company.turnover.isNotEmpty && company.turnover != '-')
          _buildDetailRow('Turnover', company.turnover),
        if (company.gstNumber.isNotEmpty && company.gstNumber != '-')
          _buildDetailRow('GST Number', company.gstNumber),
        if (company.country.isNotEmpty && company.country != '-')
          _buildDetailRow('Country', company.country),
        if (company.state.isNotEmpty && company.state != '-')
          _buildDetailRow('State', company.state),
        if (company.city.isNotEmpty && company.city != '-')
          _buildDetailRow('City', company.city),
        _buildDetailRow('Created By', company.createdBy),
        _buildDetailRow('Created Date', formatDate(company.createdAt)),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = _insights!['stats'] as Map<String, dynamic>? ?? {};
    final contacts = stats['contacts'] ?? 0;
    final inquiries = stats['inquiries'] ?? 0;
    final activities = stats['activities'] ?? 0;
    final messages = stats['messages'] ?? 0;
    final employees = stats['employees'] ?? 0;
    final productSearches = stats['productSearches'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _buildSectionHeader('Statistics'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Contacts', '$contacts', AppColors.primary)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Inquiries', '$inquiries', Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Activities', '$activities', Colors.orange)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard('Messages', '$messages', Colors.purple)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Employees', '$employees', AppColors.success)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard('Searches', '$productSearches', Colors.teal)),
          ],
        ),
        if (_insights!['notes'] != null && _insights!['notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildDetailRow('Notes', _insights!['notes'].toString()),
        ],
      ],
    );
  }

  Widget _buildContactsSection() {
    final contacts = _insights!['contacts'] as List<dynamic>? ?? [];
    if (contacts.isEmpty) return const SizedBox.shrink();

    return _buildExpansionSection(
      'Contacts',
      Icons.contacts_outlined,
      Column(
        children: contacts.map((c) {
          final map = c as Map<String, dynamic>;
          final name = map['name']?.toString() ?? map['fullName']?.toString() ?? 'N/A';
          final role = map['role']?.toString();
          final phone = map['phone']?.toString();
          final email = map['email']?.toString();
          return _buildContactTile(name, role: role, phone: phone, email: email);
        }).toList(),
      ),
    );
  }

  Widget _buildAssignedEmployeesSection() {
    final employees = _insights!['assignedEmployees'] as List<dynamic>? ?? [];
    if (employees.isEmpty) return const SizedBox.shrink();

    return _buildExpansionSection(
      'Assigned Employees',
      Icons.people_outlined,
      Column(
        children: employees.map((e) {
          final map = e as Map<String, dynamic>;
          final name = map['name']?.toString() ?? map['fullName']?.toString() ?? 'N/A';
          final designation = map['designation']?.toString();
          final phone = map['phone']?.toString();
          return _buildContactTile(name, role: designation, phone: phone);
        }).toList(),
      ),
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
            subtitle: map['inquiry']?.toString(),
            date: map['createdAt']?.toString(),
          );
        }).toList(),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
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

  Widget _buildContactTile(String name, {String? role, String? phone, String? email}) {
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
          Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          if (role != null && role.isNotEmpty && role != '-') ...[
            const SizedBox(height: 2),
            Text(role, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (phone != null && phone.isNotEmpty && phone != '-') ...[
            const SizedBox(height: 2),
            Text(phone, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
          if (email != null && email.isNotEmpty && email != '-') ...[
            const SizedBox(height: 2),
            Text(email, style: const TextStyle(fontSize: 12, color: AppColors.textLight)),
          ],
        ],
      ),
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
}
