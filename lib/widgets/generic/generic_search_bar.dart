import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../custom_button.dart';

/// Configuration for filter options
class FilterConfig {
  final String label;
  final String key;
  final List<FilterOption> options;

  const FilterConfig({
    required this.label,
    required this.key,
    required this.options,
  });

  /// Helper to create a status filter (Active/Inactive)
  static FilterConfig statusFilter() {
    return FilterConfig(
      label: 'Status',
      key: 'status',
      options: [
        FilterOption(label: 'All', value: 'all'),
        FilterOption(label: 'Active', value: 'active'),
        FilterOption(label: 'Inactive', value: 'inactive'),
      ],
    );
  }
}

class FilterOption {
  final String label;
  final String value;

  const FilterOption({
    required this.label,
    required this.value,
  });
}

/// Generic search bar with filtering capability
class GenericSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(Map<String, dynamic>) onApplyFilters;
  final Map<String, dynamic> currentFilters;
  final String? initialSearchQuery;
  final String searchHint;
  final List<FilterConfig> filterConfigs;
  final int? totalCount;
  final Duration debounceDuration;
  final int minSearchLength;

  const GenericSearchBar({
    Key? key,
    required this.onSearch,
    required this.onApplyFilters,
    required this.currentFilters,
    this.initialSearchQuery,
    this.searchHint = 'Search...',
    this.filterConfigs = const [],
    this.totalCount,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.minSearchLength = 1,
  }) : super(key: key);

  @override
  State<GenericSearchBar> createState() => _GenericSearchBarState();
}

class _GenericSearchBarState extends State<GenericSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _showFilters = false;
  final Map<String, String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    // Initialize selected filters from current filters
    for (final config in widget.filterConfigs) {
      _selectedFilters[config.key] = widget.currentFilters[config.key] ?? 'all';
    }

    // Set initial search query if provided
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
  }

  @override
  void didUpdateWidget(GenericSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update search text if initial query changed
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery) {
      if (widget.initialSearchQuery != null &&
          widget.initialSearchQuery != _searchController.text) {
        _searchController.text = widget.initialSearchQuery!;
      } else if (widget.initialSearchQuery == null || widget.initialSearchQuery!.isEmpty) {
        if (_searchController.text.isNotEmpty) {
          _searchController.clear();
        }
      }
    }

    // Update filters if they changed externally
    if (oldWidget.currentFilters != widget.currentFilters) {
      setState(() {
        for (final config in widget.filterConfigs) {
          _selectedFilters[config.key] = widget.currentFilters[config.key] ?? 'all';
        }
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

    // Set up debounced search
    _debounceTimer = Timer(widget.debounceDuration, () {
      if (value.length >= widget.minSearchLength || value.isEmpty) {
        widget.onSearch(value);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _debounceTimer?.cancel();
    setState(() {});
    widget.onSearch('');
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};
    for (final entry in _selectedFilters.entries) {
      if (entry.value != 'all') {
        filters[entry.key] = entry.value;
      }
    }
    widget.onApplyFilters(filters);
    setState(() {
      _showFilters = false;
    });
  }

  void _clearFilters() {
    setState(() {
      for (final key in _selectedFilters.keys) {
        _selectedFilters[key] = 'all';
      }
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
            color: Colors.grey.withOpacity(0.1),
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
                      hintText: widget.searchHint,
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
                if (widget.filterConfigs.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppColors.primary.withOpacity(0.1)
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
                ],
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
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
                if (widget.totalCount != null) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      'Total: ${widget.totalCount}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_showFilters && widget.filterConfigs.isNotEmpty)
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
                  const Text(
                    'Filter Options',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ...widget.filterConfigs.map((config) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            Text(
                              '${config.label}:',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                children: config.options
                                    .map((option) => _buildFilterChip(
                                          option.label,
                                          option.value,
                                          config.key,
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      )),
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
                      SizedBox(
                        width: 80,
                        child: CustomButton(
                          onPressed: _applyFilters,
                          text: 'Apply',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String filterKey) {
    final isSelected = _selectedFilters[filterKey] == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilters[filterKey] = value;
        });
      },
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary.withOpacity(0.1),
      checkmarkColor: AppColors.primary,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.lightGrey,
      ),
    );
  }
}
