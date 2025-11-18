import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';
import '../../widgets/generic/index.dart';

/// Inquiry list screen using generic widgets
class InquiryScreen extends StatefulWidget {
  const InquiryScreen({Key? key}) : super(key: key);

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final Map<int, bool> _expandedRows = {};

  @override
  Widget build(BuildContext context) {
    return GenericListScreen<InquiryModel>(
      config: GenericListScreenConfig<InquiryModel>(
        title: 'Inquiries',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<InquiryModel>(
          service: GetIt.I<InquiryService>(),
          sortComparator: _inquirySortComparator,
        ),
        filterConfigs: [],
        searchHint: 'Search inquiries...',
        emptyIcon: Icons.assignment_outlined,
        emptyMessage: 'No inquiries found',
        showCreateButton: true,
        showSerialNumber: true,
        showTotalCount: false,
        enableEdit: false,
        enableDelete: false,
      ),
    );
  }

  /// Define columns for inquiry table
  List<GenericColumnConfig<InquiryModel>> _buildColumns() {
    return [
      // Inquiry Name
      GenericColumnConfig<InquiryModel>(
        label: 'Inquiry Name',
        fieldKey: 'name',
        sortable: true,
        customRenderer: (inquiry, index) {
          return Text(
            inquiry.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        },
      ),

      // Company
      GenericColumnConfig<InquiryModel>(
        label: 'Company',
        fieldKey: 'company',
        sortable: true,
        customRenderer: (inquiry, index) {
          return Text(
            inquiry.company,
            style: const TextStyle(fontSize: 14),
          );
        },
      ),

      // Contact User
      GenericColumnConfig<InquiryModel>(
        label: 'Contact User',
        fieldKey: 'contactUser',
        sortable: true,
        customRenderer: (inquiry, index) {
          return Text(
            inquiry.contactUser,
            style: const TextStyle(fontSize: 14),
          );
        },
      ),

      // Status
      GenericColumnConfig<InquiryModel>(
        label: 'Status',
        fieldKey: 'status',
        sortable: true,
        customRenderer: (inquiry, index) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(inquiry.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(inquiry.status),
                width: 1,
              ),
            ),
            child: Text(
              inquiry.status,
              style: TextStyle(
                color: _getStatusColor(inquiry.status),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),

      // Note (expandable)
      GenericColumnConfig<InquiryModel>(
        label: 'Note',
        fieldKey: 'note',
        sortable: false,
        customRenderer: (inquiry, index) {
          final isExpanded = _expandedRows[index] ?? false;
          final note = inquiry.note;

          if (note.isEmpty || note == 'NA' || note == '-') {
            return const Text(
              '-',
              style: TextStyle(color: AppColors.grey),
            );
          }

          return GestureDetector(
            onTap: () {
              setState(() {
                _expandedRows[index] = !isExpanded;
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpanded || note.length <= 50
                      ? note
                      : '${note.substring(0, 50)}...',
                  style: const TextStyle(fontSize: 14),
                ),
                if (note.length > 50)
                  Text(
                    isExpanded ? 'Show less' : 'Show more',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          );
        },
      ),

      // Created By
      GenericColumnConfig<InquiryModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      // Created Date
      GenericColumnConfig<InquiryModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  /// Get status color based on status value
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF2196F3); // Blue
      case 'closed':
        return const Color(0xFF4CAF50); // Green
      case 'pending':
        return const Color(0xFFFFA726); // Orange
      case 'cancelled':
        return const Color(0xFFF44336); // Red
      default:
        return AppColors.grey;
    }
  }

  /// Sort comparator for inquiries
  int _inquirySortComparator(
    InquiryModel a,
    InquiryModel b,
    String sortBy,
    String sortOrder,
  ) {
    int comparison = 0;

    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'company':
        comparison = a.company.compareTo(b.company);
        break;
      case 'contactUser':
        comparison = a.contactUser.compareTo(b.contactUser);
        break;
      case 'status':
        comparison = a.status.compareTo(b.status);
        break;
      case 'createdAt':
        comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
        break;
      case 'createdBy':
        comparison = a.createdBy.compareTo(b.createdBy);
        break;
      default:
        comparison = 0;
    }

    return sortOrder == 'asc' ? comparison : -comparison;
  }

  /// Parse date string in format "DD-MM-YYYY"
  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      // Return current date if parsing fails
    }
    return DateTime.now();
  }
}
