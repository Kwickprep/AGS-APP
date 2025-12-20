import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/theme_model.dart';
import '../../services/theme_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';

/// Theme list screen with full features: filter, sort, pagination, and details
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late GenericListBloc<ThemeModel> _bloc;
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
    _bloc = GenericListBloc<ThemeModel>(
      service: GetIt.I<ThemeService>(),
      sortComparator: _themeSortComparator,
      filterPredicate: _themeFilterPredicate,
    );
    _bloc.add(LoadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<ThemeModel> _getPaginatedData(List<ThemeModel> allData) {
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
    List<String> creators = [];
    final state = _bloc.state;
    if (state is GenericListLoaded<ThemeModel>) {
      creators = state.data.map((t) => t.createdBy).toSet().toList();
    }

    FilterBottomSheet.show(
      context: context,
      initialFilter: _filterModel,
      creatorOptions: creators,
      statusOptions: const ['Active', 'Inactive'],
      onApplyFilters: (filter) {
        setState(() {
          _filterModel = filter;
          _currentPage = 1;
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
          _currentPage = 1;
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

  void _showThemeDetails(ThemeModel theme) {
    final fields = <DetailField>[
      DetailField(label: 'Theme Name', value: theme.name),
    ];

    if (theme.description.isNotEmpty && theme.description != 'NA' && theme.description != '-') {
      fields.add(DetailField(label: 'Description', value: theme.description));
    }

    fields.addAll([
      DetailField(label: 'Status', value: theme.isActive ? 'Active' : 'Inactive'),
      DetailField(label: 'Created By', value: theme.createdBy),
      DetailField(label: 'Created Date', value: theme.createdAt),
    ]);

    DetailsBottomSheet.show(
      context: context,
      title: theme.name,
      isActive: theme.isActive,
      fields: fields,
      onEdit: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
      },
      onDelete: () => _confirmDelete(theme),
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
          'Themes',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.iconPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocProvider<GenericListBloc<ThemeModel>>(
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
                    hintText: 'Search themes...',
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
                      _currentPage = 1;
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
                child: BlocBuilder<GenericListBloc<ThemeModel>, GenericListState>(
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
                    } else if (state is GenericListLoaded<ThemeModel>) {
                      if (state.data.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.palette_outlined, size: 64, color: AppColors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No themes found',
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
                                  final theme = paginatedData[index];
                                  final serialNumber = (_currentPage - 1) * _itemsPerPage + index + 1;
                                  return _buildThemeCard(theme, serialNumber);
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

  Widget _buildThemeCard(ThemeModel theme, int serialNumber) {
    final fields = <CardField>[
      CardField.title(
        label: 'Theme Name',
        value: theme.name,
      ),
    ];

    if (theme.description.isNotEmpty && theme.description != 'NA' && theme.description != '-') {
      fields.add(CardField.description(
        label: 'Description',
        value: theme.description,
        maxLines: 2,
      ));
    }

    fields.addAll([
      CardField.regular(
        label: 'Created By',
        value: theme.createdBy,
      ),
      CardField.regular(
        label: 'Created Date',
        value: theme.createdAt,
      ),
    ]);

    return RecordCard(
      serialNumber: serialNumber,
      isActive: theme.isActive,
      fields: fields,
      onView: () => _showThemeDetails(theme),
      onDelete: () => _confirmDelete(theme),
      onTap: () => _showThemeDetails(theme),
    );
  }

  void _confirmDelete(ThemeModel theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteData(theme.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Sort comparator for themes
  int _themeSortComparator(ThemeModel a, ThemeModel b, String sortBy, String sortOrder) {
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
  bool _themeFilterPredicate(ThemeModel theme, Map<String, dynamic> filters) {
    if (filters.containsKey('status') && filters['status'] != null) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !theme.isActive) return false;
      if (statusFilter == 'inactive' && theme.isActive) return false;
    }

    if (filters.containsKey('createdBy') && filters['createdBy'] != null) {
      if (theme.createdBy != filters['createdBy']) return false;
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
