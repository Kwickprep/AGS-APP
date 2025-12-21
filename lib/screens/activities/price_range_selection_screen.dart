import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'package:get_it/get_it.dart';
import '../../widgets/custom_button.dart';
import '../../config/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../services/activity_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_button.dart';
import 'product_selection_screen.dart';
import '../../widgets/custom_button.dart';

class PriceRangeSelectionScreen extends StatefulWidget {
  final String activityId;
  final List<dynamic> availablePriceRanges;
  final Map<String, dynamic>? selectedTheme;
  final Map<String, dynamic>? selectedCategory;

  const PriceRangeSelectionScreen({
    super.key,
    required this.activityId,
    required this.availablePriceRanges,
    this.selectedTheme,
    this.selectedCategory,
  });

  @override
  State<PriceRangeSelectionScreen> createState() =>
      _PriceRangeSelectionScreenState();
}

class _PriceRangeSelectionScreenState extends State<PriceRangeSelectionScreen> {
  final ActivityService _activityService = GetIt.I<ActivityService>();
  Map<String, dynamic>? _selectedPriceRange;
  bool _isLoading = false;

  Future<void> _submitPriceRangeSelection() async {
    if (_selectedPriceRange == null) {
      CustomToast.show(
        context,
        'Please select a price range',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = {
        'body': {
          'selectedPriceRange': {
            'label': _selectedPriceRange!['label'],
            'value': _selectedPriceRange!['value'],
            'min': _selectedPriceRange!['min'],
            'max': _selectedPriceRange!['max'],
          },
        },
      };

      final response = await _activityService.updateActivity(widget.activityId, data);

      // Print JSON response for debugging
      debugPrint('Price Range Selection Response:');
      debugPrint('Body: ${response.body?.toJson()}');

      if (mounted) {
        CustomToast.show(
          context,
          'Price range selected successfully',
          type: ToastType.success,
        );

        // Navigate to product selection if available
        final responseBody = response.body;
        if (responseBody != null &&
            responseBody.aiSuggestedProducts != null &&
            responseBody.aiSuggestedProducts!.isNotEmpty) {
          final productResult = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductSelectionScreen(
                activityId: widget.activityId,
                aiSuggestedProducts: responseBody.aiSuggestedProducts!,
                selectedTheme: widget.selectedTheme,
                selectedCategory: widget.selectedCategory,
                selectedPriceRange: _selectedPriceRange,
              ),
            ),
          );

          if (productResult != null && mounted) {
            Navigator.pop(context, productResult);
          }
        } else {
          Navigator.pop(context, response);
        }
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error submitting price range selection: $e');
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

                    // Select Price Range Section
                    _buildPriceRangeSelectionSection(),
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
                onPressed: _submitPriceRangeSelection,
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
          _buildSummaryItem(
            'CATEGORY',
            widget.selectedCategory?['name'] ?? 'N/A',
          ),
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

  Widget _buildPriceRangeSelectionSection() {
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
                  '4',
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
              'Select Price Range',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Price Range Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: widget.availablePriceRanges.length,
          itemBuilder: (context, index) {
            final priceRange = widget.availablePriceRanges[index];
            final bool isSelected = _selectedPriceRange != null &&
                _selectedPriceRange!['value'] == priceRange['value'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPriceRange = priceRange;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.lightGrey,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    priceRange['label'] ?? '',
                    style: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
