import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../models/group_model.dart';
import './group_bloc.dart';
import '../../core/permissions/permission_checker.dart';
import '../../widgets/permission_widget.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';
import '../../utils/date_formatter.dart';

/// Group list screen with full features: filter, sort, pagination, and details
class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  late GroupBloc _bloc;
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
    _bloc = GroupBloc();
    _loadGroups();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadGroups() {
    _bloc.add(
      LoadGroups(
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
        _loadGroups();
      },
    );
  }

  void _showSortSheet() {
    SortBottomSheet.show(
      context: context,
      initialSort: SortModel(
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ),
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
        _loadGroups();
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearch = value;
      _currentPage = 1;
    });
    _loadGroups();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadGroups();
  }

  void _showGroupDetails(GroupModel group) {
    DetailsBottomSheet.show(
      context: context,
      title: group.name,
      isActive: group.isActive,
      fields: [
        DetailField(label: 'Group Name', value: group.name),
        DetailField(label: 'Members', value: group.users.isNotEmpty ? group.users : 'N/A'),
        DetailField(label: 'Note', value: group.note.isNotEmpty ? group.note : 'N/A'),
        DetailField(label: 'Status', value: group.isActive ? 'Active' : 'Inactive'),
        if (group.createdInfo.isNotEmpty)
          DetailField(label: 'Created', value: group.createdInfo),
        if (group.createdInfo.isEmpty)
          DetailField(label: 'Created By', value: group.createdBy),
        if (group.createdInfo.isEmpty)
          DetailField(label: 'Created Date', value: formatDate(group.createdAt)),
        if (group.updatedInfo != null && group.updatedInfo!.isNotEmpty)
          DetailField(label: 'Updated', value: group.updatedInfo!),
      ],
      onEdit: () => _navigateToEditGroup(group),
    );
  }

  Future<void> _navigateToEditGroup(GroupModel group) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.createGroup,
      arguments: {'group': group, 'isEdit': true},
    );

    // Reload groups if update was successful
    if (result == true) {
      _loadGroups();
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
            permission: 'groups.create',
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.createGroup);
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
          'Groups',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocProvider<GroupBloc>(
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
                    hintText: 'Search groups...',
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
                              _loadGroups();
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: FilterSortBar(
                  onFilterTap: _showFilterSheet,
                  onSortTap: _showSortSheet,
                ),
              ),

              // Card list
              Expanded(
                child: BlocBuilder<GroupBloc, GroupState>(
                  builder: (context, state) {
                    if (state is GroupLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is GroupError) {
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
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadGroups,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is GroupLoaded) {
                      if (state.groups.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.group_outlined,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No groups found',
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
                                _loadGroups();
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.groups.length,
                                itemBuilder: (context, index) {
                                  final group = state.groups[index];
                                  final serialNumber =
                                      (state.page - 1) * state.take + index + 1;
                                  return _buildGroupCard(group, serialNumber);
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

  Widget _buildGroupCard(GroupModel group, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      isActive: group.isActive,
      fields: [
        CardField.title(label: 'Group Name', value: group.name),
        CardField.regular(label: 'Members', value: group.users),
        if (group.note.isNotEmpty && group.note != '-')
          CardField.description(label: 'Note', value: group.note, maxLines: 2),
      ],
      createdBy: group.createdInfo.isNotEmpty ? group.createdInfo : group.createdBy,
      createdAt: group.createdInfo.isNotEmpty ? null : formatDate(group.createdAt),
      updatedBy: group.updatedInfo != null && group.updatedInfo!.isNotEmpty ? group.updatedInfo : null,
      onView: () => _showGroupDetails(group),
      onEdit: PermissionChecker.canUpdateGroup
          ? () => _navigateToEditGroup(group)
          : null,
      onDelete: PermissionChecker.canDeleteGroup
          ? () => _confirmDelete(group)
          : null,
      onTap: () => _showGroupDetails(group),
    );
  }

  void _confirmDelete(GroupModel group) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteGroup(group.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group deleted successfully')),
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
