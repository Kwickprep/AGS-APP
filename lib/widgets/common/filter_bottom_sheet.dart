import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../custom_button.dart';
import 'filter_chip_button.dart';

/// Generic filter model for filtering records
class FilterModel {
  Set<String> selectedStatuses;
  DateTime? startDate;
  DateTime? endDate;
  String? createdBy;

  FilterModel({
    Set<String>? selectedStatuses,
    this.startDate,
    this.endDate,
    this.createdBy,
  }) : selectedStatuses = selectedStatuses ?? {};

  FilterModel copyWith({
    Set<String>? selectedStatuses,
    DateTime? startDate,
    DateTime? endDate,
    String? createdBy,
  }) {
    return FilterModel(
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  void clear() {
    selectedStatuses.clear();
    startDate = null;
    endDate = null;
    createdBy = null;
  }

  bool get hasActiveFilters {
    return selectedStatuses.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        createdBy != null;
  }
}

/// Reusable filter bottom sheet
class FilterBottomSheet extends StatefulWidget {
  final FilterModel initialFilter;
  final List<String> creatorOptions;
  final Function(FilterModel) onApplyFilters;
  final List<String> statusOptions;

  const FilterBottomSheet({
    super.key,
    required this.initialFilter,
    required this.creatorOptions,
    required this.onApplyFilters,
    this.statusOptions = const ['Active', 'Inactive'],
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();

  /// Helper method to show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required FilterModel initialFilter,
    required List<String> creatorOptions,
    required Function(FilterModel) onApplyFilters,
    List<String> statusOptions = const ['Active', 'Inactive'],
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilter: initialFilter,
        creatorOptions: creatorOptions,
        onApplyFilters: onApplyFilters,
        statusOptions: statusOptions,
      ),
    );
  }
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterModel _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = FilterModel(
      selectedStatuses: Set.from(widget.initialFilter.selectedStatuses),
      startDate: widget.initialFilter.startDate,
      endDate: widget.initialFilter.endDate,
      createdBy: widget.initialFilter.createdBy,
    );
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_currentFilter.selectedStatuses.contains(status)) {
        _currentFilter.selectedStatuses.remove(status);
      } else {
        _currentFilter.selectedStatuses.add(status);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _currentFilter.clear();
    });
  }

  void _applyFilters() {
    widget.onApplyFilters(_currentFilter);
    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_currentFilter.startDate ?? DateTime.now())
          : (_currentFilter.endDate ?? DateTime.now()),
      firstDate: isStartDate ? DateTime(2000) : (_currentFilter.startDate ?? DateTime(2000)),
      lastDate: isStartDate ? (_currentFilter.endDate ?? DateTime(2100)) : DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _currentFilter.startDate = picked;
        } else {
          _currentFilter.endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: AppTextStyles.heading3,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Filter content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status section
                    Text(
                      'Status',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.statusOptions.map((status) {
                        return FilterChipButton(
                          label: status,
                          isSelected: _currentFilter.selectedStatuses.contains(status),
                          onTap: () => _toggleStatus(status),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Created By section
                    if (widget.creatorOptions.isNotEmpty) ...[
                      Text(
                        'Created By',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _currentFilter.createdBy,
                            isExpanded: true,
                            hint: Text(
                              'All Creators',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            items: [
                              DropdownMenuItem<String>(
                                value: null,
                                child: Text(
                                  'All Creators',
                                  style: AppTextStyles.bodyMedium,
                                ),
                              ),
                              ...widget.creatorOptions.map((creator) {
                                return DropdownMenuItem<String>(
                                  value: creator,
                                  child: Text(
                                    creator,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _currentFilter.createdBy = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearAll,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Clear All',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Apply Filters',
                      onPressed: _applyFilters,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
