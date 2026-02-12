import 'package:flutter/material.dart';
import '../../../../config/app_colors.dart';
import '../../../../config/app_text_styles.dart';
import '../../../../models/user_insights_model.dart';
import '../../../../utils/date_formatter.dart';

class ProductSearchesTab extends StatelessWidget {
  final UserProductSearches searches;

  const ProductSearchesTab({super.key, required this.searches});

  @override
  Widget build(BuildContext context) {
    if (searches.totalSearches == 0) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          _buildStatCards(),
          const SizedBox(height: 24),

          // Top sections
          if (searches.topThemes.isNotEmpty)
            _buildRankedList('Top Themes', searches.topThemes, Icons.palette_outlined, const Color(0xFF6366F1)),
          if (searches.topProducts.isNotEmpty)
            _buildRankedList('Top Products', searches.topProducts, Icons.inventory_2_outlined, const Color(0xFF22C55E)),
          if (searches.topPriceRanges.isNotEmpty)
            _buildRankedList('Top Price Ranges', searches.topPriceRanges, Icons.attach_money, const Color(0xFFF59E0B)),
          if (searches.topBrands.isNotEmpty)
            _buildRankedList('Top Brands', searches.topBrands, Icons.branding_watermark_outlined, const Color(0xFF3B82F6)),
          if (searches.topCategories.isNotEmpty)
            _buildRankedList('Top Categories', searches.topCategories, Icons.category_outlined, const Color(0xFFEC4899)),
          if (searches.topMOQs.isNotEmpty)
            _buildRankedList('Top MOQs', searches.topMOQs, Icons.shopping_cart_outlined, const Color(0xFF14B8A6)),

          // Recent searches
          if (searches.recentSearches.isNotEmpty) ...[
            Text('Recent Searches', style: AppTextStyles.heading3),
            const SizedBox(height: 12),
            ...searches.recentSearches.map(_buildRecentItem),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppColors.grey.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text(
            'No product searches yet',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    final items = [
      _StatItem('Total Searches', searches.totalSearches.toString(), Icons.search, const Color(0xFF6366F1)),
      _StatItem('Completed', searches.completedSearches.toString(), Icons.check_circle_outline, const Color(0xFF22C55E)),
      _StatItem('Completion Rate', '${searches.completionRate.toStringAsFixed(1)}%', Icons.pie_chart_outline, const Color(0xFFF59E0B)),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: item != items.last ? 8 : 0),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, size: 20, color: item.color),
                ),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: item.color,
                  ),
                ),
                Text(
                  item.label,
                  style: const TextStyle(fontSize: 10, color: AppColors.grey, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRankedList(String title, List<InsightNameCount> items, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.heading3),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        style: AppTextStyles.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.count}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentItem(InsightRecentSearch search) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (search.inputText.isNotEmpty)
            Text(
              search.inputText,
              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (search.theme.isNotEmpty) _chip(search.theme, const Color(0xFF6366F1)),
              if (search.priceRange.isNotEmpty) _chip(search.priceRange, const Color(0xFFF59E0B)),
              if (search.stage.isNotEmpty) _chip(search.stage, const Color(0xFF22C55E)),
            ],
          ),
          if (search.date != null) ...[
            const SizedBox(height: 6),
            Text(formatDateShort(search.date), style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}
