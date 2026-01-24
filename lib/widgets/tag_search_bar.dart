import 'dart:async';
import 'package:ags/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../config/app_text_styles.dart';

class TagSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic> currentFilters;
  final String? initialSearchQuery;

  const TagSearchBar({
    super.key,
    required this.onSearch,
    required this.onApplyFilters,
    required this.currentFilters,
    this.initialSearchQuery,
  });

  @override
  State<TagSearchBar> createState() => _TagSearchBarState();
}

class _TagSearchBarState extends State<TagSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _showFilters = false;
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentFilters['status'] ?? 'all';
    // Set initial search query if provided
    if (widget.initialSearchQuery != null &&
        widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  @override
  void didUpdateWidget(TagSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update search text if initial query changed and controller is empty
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery) {
      if (widget.initialSearchQuery != null &&
          widget.initialSearchQuery != _searchController.text) {
        _searchController.text = widget.initialSearchQuery!;
      } else if (widget.initialSearchQuery == null ||
          widget.initialSearchQuery!.isEmpty) {
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
        }
      }
    }

    // Update filters if they changed externally
    if (oldWidget.currentFilters != widget.currentFilters) {
      setState(() {
        _selectedStatus = widget.currentFilters['status'] ?? 'all';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Update UI immediately to show/hide clear button
    setState(() {});

    // Set up debounced search with 500ms delay
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (value.isNotEmpty || value.isEmpty) {
        widget.onSearch(value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {});
    widget.onSearch(''); // Clear search results
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    if (_selectedStatus != 'all') {
      filters['status'] = _selectedStatus;
    }
    widget.onApplyFilters(filters);
    setState(() {
      _showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedStatus = 'all';
    });
    widget.onApplyFilters({});
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = widget.currentFilters.isNotEmpty;
    final hasSearchText = _searchController.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tags...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.grey,
                      ),
                      suffixIcon: hasSearchText
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.grey,
                              ),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lightGrey,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.lightGrey,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      filled: true,
                      fillColor: AppColors.background,
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: hasActiveFilters
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: hasActiveFilters
                          ? AppColors.primary
                          : AppColors.lightGrey,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.filter_list,
                      color: hasActiveFilters
                          ? AppColors.primary
                          : AppColors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    tooltip: 'Filters',
                  ),
                ),
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.error,
                        size: 20,
                      ),
                      onPressed: _clearFilters,
                      tooltip: 'Clear Filters',
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_showFilters)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Options',
                    style: AppTextStyles.cardTitle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        'Status:',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip('All', 'all'),
                            _buildFilterChip('Active', 'active'),
                            _buildFilterChip('Inactive', 'inactive'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showFilters = false;
                          });
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      CustomButton(
                          width: 100,
                          onPressed: _applyFilters, text: ('Apply')),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
      },
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary.withValues(alpha: 0.1),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.lightGrey,
      ),
    );
  }
}
