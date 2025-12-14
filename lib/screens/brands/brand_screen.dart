import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../models/brand_model.dart';
import '../../services/brand_service.dart';
import '../../widgets/generic/index.dart';

/// Brand list screen using generic widgets
class BrandScreen extends StatefulWidget {
  const BrandScreen({Key? key}) : super(key: key);

  @override
  State<BrandScreen> createState() => _BrandScreenState();
}

class _BrandScreenState extends State<BrandScreen> {
  @override
  Widget build(BuildContext context) {
    return GenericListScreen<BrandModel>(
      config: GenericListScreenConfig<BrandModel>(
        title: 'Brands',
        columns: _buildColumns(),
        blocBuilder: () => GenericListBloc<BrandModel>(
          service: GetIt.I<BrandService>(),
          sortComparator: _brandSortComparator,
          filterPredicate: _brandFilterPredicate,
        ),
        filterConfigs: [FilterConfig.statusFilter()],
        searchHint: 'Search brands...',
        emptyIcon: Icons.category_outlined,
        emptyMessage: 'No brands found',
        showCreateButton: false,
        showSerialNumber: true,
        showTotalCount: false,
        enableEdit: false,
        enableDelete: true,
      ),
    );
  }

  /// Define columns for brand table
  List<GenericColumnConfig<BrandModel>> _buildColumns() {
    return [
      // Brand Name
      GenericColumnConfig<BrandModel>(
        label: 'Name',
        fieldKey: 'name',
        sortable: true,
        customRenderer: (brand, index) {
          return Text(
            brand.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          );
        },
      ),

      // Status badge
      GenericColumnConfig.statusBadge<BrandModel>(
        getStatus: (brand) => brand.isActive ? 'Active' : 'Inactive',
        isActive: (brand) => brand.isActive,
      ),

      // Created By
      GenericColumnConfig<BrandModel>(
        label: 'Created By',
        fieldKey: 'createdBy',
        sortable: true,
      ),

      // Created Date
      GenericColumnConfig<BrandModel>(
        label: 'Created Date',
        fieldKey: 'createdAt',
        sortable: true,
      ),
    ];
  }

  /// Sort comparator for brands
  int _brandSortComparator(
    BrandModel a,
    BrandModel b,
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

  /// Filter predicate for brands
  bool _brandFilterPredicate(
    BrandModel brand,
    Map<String, dynamic> filters,
  ) {
    // Apply status filter
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !brand.isActive) return false;
      if (statusFilter == 'inactive' && brand.isActive) return false;
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
