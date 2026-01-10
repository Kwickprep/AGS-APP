import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/activity_type_model.dart';
import './activity_type_bloc.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';
import '../../widgets/common/filter_sort_bar.dart';

/// Activity Type list screen with full features: filter, sort, pagination, and details
class ActivityTypeScreen extends StatefulWidget {
  const ActivityTypeScreen({super.key});

  @override
  State<ActivityTypeScreen> createState() => _ActivityTypeScreenState();
}

class _ActivityTypeScreenState extends State<ActivityTypeScreen> {
  late ActivityTypeBloc _bloc;
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
    _bloc = ActivityTypeBloc();
    _loadActivityTypes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadActivityTypes() {
    _bloc.add(LoadActivityTypes(
      page: _currentPage,
      take: _itemsPerPage,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
      filters: _currentFilters,
    ));
  }

  void _showFilterSheet() {
    // Determine current selected statuses
    List<String> selectedStatuses = [];
    if (_currentFilters['isActive'] == true) {
      selectedStatuses.add('Active');
    } else if (_currentFilters['isActive'] == false) {
      selectedStatuses.add('Inactive');
    }

    FilterBottomSheet.show(
      context: context,
      initialFilter: FilterModel(
        selectedStatuses: selectedStatuses.toSet(),
        createdBy: _currentFilters['createdBy'],
      ),
      creatorOptions: const [],
      statusOptions: const ['Active', 'Inactive'],
      onApplyFilters: (filter) {
        setState(() {
          _currentFilters = {};
          if (filter.selectedStatuses.isNotEmpty) {
            if (filter.selectedStatuses.contains('Active') &&
                !filter.selectedStatuses.contains('Inactive')) {
              _currentFilters['isActive'] = true;
            } else if (filter.selectedStatuses.contains('Inactive') &&
                       !filter.selectedStatuses.contains('Active')) {
              _currentFilters['isActive'] = false;
            }
          }
          if (filter.createdBy != null) {
            _currentFilters['createdBy'] = filter.createdBy;
          }
          _currentPage = 1;
        });
        _loadActivityTypes();
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
          _currentPage = 1;
        });
        _loadActivityTypes();
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearch = value;
      _currentPage = 1;
    });
    _loadActivityTypes();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadActivityTypes();
  }

  void _showActivityTypeDetails(ActivityTypeModel activityType) {
    DetailsBottomSheet.show(
      context: context,
      title: activityType.name,
      isActive: activityType.isActive,
      fields: [
        DetailField(label: 'Activity Type Name', value: activityType.name),
        DetailField(label: 'Status', value: activityType.isActive ? 'Active' : 'Inactive'),
        DetailField(label: 'Created By', value: activityType.createdBy),
        DetailField(label: 'Created Date', value: activityType.createdAt),
        if (activityType.updatedBy != null) DetailField(label: 'Updated By', value: activityType.updatedBy!),
        if (activityType.updatedAt != null) DetailField(label: 'Updated Date', value: activityType.updatedAt!),
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
          IconButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/activity-types/create');
              // Refresh the list if an activity type was created
              if (result == true) {
                _loadActivityTypes();
              }
            },
            icon: const Icon(Icons.add),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Activity Types',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocProvider<ActivityTypeBloc>(
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
                    hintText: 'Search activity types...',
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
                              _loadActivityTypes();
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
                child: FilterSortBar(
                  onFilterTap: _showFilterSheet,
                  onSortTap: _showSortSheet,
                ),
              ),

              // Card list
              Expanded(
                child: BlocBuilder<ActivityTypeBloc, ActivityTypeState>(
                  builder: (context, state) {
                    if (state is ActivityTypeLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is ActivityTypeError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(state.message, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadActivityTypes,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is ActivityTypeLoaded) {
                      if (state.activityTypes.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.category_outlined, size: 64, color: AppColors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No activity types found',
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
                                _loadActivityTypes();
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.activityTypes.length,
                                itemBuilder: (context, index) {
                                  final activityType = state.activityTypes[index];
                                  final serialNumber = (state.page - 1) * state.take + index + 1;
                                  return _buildActivityTypeCard(activityType, serialNumber);
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

  Widget _buildActivityTypeCard(ActivityTypeModel activityType, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      isActive: activityType.isActive,
      fields: [
        CardField.title(
          label: 'Activity Type Name',
          value: activityType.name,
        ),
        CardField.regular(
          label: 'Created By',
          value: activityType.createdBy,
        ),
        CardField.regular(
          label: 'Created Date',
          value: activityType.createdAt,
        ),
      ],
      onEdit: activityType.actions.any((action) => action.type == 'routerLink')
          ? () async {
              final result = await Navigator.pushNamed(
                context,
                '/activity-types/create',
                arguments: {'isEdit': true, 'activityTypeData': activityType},
              );
              if (result == true) {
                _loadActivityTypes();
              }
            }
          : null,
      onDelete: activityType.actions.any((action) => action.type == 'delete')
          ? () => _confirmDelete(activityType)
          : null,
      onTap: () => _showActivityTypeDetails(activityType),
    );
  }

  void _confirmDelete(ActivityTypeModel activityType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${activityType.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteActivityType(activityType.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Activity type deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
