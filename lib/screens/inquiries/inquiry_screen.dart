import 'package:ags/screens/inquiries/inquiry_create_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../models/inquiry_model.dart';
import '../../services/inquiry_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';

/// Inquiry list screen with full features: filter, sort, pagination, and details
class InquiryScreen extends StatefulWidget {
  const InquiryScreen({Key? key}) : super(key: key);

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  late GenericListBloc<InquiryModel> _bloc;
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
    _bloc = GenericListBloc<InquiryModel>(
      service: GetIt.I<InquiryService>(),
      sortComparator: _inquirySortComparator,
      filterPredicate: _inquiryFilterPredicate,
    );
    _bloc.add(LoadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  List<InquiryModel> _getPaginatedData(List<InquiryModel> allData) {
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
    List<String> statuses = [];
    final state = _bloc.state;
    if (state is GenericListLoaded<InquiryModel>) {
      creators = state.data.map((i) => i.createdBy).toSet().toList();
      statuses = state.data.map((i) => i.status).toSet().toList();
    }

    FilterBottomSheet.show(
      context: context,
      initialFilter: _filterModel,
      creatorOptions: creators,
      statusOptions: statuses.isNotEmpty ? statuses : ['Open', 'Closed', 'Pending'],
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
        SortOption(field: 'company', label: 'Company'),
        SortOption(field: 'contactUser', label: 'Contact User'),
        SortOption(field: 'status', label: 'Status'),
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
      filters['status'] = _filterModel.selectedStatuses.first;
    }

    if (_filterModel.createdBy != null) {
      filters['createdBy'] = _filterModel.createdBy;
    }

    _bloc.add(ApplyFilters(filters));
    _bloc.add(SortData(_sortModel.sortBy, _sortModel.sortOrder));
  }

  void _showInquiryDetails(InquiryModel inquiry) {
    DetailsBottomSheet.show(
      context: context,
      title: inquiry.name,
      status: inquiry.status,
      fields: [
        DetailField(label: 'Name', value: inquiry.name),
        DetailField(label: 'Company', value: inquiry.company),
        DetailField(label: 'Contact User', value: inquiry.contactUser),
        DetailField(label: 'Status', value: inquiry.status),
        if (inquiry.note.isNotEmpty) DetailField(label: 'Note', value: inquiry.note),
        DetailField(label: 'Created By', value: inquiry.createdBy),
        DetailField(label: 'Created Date', value: inquiry.createdAt),
      ],
      onEdit: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Edit functionality coming soon')),
        );
      },
      onDelete: () => _confirmDelete(inquiry),
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
          'Inquiries',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.iconPrimary),
            onPressed: _navigateToCreate,
            tooltip: 'Create Inquiry',
          ),
        ],
      ),
      body: BlocProvider<GenericListBloc<InquiryModel>>(
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
                    hintText: 'Search inquiries...',
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
                child: BlocBuilder<GenericListBloc<InquiryModel>, GenericListState>(
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
                    } else if (state is GenericListLoaded<InquiryModel>) {
                      if (state.data.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.assignment_outlined, size: 64, color: AppColors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No inquiries found',
                                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _navigateToCreate,
                                child: const Text('Create Inquiry'),
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
                                  final inquiry = paginatedData[index];
                                  final serialNumber = (_currentPage - 1) * _itemsPerPage + index + 1;
                                  return _buildInquiryCard(inquiry, serialNumber);
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

  Widget _buildInquiryCard(InquiryModel inquiry, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      status: inquiry.status,
      fields: [
        CardField.title(
          label: 'Name',
          value: inquiry.name,
        ),
        CardField.regular(
          label: 'Company',
          value: inquiry.company,
        ),
        CardField.regular(
          label: 'Contact User',
          value: inquiry.contactUser,
        ),
        CardField.regular(
          label: 'Created Date',
          value: inquiry.createdAt,
        ),
      ],
      onView: () => _showInquiryDetails(inquiry),
      onDelete: () => _confirmDelete(inquiry),
      onTap: () => _showInquiryDetails(inquiry),
    );
  }

  void _confirmDelete(InquiryModel inquiry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${inquiry.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteData(inquiry.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Inquiry deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const InquiryCreateScreen()),
    );
    if (result == true && mounted) {
      _bloc.add(LoadData());
    }
  }

  /// Sort comparator for inquiries
  int _inquirySortComparator(InquiryModel a, InquiryModel b, String sortBy, String sortOrder) {
    int comparison = 0;

    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'company':
        comparison = a.company.compareTo(b.company);
        break;
      case 'contactUser':
        comparison = a.contactUser.compareTo(b.contactUser);
        break;
      case 'status':
        comparison = a.status.compareTo(b.status);
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

  /// Filter predicate for inquiries
  bool _inquiryFilterPredicate(InquiryModel inquiry, Map<String, dynamic> filters) {
    if (filters.containsKey('status') && filters['status'] != null) {
      if (inquiry.status != filters['status']) return false;
    }

    if (filters.containsKey('createdBy') && filters['createdBy'] != null) {
      if (inquiry.createdBy != filters['createdBy']) return false;
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
