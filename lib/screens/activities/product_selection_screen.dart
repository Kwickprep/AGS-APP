import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_button.dart';
import 'package:get_it/get_it.dart';
import '../../widgets/custom_button.dart';
import '../../config/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../config/routes.dart';
import '../../widgets/custom_button.dart';
import '../../services/activity_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_toast.dart';
import '../../widgets/custom_button.dart';

class ProductSelectionScreen extends StatefulWidget {
  final String activityId;
  final List<dynamic> aiSuggestedProducts;
  final Map<String, dynamic>? selectedTheme;
  final Map<String, dynamic>? selectedCategory;
  final Map<String, dynamic>? selectedPriceRange;

  const ProductSelectionScreen({
    super.key,
    required this.activityId,
    required this.aiSuggestedProducts,
    this.selectedTheme,
    this.selectedCategory,
    this.selectedPriceRange,
  });

  @override
  State<ProductSelectionScreen> createState() =>
      _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen> {
  final ActivityService _activityService = GetIt.I<ActivityService>();
  Map<String, dynamic>? _selectedProduct;
  final TextEditingController _moqController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listener to MOQ controller to update summary
    _moqController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _moqController.dispose();
    super.dispose();
  }

  Future<void> _completeActivity() async {
    if (_selectedProduct == null) {
      CustomToast.show(
        context,
        'Please select a product',
        type: ToastType.error,
      );
      return;
    }

    if (_moqController.text.trim().isEmpty) {
      CustomToast.show(
        context,
        'Please enter MOQ',
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
          'selectedProduct': {
            'id': _selectedProduct!['id'],
            'name': _selectedProduct!['name'],
            'reason': _selectedProduct!['reason'],
            'aiGeneratedDescription': _selectedProduct!['aiGeneratedDescription'],
            'conceptAlignment': _selectedProduct!['conceptAlignment'],
            'description': _selectedProduct!['description'],
            'imageUrl': _selectedProduct!['imageUrl'],
            'images': _selectedProduct!['images'],
            'brand': _selectedProduct!['brand'],
            'themes': _selectedProduct!['themes'],
            'tags': _selectedProduct!['tags'],
          },
          'moq': _moqController.text.trim(),
        },
      };

      final response = await _activityService.updateActivity(widget.activityId, data);

      // Print JSON response for debugging
      debugPrint('Product Selection Response:');
      debugPrint('Body: ${response.body?.toJson()}');

      if (mounted) {
        CustomToast.show(
          context,
          'Activity completed successfully',
          type: ToastType.success,
        );
        // Navigate to activities screen and remove all previous routes
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.activities,
          (route) => route.settings.name == AppRoutes.home,
        );
      }
    } catch (e) {
      if (mounted) {
        debugPrint('Error completing activity: $e');
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

                    // Select Product Section
                    _buildProductSelectionSection(),
                  ],
                ),
              ),
            ),

            // Complete Activity Button
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
                text: 'Complete Activity',
                onPressed: _completeActivity,
                isLoading: _isLoading,
                icon: Icons.check_circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    // Build product and MOQ display
    String productMoqValue = 'N/A';
    if (_selectedProduct != null && _moqController.text.trim().isNotEmpty) {
      productMoqValue = '${_selectedProduct!['name']} (${_moqController.text.trim()})';
    } else if (_selectedProduct != null) {
      productMoqValue = _selectedProduct!['name'];
    }

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
          _buildSummaryItem(
            'PRICE RANGE',
            widget.selectedPriceRange?['label'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem('PRODUCT (MOQ)', productMoqValue),
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

  Widget _buildProductSelectionSection() {
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
                  '5',
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
              'Select Product & Quantity',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Product List
        ...widget.aiSuggestedProducts.map((product) {
          final bool isSelected = _selectedProduct != null &&
              _selectedProduct!['id'] == product['id'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedProduct = product;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.lightGrey,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image
                            if (product['imageUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product['imageUrl'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: AppColors.lightGrey,
                                      child: const Icon(
                                        Icons.image,
                                        color: AppColors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            const SizedBox(width: 12),

                            // Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          product['name'] ?? '',
                                          style: TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.lightGrey,
                                            width: 2,
                                          ),
                                          color: isSelected
                                              ? AppColors.primary
                                              : Colors.transparent,
                                        ),
                                        child: isSelected
                                            ? const Icon(
                                                Icons.check,
                                                size: 16,
                                                color: Colors.white,
                                              )
                                            : null,
                                      ),
                                    ],
                                  ),
                                  if (product['brand'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Brand: ${product['brand']['name']}',
                                      style: const TextStyle(
                                        color: AppColors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Text(
                                    product['reason'] ?? '',
                                    style: const TextStyle(
                                      color: AppColors.grey,
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Show full details when selected
                        if (isSelected) ...[
                          const SizedBox(height: 12),
                          const Divider(color: AppColors.lightGrey),
                          const SizedBox(height: 12),

                          // AI Description
                          if (product['aiGeneratedDescription'] != null) ...[
                            const Text(
                              'AI Description:',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product['aiGeneratedDescription'],
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Product Description
                          if (product['description'] != null) ...[
                            const Text(
                              'Description:',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product['description'],
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Concept Alignment
                          if (product['conceptAlignment'] != null &&
                              (product['conceptAlignment'] as List).isNotEmpty) ...[
                            const Text(
                              'Concept Alignment:',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...(product['conceptAlignment'] as List).map((concept) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '• ',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        concept,
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                // MOQ Input Field (shown only for selected product)
                if (isSelected) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.lightGrey),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Minimum Order Quantity (MOQ)',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _moqController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter MOQ',
                            hintStyle: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 14,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}
