import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:country_state_city/country_state_city.dart' as csc;
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../services/company_service.dart';
import '../../services/user_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_toast.dart';
import '../../models/company_model.dart';
import '../../models/user_screen_model.dart';

class CompanyCreateScreen extends StatefulWidget {
  final bool isEdit;
  final CompanyModel? companyData;

  const CompanyCreateScreen({
    super.key,
    this.isEdit = false,
    this.companyData,
  });

  @override
  State<CompanyCreateScreen> createState() => _CompanyCreateScreenState();
}

class _CompanyCreateScreenState extends State<CompanyCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final CompanyService _companyService = GetIt.I<CompanyService>();
  final UserService _userService = GetIt.I<UserService>();

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _gstNumberController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _noteController = TextEditingController();
  final _userSearchController = TextEditingController();

  // Dropdown values
  String? _selectedIndustry;
  String? _selectedEmployees;
  String? _selectedTurnover;
  String? _selectedCountryValue;
  String? _selectedStateValue;
  String? _selectedCityValue;
  bool _isActive = true;

  // Country, State, City data
  List<csc.Country> _countries = [];
  List<csc.State> _states = [];
  List<csc.City> _cities = [];

  // Users data and pagination
  List<UserScreenModel> _allUsers = []; // All users from API
  List<UserScreenModel> _selectedUsers = []; // Selected users for display
  List<UserScreenModel> _unselectedUsers = []; // Unselected users for display
  final Set<String> _selectedUserIds = {};
  int _selectedPage = 1;
  int _unselectedPage = 1;
  final int _usersTake = 10;
  int _selectedTotal = 0;
  int _unselectedTotal = 0;
  int _selectedTotalPages = 0;
  int _unselectedTotalPages = 0;
  bool _isLoadingUsers = false;
  String _userSearchQuery = '';

  bool _isLoading = false;
  bool _isLoadingData = true;

  // Options matching API response
  final List<String> _industries = [
    'PHARMACEUTICALS – PHARMA',
    'BIOTECH – PHARMA',
    'MEDICAL DEVICES – PHARMA',
    'DIAGNOSTICS & LABORATORIES – PHARMA',
    'CONTRACT RESEARCH/MANUFACTURING (CRO/CDMO) – PHARMA',
    'HOSPITALS & HEALTHCARE PROVIDERS – PHARMA',
    'NUTRACEUTICALS & WELLNESS – PHARMA',
    'IT & ITES – NON PHARMA',
    'BPO/KPO – NON PHARMA',
    'TELECOMMUNICATIONS – NON PHARMA',
    'E-COMMERCE – NON PHARMA',
    'MEDIA & ENTERTAINMENT – NON PHARMA',
    'EDUCATION & EDTECH – NON PHARMA',
    'ELECTRONICS MANUFACTURING – NON PHARMA',
    'BANKING – NON PHARMA',
    'INSURANCE – NON PHARMA',
    'NBFCS – NON PHARMA',
    'CAPITAL MARKETS – NON PHARMA',
    'CEMENT – NON PHARMA',
    'CERAMICS – NON PHARMA',
    'PAINT – NON PHARMA',
    'CHEMICALS & PETROCHEMICALS – NON PHARMA',
    'METALS & MINING – NON PHARMA',
    'STEEL – NON PHARMA',
    'TEXTILES & APPAREL – NON PHARMA',
    'LEATHER & FOOTWEAR – NON PHARMA',
    'PAPER & PULP – NON PHARMA',
    'GLASS – NON PHARMA',
    'RUBBER & PLASTICS – NON PHARMA',
    'INDUSTRIAL MACHINERY – NON PHARMA',
    'PACKAGING – NON PHARMA',
    'FURNITURE & FIXTURES – NON PHARMA',
    'JEWELRY & GEMS – NON PHARMA',
    'PRINTING & PUBLISHING – NON PHARMA',
    'RETAIL CHAINS – NON PHARMA',
    'FMCG/CONSUMER GOODS – NON PHARMA',
    'FOOD & BEVERAGE – NON PHARMA',
    'TOBACCO – NON PHARMA',
    'DISTILLERIES & BREWERIES – NON PHARMA',
    'SUGAR – NON PHARMA',
    'INFRASTRUCTURE – NON PHARMA',
    'CONSTRUCTION – NON PHARMA',
    'REAL ESTATE – NON PHARMA',
    'ENERGY & POWER – NON PHARMA',
    'OIL & GAS – NON PHARMA',
    'RENEWABLE ENERGY – NON PHARMA',
    'WATER & SANITATION UTILITIES – NON PHARMA',
    'AUTOMOTIVE & AUTO COMPONENTS – NON PHARMA',
    'LOGISTICS & TRANSPORTATION – NON PHARMA',
    'SHIPPING – NON PHARMA',
    'AVIATION & AEROSPACE – NON PHARMA',
    'RAILWAYS – NON PHARMA',
    'PORTS & MARITIME – NON PHARMA',
    'WAREHOUSING – NON PHARMA',
    'AGRICULTURE & AGRITECH – NON PHARMA',
    'FERTILIZERS – NON PHARMA',
    'FISHING & AQUACULTURE – NON PHARMA',
    'FORESTRY – NON PHARMA',
    'HOSPITALITY & TOURISM – NON PHARMA',
    'TRAVEL – NON PHARMA',
    'PROFESSIONAL SERVICES (LEGAL/CONSULTING/ACCOUNTING) – NON PHARMA',
    'SECURITY SERVICES – NON PHARMA',
    'FACILITY MANAGEMENT – NON PHARMA',
    'WASTE MANAGEMENT – NON PHARMA',
    'PERSONAL CARE SERVICES – NON PHARMA',
    'SPORTS & RECREATION – NON PHARMA',
    'COOPERATIVES – NON PHARMA',
    'PUBLIC SECTOR/GOVERNMENT – NON PHARMA',
    'DEFENSE & MILITARY – NON PHARMA',
    'STARTUPS/VENTURE-BACKED – NON PHARMA',
    'RESEARCH & DEVELOPMENT – NON PHARMA',
    'NON-PROFIT/NGO – NON PHARMA',
    'OTHERS – NON PHARMA',
  ];

  final List<String> _employeeRanges = [
    '1-10 EMPLOYEES (MICRO)',
    '11-50 EMPLOYEES (SMALL)',
    '51-200 EMPLOYEES (SMALL-MEDIUM)',
    '201-500 EMPLOYEES (MEDIUM)',
    '501-1,000 EMPLOYEES (MEDIUM-LARGE)',
    '1,001-5,000 EMPLOYEES (LARGE)',
    '5,001-10,000 EMPLOYEES (ENTERPRISE)',
    '10,000+ EMPLOYEES (LARGE ENTERPRISE)',
  ];

  final List<String> _turnoverRanges = [
    '< ₹50 LAKHS (MICRO)',
    '₹50 LAKHS - 1 CR (MICRO)',
    '₹1 - 5 CR (MICRO)',
    '₹5 - 10 CR (SMALL)',
    '₹10 - 25 CR (SMALL)',
    '₹25 - 50 CR (SMALL)',
    '₹50 - 100 CR (MEDIUM)',
    '₹100 - 250 CR (MEDIUM)',
    '₹250 - 500 CR (MID-SIZE)',
    '₹500 - 1,000 CR (LARGE)',
    '₹1,000 - 5,000 CR (ENTERPRISE)',
    '₹5,000 - 10,000 CR (ENTERPRISE)',
    '> ₹10,000 CR (CONGLOMERATE)',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _gstNumberController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _noteController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      // Load countries and form configuration
      final countries = await csc.getAllCountries();
      final formConfig = await _companyService.getCompanyFormConfig();

      // Extract user records from form config
      final userIdsField = formConfig['context']?['pageLayout']?['body']?['form']?['fields']?['userIds'];
      final userRecords = userIdsField?['records'] as List<dynamic>? ?? [];

      // Convert to UserScreenModel list
      final allUsers = userRecords.map((record) {
        return UserScreenModel.fromJson(record as Map<String, dynamic>);
      }).toList();

      setState(() {
        _countries = countries;
        _allUsers = allUsers;
        _isLoadingData = false;
      });

      // If editing, populate fields first (including selected users)
      if (widget.isEdit && widget.companyData != null) {
        _populateFormFields();
      } else {
        // If creating, just load users normally
        _loadUsers();
      }
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Error loading data: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _populateFormFields() {
    final company = widget.companyData!;
    _nameController.text = company.name != '-' ? company.name : '';
    _emailController.text = company.email != '-' ? company.email : '';
    _websiteController.text = company.website != '-' ? company.website : '';
    _gstNumberController.text =
        company.gstNumber != '-' ? company.gstNumber : '';

    if (company.industry != '-') {
      _selectedIndustry = company.industry;
    }
    if (company.employees != '-') {
      _selectedEmployees = company.employees;
    }
    if (company.turnover != '-') {
      _selectedTurnover = company.turnover;
    }

    _isActive = company.isActive.toLowerCase() == 'active';

    // Populate selected users (no setState needed, _loadUsers will handle it)
    _selectedUserIds.clear();
    _selectedUserIds.addAll(company.users.map((user) => user.id));

    // Reload users to show selected ones first
    _loadUsers();

    // Set country, state, city if available
    if (company.country != '-') {
      final country = _countries.firstWhere(
        (c) => c.name.toLowerCase() == company.country.toLowerCase(),
        orElse: () => _countries.first,
      );
      _selectedCountryValue = country.isoCode;
      _onCountryChanged(country.isoCode);

      if (company.state != '-') {
        Future.delayed(const Duration(milliseconds: 100), () {
          final state = _states.firstWhere(
            (s) => s.name.toLowerCase() == company.state.toLowerCase(),
            orElse: () => _states.isNotEmpty ? _states.first : _states[0],
          );
          setState(() {
            _selectedStateValue = state.isoCode;
          });
          _onStateChanged(state.isoCode);

          if (company.city != '-') {
            Future.delayed(const Duration(milliseconds: 100), () {
              final city = _cities.firstWhere(
                (c) => c.name.toLowerCase() == company.city.toLowerCase(),
                orElse: () => _cities.isNotEmpty ? _cities.first : _cities[0],
              );
              setState(() {
                _selectedCityValue = city.name;
              });
            });
          }
        });
      }
    }
  }

  Future<void> _onCountryChanged(String? isoCode) async {
    if (isoCode == null) return;

    setState(() {
      _selectedCountryValue = isoCode;
      _selectedStateValue = null;
      _selectedCityValue = null;
      _states = [];
      _cities = [];
    });

    try {
      final states = await csc.getStatesOfCountry(isoCode);
      setState(() {
        _states = states;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Error loading states: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _onStateChanged(String? isoCode) async {
    if (isoCode == null || _selectedCountryValue == null) return;

    setState(() {
      _selectedStateValue = isoCode;
      _selectedCityValue = null;
      _cities = [];
    });

    try {
      final cities =
          await csc.getStateCities(_selectedCountryValue!, isoCode);
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Error loading cities: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _loadUsers() {
    setState(() {
      _isLoadingUsers = true;
    });

    try {
      // Create a copy of all users to avoid mutating the original list
      List<UserScreenModel> filteredUsers = List.from(_allUsers);

      if (_userSearchQuery.isNotEmpty) {
        final query = _userSearchQuery.toLowerCase();
        filteredUsers = filteredUsers.where((user) {
          // Search across all text fields
          final searchableText = [
            user.firstName,
            user.middleName,
            user.lastName,
            user.email,
            user.role,
            user.phone,
            user.company,
            user.designation,
            user.department,
            user.division,
            user.influenceType,
            user.employeeCode,
            user.groups,
            user.isActive,
            user.createdBy,
            user.createdAt,
          ].join(' ').toLowerCase();

          return searchableText.contains(query);
        }).toList();
      }

      // Separate into selected and unselected users
      final selected = filteredUsers.where((u) => _selectedUserIds.contains(u.id)).toList();
      final unselected = filteredUsers.where((u) => !_selectedUserIds.contains(u.id)).toList();

      // Calculate pagination for selected users
      final selectedTotal = selected.length;
      final selectedTotalPages = (selectedTotal / _usersTake).ceil();

      List<UserScreenModel> paginatedSelected = [];
      if (selectedTotal > 0) {
        final startIndex = (_selectedPage - 1) * _usersTake;
        final endIndex = startIndex + _usersTake;
        paginatedSelected = selected.sublist(
          startIndex.clamp(0, selectedTotal),
          endIndex > selectedTotal ? selectedTotal : endIndex,
        );
      }

      // Calculate pagination for unselected users
      final unselectedTotal = unselected.length;
      final unselectedTotalPages = (unselectedTotal / _usersTake).ceil();

      List<UserScreenModel> paginatedUnselected = [];
      if (unselectedTotal > 0) {
        final startIndex = (_unselectedPage - 1) * _usersTake;
        final endIndex = startIndex + _usersTake;
        paginatedUnselected = unselected.sublist(
          startIndex.clamp(0, unselectedTotal),
          endIndex > unselectedTotal ? unselectedTotal : endIndex,
        );
      }

      setState(() {
        _selectedUsers = paginatedSelected;
        _unselectedUsers = paginatedUnselected;
        _selectedTotal = selectedTotal;
        _unselectedTotal = unselectedTotal;
        _selectedTotalPages = selectedTotalPages > 0 ? selectedTotalPages : 1;
        _unselectedTotalPages = unselectedTotalPages > 0 ? unselectedTotalPages : 1;
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUsers = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Error loading users: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _onSelectedPageChanged(int page) {
    setState(() {
      _selectedPage = page;
    });
    _loadUsers();
  }

  void _onUnselectedPageChanged(int page) {
    setState(() {
      _unselectedPage = page;
    });
    _loadUsers();
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
    // Reload to move selected users to top
    _loadUsers();
  }

  void _toggleAllUsers(bool? value, bool isSelectedList) {
    setState(() {
      if (value == true) {
        if (isSelectedList) {
          _selectedUserIds.addAll(_selectedUsers.map((u) => u.id));
        } else {
          _selectedUserIds.addAll(_unselectedUsers.map((u) => u.id));
        }
      } else {
        if (isSelectedList) {
          _selectedUserIds.removeAll(_selectedUsers.map((u) => u.id));
        } else {
          _selectedUserIds.removeAll(_unselectedUsers.map((u) => u.id));
        }
      }
    });
    // Reload to update lists
    _loadUsers();
  }

  void _onUserSearchChanged(String query) {
    setState(() {
      _userSearchQuery = query;
      _selectedPage = 1; // Reset to first page when searching
      _unselectedPage = 1;
    });
    _loadUsers();
  }

  void _clearUserSearch() {
    _userSearchController.clear();
    setState(() {
      _userSearchQuery = '';
      _selectedPage = 1;
      _unselectedPage = 1;
    });
    _loadUsers();
  }

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) {
      CustomToast.show(
        context,
        'Please fill all required fields',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Build address object if any address field is filled
      Map<String, dynamic>? addressData;
      if (_selectedCountryValue != null ||
          _selectedStateValue != null ||
          _selectedCityValue != null ||
          _addressLine1Controller.text.trim().isNotEmpty ||
          _addressLine2Controller.text.trim().isNotEmpty) {
        addressData = {
          'countryIsoCode': _selectedCountryValue,
          'countryName': _selectedCountryValue != null
              ? _countries
                  .firstWhere((c) => c.isoCode == _selectedCountryValue)
                  .name
              : null,
          'stateIsoCode': _selectedStateValue,
          'stateName': _selectedStateValue != null
              ? _states.firstWhere((s) => s.isoCode == _selectedStateValue).name
              : null,
          'cityName': _selectedCityValue,
          'addressLine1': _addressLine1Controller.text.trim().isEmpty
              ? null
              : _addressLine1Controller.text.trim(),
          'addressLine2': _addressLine2Controller.text.trim().isEmpty
              ? null
              : _addressLine2Controller.text.trim(),
        };
      }

      // Build company data matching API structure
      final companyData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        'website': _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        'industry': _selectedIndustry,
        'employees': _selectedEmployees,
        'turnover': _selectedTurnover,
        'gstNumber': _gstNumberController.text.trim().isEmpty
            ? null
            : _gstNumberController.text.trim(),
        'isActive': _isActive,
        if (addressData != null) 'address': addressData,
        if (_noteController.text.trim().isNotEmpty)
          'note': _noteController.text.trim(),
        if (_selectedUserIds.isNotEmpty)
          'userIds': _selectedUserIds.toList(),
      };

      if (widget.isEdit && widget.companyData != null) {
        // Update existing company
        await _companyService.updateCompany(
          widget.companyData!.id,
          companyData,
        );
        if (mounted) {
          CustomToast.show(
            context,
            'Company updated successfully',
            type: ToastType.success,
          );
          Navigator.pop(context, true);
        }
      } else {
        // Create new company
        await _companyService.createCompany(companyData);
        if (mounted) {
          CustomToast.show(
            context,
            'Company created successfully',
            type: ToastType.success,
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Error: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEdit ? 'Edit Company' : 'Create Company'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          widget.isEdit ? 'Edit Company' : 'Create Company',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Information Section
                      _buildSectionTitle('Basic Information'),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _nameController,
                        label: 'Company Name',
                        hint: 'Enter company name',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Company name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter email address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _websiteController,
                        label: 'Website',
                        hint: 'Enter website URL',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 24),

                      // Company Details Section
                      _buildSectionTitle('Company Details'),
                      const SizedBox(height: 16),

                      CustomDropdown<String>(
                        label: 'Industry',
                        hint: 'Select industry',
                        value: _selectedIndustry,
                        items: _industries
                            .map((e) => DropdownItem(value: e, label: e))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedIndustry = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomDropdown<String>(
                        label: 'Number of Employees',
                        hint: 'Select employee range',
                        value: _selectedEmployees,
                        items: _employeeRanges
                            .map((e) => DropdownItem(value: e, label: e))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEmployees = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomDropdown<String>(
                        label: 'Annual Turnover',
                        hint: 'Select turnover range',
                        value: _selectedTurnover,
                        items: _turnoverRanges
                            .map((e) => DropdownItem(value: e, label: e))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTurnover = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _gstNumberController,
                        label: 'GST Number',
                        hint: 'Enter GST number',
                      ),
                      const SizedBox(height: 24),

                      // Location Section
                      _buildSectionTitle('Location'),
                      const SizedBox(height: 16),

                      CustomDropdown<String>(
                        label: 'Country',
                        hint: 'Select country',
                        value: _selectedCountryValue,
                        items: _countries
                            .map((c) =>
                                DropdownItem(value: c.isoCode, label: c.name))
                            .toList(),
                        onChanged: _onCountryChanged,
                      ),
                      const SizedBox(height: 16),

                      CustomDropdown<String>(
                        label: 'State',
                        hint: 'Select state',
                        value: _selectedStateValue,
                        items: _states
                            .map((s) =>
                                DropdownItem(value: s.isoCode, label: s.name))
                            .toList(),
                        onChanged: _onStateChanged,
                        isEnabled: _selectedCountryValue != null,
                      ),
                      const SizedBox(height: 16),

                      CustomDropdown<String>(
                        label: 'City',
                        hint: 'Select city',
                        value: _selectedCityValue,
                        items: _cities
                            .map((c) => DropdownItem(value: c.name, label: c.name))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCityValue = value;
                          });
                        },
                        isEnabled: _selectedStateValue != null,
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _addressLine1Controller,
                        label: 'Address Line 1',
                        hint: 'Enter address line 1',
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _addressLine2Controller,
                        label: 'Address Line 2',
                        hint: 'Enter address line 2',
                      ),
                      const SizedBox(height: 24),

                      // Status Section
                      _buildSectionTitle('Status'),
                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Active'),
                        subtitle: Text(
                          _isActive
                              ? 'Company is active'
                              : 'Company is inactive',
                          style: TextStyle(
                            color: _isActive
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                        activeThumbColor: AppColors.primary,
                      ),
                      const SizedBox(height: 24),

                      // Notes Section
                      _buildSectionTitle('Notes'),
                      const SizedBox(height: 16),

                      CustomTextField(
                        controller: _noteController,
                        label: 'Note',
                        hint: 'Enter additional notes',
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Users Section
                      _buildSectionTitle('Select Users'),
                      const SizedBox(height: 8),
                      Text(
                        '${_selectedUserIds.length} user(s) selected',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Search field
                      TextField(
                        controller: _userSearchController,
                        onChanged: _onUserSearchChanged,
                        decoration: InputDecoration(
                          hintText: 'Search users by name, email, or role...',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textSecondary,
                          ),
                          suffixIcon: _userSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: AppColors.textSecondary,
                                  ),
                                  onPressed: _clearUserSearch,
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.divider),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildUsersTable(),
                    ],
                  ),
                ),
              ),

              // Save Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: widget.isEdit ? 'Update Company' : 'Create Company',
                  onPressed: _isLoading ? null : _saveCompany,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.heading3.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildUsersTable() {
    if (_isLoadingUsers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_selectedUsers.isEmpty && _unselectedUsers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'No users found',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Users Section
        if (_selectedUsers.isNotEmpty) ...[
          Text(
            'Selected Users (${_selectedTotal})',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildUserTable(_selectedUsers, true),
          const SizedBox(height: 16),
          _buildPagination(_selectedPage, _selectedTotal, _selectedTotalPages, _onSelectedPageChanged),
          const SizedBox(height: 32),
        ],

        // Unselected Users Section
        if (_unselectedUsers.isNotEmpty) ...[
          Text(
            'Other Users (${_unselectedTotal})',
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildUserTable(_unselectedUsers, false),
          const SizedBox(height: 16),
          _buildPagination(_unselectedPage, _unselectedTotal, _unselectedTotalPages, _onUnselectedPageChanged),
        ],
      ],
    );
  }

  Widget _buildUserTable(List<UserScreenModel> users, bool isSelectedList) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            decoration: BoxDecoration(
              color: AppColors.divider.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(50),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Checkbox(
                        value: users.isNotEmpty &&
                            users.every((u) => _selectedUserIds.contains(u.id)),
                        onChanged: (value) => _toggleAllUsers(value, isSelectedList),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    _buildTableHeaderCell('Name'),
                    _buildTableHeaderCell('Email'),
                    _buildTableHeaderCell('Role'),
                    _buildTableHeaderCell('Company'),
                  ],
                ),
              ],
            ),
          ),
          // Table Body
          ...(users.asMap().entries.map((entry) {
            final index = entry.key;
            final user = entry.value;
            final isSelected = _selectedUserIds.contains(user.id);

            return Container(
              decoration: BoxDecoration(
                color: index.isEven
                    ? Colors.white
                    : AppColors.divider.withValues(alpha: 0.1),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.divider,
                    width: index == users.length - 1 ? 0 : 0.5,
                  ),
                ),
              ),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(50),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(1.5),
                  4: FlexColumnWidth(1.5),
                },
                children: [
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (value) => _toggleUserSelection(user.id),
                          activeColor: AppColors.primary,
                        ),
                      ),
                      _buildTableCell(
                        '${user.firstName} ${user.middleName != '-' ? '${user.middleName} ' : ''}${user.lastName}',
                      ),
                      _buildTableCell(user.email),
                      _buildTableCell(user.role),
                      _buildTableCell(user.company),
                    ],
                  ),
                ],
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textPrimary,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPagination(int currentPage, int total, int totalPages, Function(int) onPageChanged) {
    if (total == 0) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing ${(currentPage - 1) * _usersTake + 1}-${(currentPage * _usersTake > total) ? total : currentPage * _usersTake} of $total users',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: currentPage > 1
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              color: AppColors.primary,
            ),
            Text(
              'Page $currentPage of $totalPages',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: currentPage < totalPages
                  ? () => onPageChanged(currentPage + 1)
                  : null,
              color: AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }
}
