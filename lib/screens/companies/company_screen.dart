import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../config/routes.dart';
import '../../models/company_model.dart';
import './company_bloc.dart';
import '../../widgets/common/record_card.dart';
import '../../widgets/common/filter_sort_bar.dart';
import '../../widgets/common/pagination_controls.dart';
import '../../widgets/common/filter_bottom_sheet.dart';
import '../../widgets/common/sort_bottom_sheet.dart';
import '../../widgets/common/details_bottom_sheet.dart';

/// Company list screen with full features: filter, sort, pagination, and details
class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  late CompanyBloc _bloc;
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
    _bloc = CompanyBloc();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  void _loadCompanies() {
    _bloc.add(
      LoadCompanies(
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
        _loadCompanies();
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
        _loadCompanies();
      },
    );
  }

  void _onSearchChanged(String value) {
    setState(() {
      _currentSearch = value;
      _currentPage = 1;
    });
    _loadCompanies();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadCompanies();
  }

  void _showCompanyDetails(CompanyModel company) {
    DetailsBottomSheet.show(
      context: context,
      title: company.name,
      isActive: company.isActive == "Active",
      fields: [
        DetailField(
          label: 'Company Name',
          value: company.name,
        ),
        DetailField(
          label: 'Email',
          value: company.email,
        ),
        DetailField(
          label: 'Website',
          value: company.website,
        ),
        DetailField(
          label: 'Industry',
          value: company.industry,
        ),
        DetailField(
          label: 'Employees',
          value: company.employees,
        ),
        DetailField(
          label: 'Turnover',
          value: company.turnover,
        ),
        DetailField(
          label: 'GST Number',
          value: company.gstNumber,
        ),
        DetailField(
          label: 'Country',
          value: company.country,
        ),
        DetailField(
          label: 'State',
          value: company.state,
        ),
        DetailField(
          label: 'City',
          value: company.city,
        ),
        DetailField(
          label: 'Status',
          value: company.isActive == "Active" ? 'Active' : 'Inactive',
        ),
        DetailField(
          label: 'Created By',
          value: company.createdBy,
        ),
        DetailField(
          label: 'Created Date',
          value: company.createdAt,
        ),
      ],
    );
  }

  void _navigateToEditCompany(CompanyModel company) async {
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.createCompany,
      arguments: {
        'isEdit': true,
        'companyData': company,
      },
    );

    if (result == true) {
      _loadCompanies();
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
          IconButton(
            onPressed: () async {
              final result = await Navigator.pushNamed(
                context,
                AppRoutes.createCompany,
              );
              if (result == true) {
                _loadCompanies();
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
          'Companies',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocProvider<CompanyBloc>(
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
                    hintText: 'Search companies...',
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
                              _loadCompanies();
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
                child: BlocBuilder<CompanyBloc, CompanyState>(
                  builder: (context, state) {
                    if (state is CompanyLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is CompanyError) {
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
                              onPressed: _loadCompanies,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    } else if (state is CompanyLoaded) {
                      if (state.companies.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.business_outlined,
                                size: 64,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No companies found',
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
                                _loadCompanies();
                                await Future.delayed(
                                  const Duration(milliseconds: 500),
                                );
                              },
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.companies.length,
                                itemBuilder: (context, index) {
                                  final company = state.companies[index];
                                  final serialNumber =
                                      (state.page - 1) * state.take + index + 1;
                                  return _buildCompanyCard(
                                      company, serialNumber);
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

  Widget _buildCompanyCard(CompanyModel company, int serialNumber) {
    return RecordCard(
      serialNumber: serialNumber,
      isActive: company.isActive == "Active",
      fields: [
        CardField.title(
          label: 'Company Name',
          value: company.name,
        ),
        CardField.regular(
          label: 'Email',
          value: company.email,
        ),
        CardField.regular(
          label: 'Industry',
          value: company.industry,
        ),
        CardField.regular(
          label: 'Created By',
          value: company.createdBy,
        ),
        CardField.regular(
          label: 'Created Date',
          value: company.createdAt,
        ),
      ],
      onEdit: () => _navigateToEditCompany(company),
      onDelete: () => _confirmDelete(company),
      onTap: () => _showCompanyDetails(company),
    );
  }

  void _confirmDelete(CompanyModel company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete "${company.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteCompany(company.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Company deleted successfully')),
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
