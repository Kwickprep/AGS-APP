import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/activity_type_model.dart';
import '../../models/form_page_layout_model.dart';
import '../../services/activity_type_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dynamic_form_builder.dart';

class ActivityTypeCreateScreen extends StatefulWidget {
  final bool isEdit;
  final ActivityTypeModel? activityTypeData;

  const ActivityTypeCreateScreen({
    super.key,
    this.isEdit = false,
    this.activityTypeData,
  });

  @override
  State<ActivityTypeCreateScreen> createState() =>
      _ActivityTypeCreateScreenState();
}

class _ActivityTypeCreateScreenState extends State<ActivityTypeCreateScreen> {
  final ActivityTypeService _activityTypeService =
      GetIt.I<ActivityTypeService>();
  final StorageService _storageService = GetIt.I<StorageService>();
  final _formKey = GlobalKey<FormState>();

  // State variables
  bool _isLoading = false;
  bool _isLoadingLayout = true;
  FormPageLayoutResponse? _layoutResponse;

  // Form data
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    _loadFormLayout();
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadFormLayout() async {
    setState(() {
      _isLoadingLayout = true;
    });

    try {
      // Use 'none' for create, or actual ID for edit
      final id = widget.isEdit && widget.activityTypeData != null
          ? widget.activityTypeData!.id
          : 'none';

      final layoutResponse = await _activityTypeService.getFormPageLayout(id);

      setState(() {
        _layoutResponse = layoutResponse;
        _isLoadingLayout = false;
      });

      // Initialize controllers and values after layout is loaded
      _initializeFormData();
    } catch (e) {
      setState(() {
        _isLoadingLayout = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to load form: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _initializeFormData() {
    if (_layoutResponse?.context?.pageLayout.body.form == null) return;

    final formConfig = _layoutResponse!.context!.pageLayout.body.form;
    final fields = formConfig.fields;

    fields.forEach((fieldName, fieldConfig) {
      // Initialize controllers for text fields
      if (fieldConfig.isTextField) {
        final controller = TextEditingController();

        // Set default value or prefill from edit data
        if (widget.isEdit && widget.activityTypeData != null) {
          if (fieldName == 'name') {
            controller.text = widget.activityTypeData!.name;
          }
        } else if (fieldConfig.defaultValue != null) {
          controller.text = fieldConfig.defaultValue.toString();
        }

        _controllers[fieldName] = controller;
        _formValues[fieldName] = controller.text;
      }

      // Initialize values for dropdowns
      if (fieldConfig.isDropdown) {
        if (widget.isEdit && widget.activityTypeData != null) {
          if (fieldName == 'isActive') {
            _formValues[fieldName] = widget.activityTypeData!.isActive;
          }
        } else {
          _formValues[fieldName] = fieldConfig.defaultValue;
        }
      }

      // Initialize hidden fields
      if (!fieldConfig.isVisible) {
        if (widget.isEdit && widget.activityTypeData != null) {
          switch (fieldName) {
            case 'id':
              _formValues[fieldName] = widget.activityTypeData!.id;
              break;
            case 'createdBy':
              _formValues[fieldName] = widget.activityTypeData!.createdBy;
              break;
            case 'createdAt':
              _formValues[fieldName] = widget.activityTypeData!.createdAt;
              break;
            case 'updatedBy':
              _formValues[fieldName] = widget.activityTypeData?.updatedBy ?? '';
              break;
            case 'updatedAt':
              _formValues[fieldName] = widget.activityTypeData?.updatedAt ?? '';
              break;
          }
        } else {
          _formValues[fieldName] = fieldConfig.defaultValue ?? '';
        }
      }
    });
  }

  void _onFieldChanged(String fieldName, dynamic value) {
    setState(() {
      _formValues[fieldName] = value;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    final formConfig = _layoutResponse?.context?.pageLayout.body.form;
    if (formConfig != null) {
      for (var field in formConfig.getVisibleFields()) {
        if (field.isRequired) {
          final value = _formValues[field.fieldName];
          if (value == null || (value is String && value.trim().isEmpty)) {
            CustomToast.show(
              context,
              'Please fill in all required fields',
              type: ToastType.error,
            );
            return;
          }
        }
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isEdit && widget.activityTypeData != null) {
        // Get current user for updatedBy
        final currentUser = await _storageService.getUser();
        final currentUserId = currentUser?.id ?? widget.activityTypeData!.createdBy;
        final currentTimestamp = DateTime.now().toUtc().toIso8601String();

        await _activityTypeService.updateActivityType(
          id: widget.activityTypeData!.id,
          name: _formValues['name']?.toString().trim() ?? '',
          isActive: _formValues['isActive'] ?? true,
          createdBy: widget.activityTypeData!.createdBy,
          createdAt: widget.activityTypeData!.createdAt,
          updatedBy: currentUserId,
          updatedAt: currentTimestamp,
        );
      } else {
        await _activityTypeService.createActivityType(
          name: _formValues['name']?.toString().trim() ?? '',
          isActive: _formValues['isActive'] ?? true,
        );
      }

      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit
              ? 'Activity type updated successfully'
              : 'Activity type created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit
              ? 'Failed to update activity type: ${e.toString()}'
              : 'Failed to create activity type: ${e.toString()}',
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

  void _handleReset() {
    // Reset form to default values
    final formConfig = _layoutResponse?.context?.pageLayout.body.form;
    if (formConfig == null) return;

    setState(() {
      formConfig.fields.forEach((fieldName, fieldConfig) {
        if (fieldConfig.isTextField) {
          _controllers[fieldName]?.text =
              fieldConfig.defaultValue?.toString() ?? '';
          _formValues[fieldName] = _controllers[fieldName]?.text ?? '';
        } else if (fieldConfig.isDropdown) {
          _formValues[fieldName] = fieldConfig.defaultValue;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final pageLayout = _layoutResponse?.context?.pageLayout;
    final title = pageLayout?.header.title ??
        (widget.isEdit ? 'Edit Activity Type' : 'Create Activity Type');

    if (_isLoadingLayout) {
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
          title: Text(
            title,
            style: const TextStyle(
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_layoutResponse == null || pageLayout == null) {
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
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Failed to load form'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFormLayout,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final formConfig = pageLayout.body.form;
    final hasResetAction = pageLayout.footer?.actions
            .any((action) => action.isReset) ??
        false;

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
        title: Text(
          title,
          style: const TextStyle(
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
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              // Scrollable form content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: DynamicFormBuilder(
                      formConfig: formConfig,
                      controllers: _controllers,
                      values: _formValues,
                      onFieldChanged: _onFieldChanged,
                    ),
                  ),
                ),
              ),

              // Sticky footer with action buttons
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
                  child: Row(
                    children: [
                      // Reset button (if configured)
                      if (hasResetAction) ...[
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : _handleReset,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      // Submit button
                      Expanded(
                        child: CustomButton(
                          text: widget.isEdit ? 'Update' : 'Submit',
                          onPressed: _handleSubmit,
                          isLoading: _isLoading,
                          icon: Icons.check,
                        ),
                      ),
                    ],
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
