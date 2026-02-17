import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/activity_model.dart';
import '../../services/activity_service.dart';
import '../../widgets/custom_toast.dart';
import 'activity_create_screen.dart';
import 'category_selection_screen.dart';
import 'price_range_selection_screen.dart';
import 'product_search_summary_screen.dart';
import 'product_selection_screen.dart';
import 'theme_selection_screen.dart';

/// Loading screen that fetches full activity detail, determines the current
/// stage of a Product Search activity, and routes to the correct screen.
class ProductSearchEditRouter extends StatefulWidget {
  final ActivityModel activity;

  const ProductSearchEditRouter({super.key, required this.activity});

  @override
  State<ProductSearchEditRouter> createState() =>
      _ProductSearchEditRouterState();
}

class _ProductSearchEditRouterState extends State<ProductSearchEditRouter> {
  final ActivityService _activityService = GetIt.I<ActivityService>();

  @override
  void initState() {
    super.initState();
    _fetchAndRoute();
  }

  Future<void> _fetchAndRoute() async {
    try {
      final detail = await _activityService.getActivityDetail(
        widget.activity.id,
      );
      if (!mounted) return;

      final body = detail.body;
      final stage = body?.stage;

      print('Router - body is null: ${body == null}');
      print('Router - stage: $stage');
      if (body != null) {
        print('Router - selectedTheme: ${body.selectedTheme}');
        print('Router - selectedCategory: ${body.selectedCategory}');
        print('Router - selectedPriceRange: ${body.selectedPriceRange}');
        print(
          'Router - aiSuggestedProducts count: ${body.aiSuggestedProducts?.length}',
        );
        print('Router - selectedProduct: ${body.selectedProduct}');
        print('Router - moq: ${body.moq}');
      }

      // Route based on the stage field from the API
      Widget destination;

      if (body == null || stage == null) {
        // No body or stage: go to step-1 edit orm
        destination = ActivityCreateScreen(isEdit: true, activity: detail);
      } else if (stage == 'COMPLETED') {
        destination = ProductSearchSummaryScreen(activity: detail);
      } else if (stage == 'PRODUCT_SELECTION' &&
          body.aiSuggestedProducts != null &&
          body.aiSuggestedProducts!.isNotEmpty) {
        destination = ProductSelectionScreen(
          activityId: detail.id,
          aiSuggestedProducts: body.aiSuggestedProducts!,
          selectedTheme: body.selectedTheme,
          selectedCategory: body.selectedCategory,
          selectedPriceRange: body.selectedPriceRange,
        );
      } else if (stage == 'PRICE_RANGE_SELECTION' &&
          body.availablePriceRanges != null &&
          body.availablePriceRanges!.isNotEmpty) {
        destination = PriceRangeSelectionScreen(
          activityId: detail.id,
          availablePriceRanges: body.availablePriceRanges!,
          selectedTheme: body.selectedTheme,
          selectedCategory: body.selectedCategory,
        );
      } else if (stage == 'CATEGORY_SELECTION' &&
          body.aiSuggestedCategories != null &&
          body.aiSuggestedCategories!.isNotEmpty) {
        destination = CategorySelectionScreen(
          activityId: detail.id,
          aiSuggestedCategories: body.aiSuggestedCategories!,
          selectedTheme: body.selectedTheme,
        );
      } else if (stage == 'THEME_SELECTION' &&
          body.aiSuggestedThemes != null &&
          body.aiSuggestedThemes!.isNotEmpty) {
        destination = ThemeSelectionScreen(
          activityId: detail.id,
          aiSuggestedThemes: body.aiSuggestedThemes!,
        );
      } else {
        // Fallback for unknown stages: go to step-1 edit form
        destination = ActivityCreateScreen(isEdit: true, activity: detail);
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    } catch (e, stackTrace) {
      print('ProductSearchEditRouter error: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      CustomToast.show(
        context,
        'Failed to load activity: ${e.toString().replaceAll('Exception: ', '')}',
        type: ToastType.error,
      );
      Navigator.pop(context);
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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            SizedBox(height: 16),
            Text(
              'Loading activity...',
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
