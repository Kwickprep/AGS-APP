import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/contact_model.dart';
import '../../models/group_model.dart';
import '../../services/group_service.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_button.dart';

class GroupCreateScreen extends StatefulWidget {
  final GroupModel? group;
  final bool isEdit;

  const GroupCreateScreen({super.key, this.group, this.isEdit = false});

  @override
  State<GroupCreateScreen> createState() => _GroupCreateScreenState();
}

class _GroupCreateScreenState extends State<GroupCreateScreen> {
  final GroupService _groupService = GetIt.I<GroupService>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  final TextEditingController _contactSearchController = TextEditingController();

  bool? _isActive;
  bool _isLoading = false;
  bool _isLoadingContacts = true;
  List<ContactModel> _contacts = [];
  List<String> _selectedContactIds = [];
  String? _errorMessage;

  // Contact search and pagination
  Timer? _contactSearchDebounce;
  String _contactSearchQuery = '';
  int _contactsCurrentPage = 1;
  final int _contactsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    if (widget.isEdit && widget.group != null) {
      _prefillFormData();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    _contactSearchController.dispose();
    _contactSearchDebounce?.cancel();
    super.dispose();
  }

  void _prefillFormData() async {
    final group = widget.group!;

    // Set basic form fields
    _nameController.text = group.name;
    _isActive = group.isActive;
    if (group.note.isNotEmpty && group.note != '-') {
      _noteController.text = group.note;
    }

    // Fetch group details to get user IDs
    try {
      final userIds = await _groupService.getGroupUserIds(group.id);
      setState(() {
        _selectedContactIds = userIds;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to load group contacts: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
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

    if (_isActive == null) {
      CustomToast.show(
        context,
        'Please select status',
        type: ToastType.error,
      );
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
      if (widget.isEdit) {
        await _groupService.updateGroup(
          id: widget.group!.id,
          name: _nameController.text.trim(),
          isActive: _isActive!,
          note: _noteController.text.trim(),
          userIds: _selectedContactIds,
        );
      } else {
        await _groupService.createGroup(
          name: _nameController.text.trim(),
          isActive: _isActive!,
          note: _noteController.text.trim(),
          userIds: _selectedContactIds,
        );
      }

      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit
              ? 'Group updated successfully'
              : 'Group created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit
              ? 'Failed to update group: ${e.toString()}'
              : 'Failed to create group: ${e.toString()}',
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

  void _onContactSearchChanged(String value) {
    // Cancel previous timer
    _contactSearchDebounce?.cancel();

    // Set new timer - wait 500ms before searching
    _contactSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _contactSearchQuery = value.trim();
        _contactsCurrentPage = 1;
      });
    });
  }

  List<ContactModel> _getFilteredContacts() {
    if (_contactSearchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      final query = _contactSearchQuery.toLowerCase();
      return contact.fullName.toLowerCase().contains(query) ||
          (contact.email?.toLowerCase().contains(query) ?? false) ||
          contact.displayPhone.contains(query);
    }).toList();
  }

  List<ContactModel> _getPaginatedContacts() {
    final filtered = _getFilteredContacts();
    final startIndex = (_contactsCurrentPage - 1) * _contactsPerPage;
    final endIndex = startIndex + _contactsPerPage;
    if (startIndex >= filtered.length) return [];
    return filtered.sublist(
      startIndex,
      endIndex > filtered.length ? filtered.length : endIndex,
    );
  }

