import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/tag_model.dart';
import '../../services/tag_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';

class TagCreateScreen extends StatefulWidget {
  final bool isEdit;
  final TagModel? tagData;

  const TagCreateScreen({super.key, this.isEdit = false, this.tagData});

  @override
  State<TagCreateScreen> createState() => _TagCreateScreenState();
}

class _TagCreateScreenState extends State<TagCreateScreen> {
  final TagService _tagService = GetIt.I<TagService>();
  final StorageService _storageService = GetIt.I<StorageService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  bool? _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.tagData != null) {
      _nameController.text = widget.tagData!.name;
      _isActive = widget.tagData!.isActive;
    } else {
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      if (widget.isEdit && widget.tagData != null) {
        final currentUser = await _storageService.getUser();
        final currentUserId = currentUser?.id ?? widget.tagData!.createdBy;
        final currentTimestamp = DateTime.now().toUtc().toString();

        await _tagService.updateTag(
          id: widget.tagData!.id,
          name: _nameController.text.trim(),
          isActive: _isActive!,
          createdBy: widget.tagData!.createdBy,
          createdAt: widget.tagData!.createdAt,
          updatedBy: currentUserId,
          updatedAt: currentTimestamp,
        );
      } else {
        await _tagService.createTag(
          name: _nameController.text.trim(),
          isActive: _isActive!,
        );
      }

      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit ? 'Tag updated successfully' : 'Tag created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit ? 'Failed to update tag' : 'Failed to create tag: ${e.toString()}',
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
        title: Text(
          widget.isEdit ? 'Edit Tag' : 'Create Tag',
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
                        // Tag Name
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter tag name',
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter tag name';
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
                    text: widget.isEdit ? 'Update' : 'Submit',
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
