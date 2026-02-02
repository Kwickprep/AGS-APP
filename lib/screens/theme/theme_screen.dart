import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/permissions/permission_checker.dart';
import '../../models/theme_model.dart';
import '../category/category_bloc.dart';
import './theme_bloc.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';
import '../../widgets/permission_widget.dart';
import '../../utils/date_formatter.dart';

/// Theme list screen with full features: filter, sort, pagination, and details
class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late ThemeBloc _bloc;
  final TextEditingController _searchController = TextEditingController();

  // Current state parameters
  int _currentPage = 1;
  final int _itemsPerPage = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';
  Map<String, dynamic> _currentFilters = {};

  @override
  void initState() {
    super.initState();
    _bloc = ThemeBloc();
    _loadThemes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadThemes() {
    _bloc.add(
      LoadThemes(
        page: _currentPage,
        take: _itemsPerPage,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ),
    );
  }

  void _showFilterSheet() {
    List<String> selectedStatuses = [];
    if (_currentFilters['isActive'] == true) {
      selectedStatuses.add('Active');
    } else if (_currentFilters['isActive'] == false) {
      selectedStatuses.add('Inactive');
    }

    FilterBottomSheet.show(
      context: context,
      initialFilter: FilterModel(selectedStatuses: selectedStatuses.toSet(), createdBy: _currentFilters['createdBy']),
      creatorOptions: const [],
      statusOptions: const ['Active', 'Inactive'],
      onApplyFilters: (filter) {
        setState(() {
          _currentFilters = {};
          if (filter.selectedStatuses.isNotEmpty) {
            if (filter.selectedStatuses.contains('Active') && !filter.selectedStatuses.contains('Inactive')) {
              _currentFilters['isActive'] = true;
            } else if (filter.selectedStatuses.contains('Inactive') && !filter.selectedStatuses.contains('Active')) {
              _currentFilters['isActive'] = false;
            }
          }
          if (filter.createdBy != null) {
            _currentFilters['createdBy'] = filter.createdBy;
          }
          _currentPage = 1;
        });
        _loadThemes();
      },
    );
  }

  void _showSortSheet() {
    SortBottomSheet.show(
      context: context,
      initialSort: SortModel(sortBy: _currentSortBy, sortOrder: _currentSortOrder),
      sortOptions: const [
        SortOption(field: 'name', label: 'Name'),
        SortOption(field: 'isActive', label: 'Status'),
        SortOption(field: 'createdAt', label: 'Created Date'),
        SortOption(field: 'createdBy', label: 'Created By'),
      ],
      onApplySort: (sort) {
        setState(() {
          _currentSortBy = sort.sortBy;
          _currentSortOrder = sort.sortOrder;
          _currentPage =  1;
        });
        _loadThemes();
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearch = value;
      _currentPage = 1;
    });
    _loadThemes();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadThemes();
  }

  void _showThemeDetails(ThemeModel theme) {
    DetailsBottomSheet.show(
      context: context,
      title: theme.name,
      isActive: theme.isActive,
      fields: [
        DetailField(label: 'Theme Name', value: theme.name),
        DetailField(label: 'Status', value: theme.isActive ? 'Active' : 'Inactive'),
        DetailField(label: 'Description', value: theme.description.isNotEmpty ? theme.description : 'N/A'),
        DetailField(label: 'Created By', value: theme.createdBy),
        DetailField(label: 'Product Count', value: theme.productCount.toString()),
        DetailField(label: 'Created Date', value: theme.createdAt),
        DetailField(label: 'Updated Date', value: theme.updatedAt),
        if (theme.creator != null) DetailField(label: 'Creator Name', value: theme.creator!.fullName),
        if (theme.creator != null) DetailField(label: 'Creator Role', value: theme.creator!.role),
        if (theme.updater != null) DetailField(label: 'Updater Name', value: theme.updater!.fullName),
        if (theme.updater != null) DetailField(label: 'Updater Role', value: theme.updater!.role),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        actions: [
          // Only show "Add Theme" button if user has create permission
          PermissionWidget(
            permission: 'themes.create',
            child: IconButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/themes/create');
                // Refresh the list if a theme was created
                if (result == true) {
                  _loadThemes();
                }
              },
              icon: const Icon(Icons.add),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Themes', style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary)),
      ),
      body: BlocProvider<ThemeBloc>(
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
                              setState(() {
                                _currentSearch = '';
                                _currentPage = 1;
                              });
                              _loadThemes();
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
                  onChanged: _onSearchChanged,
                ),
              ),

              // Filter and Sort bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: FilterSortBar(onFilterTap: _showFilterSheet, onSortTap: _showSortSheet),
              ),

              // Card list
              Expanded(
                child: BlocBuilder<ThemeBloc, ThemeState>(
                  builder: (context, state) {
                    if (state is ThemeLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ThemeError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(state.message, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(onPressed: _loadThemes, child: const Text('Retry')),
                          ],
                        ),
                      );
                    } else if (state is ThemeLoaded) {
                      if (state.themes.isEmpty) {
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

                      return Column(
                        children: [
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                _loadThemes();
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.themes.length,
                                itemBuilder: (context, index) {
                                  final theme = state.themes[index];
                                  final serialNumber = (state.page - 1) * state.take + index + 1;
                                  return _buildThemeCard(theme, serialNumber);
                                },
                              ),
                            ),
                          ),

                          // Pagination controls
                          PaginationControls(
                            currentPage: state.page,
                            totalPages: state.totalPages,
                            totalItems: state.total,
                            itemsPerPage: state.take,
                            onPageChanged: _onPageChanged,
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
    return RecordCard(
      serialNumber: serialNumber,
      isActive: theme.isActive,
      fields: [
        CardField.title(label: 'Theme Name', value: theme.name),
        CardField.regular(label: 'Description', value: theme.description.isNotEmpty ? theme.description : 'N/A'),
      ],
      createdBy: theme.createdBy,
      createdAt: formatDate(theme.createdAt),
      updatedBy: theme.updatedBy,
      updatedAt: formatDate(theme.updatedAt),
      onEdit: PermissionChecker.canUpdateTheme
          ? () async {
              final result = await Navigator.pushNamed(
                context,
                '/themes/create',
                arguments: {'isEdit': true, 'themeData': theme},
              );
              if (result == true) {
                _loadThemes();
              }
            }
          : null,
      onDelete: PermissionChecker.canDeleteTheme ? () => _confirmDelete(theme) : null,
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteTheme(theme.id));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Theme deleted successfully')));
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
