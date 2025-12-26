import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../services/theme_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';

class ThemeCreateScreen extends StatefulWidget {
  const ThemeCreateScreen({super.key});

  @override
  State<ThemeCreateScreen> createState() => _ThemeCreateScreenState();
}

class _ThemeCreateScreenState extends State<ThemeCreateScreen> {
  final ThemeService _themeService = GetIt.I<ThemeService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool? _isActive;
  bool _isLoading = false;
  int _nameCharCount = 0;
  final int _nameCharLimit = 24;

  @override
  void initState() {
    super.initState();
    // Set default value for status as per API response
    _isActive = true;

    // Listen to name field changes for character count
    _nameController.addListener(() {
      setState(() {
        _nameCharCount = _nameController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isActive == null) {
      CustomToast.show(
        context,
        'Please select status',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _themeService.createTheme(
        name: _nameController.text.trim(),
        isActive: _isActive!,
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        CustomToast.show(
          context,
          'Theme created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to create theme: ${e.toString()}',
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Theme',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          // Unfocus any focused widget when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Theme Name with Character Counter
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter name',
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter theme name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),

                        // Character count and warning
                        Row(
                          children: [
                            Text(
                              '$_nameCharCount characters',
                              style: TextStyle(
                                fontSize: 12,
                                color: _nameCharCount > _nameCharLimit
                                    ? AppColors.error
                                    : AppColors.grey,
                              ),
                            ),
                            if (_nameCharCount > _nameCharLimit) ...[
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Theme names longer than 24 characters will be truncated in WhatsApp messages',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Status Dropdown
                        CustomDropdown<bool>(
                          label: 'Status',
                          hint: 'Select status',
                          value: _isActive,
                          isRequired: true,
                          items: [
                            DropdownItem(
                              value: true,
                              label: 'Active',
                            ),
                            DropdownItem(
                              value: false,
                              label: 'Inactive',
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select status';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Description (Optional)
                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Enter description',
                          isRequired: false,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Sticky Submit Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: CustomButton(
                    text: 'Submit',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading,
                    icon: Icons.check,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
