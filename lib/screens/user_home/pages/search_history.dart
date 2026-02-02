import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/activity_model.dart';
import '../search_history_bloc.dart';

class SearchHistory extends StatefulWidget {
  const SearchHistory({super.key});

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SearchHistoryBloc>().add(LoadSearchHistory());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchHistoryBloc>().add(LoadMoreSearchHistory());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        automaticallyImplyLeading: false,
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'My Product Search',
          style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<SearchHistoryBloc, SearchHistoryState>(
        builder: (context, state) {
          if (state is SearchHistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SearchHistoryError) {
            return _buildErrorState(state.message);
          }

          if (state is SearchHistoryLoaded) {
            if (state.activities.isEmpty) {
              return _buildEmptyState();
            }
            return RefreshIndicator(
              onRefresh: () async {
                context.read<SearchHistoryBloc>().add(RefreshSearchHistory());
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: state.activities.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.activities.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }
                  return _buildActivityCard(state.activities[index]);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildActivityCard(ActivityModel activity) {
    final body = activity.body;
    final inputText = body?.inputText ?? '';
    final stage = body?.stage ?? 'INITIAL';
    // Use top-level formatted fields (from backend formatter) with body as fallback
    final themeName = activity.theme.isNotEmpty
        ? activity.theme
        : (body?.selectedTheme?['name'] as String? ?? '');
    final productName = activity.product.isNotEmpty
        ? activity.product
        : (body?.selectedProduct?['name'] as String? ?? '');
    final moq = activity.moq.isNotEmpty
        ? activity.moq
        : (body?.moq ?? '');
    final hasDocuments = body?.documentIds?.isNotEmpty == true;
    final stageInfo = _getStageInfo(stage);

    String dateStr = '';
    if (activity.createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(activity.createdAt);
        dateStr = DateFormat('dd MMM yyyy, h:mm a').format(date);
      } catch (_) {
        dateStr = activity.createdAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: query + stage badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    inputText.isNotEmpty
                        ? inputText
                        : hasDocuments
                            ? 'Image Search'
                            : 'Product Search',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: stageInfo.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stageInfo.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: stageInfo.color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details rows
            if (themeName.isNotEmpty)
              _buildDetailRow(Icons.palette_outlined, 'Theme', themeName),
            if (productName.isNotEmpty)
              _buildDetailRow(Icons.inventory_2_outlined, 'Product', productName),
            if (moq.isNotEmpty)
              _buildDetailRow(Icons.production_quantity_limits_outlined, 'Quantity', moq),

            const SizedBox(height: 10),

            // Date
            Row(
              children: [
                Icon(Icons.access_time_outlined, size: 14, color: AppColors.grey.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: TextStyle(fontSize: 12, color: AppColors.grey.withValues(alpha: 0.8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 13, color: AppColors.grey, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  _StageInfo _getStageInfo(String stage) {
    switch (stage) {
      case 'COMPLETED':
        return _StageInfo('Completed', const Color(0xFF2E7D32));
      case 'PRODUCT_SELECTION':
      case 'MOQ_SELECTION':
        return _StageInfo('Selecting', const Color(0xFFE65100));
      case 'PRICE_RANGE_SELECTION':
        return _StageInfo('Browsing', const Color(0xFF1565C0));
      case 'CATEGORY_SELECTION':
      case 'THEME_SELECTION':
        return _StageInfo('In Progress', const Color(0xFFF9A825));
      default:
        return _StageInfo('Started', AppColors.grey);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_outlined,
            size: 80,
            color: AppColors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 24),
          Text(
            'No Requests Yet',
            style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Your product search requests will appear here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load requests',
              style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.read<SearchHistoryBloc>().add(LoadSearchHistory()),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageInfo {
  final String label;
  final Color color;
  _StageInfo(this.label, this.color);
}
