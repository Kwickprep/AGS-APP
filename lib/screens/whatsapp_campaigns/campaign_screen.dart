import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../core/permissions/permission_checker.dart';
import '../../models/whatsapp_models.dart';
import './campaign_bloc.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/permission_widget.dart';

/// Campaign list screen with full features: filter, sort, pagination, and details
class CampaignScreen extends StatefulWidget {
  const CampaignScreen({super.key});

  @override
  State<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends State<CampaignScreen> {
  late CampaignBloc _bloc;
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
    _bloc = CampaignBloc();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadRecords() {
    _bloc.add(LoadCampaigns(
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
        SortOption(field: 'status', label: 'Status'),
        SortOption(field: 'startDateTime', label: 'Start Date'),
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

  void _showDetails(WhatsAppCampaignModel record) {
    DetailsBottomSheet.show(
      context: context,
      title: record.name,
      status: record.status,
      isActive: record.isActive,
      fields: [
        DetailField(label: 'Name', value: record.name),
        DetailField(label: 'Description', value: record.description.isNotEmpty ? record.description : 'N/A'),
        DetailField(label: 'Status', value: record.status),
        DetailField(label: 'Contacts', value: record.contactCount.toString()),
        DetailField(label: 'Start Date', value: record.startDateTime.isNotEmpty ? record.startDateTime : 'N/A'),
        if (record.categoryName != null) DetailField(label: 'Category', value: record.categoryName!),
        DetailField(label: 'Created By', value: record.createdBy),
        DetailField(label: 'Created Date', value: record.createdAt),
        if (record.updatedBy != null) DetailField(label: 'Updated By', value: record.updatedBy!),
        if (record.updatedAt != null) DetailField(label: 'Updated Date', value: record.updatedAt!),
      ],
    );
  }

  void _confirmExecute(WhatsAppCampaignModel record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Execute Campaign'),
        content: Text('Are you sure you want to execute "${record.name}"? This will send messages to ${record.contactCount} contacts.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(ExecuteCampaign(record.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Campaign execution started')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Execute'),
          ),
        ],
      ),
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
                final result = await Navigator.pushNamed(context, '/whatsapp-campaigns/create');
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
          'Campaigns',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocProvider<CampaignBloc>(
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
                    hintText: 'Search campaigns...',
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
                child: BlocConsumer<CampaignBloc, CampaignState>(
                  listener: (context, state) {
                    if (state is CampaignExecuted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Campaign executed successfully')),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is CampaignLoading || state is CampaignExecuting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is CampaignError) {
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
                    } else if (state is CampaignLoaded) {
                      if (state.records.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.campaign_outlined, size: 64, color: AppColors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No campaigns found',
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

  Widget _buildRecordCard(WhatsAppCampaignModel record, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      status: record.status,
      isActive: record.isActive,
      fields: [
        CardField.title(
          label: 'Name',
          value: record.name,
        ),
        CardField.regular(
          label: 'Description',
          value: record.description.isNotEmpty ? record.description : 'N/A',
        ),
        CardField.regular(
          label: 'Status',
          value: record.status,
        ),
        CardField.regular(
          label: 'Contacts',
          value: record.contactCount.toString(),
        ),
        CardField.regular(
          label: 'Start Date',
          value: record.startDateTime.isNotEmpty ? record.startDateTime : 'N/A',
        ),
        CardField.regular(
          label: 'Created By',
          value: record.createdBy,
        ),
      ],
      onEdit: PermissionChecker.canUpdateWhatsApp
          ? () async {
              final result = await Navigator.pushNamed(
                context,
                '/whatsapp-campaigns/create',
                arguments: {'isEdit': true, 'recordData': record},
              );
              if (result == true) {
                _loadRecords();
              }
            }
          : null,
      onDelete: PermissionChecker.canDeleteWhatsApp ? () => _confirmDelete(record) : null,
      onView: (!record.hasRun && !record.isRunning && PermissionChecker.canSendWhatsApp)
          ? () => _confirmExecute(record)
          : null,
      onTap: () => _showDetails(record),
    );
  }

  void _confirmDelete(WhatsAppCampaignModel record) {
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
              _bloc.add(DeleteCampaign(record.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Campaign deleted successfully')),
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
