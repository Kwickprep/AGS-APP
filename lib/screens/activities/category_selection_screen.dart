import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../services/activity_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_toast.dart';
import 'price_range_selection_screen.dart';

class CategorySelectionScreen extends StatefulWidget {
  final String activityId;
  final List<dynamic> aiSuggestedCategories;
  final Map<String, dynamic>? selectedTheme;

  const CategorySelectionScreen({
    super.key,
    required this.activityId,
    required this.aiSuggestedCategories,
    this.selectedTheme,
  });

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final ActivityService _activityService = GetIt.I<ActivityService>();
  Map<String, dynamic>? _selectedCategory;
  bool _isLoading = false;

  Future<void> _submitCategorySelection() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'body': {
          'selectedCategory': _selectedCategory != null
              ? {
                  'id': _selectedCategory!['id'],
                  'name': _selectedCategory!['name'],
                  'reason': _selectedCategory!['reason'],
                }
              : null,
        },
      };

      final response = await _activityService.updateActivity(widget.activityId, data);

      // Print JSON response for debugging
      debugPrint('Category Selection Response:');
      debugPrint('Body: ${response.body?.toJson()}');

      if (mounted) {
        CustomToast.show(
          context,
          'Category selected successfully',
          type: ToastType.success,
        );

        // Navigate to price range selection if available
        final responseBody = response.body;
        if (responseBody != null &&
            responseBody.availablePriceRanges != null &&
            responseBody.availablePriceRanges!.isNotEmpty) {
          final priceRangeResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PriceRangeSelectionScreen(
                activityId: widget.activityId,
                availablePriceRanges: responseBody.availablePriceRanges!,
                selectedTheme: widget.selectedTheme,
                selectedCategory: _selectedCategory,
              ),
            ),
          );

          if (priceRangeResult != null && mounted) {
            Navigator.pop(context, priceRangeResult);
          }
        } else {
          Navigator.pop(context, response);
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error submitting category selection: $e');
        CustomToast.show(
          context,
          e.toString().replaceAll('Exception: ', ''),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Activity',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Section
                    _buildSummarySection(),
                    const SizedBox(height: 24),

                    // Select Category Section
                    _buildCategorySelectionSection(),
                  ],
                ),
              ),
            ),

            // Next Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: CustomButton(
                text: 'Next',
                onPressed: _submitCategorySelection,
                isLoading: _isLoading,
                icon: Icons.arrow_forward,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryItem(
            'THEME',
            widget.selectedTheme?['name'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem('CATEGORY', 'N/A'),
          const SizedBox(height: 12),
          _buildSummaryItem('PRICE RANGE', 'N/A'),
          const SizedBox(height: 12),
          _buildSummaryItem('PRODUCT (MOQ)', 'N/A'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '3',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Select a Category (Optional)',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Category Options
        ...widget.aiSuggestedCategories.map((category) {
          final bool isSelected = _selectedCategory != null &&
              _selectedCategory!['id'] == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.lightGrey,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.lightGrey,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category['name'] ?? '',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          category['reason'] ?? '',
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
