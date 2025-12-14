import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../services/activity_service.dart';
import '../../services/file_upload_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_toast.dart';
import 'theme_selection_screen.dart';

class ActivityCreateScreen extends StatefulWidget {
  const ActivityCreateScreen({Key? key}) : super(key: key);

  @override
  State<ActivityCreateScreen> createState() => _ActivityCreateScreenState();
}

class _ActivityCreateScreenState extends State<ActivityCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ActivityService _activityService = GetIt.I<ActivityService>();
  final FileUploadService _fileUploadService = GetIt.I<FileUploadService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _activityNoteController = TextEditingController();
  final _nextScheduleNoteController = TextEditingController();
  final _nextScheduleDateController = TextEditingController();
  final _requirementsController = TextEditingController();

  // Dropdown values
  String? _selectedActivityTypeId;
  String? _selectedInquiryId;
  String? _selectedCompanyId;
  String? _selectedUserId;
  bool _scheduledCallCompleted = false;

  // Dropdown data
  List<ActivityTypeModel> _activityTypes = [];
  List<InquiryDropdownModel> _inquiries = [];
  List<CompanyDropdownModel> _companies = [];
  List<UserDropdownModel> _users = [];
  List<UserDropdownModel> _filteredUsers = [];

  // Image upload
  List<File> _selectedImages = [];
  List<String> _uploadedDocumentIds = [];
  bool _isUploadingImages = false;

  bool _isLoading = false;
  bool _isLoadingData = true;

  // Check if selected activity type is "Product Search"
  bool get _isProductSearch {
    if (_selectedActivityTypeId == null) return false;
    final selectedType = _activityTypes.firstWhere(
      (type) => type.id == _selectedActivityTypeId,
      orElse: () => ActivityTypeModel(
        id: '',
        name: '',
        isActive: false,
        isDefault: false,
      ),
    );
    return selectedType.name.toLowerCase().contains('product search');
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _activityNoteController.dispose();
    _nextScheduleNoteController.dispose();
    _nextScheduleDateController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final activityTypes = await _activityService.getActivityTypes();
      final inquiries = await _activityService.getInquiries();
      final companies = await _activityService.getActiveCompanies();
      final users = await _activityService.getActiveUsers();

      setState(() {
        _activityTypes = activityTypes;
        _inquiries = inquiries;
        _companies = companies;
        _users = users;
        _filteredUsers = users;
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
      _selectedUserId = null;

      if (companyId != null) {
        final selectedCompany = _companies.firstWhere((c) => c.id == companyId);
        _filteredUsers = selectedCompany.users;
      } else {
        _filteredUsers = _users;
      }
    });
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _nextScheduleDateController.text =
            '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      });
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage();

      if (images != null && images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)).toList());
        });

        // Upload images immediately to get document IDs
        await _uploadImages();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to pick images: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final documentIds = await _fileUploadService.uploadMultipleFiles(_selectedImages);
      setState(() {
        _uploadedDocumentIds = documentIds;
        _isUploadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to upload images: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _uploadedDocumentIds.length) {
        _uploadedDocumentIds.removeAt(index);
      }
    });
  }

  Future<void> _createActivity() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate Product Search requirements
    if (_isProductSearch) {
      final hasText = _requirementsController.text.trim().isNotEmpty;
      final hasImages = _uploadedDocumentIds.isNotEmpty;

      if (!hasText && !hasImages) {
        CustomToast.show(
          context,
          'Please provide either text requirements or upload images',
          type: ToastType.error,
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> data;

      if (_isProductSearch) {
        // Product Search activity format
        data = {
          'activityTypeId': _selectedActivityTypeId,
          'companyId': _selectedCompanyId,
          'inquiryId': _selectedInquiryId,
          'userId': _selectedUserId,
          'body': {
            'inputText': _requirementsController.text.trim(),
            'documentIds': _uploadedDocumentIds,
            'stage': 'INITIAL',
          },
        };
      } else {
        // Standard activity format
        data = {
          'activityTypeId': _selectedActivityTypeId,
          'inquiryId': _selectedInquiryId,
          'companyId': _selectedCompanyId,
          'userId': _selectedUserId,
          'activityNote': _activityNoteController.text.trim(),
          'nextScheduleNote': _nextScheduleNoteController.text.trim(),
          'nextScheduleDate': _nextScheduleDateController.text.trim(),
          'scheduledCallCompleted': _scheduledCallCompleted,
        };
      }

      final createdActivityRecord = await _activityService.createActivity(data);

      if (mounted) {
        if (_isProductSearch) {
          // For Product Search, navigate to theme selection screen
          final body = createdActivityRecord['body'] as Map<String, dynamic>?;
          final aiSuggestedThemes = body?['aiSuggestedThemes'];

          if (aiSuggestedThemes != null && aiSuggestedThemes is List && aiSuggestedThemes.isNotEmpty) {
            // Navigate to theme selection screen
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ThemeSelectionScreen(
                  activityId: createdActivityRecord['id'] as String,
                  aiSuggestedThemes: aiSuggestedThemes,
                ),
              ),
            );

            // If theme was selected successfully, pop this screen too
            if (result == true && mounted) {
              Navigator.pop(context, true);
            }
          } else {
            CustomToast.show(
              context,
              'Activity created successfully',
              type: ToastType.success,
            );
            Navigator.pop(context, true);
          }
        } else {
          // For standard activities, just show success and pop
          CustomToast.show(
            context,
            'Activity created successfully',
            type: ToastType.success,
          );
          Navigator.pop(context, true);
        }
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
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '1',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Activity Details',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
                    // Activity Type
                    CustomDropdown<String>(
                      label: 'Activity Type',
                      hint: 'Select Activity Type',
                      value: _selectedActivityTypeId,
                      items: _activityTypes.map((type) {
                        return DropdownItem(
                          value: type.id,
                          label: type.name,
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedActivityTypeId = value;
                        });
                      },
                      isRequired: true,
                      validator: (value) {
                        if (value == null) {
                          return 'Activity type is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Always show basic dropdowns
                    _buildBasicDropdowns(),

                    // Conditional rendering based on activity type selection
                    if (_selectedActivityTypeId != null) ...[
                      const SizedBox(height: 24),
                      if (_isProductSearch) ...[
                        // Requirements field for Product Search
                        _buildRequirementsField(),
                      ] else ...[
                        // Standard fields for other activity types
                        _buildStandardFields(),
                      ],
                    ],

                    // Buttons
                    const SizedBox(height: 32),
                    CustomButton(
                      text: 'Submit',
                      onPressed: _createActivity,
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

  Widget _buildBasicDropdowns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Inquiry
        CustomDropdown<String>(
          label: 'Inquiry',
          hint: 'Select Inquiry',
          value: _selectedInquiryId,
          items: _inquiries.map((inquiry) {
            return DropdownItem(
              value: inquiry.id,
              label: inquiry.name,
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedInquiryId = value;
            });
          },
          isRequired: false,
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
          isRequired: false,
          onClear: () {
            _onCompanyChanged(null);
          },
        ),
        const SizedBox(height: 24),

        // User
        CustomDropdown<String>(
          label: 'User',
          hint: 'Select User',
          value: _selectedUserId,
          items: _filteredUsers.map((user) {
            return DropdownItem(
              value: user.id,
              label: user.fullName,
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedUserId = value;
            });
          },
          isRequired: false,
          onClear: () {
            setState(() {
              _selectedUserId = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStandardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Activity Note
        const Text(
          'Activity Note',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _activityNoteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter activity notes',
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
        const SizedBox(height: 24),

        // Next Schedule Note
        const Text(
          'Next Schedule Note',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nextScheduleNoteController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter note',
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
        const SizedBox(height: 24),

        // Next Schedule Date
        const Text(
          'Next Schedule Date',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nextScheduleDateController,
          readOnly: true,
          onTap: _selectDate,
          decoration: InputDecoration(
            hintText: 'Select date',
            hintStyle: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.grey),
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
        const SizedBox(height: 24),

        // Scheduled Call Completed Toggle
        Row(
          children: [
            Switch(
              value: _scheduledCallCompleted,
              onChanged: (value) {
                setState(() {
                  _scheduledCallCompleted = value;
                });
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: 12),
            const Text(
              'Scheduled Call Completed',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRequirementsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            text: 'Describe your requirements',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            children: [
              TextSpan(
                text: ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _requirementsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'E.g., Looking for corporate gifts for 100 employees, budget around 500 per piece...',
            hintStyle: const TextStyle(
              color: AppColors.grey,
              fontSize: 14,
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.attach_file, color: AppColors.grey),
              onPressed: _pickImages,
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Image upload status
        if (_isUploadingImages)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Uploading images...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

        // Selected images preview
        if (_selectedImages.isNotEmpty && !_isUploadingImages) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _selectedImages.asMap().entries.map((entry) {
              final index = entry.key;
              final image = entry.value;

              return Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.lightGrey),
                      image: DecorationImage(
                        image: FileImage(image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
