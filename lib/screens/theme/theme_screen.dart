import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/theme_model.dart';
import '../../services/theme_service.dart';
import '../../widgets/generic/index.dart';

/// Theme list screen using generic widgets
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  final Map<int, bool> _expandedRows = {};

  @override
  Widget build(BuildContext context) {
    return GenericListScreen<ThemeModel>(
      config: GenericListScreenConfig<ThemeModel>(
        title: 'Themes',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<ThemeModel>(
          service: GetIt.I<ThemeService>(),
          sortComparator: _themeSortComparator,
          filterPredicate: _themeFilterPredicate,
        ),
        filterConfigs: [FilterConfig.statusFilter()],
        searchHint: 'Search themes...',
        emptyIcon: Icons.palette_outlined,
        emptyMessage: 'No themes found',
        showCreateButton: false,
        showSerialNumber: true,
        showTotalCount: false,
        enableEdit: false,
        enableDelete: true,
      ),
    );
  }

  /// Define columns for theme table
  List<GenericColumnConfig<ThemeModel>> _buildColumns() {
    return [
      // Theme Name
      GenericColumnConfig<ThemeModel>(
        label: 'Name',
        fieldKey: 'name',
        sortable: true,
        customRenderer: (theme, index) {
          return Text(
            theme.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        },
      ),

      // Description (expandable)
      GenericColumnConfig<ThemeModel>(
        label: 'Description',
        fieldKey: 'description',
        sortable: false,
        customRenderer: (theme, index) {
          final isExpanded = _expandedRows[index] ?? false;
          final description = theme.description;

          if (description.isEmpty || description == 'NA' || description == '-') {
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
                  isExpanded || description.length <= 50
                      ? description
                      : '${description.substring(0, 50)}...',
                  style: const TextStyle(fontSize: 14),
                ),
                if (description.length > 50)
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

      // Status badge
      GenericColumnConfig.statusBadge<ThemeModel>(
        getStatus: (theme) => theme.isActive ? 'Active' : 'Inactive',
        isActive: (theme) => theme.isActive,
      ),

      // Created By
      GenericColumnConfig<ThemeModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      // Created Date
      GenericColumnConfig<ThemeModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  /// Sort comparator for themes
  int _themeSortComparator(
    ThemeModel a,
    ThemeModel b,
    String sortBy,
    String sortOrder,
  ) {
    int comparison = 0;

    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
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

  /// Filter predicate for themes
  bool _themeFilterPredicate(
    ThemeModel theme,
    Map<String, dynamic> filters,
  ) {
    // Apply status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !theme.isActive) return false;
      if (statusFilter == 'inactive' && theme.isActive) return false;
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
