import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/permissions/permission_checker.dart';
import '../../models/whatsapp_models.dart';
import './template_category_bloc.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/permission_widget.dart';

/// Template Category list screen with full features: filter, sort, pagination, and details
class TemplateCategoryScreen extends StatefulWidget {
  const TemplateCategoryScreen({super.key});

  @override
  State<TemplateCategoryScreen> createState() => _TemplateCategoryScreenState();
}

class _TemplateCategoryScreenState extends State<TemplateCategoryScreen> {
  late TemplateCategoryBloc _bloc;
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
    _bloc = TemplateCategoryBloc();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadRecords() {
    _bloc.add(LoadTemplateCats(
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
        _loadRecords();
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
        _loadRecords();
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearch = value;
      _currentPage = 1;
    });
    _loadRecords();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadRecords();
  }

  void _showDetails(WhatsAppTemplateCategoryModel record) {
    DetailsBottomSheet.show(
      context: context,
      title: record.name,
      isActive: record.isActive,
      fields: [
        DetailField(label: 'Name', value: record.name),
        DetailField(label: 'Note', value: record.note.isNotEmpty ? record.note : 'N/A'),
        DetailField(label: 'Templates', value: record.templates.length.toString()),
        DetailField(label: 'Status', value: record.isActive ? 'Active' : 'Inactive'),
        DetailField(label: 'Created By', value: record.createdBy),
        DetailField(label: 'Created Date', value: record.createdAt),
        if (record.updatedBy != null) DetailField(label: 'Updated By', value: record.updatedBy!),
        if (record.updatedAt != null) DetailField(label: 'Updated Date', value: record.updatedAt!),
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
          // Only show "Add" button if user has create permission
          PermissionWidget(
            permission: 'whatsapp.create',
            child: IconButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(context, '/whatsapp-template-categories/create');
                // Refresh the list if a record was created
                if (result == true) {
                  _loadRecords();
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
        title: Text(
          'Template Categories',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocProvider<TemplateCategoryBloc>(
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
                    hintText: 'Search template categories...',
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
                              _loadRecords();
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
                child: BlocBuilder<TemplateCategoryBloc, TemplateCatState>(
                  builder: (context, state) {
                    if (state is TemplateCatLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is TemplateCatError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                            const SizedBox(height: 16),
                            Text(state.message, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRecords,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is TemplateCatLoaded) {
                      if (state.records.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.category_outlined, size: 64, color: AppColors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No template categories found',
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
                                _loadRecords();
                                await Future.delayed(const Duration(milliseconds: 500));
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.records.length,
                                itemBuilder: (context, index) {
                                  final record = state.records[index];
                                  final serialNumber = (state.page - 1) * state.take + index + 1;
                                  return _buildRecordCard(record, serialNumber);
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

  Widget _buildRecordCard(WhatsAppTemplateCategoryModel record, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      isActive: record.isActive,
      fields: [
        CardField.title(
          label: 'Name',
          value: record.name,
        ),
        CardField.regular(
          label: 'Note',
          value: record.note.isNotEmpty ? record.note : 'N/A',
        ),
        CardField.regular(
          label: 'Templates',
          value: record.templates.length.toString(),
        ),
        CardField.regular(
          label: 'Created By',
          value: record.createdBy,
        ),
        CardField.regular(
          label: 'Created Date',
          value: record.createdAt,
        ),
      ],
      onEdit: PermissionChecker.canUpdateWhatsApp
          ? () async {
              final result = await Navigator.pushNamed(
                context,
                '/whatsapp-template-categories/create',
                arguments: {'isEdit': true, 'recordData': record},
              );
              if (result == true) {
                _loadRecords();
              }
            }
          : null,
      onDelete: PermissionChecker.canDeleteWhatsApp ? () => _confirmDelete(record) : null,
      onTap: () => _showDetails(record),
    );
  }

  void _confirmDelete(WhatsAppTemplateCategoryModel record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${record.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteTemplateCat(record.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Template category deleted successfully')),
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
