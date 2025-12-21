import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/contact_model.dart';

class ContactSelectionTable extends StatefulWidget {
  final List<ContactModel> contacts;
  final List<String> selectedContactIds;
  final Function(List<String>) onSelectionChanged;

  const ContactSelectionTable({
    super.key,
    required this.contacts,
    required this.selectedContactIds,
    required this.onSelectionChanged,
  });

  @override
  State<ContactSelectionTable> createState() => _ContactSelectionTableState();
}

class _ContactSelectionTableState extends State<ContactSelectionTable> {
  final TextEditingController _searchController = TextEditingController();
  List<ContactModel> _filteredContacts = [];
  String _sortColumn = '';
  bool _sortAscending = true;
  int _currentPage = 1;
  final int _itemsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts.where((contact) {
          return contact.fullName.toLowerCase().contains(query) ||
              contact.email?.toLowerCase().contains(query) == true ||
              contact.displayPhone.contains(query);
        }).toList();
      }
      _applySorting();
    });
  }

  void _sortByColumn(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _applySorting();
    });
  }

  void _applySorting() {
    if (_sortColumn.isEmpty) return;

    _filteredContacts.sort((a, b) {
      int comparison = 0;
      switch (_sortColumn) {
        case 'firstName':
          comparison = a.firstName.compareTo(b.firstName);
          break;
        case 'middleName':
          comparison = (a.middleName ?? '').compareTo(b.middleName ?? '');
          break;
        case 'lastName':
          comparison = (a.lastName ?? '').compareTo(b.lastName ?? '');
          break;
        case 'email':
          comparison = (a.email ?? '').compareTo(b.email ?? '');
          break;
        case 'phone':
          comparison = a.displayPhone.compareTo(b.displayPhone);
          break;
        case 'role':
          comparison = a.role.compareTo(b.role);
          break;
        case 'company':
          comparison = (a.company ?? '').compareTo(b.company ?? '');
          break;
        case 'department':
          comparison = (a.department ?? '').compareTo(b.department ?? '');
          break;
        case 'designation':
          comparison = (a.designation ?? '').compareTo(b.designation ?? '');
          break;
        case 'division':
          comparison = (a.division ?? '').compareTo(b.division ?? '');
          break;
        case 'createdAt':
          comparison = (a.createdAt ?? '').compareTo(b.createdAt ?? '');
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _toggleSelection(String contactId) {
    final List<String> newSelection = List.from(widget.selectedContactIds);
    if (newSelection.contains(contactId)) {
      newSelection.remove(contactId);
    } else {
      newSelection.add(contactId);
    }
    widget.onSelectionChanged(newSelection);
  }

  void _toggleSelectAll() {
    final paginatedContacts = _getPaginatedContacts();
    final currentPageIds = paginatedContacts.map((c) => c.id).toSet();
    final allCurrentPageSelected = currentPageIds.every((id) => widget.selectedContactIds.contains(id));
    
    if (allCurrentPageSelected) {
      // Deselect all contacts on current page
      final newSelection = widget.selectedContactIds.where((id) => !currentPageIds.contains(id)).toList();
      widget.onSelectionChanged(newSelection);
    } else {
      // Select all contacts on current page
      final newSelection = {...widget.selectedContactIds, ...currentPageIds}.toList();
      widget.onSelectionChanged(newSelection);
    }
  }

  List<ContactModel> _getPaginatedContacts() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    if (startIndex >= _filteredContacts.length) return [];
    return _filteredContacts.sublist(
      startIndex,
      endIndex > _filteredContacts.length ? _filteredContacts.length : endIndex,
    );
  }

  int get _totalPages => (_filteredContacts.length / _itemsPerPage).ceil();

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  Widget _buildSortableHeader(String label, String columnKey) {
    final isCurrentColumn = _sortColumn == columnKey;
    return InkWell(
      onTap: () => _sortByColumn(columnKey),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          if (isCurrentColumn)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: AppColors.primary,
            )
          else
            const Icon(
              Icons.unfold_more,
              size: 16,
              color: AppColors.grey,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paginatedContacts = _getPaginatedContacts();
    final currentPageIds = paginatedContacts.map((c) => c.id).toSet();
    final allSelected = paginatedContacts.isNotEmpty &&
        currentPageIds.every((id) => widget.selectedContactIds.contains(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        // Search bar
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            prefixIcon: const Icon(Icons.search, color: AppColors.grey),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Selected count
        if (widget.selectedContactIds.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '${widget.selectedContactIds.length} contact(s) selected',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // Table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(
            maxHeight: 400,
          ),
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.grey.withValues(alpha: 0.1),
                  ),
                  columnSpacing: 24,
                  columns: [
                    DataColumn(
                      label: Checkbox(
                        value: allSelected,
                        onChanged: (_) => _toggleSelectAll(),
                        activeColor: AppColors.primary,
                      ),
                    ),
                    DataColumn(label: _buildSortableHeader('First Name', 'firstName')),
                    DataColumn(label: _buildSortableHeader('Middle Name', 'middleName')),
                    DataColumn(label: _buildSortableHeader('Last Name', 'lastName')),
                    DataColumn(label: _buildSortableHeader('Email', 'email')),
                    DataColumn(label: _buildSortableHeader('Phone', 'phone')),
                    DataColumn(label: _buildSortableHeader('Role', 'role')),
                    DataColumn(label: _buildSortableHeader('Company', 'company')),
                    DataColumn(label: _buildSortableHeader('Department', 'department')),
                    DataColumn(label: _buildSortableHeader('Designation', 'designation')),
                    DataColumn(label: _buildSortableHeader('Division', 'division')),
                    const DataColumn(label: Text('Influence Type', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Employee Code', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Groups', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    const DataColumn(label: Text('Created By', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: _buildSortableHeader('Created Date', 'createdAt')),
                  ],
                  rows: paginatedContacts.map((contact) {
                    final isSelected = widget.selectedContactIds.contains(contact.id);
                    return DataRow(
                      cells: [
                        DataCell(
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _toggleSelection(contact.id),
                            activeColor: AppColors.primary,
                          ),
                        ),
                        DataCell(Text(contact.firstName)),
                        DataCell(Text(contact.middleName ?? '-')),
                        DataCell(Text(contact.lastName ?? '-')),
                        DataCell(Text(contact.email ?? '-')),
                        DataCell(Text(contact.displayPhone)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getRoleColor(contact.role).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              contact.role,
                              style: TextStyle(
                                color: _getRoleColor(contact.role),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(contact.company ?? '-')),
                        DataCell(Text(contact.department ?? '-')),
                        DataCell(Text(contact.designation ?? '-')),
                        DataCell(Text(contact.division ?? '-')),
                        DataCell(Text(contact.influenceType ?? '-')),
                        DataCell(Text(contact.employeeCode ?? '-')),
                        DataCell(Text(contact.groups ?? '-')),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: contact.isActiveStatus
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              contact.isActive,
                              style: TextStyle(
                                color: contact.isActiveStatus
                                    ? AppColors.success
                                    : AppColors.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(contact.createdBy ?? '-')),
                        DataCell(Text(contact.createdAt ?? '-')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),

        // Pagination
        if (_totalPages > 1) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${(_currentPage - 1) * _itemsPerPage + 1}-${(_currentPage * _itemsPerPage > _filteredContacts.length ? _filteredContacts.length : _currentPage * _itemsPerPage)} of ${_filteredContacts.length}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textLight,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
                    color: _currentPage > 1 ? AppColors.primary : AppColors.grey,
                  ),
                  ...List.generate(
                    _totalPages > 5 ? 5 : _totalPages,
                    (index) {
                      int pageNum;
                      if (_totalPages <= 5) {
                        pageNum = index + 1;
                      } else if (_currentPage <= 3) {
                        pageNum = index + 1;
                      } else if (_currentPage >= _totalPages - 2) {
                        pageNum = _totalPages - 4 + index;
                      } else {
                        pageNum = _currentPage - 2 + index;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => _goToPage(pageNum),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: _currentPage == pageNum
                                  ? AppColors.primary
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: _currentPage == pageNum
                                    ? AppColors.primary
                                    : AppColors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              pageNum.toString(),
                              style: TextStyle(
                                color: _currentPage == pageNum
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: _currentPage == pageNum
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages ? () => _goToPage(_currentPage + 1) : null,
                    color: _currentPage < _totalPages ? AppColors.primary : AppColors.grey,
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Colors.purple;
      case 'EMPLOYEE':
        return Colors.blue;
      case 'CUSTOMER':
        return Colors.green;
      default:
        return AppColors.grey;
    }
  }
}
