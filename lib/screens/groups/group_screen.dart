import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../widgets/generic/index.dart';

/// Group list screen using generic widgets
class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final Map<int, bool> _expandedRows = {};

  @override
  Widget build(BuildContext context) {
    return GenericListScreen<GroupModel>(
      config: GenericListScreenConfig<GroupModel>(
        title: 'Groups',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<GroupModel>(
          service: GetIt.I<GroupService>(),
          sortComparator: _groupSortComparator,
          filterPredicate: _groupFilterPredicate,
        ),
        filterConfigs: [FilterConfig.statusFilter()],
        searchHint: 'Search groups...',
        emptyIcon: Icons.group_outlined,
        emptyMessage: 'No groups found',
        showCreateButton: true,
        createRoute: AppRoutes.createGroup,
        showSerialNumber: true,
        showTotalCount: false,
        enableEdit: false,
        enableDelete: false,
      ),
    );
  }

  /// Define columns for group table
  List<GenericColumnConfig<GroupModel>> _buildColumns() {
    return [
      // Group Name
      GenericColumnConfig<GroupModel>(
        label: 'Name',
        fieldKey: 'name',
        sortable: true,
        customRenderer: (group, index) {
          return Center(
            child: Text(
              group.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          );
        },
      ),

      // Contacts/Users
      GenericColumnConfig<GroupModel>(
        label: 'Contacts',
        fieldKey: 'users',
        sortable: true,
        customRenderer: (group, index) {
          final users = group.users;
          if (users.isEmpty || users == '-') {
            return const Center(
              child: Text(
                'No contacts',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 14,
                ),
              ),
            );
          }

          return Center(
            child: Text(
              users,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          );
        },
      ),

      // Note (expandable)
      GenericColumnConfig<GroupModel>(
        label: 'Note',
        fieldKey: 'note',
        sortable: false,
        customRenderer: (group, index) {
          final isExpanded = _expandedRows[index] ?? false;
          final note = group.note;

          if (note.isEmpty || note == 'NA' || note == '-') {
            return const Center(
              child: Text(
                '-',
                style: TextStyle(color: AppColors.grey),
              ),
            );
          }

          return Center(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _expandedRows[index] = !isExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isExpanded || note.length <= 50
                        ? note
                        : '${note.substring(0, 50)}...',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
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
            ),
          );
        },
      ),

      // Status badge
      GenericColumnConfig.statusBadge<GroupModel>(
        getStatus: (group) => group.isActive ? 'Active' : 'Inactive',
        isActive: (group) => group.isActive,
      ),

      // Created By
      GenericColumnConfig<GroupModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      // Created Date
      GenericColumnConfig<GroupModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  /// Sort comparator for groups
  int _groupSortComparator(
    GroupModel a,
    GroupModel b,
    String sortBy,
    String sortOrder,
  ) {
    int comparison = 0;

    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'users':
        comparison = a.users.compareTo(b.users);
        break;
      case 'isActive':
        comparison = a.isActive == b.isActive ? 0 : (a.isActive ? 1 : -1);
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

  /// Filter predicate for groups
  bool _groupFilterPredicate(
    GroupModel group,
    Map<String, dynamic> filters,
  ) {
    // Apply status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !group.isActive) return false;
      if (statusFilter == 'inactive' && group.isActive) return false;
    }

    return true;
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
