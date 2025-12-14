import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/tag_model.dart';
import '../../services/tag_service.dart';
import '../../widgets/generic/index.dart';

/// Tag list screen using generic widgets
class TagScreen extends StatefulWidget {
  const TagScreen({Key? key}) : super(key: key);

  @override
  State<TagScreen> createState() => _TagScreenState();
}

class _TagScreenState extends State<TagScreen> {
  @override
  Widget build(BuildContext context) {
    return GenericListScreen<TagModel>(
      config: GenericListScreenConfig<TagModel>(
        title: 'Tags',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<TagModel>(
          service: GetIt.I<TagService>(),
          sortComparator: _tagSortComparator,
          filterPredicate: _tagFilterPredicate,
        ),
        filterConfigs: [FilterConfig.statusFilter()],
        searchHint: 'Search tags...',
        emptyIcon: Icons.label_outlined,
        emptyMessage: 'No tags found',
        showCreateButton: false,
        showSerialNumber: true,
        showTotalCount: false,
        enableEdit: false,
        enableDelete: true,
      ),
    );
  }

  /// Define columns for tag table
  List<GenericColumnConfig<TagModel>> _buildColumns() {
    return [
      // Tag Name
      GenericColumnConfig<TagModel>(
        label: 'Name',
        fieldKey: 'name',
        sortable: true,
        customRenderer: (tag, index) {
          return Text(
            tag.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        },
      ),

      // Status badge
      GenericColumnConfig.statusBadge<TagModel>(
        getStatus: (tag) => tag.isActive ? 'Active' : 'Inactive',
        isActive: (tag) => tag.isActive,
      ),

      // Created By
      GenericColumnConfig<TagModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      // Created Date
      GenericColumnConfig<TagModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  /// Sort comparator for tags
  int _tagSortComparator(
    TagModel a,
    TagModel b,
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

  /// Filter predicate for tags
  bool _tagFilterPredicate(
    TagModel tag,
    Map<String, dynamic> filters,
  ) {
    // Apply status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !tag.isActive) return false;
      if (statusFilter == 'inactive' && tag.isActive) return false;
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
