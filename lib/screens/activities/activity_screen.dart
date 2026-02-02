import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../models/activity_model.dart';
import './activity_bloc.dart';
import '../../core/permissions/permission_checker.dart';
import '../../widgets/permission_widget.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';
import '../../utils/date_formatter.dart';

/// Activity list screen with full features: filter, sort, pagination, and details
/// Uses individual BLoC pattern - every change triggers new API call
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late ActivityBloc _bloc;
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
    _bloc = ActivityBloc();
    // Initial load
    _loadActivities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  /// Load activities with current parameters - Simple: Fire event -> API call -> Update state
  void _loadActivities() {
    _bloc.add(LoadActivities(
      page: _currentPage,
      take: _itemsPerPage,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
      filters: _currentFilters,
    ));
  }

  void _showFilterSheet() {
    FilterBottomSheet.show(
      context: context,
      initialFilter: FilterModel(
        createdBy: _currentFilters['createdBy'],
      ),
      creatorOptions: const [], // Can be populated from API if needed
      statusOptions: const [], // Activities don't have active/inactive status
      onApplyFilters: (filter) {
        setState(() {
          _currentFilters = {};
          if (filter.createdBy != null) {
            _currentFilters['createdBy'] = filter.createdBy;
          }
          _currentPage = 1; // Reset to first page
        });
        _loadActivities(); // Reload with new filters
      },
    );
  }

  void _showSortSheet() {
    SortBottomSheet.show(
      context: context,
      initialSort: SortModel(sortBy: _currentSortBy, sortOrder: _currentSortOrder),
      sortOptions: const [
        SortOption(field: 'activityType', label: 'Activity Type'),
        SortOption(field: 'company', label: 'Company'),
        SortOption(field: 'inquiry', label: 'Inquiry'),
        SortOption(field: 'user', label: 'User'),
        SortOption(field: 'source', label: 'Source'),
        SortOption(field: 'theme', label: 'Theme'),
        SortOption(field: 'category', label: 'Category'),
        SortOption(field: 'priceRange', label: 'Price Range'),
        SortOption(field: 'product', label: 'Product'),
        SortOption(field: 'moq', label: 'MOQ'),
        SortOption(field: 'nextScheduleDate', label: 'Next Schedule Date'),
        SortOption(field: 'createdAt', label: 'Created Date'),
        SortOption(field: 'createdBy', label: 'Created By'),
      ],
      onApplySort: (sort) {
        setState(() {
          _currentSortBy = sort.sortBy;
          _currentSortOrder = sort.sortOrder;
          _currentPage = 1; // Reset to first page
        });
        _loadActivities(); // Reload with new sort
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearch = value;
      _currentPage = 1; // Reset to first page
    });
    _loadActivities(); // Reload with new search
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadActivities(); // Reload with new page
  }

  void _showActivityDetails(ActivityModel activity) {
    DetailsBottomSheet.show(
      context: context,
      title: activity.activityType,
      isActive: null, // Don't show active/inactive status for activities
      fields: [
        DetailField(label: 'Activity Type', value: activity.activityType),
        DetailField(label: 'Company', value: activity.company),
        DetailField(label: 'Inquiry', value: activity.inquiry),
        DetailField(label: 'User', value: activity.user),
        DetailField(label: 'Source', value: activity.source),
        DetailField(label: 'Theme', value: activity.theme),
        DetailField(label: 'Category', value: activity.category),
        DetailField(label: 'Price Range', value: activity.priceRange),
        DetailField(label: 'Product', value: activity.product),
        DetailField(label: 'MOQ', value: activity.moq),
        DetailField(label: 'Documents', value: activity.documents),
        DetailField(
          label: 'Next Schedule Date',
          value: activity.nextScheduleDate,
        ),
        DetailField(label: 'Details', value: activity.note),
        DetailField(label: 'Created By', value: activity.createdBy),
        DetailField(label: 'Created Date', value: activity.createdAt),
      ],
    );
  }

  Future<void> _navigateToEditActivity(ActivityModel activity) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.createActivity,
      arguments: {
        'activity': activity,
        'isEdit': true,
      },
    );

    // Reload activities if activity was updated successfully
    if (result == true) {
      _loadActivities();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        actions: [
          PermissionWidget(
            permission: 'activities.create',
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.createActivity);
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
        title: Text(
          'Activities',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocProvider<ActivityBloc>(
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
                    hintText: 'Search activities...',
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
                              _loadActivities();
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

              // Sort bar
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _showSortSheet,
                      icon: const Icon(Icons.sort, size: 18),
                      label: const Text('Sort'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Card list
              Expanded(
                child: BlocBuilder<ActivityBloc, ActivityState>(
                  builder: (context, state) {
                    if (state is ActivityLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else if (state is ActivityError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              state.message,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadActivities,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is ActivityLoaded) {
                      if (state.activities.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_note,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No activities found',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.textLight,
                                ),
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
                                _loadActivities();
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.activities.length,
                                itemBuilder: (context, index) {
                                  final activity = state.activities[index];
                                  final serialNumber =
                                      (state.page - 1) * state.take + index + 1;
                                  return _buildActivityCard(
                                    activity,
                                    serialNumber,
                                  );
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

  Widget _buildActivityCard(ActivityModel activity, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      isActive: null, // Don't show any status badge for activities
      fields: [
        CardField.title(label: 'Activity Type', value: activity.activityType),
        CardField.regular(label: 'Company', value: activity.company),
        CardField.regular(label: 'User', value: activity.user),
        if (activity.nextScheduleDate.isNotEmpty)
          CardField.regular(
            label: 'Next Schedule',
            value: activity.nextScheduleDate,
          ),
      ],
      createdBy: activity.createdBy,
      createdAt: formatDate(activity.createdAt),
      updatedBy: activity.updatedBy,
      updatedAt: activity.updatedAt != null ? formatDate(activity.updatedAt!) : null,
      onView: () => _showActivityDetails(activity),
      onEdit: PermissionChecker.canUpdateActivity ? () => _navigateToEditActivity(activity) : null,
      onDelete: PermissionChecker.canDeleteActivity ? () => _confirmDelete(activity) : null,
      onTap: () => _showActivityDetails(activity),
    );
  }

  void _confirmDelete(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete this activity "${activity.activityType}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteActivity(activity.id));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
