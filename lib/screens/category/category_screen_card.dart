import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common_list_card.dart';
import '../../widgets/pagination_widget.dart';

/// Category list screen with card-based UI
class CategoryScreenCard extends StatefulWidget {
  const CategoryScreenCard({Key? key}) : super(key: key);

  @override
  State<CategoryScreenCard> createState() => _CategoryScreenCardState();
}

class _CategoryScreenCardState extends State<CategoryScreenCard> {
  late GenericListBloc<CategoryModel> _bloc;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: BlocProvider<GenericListBloc<CategoryModel>>(
        create: (_) => _bloc,
        child: Column(
          children: [
            // Search bar and filters
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search field
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search categories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _bloc.add(SearchData(''));
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (value) {
                      _bloc.add(SearchData(value));
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),

                  // Status filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(

                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.lightGrey),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.sort, size: 20, color: AppColors.grey),
                              const SizedBox(width: 8),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _currentSortBy,
                                  isDense: true,
                                  items: const [
                                    DropdownMenuItem(value: 'name', child: Text('Name')),
                                    DropdownMenuItem(value: 'description', child: Text('Description')),
                                    DropdownMenuItem(value: 'isActive', child: Text('Status')),
                                    DropdownMenuItem(value: 'createdBy', child: Text('Created By')),
                                    DropdownMenuItem(value: 'createdAt', child: Text('Created Date')),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _currentSortBy = value);
                                      _bloc.add(SortData(_currentSortBy, _currentSortOrder));
                                    }
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  _currentSortOrder == 'asc'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 20,
                                ),
                                color: AppColors.primary,
                                onPressed: () {
                                  setState(() {
                                    _currentSortOrder = _currentSortOrder == 'asc' ? 'desc' : 'asc';
                                  });
                                  _bloc.add(SortData(_currentSortBy, _currentSortOrder));
                                },
                                tooltip: _currentSortOrder == 'asc' ? 'Ascending' : 'Descending',
                              ),
                            ],
                          ),
                        ),
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', 'active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Inactive', 'inactive'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sorting UI

                ],
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
                          children: const [
                            Icon(Icons.category_outlined, size: 64, color: AppColors.grey),
                            SizedBox(height: 16),
                            Text('No categories found', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              _bloc.add(LoadData());
                              await Future.delayed(const Duration(milliseconds: 500));
                            },
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              itemCount: state.data.length,
                              itemBuilder: (context, index) {
                                final category = state.data[index];
                                return _buildCategoryCard(category);
                              },
                            ),
                          ),
                        ),
                        PaginationWidget(
                          currentPage: state.page,
                          totalPages: state.totalPages,
                          pageSize: state.take,
                          totalItems: state.total,
                          onPageChange: (page) => _bloc.add(ChangePage(page)),
                          onPageSizeChange: (size) => _bloc.add(ChangePageSize(size)),
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
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _bloc.add(ApplyFilters({'status': value == 'all' ? null : value}));
        });
      },
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.lightGrey,
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category) {
    return CommonListCard(
      title: category.name,
      statusBadge: StatusBadgeConfig.status(category.isActive ? 'Active' : 'Inactive'),
      cardHeaderBackgroundColor: AppColors.background,
      showActionsDivider: true,
      showColumnLabels: true,
      rows: [
        if (category.description.isNotEmpty)
          CardRowConfig(
            icon: Icons.description_outlined,
            text: category.description,
            label: 'Description',
            iconColor: AppColors.primary,
          ),
        CardRowConfig(
          icon: Icons.person_outline,
          text: category.createdBy,
          label: 'Created By',
          iconColor: AppColors.primary,
        ),
        CardRowConfig(
          icon: Icons.calendar_today_outlined,
          text: category.createdAt,
          label: 'Created Date',
          iconColor: AppColors.primary,
        ),
      ],
      onView: () {
        _showCategoryDetails(category);
      },
      onDelete: () {
        _confirmDelete(category);
      },
    );
  }

  void _showCategoryDetails(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Description', category.description.isEmpty ? '-' : category.description),
            _buildDetailRow('Status', category.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Created By', category.createdBy),
            _buildDetailRow('Created Date', category.createdAt),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
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

  /// Sort comparator for categories
  int _categorySortComparator(CategoryModel a, CategoryModel b, String sortBy, String sortOrder) {
    int comparison = 0;

    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'description':
        comparison = a.description.compareTo(b.description);
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

  /// Filter predicate for categories
  bool _categoryFilterPredicate(CategoryModel category, Map<String, dynamic> filters) {
    // Apply status filter
    if (filters.containsKey('status') && filters['status'] != null) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !category.isActive) return false;
      if (statusFilter == 'inactive' && category.isActive) return false;
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
