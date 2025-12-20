import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';

/// Category list screen with full features: filter, sort, pagination, and details
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late GenericListBloc<CategoryModel> _bloc;
  final TextEditingController _searchController = TextEditingController();

  // Filter and sort state
  FilterModel _filterModel = FilterModel();
  SortModel _sortModel = SortModel(sortBy: 'name', sortOrder: 'asc');

  // Pagination state
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _bloc = GenericListBloc<CategoryModel>(
      service: GetIt.I<CategoryService>(),
      sortComparator: _categorySortComparator,
      filterPredicate: _categoryFilterPredicate,
    );
    _bloc.add(LoadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<CategoryModel> _getPaginatedData(List<CategoryModel> allData) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= allData.length) {
      return [];
    }

    return allData.sublist(
      startIndex,
      endIndex > allData.length ? allData.length : endIndex,
    );
  }

  int _getTotalPages(int totalItems) {
    return (totalItems / _itemsPerPage).ceil();
  }

  void _showFilterSheet() {
    // Get unique creators from loaded data
    List<String> creators = [];
    final state = _bloc.state;
    if (state is GenericListLoaded<CategoryModel>) {
      creators = state.data.map((b) => b.createdBy).toSet().toList();
    }

    FilterBottomSheet.show(
      context: context,
      initialFilter: _filterModel,
      creatorOptions: creators,
      statusOptions: const ['Active', 'Inactive'],
      onApplyFilters: (filter) {
        setState(() {
          _filterModel = filter;
          _currentPage = 1; // Reset to first page
        });
        _applyFiltersAndSort();
      },
    );
  }

  void _showSortSheet() {
    SortBottomSheet.show(
      context: context,
      initialSort: _sortModel,
      sortOptions: const [
        SortOption(field: 'name', label: 'Name'),
        SortOption(field: 'isActive', label: 'Status'),
        SortOption(field: 'createdAt', label: 'Created Date'),
        SortOption(field: 'createdBy', label: 'Created By'),
      ],
      onApplySort: (sort) {
        setState(() {
          _sortModel = sort;
          _currentPage = 1; // Reset to first page
        });
        _applyFiltersAndSort();
      },
    );
  }

  void _applyFiltersAndSort() {
    Map<String, dynamic> filters = {};

    if (_filterModel.selectedStatuses.isNotEmpty) {
      if (_filterModel.selectedStatuses.contains('Active') &&
          !_filterModel.selectedStatuses.contains('Inactive')) {
        filters['status'] = 'active';
      } else if (_filterModel.selectedStatuses.contains('Inactive') &&
                 !_filterModel.selectedStatuses.contains('Active')) {
        filters['status'] = 'inactive';
      }
    }

    if (_filterModel.createdBy != null) {
      filters['createdBy'] = _filterModel.createdBy;
    }

    _bloc.add(ApplyFilters(filters));
    _bloc.add(SortData(_sortModel.sortBy, _sortModel.sortOrder));
  }

  void _showCategoryDetails(CategoryModel category) {
    DetailsBottomSheet.show(
      context: context,
      title: category.name,
      isActive: category.isActive,
      fields: [
        DetailField(label: 'Category Name', value: category.name),
        DetailField(label: 'Status', value: category.isActive ? 'Active' : 'Inactive'),
        DetailField(label: 'Created By', value: category.createdBy),
        DetailField(label: 'Created Date', value: category.createdAt),
      ],
      onEdit: () {
        // TODO: Navigate to edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
      },
      onDelete: () => _confirmDelete(category),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        scrolledUnderElevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Categorys',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.iconPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocProvider<GenericListBloc<CategoryModel>>(
        create: (_) => _bloc,
        child: SafeArea(
          child: Column(
            children: [
              // Search bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search categorys...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _bloc.add(SearchData(''));
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  onChanged: (value) {
                    _bloc.add(SearchData(value));
                    setState(() {
                      _currentPage = 1; // Reset to first page on search
                    });
                  },
                ),
              ),

              // Filter and Sort bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FilterSortBar(
                  onFilterTap: _showFilterSheet,
                  onSortTap: _showSortSheet,
                ),
              ),

              // Card list
              Expanded(
                child: BlocBuilder<GenericListBloc<CategoryModel>, GenericListState>(
                  builder: (context, state) {
                    if (state is GenericListLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is GenericListError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(state.message, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _bloc.add(LoadData()),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is GenericListLoaded<CategoryModel>) {
                      if (state.data.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.category_outlined, size: 64, color: AppColors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No categorys found',
                                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
                              ),
                            ],
                          ),
                        );
                      }

                      final paginatedData = _getPaginatedData(state.data);
                      final totalPages = _getTotalPages(state.data.length);

                      return Column(
                        children: [
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                _bloc.add(LoadData());
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: paginatedData.length,
                                itemBuilder: (context, index) {
                                  final category = paginatedData[index];
                                  final serialNumber = (_currentPage - 1) * _itemsPerPage + index + 1;
                                  return _buildCategoryCard(category, serialNumber);
                                },
                              ),
                            ),
                          ),

                          // Pagination controls
                          if (totalPages > 1)
                            PaginationControls(
                              currentPage: _currentPage,
                              totalPages: totalPages,
                              totalItems: state.data.length,
                              itemsPerPage: _itemsPerPage,
                              onFirst: () {
                                setState(() {
                                  _currentPage = 1;
                                });
                              },
                              onPrevious: () {
                                setState(() {
                                  _currentPage--;
                                });
                              },
                              onNext: () {
                                setState(() {
                                  _currentPage++;
                                });
                              },
                              onLast: () {
                                setState(() {
                                  _currentPage = totalPages;
                                });
                              },
                            ),
                        ],
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      isActive: category.isActive,
      fields: [
        CardField.title(
          label: 'Category Name',
          value: category.name,
        ),
        CardField.regular(
          label: 'Created By',
          value: category.createdBy,
        ),
        CardField.regular(
          label: 'Created Date',
          value: category.createdAt,
        ),
      ],
      onView: () => _showCategoryDetails(category),
      onDelete: () => _confirmDelete(category),
      onTap: () => _showCategoryDetails(category),
    );
  }

  void _confirmDelete(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteData(category.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Category deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Sort comparator for categorys
  int _categorySortComparator(CategoryModel a, CategoryModel b, String sortBy, String sortOrder) {
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

  /// Filter predicate for categorys
  bool _categoryFilterPredicate(CategoryModel category, Map<String, dynamic> filters) {
    if (filters.containsKey('status') && filters['status'] != null) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !category.isActive) return false;
      if (statusFilter == 'inactive' && category.isActive) return false;
    }

    if (filters.containsKey('createdBy') && filters['createdBy'] != null) {
      if (category.createdBy != filters['createdBy']) return false;
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
