import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../custom_button.dart';

/// Sort option model
class SortOption {
  final String field;
  final String label;

  const SortOption({
    required this.field,
    required this.label,
  });
}

/// Sort model to hold sort state
class SortModel {
  String sortBy;
  String sortOrder; // 'asc' or 'desc'

  SortModel({
    required this.sortBy,
    required this.sortOrder,
  });

  SortModel copyWith({
    String? sortBy,
    String? sortOrder,
  }) {
    return SortModel(
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

/// Reusable sort bottom sheet
class SortBottomSheet extends StatefulWidget {
  final SortModel initialSort;
  final List<SortOption> sortOptions;
  final Function(SortModel) onApplySort;

  const SortBottomSheet({
    super.key,
    required this.initialSort,
    required this.sortOptions,
    required this.onApplySort,
  });

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();

  /// Helper method to show the bottom sheet
  static Future<void> show({
    required BuildContext context,
    required SortModel initialSort,
    required List<SortOption> sortOptions,
    required Function(SortModel) onApplySort,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SortBottomSheet(
        initialSort: initialSort,
        sortOptions: sortOptions,
        onApplySort: onApplySort,
      ),
    );
  }
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  late SortModel _currentSort;

  @override
  void initState() {
    super.initState();
    _currentSort = SortModel(
      sortBy: widget.initialSort.sortBy,
      sortOrder: widget.initialSort.sortOrder,
    );
  }

  void _applySort() {
    widget.onApplySort(_currentSort);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20, // Add space from top
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sort By',
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

            // Sort options - constrain max height to prevent touching top
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.6, // Max 60% of screen
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort by field options
                    ...widget.sortOptions.map((option) {
                      final isSelected = _currentSort.sortBy == option.field;
                      return RadioListTile<String>(
                        value: option.field,
                        groupValue: _currentSort.sortBy,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _currentSort.sortBy = value;
                            });
                          }
                        },
                        title: Text(
                          option.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      );
                    }),

                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 16),

                    // Sort order section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),

                    RadioListTile<String>(
                      value: 'asc',
                      groupValue: _currentSort.sortOrder,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currentSort.sortOrder = value;
                          });
                        }
                      },
                      title: Row(
                        children: [
                          const Icon(Icons.arrow_upward, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Ascending',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: _currentSort.sortOrder == 'asc' ? FontWeight.w600 : FontWeight.normal,
                              color: _currentSort.sortOrder == 'asc' ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    RadioListTile<String>(
                      value: 'desc',
                      groupValue: _currentSort.sortOrder,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _currentSort.sortOrder = value;
                          });
                        }
                      },
                      title: Row(
                        children: [
                          const Icon(Icons.arrow_downward, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Descending',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: _currentSort.sortOrder == 'desc' ? FontWeight.w600 : FontWeight.normal,
                              color: _currentSort.sortOrder == 'desc' ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      activeColor: AppColors.primary,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Action button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                ),
              ),
              child: CustomButton(
                text: 'Apply Sort',
                onPressed: _applySort,
              ),
            ),
          ],
        ),
      );
  }
}
