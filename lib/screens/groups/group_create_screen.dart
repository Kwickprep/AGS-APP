import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/contact_model.dart';
import '../../services/group_service.dart';
import '../../widgets/contact_selection_table.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';

class GroupCreateScreen extends StatefulWidget {
  const GroupCreateScreen({Key? key}) : super(key: key);

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final GroupService _groupService = GetIt.I<GroupService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isLoadingContacts = true;
  List<ContactModel> _contacts = [];
  List<String> _selectedContactIds = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoadingContacts = true;
      _errorMessage = null;
    });

    try {
      final contacts = await _groupService.getContacts();
      setState(() {
        _contacts = contacts;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load contacts: ${e.toString()}';
        _isLoadingContacts = false;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedContactIds.isEmpty) {
      CustomToast.show(
        context,
        'Please select at least one contact',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _groupService.createGroup(
        name: _nameController.text.trim(),
        isActive: _isActive,
        note: _noteController.text.trim(),
        userIds: _selectedContactIds,
      );

      if (mounted) {
        CustomToast.show(
          context,
          'Group created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to create group: ${e.toString()}',
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
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Create Group',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: _isLoadingContacts
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Retry',
                        onPressed: _loadContacts,
                        width: 120,
                        icon: Icons.refresh,
                      ),
                    ],
                  ),
                )
              : GestureDetector(
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
                        // Group Name
                        CustomTextField(
                          controller: _nameController,
                          label: 'Group Name',
                          hint: 'Enter group name',
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter group name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Status Dropdown
                        CustomDropdown<bool>(
                          label: 'Status',
                          hint: 'Select Status',
                          value: _isActive,
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
                            if (value != null) {
                              setState(() {
                                _isActive = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // Note
                        CustomTextField(
                          controller: _noteController,
                          label: 'Note',
                          hint: 'Enter note (optional)',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        // Contact Selection
                        const Text(
                          'Select Contacts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ContactSelectionTable(
                          contacts: _contacts,
                          selectedContactIds: _selectedContactIds,
                          onSelectionChanged: (selectedIds) {
                            setState(() {
                              _selectedContactIds = selectedIds;
                            });
                          },
                        ),
                        const SizedBox(height: 100),
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
                              color: Colors.black.withOpacity(0.1),
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
                )
    );
  }
}
