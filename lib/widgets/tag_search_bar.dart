import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class TagSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic> currentFilters;

  const TagSearchBar({
    Key? key,
    required this.onSearch,
    required this.onApplyFilters,
    required this.currentFilters,
  }) : super(key: key);

  @override
  State<TagSearchBar> createState() => _TagSearchBarState();
}

class _TagSearchBarState extends State<TagSearchBar> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty || value.length >= 3) {
      _debounceTimer = Timer(const Duration(seconds: 2), () {
        widget.onSearch(value);
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        currentFilters: widget.currentFilters,
        onApply: (filters) {
          widget.onApplyFilters(filters);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search (min 3 characters)...',
                prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.grey),
                  onPressed: () {
                    _searchController.clear();
                    widget.onSearch('');
                  },
                )
                    : null,
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
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            label: Text(
              widget.currentFilters.isEmpty
                  ? 'Filter'
                  : 'Filter (${widget.currentFilters.length})',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.currentFilters.isEmpty
                  ? AppColors.white
                  : AppColors.primary,
              foregroundColor: widget.currentFilters.isEmpty
                  ? AppColors.primary
                  : AppColors.white,
              side: BorderSide(
                color: AppColors.primary,
                width: widget.currentFilters.isEmpty ? 1 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FilterDialog extends StatefulWidget {
  final Map<String, dynamic> currentFilters;
  final Function(Map<String, dynamic>) onApply;

  const FilterDialog({
    Key? key,
    required this.currentFilters,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late Map<String, dynamic> _filters;

  @override
  void initState() {
    super.initState();
    _filters = Map.from(widget.currentFilters);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Options'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            RadioListTile<String?>(
              title: const Text('All'),
              value: null,
              groupValue: _filters['status'],
              onChanged: (value) {
                setState(() {
                  if (value == null) {
                    _filters.remove('status');
                  } else {
                    _filters['status'] = value;
                  }
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Active'),
              value: 'active',
              groupValue: _filters['status'],
              onChanged: (value) {
                setState(() {
                  _filters['status'] = value;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Inactive'),
              value: 'inactive',
              groupValue: _filters['status'],
              onChanged: (value) {
                setState(() {
                  _filters['status'] = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _filters.clear();
            });
          },
          child: const Text('Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_filters);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
