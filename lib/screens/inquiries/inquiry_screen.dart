import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../models/inquiry_model.dart';
import './inquiry_bloc.dart';
import '../../core/permissions/permission_checker.dart';
import '../../widgets/permission_widget.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';
import '../../utils/date_formatter.dart';

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  late InquiryBloc _bloc;
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
    _bloc = InquiryBloc();
    _loadInquiries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadInquiries() {
    _bloc.add(
      LoadInquiries(
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
        _loadInquiries();
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
        _loadInquiries();
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearch = value;
      _currentPage = 1;
    });
    _loadInquiries();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadInquiries();
  }

  void _showInquiryDetails(InquiryModel inquiry) {
    DetailsBottomSheet.show(
      context: context,
      title: inquiry.name,
      isActive: true,
      fields: [
        DetailField(label: 'Inquiry Name', value: inquiry.name),
        DetailField(label: 'Company', value: inquiry.company),
        DetailField(label: 'Contact', value: inquiry.contactUser),
        DetailField(label: 'Status', value: inquiry.status.isNotEmpty ? inquiry.status : 'N/A'),
        DetailField(label: 'Note', value: inquiry.note.isNotEmpty ? inquiry.note : 'N/A'),
        DetailField(label: 'Created By', value: inquiry.createdBy),
        DetailField(label: 'Created Date', value: inquiry.createdAt),
        if (inquiry.updatedBy != null && inquiry.updatedBy!.isNotEmpty) DetailField(label: 'Updated By', value: inquiry.updatedBy!),
        if (inquiry.updatedAt != null && inquiry.updatedAt!.isNotEmpty) DetailField(label: 'Updated Date', value: inquiry.updatedAt!),
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
          PermissionWidget(
            permission: 'inquiries.create',
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.createInquiry);
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
          'Inquiries',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocProvider<InquiryBloc>(
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
                    hintText: 'Search inquirys...',
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
                              _loadInquiries();
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
                child: BlocBuilder<InquiryBloc, InquiryState>(
                  builder: (context, state) {
                    if (state is InquiryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is InquiryError) {
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
                              onPressed: _loadInquiries,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is InquiryLoaded) {
                      if (state.inquiries.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.question_answer_outlined,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No inquirys found',
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
                                _loadInquiries();
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.inquiries.length,
                                itemBuilder: (context, index) {
                                  final inquiry = state.inquiries[index];
                                  final serialNumber =
                                      (state.page - 1) * state.take + index + 1;
                                  return _buildInquiryCard(
                                    inquiry,
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

  Widget _buildInquiryCard(InquiryModel inquiry, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      isActive: true,
      fields: [
        CardField.title(label: 'Inquiry Name', value: inquiry.name),
        CardField.regular(label: 'Company', value: inquiry.company),
        CardField.regular(label: 'Status', value: inquiry.status),
        CardField.regular(label: 'Contact', value: inquiry.contactUser),
      ],
      createdBy: inquiry.createdBy,
      createdAt: formatDate(inquiry.createdAt),
      updatedBy: inquiry.updatedBy,
      updatedAt: inquiry.updatedAt != null ? formatDate(inquiry.updatedAt!) : null,
      onEdit: PermissionChecker.canUpdateInquiry
          ? () async {
              final result = await Navigator.pushNamed(
                context,
                '/inquiries/create',
                arguments: {'isEdit': true, 'inquiryData': inquiry},
              );
              if (result == true) {
                _loadInquiries();
              }
            }
          : null,
      onDelete: PermissionChecker.canDeleteInquiry ? () => _confirmDelete(inquiry) : null,
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
              _bloc.add(DeleteInquiry(inquiry.id));
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
}
