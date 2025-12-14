import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../services/inquiry_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_toast.dart';

class InquiryCreateScreen extends StatefulWidget {
  const InquiryCreateScreen({Key? key}) : super(key: key);

  @override
  State<InquiryCreateScreen> createState() => _InquiryCreateScreenState();
}

class _InquiryCreateScreenState extends State<InquiryCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final InquiryService _inquiryService = GetIt.I<InquiryService>();

  // Form controllers
  final _inquiryNameController = TextEditingController();
  final _noteController = TextEditingController();

  // Dropdown values
  String? _selectedCompanyId;
  String? _selectedContactPersonId;
  String? _selectedStatus;

  // Dropdown data
  List<CompanyDropdownModel> _companies = [];
  List<UserDropdownModel> _contactPersons = [];
  List<UserDropdownModel> _filteredContactPersons = [];

  // Status options
  final List<String> _statusOptions = [
    'Open',
    'In Progress',
    'On Hold',
    'Closed',
    'Won',
    'Lost',
  ];

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _inquiryNameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final companies = await _inquiryService.getActiveCompanies();
      final users = await _inquiryService.getActiveUsers();

      setState(() {
        _companies = companies;
        _contactPersons = users;
        _filteredContactPersons = users;
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    }
  }

  void _onCompanyChanged(String? companyId) {
    setState(() {
      _selectedCompanyId = companyId;
      _selectedContactPersonId = null; // Reset contact person when company changes

      if (companyId != null) {
        // Filter contact persons by selected company
        final selectedCompany = _companies.firstWhere((c) => c.id == companyId);
        _filteredContactPersons = selectedCompany.users;
      } else {
        _filteredContactPersons = _contactPersons;
      }
    });
  }

  Future<void> _createInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'name': _inquiryNameController.text.trim(),
        'companyId': _selectedCompanyId,
        'contactUserId': _selectedContactPersonId,
        'status': _selectedStatus,
        'note': _noteController.text.trim(),
      };

      await _inquiryService.createInquiry(data);

      if (mounted) {
        CustomToast.show(
          context,
          'Inquiry created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Inquiry',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : GestureDetector(
              onTap: () {
                // Unfocus any focused widget when tapping outside
                FocusScope.of(context).unfocus();
              },
              child: SafeArea(
                bottom: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    // Inquiry Name
                    Row(
                      children: [
                        const Text(
                          'Inquiry Name',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text('*', style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                        ),)
                      ],
                    ),
                    const SizedBox(height: 4),

                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _inquiryNameController,
                      label: '',
                      hint: 'Enter inquiry name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Inquiry name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Company
                    CustomDropdown<String>(
                      label: 'Company',
                      hint: 'Select Company',
                      value: _selectedCompanyId,
                      items: _companies.map((company) {
                        return DropdownItem(
                          value: company.id,
                          label: company.name,
                        );
                      }).toList(),
                      onChanged: _onCompanyChanged,
                      isRequired: true,
                      validator: (value) {
                        if (value == null) {
                          return 'Company is required';
                        }
                        return null;
                      },
                      onClear: () {
                        _onCompanyChanged(null);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Contact Person
                    CustomDropdown<String>(
                      label: 'Contact Person',
                      hint: 'Select Contact Person',
                      value: _selectedContactPersonId,
                      items: _filteredContactPersons.map((user) {
                        return DropdownItem(
                          value: user.id,
                          label: user.fullName,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedContactPersonId = value;
                        });
                      },
                      isRequired: true,
                      validator: (value) {
                        if (value == null) {
                          return 'Contact person is required';
                        }
                        return null;
                      },
                      onClear: () {
                        setState(() {
                          _selectedContactPersonId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Status
                    CustomDropdown<String>(
                      label: 'Status',
                      hint: 'Select Status',
                      value: _selectedStatus,
                      items: _statusOptions.map((status) {
                        return DropdownItem(
                          value: status,
                          label: status,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value;
                        });
                      },
                      isRequired: false,
                    ),
                    const SizedBox(height: 24),

                    // Note
                    const Text(
                      'Note',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Enter notes',
                        hintStyle: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.lightGrey),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.lightGrey),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Buttons
                    CustomButton(
                      text: 'Submit',
                      onPressed: _createInquiry,
                      isLoading: _isLoading,
                      icon: Icons.check,
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Cancel',
                      onPressed: () => Navigator.pop(context),
                      variant: ButtonVariant.outline,
                      icon: Icons.close,
                    ),
                    const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
