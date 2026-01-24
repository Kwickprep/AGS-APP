// ALTERNATIVE VERSION: Product Screen with Search Button
// This file shows an alternative implementation with a manual search button
// Copy the relevant sections to product_screen.dart if you prefer this approach
//
// Required imports (ensure these are in product_screen.dart):
// import '../../config/app_colors.dart';
// import '../../config/app_text_styles.dart';

/*
To use this approach, replace the search bar section in product_screen.dart with:

// Search bar with manual search button
Container(
  color: Colors.white,
  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
  child: TextField(
    controller: _searchController,
    decoration: InputDecoration(
      hintText: 'Search products...',
      prefixIcon: const Icon(Icons.search),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _currentSearch = '';
                  _currentPage = 1;
                });
                _loadProducts();
              },
            ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _currentSearch = _searchController.text;
                  _currentPage = 1;
                });
                _loadProducts();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: const Size(60, 36),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Search',
                style: AppTextStyles.button.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    ),
    onSubmitted: (value) {
      // Also allow search on Enter key
      setState(() {
        _currentSearch = value;
        _currentPage = 1;
      });
      _loadProducts();
    },
  ),
),

AND remove these from the current implementation:
1. Remove the debounce timer declaration: Timer? _debounceTimer;
2. Remove debounce timer disposal in dispose(): _debounceTimer?.cancel();
3. Remove the _onSearchChanged method or replace it with:
   void _onSearchChanged(String value) {
     // No auto-search, only manual search via button
     setState(() {}); // Just update UI to show/hide clear button
   }
4. Remove 'dart:async' import if not used elsewhere
*/
