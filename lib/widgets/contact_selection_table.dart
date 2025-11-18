import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/contact_model.dart';

class ContactSelectionTable extends StatefulWidget {
  final List<ContactModel> contacts;
  final List<String> selectedContactIds;
  final Function(List<String>) onSelectionChanged;

  const ContactSelectionTable({
    Key? key,
    required this.contacts,
    required this.selectedContactIds,
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<ContactSelectionTable> createState() => _ContactSelectionTableState();
}

class _ContactSelectionTableState extends State<ContactSelectionTable> {
  final TextEditingController _searchController = TextEditingController();
  List<ContactModel> _filteredContacts = [];
  String _sortColumn = '';
  bool _sortAscending = true;

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
        case 'name':
          comparison = a.fullName.compareTo(b.fullName);
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
    if (widget.selectedContactIds.length == _filteredContacts.length) {
      widget.onSelectionChanged([]);
    } else {
      widget.onSelectionChanged(
        _filteredContacts.map((c) => c.id).toList(),
      );
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
    final allSelected = _filteredContacts.isNotEmpty &&
        widget.selectedContactIds.length == _filteredContacts.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            border: Border.all(color: AppColors.grey.withOpacity(0.3)),
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
                  headingRowColor: MaterialStateProperty.all(
                    AppColors.grey.withOpacity(0.1),
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
                    const DataColumn(
                      label: Text(
                        'SR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(label: _buildSortableHeader('Name', 'name')),
                    DataColumn(label: _buildSortableHeader('Email', 'email')),
                    DataColumn(label: _buildSortableHeader('Phone', 'phone')),
                    DataColumn(label: _buildSortableHeader('Role', 'role')),
                  ],
                  rows: _filteredContacts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final contact = entry.value;
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
                        DataCell(Text('${index + 1}')),
                        DataCell(Text(contact.fullName)),
                        DataCell(Text(contact.email ?? '-')),
                        DataCell(Text(contact.displayPhone)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              contact.role,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
