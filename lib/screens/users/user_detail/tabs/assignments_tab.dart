import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/user_insights_model.dart';

class AssignmentsTab extends StatefulWidget {
  final UserAssignments assignments;

  const AssignmentsTab({super.key, required this.assignments});

  @override
  State<AssignmentsTab> createState() => _AssignmentsTabState();
}

class _AssignmentsTabState extends State<AssignmentsTab> {
  String _companySearch = '';
  String _customerSearch = '';
  String _groupSearch = '';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSection(
            title: 'Companies',
            icon: Icons.business_outlined,
            color: const Color(0xFF6366F1),
            items: widget.assignments.companies,
            search: _companySearch,
            onSearchChanged: (v) => setState(() => _companySearch = v),
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Customers',
            icon: Icons.group_outlined,
            color: const Color(0xFF3B82F6),
            items: widget.assignments.customers,
            search: _customerSearch,
            onSearchChanged: (v) => setState(() => _customerSearch = v),
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: 'Groups',
            icon: Icons.workspaces_outlined,
            color: const Color(0xFF22C55E),
            items: widget.assignments.groups,
            search: _groupSearch,
            onSearchChanged: (v) => setState(() => _groupSearch = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<InsightNameCount> items,
    required String search,
    required ValueChanged<String> onSearchChanged,
  }) {
    final filtered = search.isEmpty
        ? items
        : items.where((i) => i.name.toLowerCase().contains(search.toLowerCase())).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.heading3),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          _buildEmptySection(title)
        else ...[
          // Search field
          if (items.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search $title...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
                style: AppTextStyles.bodyMedium,
              ),
            ),
          // List
          Container(
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
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'No matches found',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: color.withValues(alpha: 0.1),
                          child: Text(
                            item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        title: Text(
                          item.name,
                          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptySection(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
        children: [
          Icon(Icons.inbox_outlined, size: 36, color: AppColors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            'No ${title.toLowerCase()} assigned',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
