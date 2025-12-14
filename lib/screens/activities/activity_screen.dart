import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';
import '../../widgets/generic/index.dart';

/// Activity list screen using generic widgets
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final Map<int, bool> _expandedRows = {};

  @override
  Widget build(BuildContext context) {
    return GenericListScreen<ActivityModel>(
      config: GenericListScreenConfig<ActivityModel>(
        title: 'Activities',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<ActivityModel>(
          service: GetIt.I<ActivityService>(),
          sortComparator: _activitySortComparator,
        ),
        filterConfigs: [],
        searchHint: 'Search activities...',
        emptyIcon: Icons.local_activity_outlined,
        emptyMessage: 'No activities found',
        showCreateButton: true,
        createRoute: AppRoutes.createActivity,
        showSerialNumber: true,
        showTotalCount: false,
        enableEdit: false,
        enableDelete: true,
      ),
    );
  }

  /// Define columns for activity table
  List<GenericColumnConfig<ActivityModel>> _buildColumns() {
    return [
      // Activity Type
      GenericColumnConfig<ActivityModel>(
        label: 'Activity Type',
        fieldKey: 'activityType',
        sortable: true,
        customRenderer: (activity, index) {
          return Text(
            activity.activityType,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        },
      ),

      // Company
      GenericColumnConfig<ActivityModel>(
        label: 'Company',
        fieldKey: 'company',
        sortable: true,
        customRenderer: (activity, index) {
          return Text(
            activity.company.isEmpty ? '-' : activity.company,
            style: const TextStyle(fontSize: 14),
          );
        },
      ),

      // Inquiry
      GenericColumnConfig<ActivityModel>(
        label: 'Inquiry',
        fieldKey: 'inquiry',
        sortable: true,
        customRenderer: (activity, index) {
          return Text(
            activity.inquiry.isEmpty ? '-' : activity.inquiry,
            style: const TextStyle(fontSize: 14),
          );
        },
      ),

      // User
      GenericColumnConfig<ActivityModel>(
        label: 'User',
        fieldKey: 'user',
        sortable: true,
        customRenderer: (activity, index) {
          return Text(
            activity.user.isEmpty ? '-' : activity.user,
            style: const TextStyle(fontSize: 14),
          );
        },
      ),

      // Theme
      GenericColumnConfig<ActivityModel>(
        label: 'Theme',
        fieldKey: 'theme',
        sortable: true,
        customRenderer: (activity, index) {
          return Text(
            activity.theme.isEmpty ? '-' : activity.theme,
            style: const TextStyle(fontSize: 14),
          );
        },
      ),

      // Next Schedule Date
      GenericColumnConfig<ActivityModel>(
        label: 'Next Schedule',
        fieldKey: 'nextScheduleDate',
        sortable: true,
        customRenderer: (activity, index) {
          return Text(
            activity.nextScheduleDate.isEmpty ? '-' : activity.nextScheduleDate,
            style: const TextStyle(fontSize: 14),
          );
        },
      ),

      // Note (expandable)
      GenericColumnConfig<ActivityModel>(
        label: 'Note',
        fieldKey: 'note',
        sortable: false,
        customRenderer: (activity, index) {
          final isExpanded = _expandedRows[index] ?? false;
          final note = activity.note;

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
      GenericColumnConfig<ActivityModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      // Created Date
      GenericColumnConfig<ActivityModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  /// Sort comparator for activities
  int _activitySortComparator(
    ActivityModel a,
    ActivityModel b,
    String sortBy,
    String sortOrder,
  ) {
    int comparison = 0;

    switch (sortBy) {
      case 'activityType':
        comparison = a.activityType.compareTo(b.activityType);
        break;
      case 'company':
        comparison = a.company.compareTo(b.company);
        break;
      case 'inquiry':
        comparison = a.inquiry.compareTo(b.inquiry);
        break;
      case 'user':
        comparison = a.user.compareTo(b.user);
        break;
      case 'theme':
        comparison = a.theme.compareTo(b.theme);
        break;
      case 'nextScheduleDate':
        comparison = _parseDate(a.nextScheduleDate).compareTo(_parseDate(b.nextScheduleDate));
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
