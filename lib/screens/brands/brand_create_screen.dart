import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../services/brand_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';

class BrandCreateScreen extends StatefulWidget {
  const BrandCreateScreen({super.key});

  @override
  State<BrandCreateScreen> createState() => _BrandCreateScreenState();
}

class _BrandCreateScreenState extends State<BrandCreateScreen> {
  final BrandService _brandService = GetIt.I<BrandService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _aopController = TextEditingController();
  final _discountController = TextEditingController();

  bool? _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default value for status as per API response
    _isActive = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aopController.dispose();
    _discountController.dispose();
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
      // Parse optional number fields
      double? aop;
      double? discount;

      if (_aopController.text.trim().isNotEmpty) {
        aop = double.tryParse(_aopController.text.trim());
      }

      if (_discountController.text.trim().isNotEmpty) {
        discount = double.tryParse(_discountController.text.trim());
      }

      await _brandService.createBrand(
        name: _nameController.text.trim(),
        isActive: _isActive!,
        aop: aop,
        discount: discount,
      );

      if (mounted) {
        CustomToast.show(
          context,
          'Brand created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to create brand: ${e.toString()}',
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
          'Create Brand',
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
                        // Brand Name
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter brand name',
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter brand name';
                            }
                            return null;
                          },
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

                        // AOP % (Optional)
                        CustomTextField(
                          controller: _aopController,
                          label: 'AOP %',
                          hint: 'Enter AOP percentage (0-100)',
                          isRequired: false,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final number = double.tryParse(value.trim());
                              if (number == null) {
                                return 'Please enter a valid number';
                              }
                              if (number < 0 || number > 100) {
                                return 'AOP % must be between 0 and 100';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Discount (Optional)
                        CustomTextField(
                          controller: _discountController,
                          label: 'Discount to AGS from Brand',
                          hint: 'Enter Discount percentage (0-100)',
                          isRequired: false,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final number = double.tryParse(value.trim());
                              if (number == null) {
                                return 'Please enter a valid number';
                              }
                              if (number < 0 || number > 100) {
                                return 'Discount must be between 0 and 100';
                              }
                            }
                            return null;
                          },
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