  int _getTotalContactPages() {
    final filtered = _getFilteredContacts();
    return (filtered.length / _contactsPerPage).ceil();
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
          widget.isEdit ? 'Edit Group' : 'Create Group',
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

                        // Note
                        CustomTextField(
                          controller: _noteController,
                          label: 'Note',
                          hint: 'Enter note (optional)',
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        // Contact Selection
                        _buildContactsSection(),
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
                )
    );
  }

  Widget _buildContactsSection() {
    final filteredContacts = _getFilteredContacts();
    final paginatedContacts = _getPaginatedContacts();
    final totalPages = _getTotalContactPages();

    // Check if all contacts on current page are selected
    final currentPageIds = paginatedContacts.map((c) => c.id).toSet();
    final allCurrentPageSelected = paginatedContacts.isNotEmpty &&
        currentPageIds.every((id) => _selectedContactIds.contains(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Text(
              'Select Contacts',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search field
        TextField(
          controller: _contactSearchController,
          decoration: InputDecoration(
            hintText: 'Search contacts by name, email, or phone...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _contactSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _contactSearchController.clear();
                      _contactSearchDebounce?.cancel();
                      setState(() {
                        _contactSearchQuery = '';
                        _contactsCurrentPage = 1;
                      });
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: _onContactSearchChanged,
        ),
        const SizedBox(height: 12),

        // Results count and selected count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (filteredContacts.isNotEmpty)
              Text(
                'Showing ${(_contactsCurrentPage - 1) * _contactsPerPage + 1}-${(_contactsCurrentPage - 1) * _contactsPerPage + paginatedContacts.length} of ${filteredContacts.length}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight.withValues(alpha: 0.7),
                ),
              ),
            if (_selectedContactIds.isNotEmpty)
              Text(
                '${_selectedContactIds.length} contact(s) selected',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Contacts table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    // Select All checkbox
                    SizedBox(
                      width: 40,
                      child: Checkbox(
                        value: allCurrentPageSelected,
                        onChanged: paginatedContacts.isEmpty
                            ? null
                            : (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    // Select all on current page
                                    for (var contact in paginatedContacts) {
                                      if (!_selectedContactIds
                                          .contains(contact.id)) {
                                        _selectedContactIds.add(contact.id);
                                      }
                                    }
                                  } else {
                                    // Deselect all on current page
                                    for (var contact in paginatedContacts) {
                                      _selectedContactIds.remove(contact.id);
                                    }
                                  }
                                });
                              },
                        activeColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(
                      width: 40,
                      child: Text(
                        'No.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Contact Name',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      flex: 1,
                      child: Text(
                        'Phone',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Table rows
              if (paginatedContacts.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No contacts found',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textLight.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: paginatedContacts.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = paginatedContacts[index];
                    final serialNumber =
                        (_contactsCurrentPage - 1) * _contactsPerPage +
                            index +
                            1;
                    final isSelected = _selectedContactIds.contains(contact.id);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          SizedBox(
                            width: 40,
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedContactIds.add(contact.id);
                                  } else {
                                    _selectedContactIds.remove(contact.id);
                                  }
                                });
                              },
                              activeColor: AppColors.primary,
                            ),
                          ),

                          // Serial number
                          SizedBox(
                            width: 40,
                            child: Text(
                              '$serialNumber.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),

                          // Contact name
                          Expanded(
                            flex: 2,
                            child: Text(
                              contact.fullName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Email
                          Expanded(
                            flex: 2,
                            child: Text(
                              contact.email ?? '-',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textLight.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Phone
                          Expanded(
                            flex: 1,
                            child: Text(
                              contact.displayPhone,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textLight.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),

        // Pagination controls
        if (totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              IconButton(
                onPressed: _contactsCurrentPage > 1
                    ? () {
                        setState(() {
                          _contactsCurrentPage--;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textPrimary,
                disabledColor: AppColors.textLight.withValues(alpha: 0.3),
              ),

              // Page numbers
              ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
                int pageNumber;
                if (totalPages <= 5) {
                  pageNumber = index + 1;
                } else if (_contactsCurrentPage <= 3) {
                  pageNumber = index + 1;
                } else if (_contactsCurrentPage >= totalPages - 2) {
                  pageNumber = totalPages - 4 + index;
                } else {
                  pageNumber = _contactsCurrentPage - 2 + index;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _contactsCurrentPage = pageNumber;
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: pageNumber == _contactsCurrentPage
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: pageNumber == _contactsCurrentPage
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: pageNumber == _contactsCurrentPage
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Next button
              IconButton(
                onPressed: _contactsCurrentPage < totalPages
                    ? () {
                        setState(() {
                          _contactsCurrentPage++;
                        });
                      }
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textPrimary,
                disabledColor: AppColors.textLight.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
