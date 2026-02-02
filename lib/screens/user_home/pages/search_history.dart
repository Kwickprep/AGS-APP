import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';

import '../../../config/app_colors.dart';
import '../../../config/app_text_styles.dart';
import '../../../models/activity_model.dart';
import '../../../services/file_upload_service.dart';
import '../search_history_bloc.dart';

class SearchHistory extends StatefulWidget {
  const SearchHistory({super.key});

  @override
  State<SearchHistory> createState() => _SearchHistoryState();
}

class _SearchHistoryState extends State<SearchHistory> {
  final ScrollController _scrollController = ScrollController();
  final FileUploadService _fileUploadService = GetIt.I<FileUploadService>();
  final Map<String, String> _imageUrlCache = {};

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

  Future<void> _loadActivityImages(List<ActivityModel> activities) async {
    final idsToLoad = <String>[];
    for (final a in activities) {
      final fileId = a.productImageFileId;
      if (fileId != null && fileId.isNotEmpty && !_imageUrlCache.containsKey(fileId)) {
        idsToLoad.add(fileId);
      }
    }
    print('[HIST-IMG] IDs to load: $idsToLoad (${idsToLoad.length} new, ${_imageUrlCache.length} cached)');
    if (idsToLoad.isEmpty) return;
    try {
      final presignedUrls = await _fileUploadService.getPresignedUrls(idsToLoad);
      print('[HIST-IMG] Got ${presignedUrls.length} presigned URLs');
      if (mounted) setState(() => _imageUrlCache.addAll(presignedUrls));
    } catch (e) {
      print('[HIST-IMG] ERROR loading presigned URLs: $e');
    }
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
      body: BlocConsumer<SearchHistoryBloc, SearchHistoryState>(
        listener: (context, state) {
          if (state is SearchHistoryLoaded) {
            print('[HIST-IMG] SearchHistoryLoaded with ${state.activities.length} activities');
            for (final a in state.activities) {
              print('[HIST-IMG]   activity ${a.id}: productImageFileId=${a.productImageFileId}');
            }
            _loadActivityImages(state.activities);
          }
        },
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
                  return GestureDetector(
                    onTap: () => _showActivityDetail(state.activities[index]),
                    child: _buildActivityCard(state.activities[index]),
                  );
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
    // Use formatted note field (backend maps inputText → note) with body as fallback
    final inputText = activity.note.isNotEmpty && activity.note != '-'
        ? activity.note
        : (body?.inputText ?? '');
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
    final hasDocuments = activity.documents.isNotEmpty && activity.documents != '-'
        ? true
        : (body?.documentIds?.isNotEmpty == true);
    final stageInfo = _getStageInfo(stage);
    final imageUrl = activity.productImageFileId != null
        ? _imageUrlCache[activity.productImageFileId]
        : null;

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
            // Product image
            if (imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  height: 120,
                  color: const Color(0xFFF5F5F5),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Top row: query + stage badge (only for meaningful stages)
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
                if (stageInfo.label.isNotEmpty) ...[
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
        return _StageInfo('', AppColors.grey);
    }
  }

  void _showActivityDetail(ActivityModel activity) {
    final body = activity.body;
    // Backend formatter maps inputText → note field
    final inputText = activity.note.isNotEmpty && activity.note != '-'
        ? activity.note
        : (body?.inputText ?? '');
    final stage = body?.stage ?? 'INITIAL';
    final stageInfo = _getStageInfo(stage);
    final themeName = activity.theme.isNotEmpty && activity.theme != '-'
        ? activity.theme
        : (body?.selectedTheme?['name'] as String? ?? '');
    final themeReason = body?.selectedTheme?['reason'] as String? ?? '';
    final priceRangeLabel = activity.priceRange.isNotEmpty && activity.priceRange != '-'
        ? activity.priceRange
        : (body?.selectedPriceRange?['label'] as String? ?? '');
    final productName = activity.product.isNotEmpty && activity.product != '-'
        ? activity.product
        : (body?.selectedProduct?['name'] as String? ?? '');
    final productDesc = body?.selectedProduct?['aiGeneratedDescription'] as String?
        ?? body?.selectedProduct?['description'] as String?
        ?? '';
    final moq = activity.moq.isNotEmpty && activity.moq != '-'
        ? activity.moq
        : (body?.moq ?? '');
    final hasDocuments = activity.documents.isNotEmpty && activity.documents != '-'
        ? true
        : (body?.documentIds?.isNotEmpty == true);
    final productImageUrl = activity.productImageFileId != null
        ? _imageUrlCache[activity.productImageFileId]
        : null;

    String dateStr = '';
    if (activity.createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(activity.createdAt);
        dateStr = DateFormat('dd MMM yyyy, h:mm a').format(date);
      } catch (_) {
        dateStr = activity.createdAt;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Search Details',
                        style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
                      ),
                    ),
                    if (stageInfo.label.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: stageInfo.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          stageInfo.label,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stageInfo.color),
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Brand message
                    _buildDetailSection(
                      icon: Icons.edit_note_outlined,
                      title: 'Brand Message',
                      child: Text(
                        inputText.isNotEmpty ? inputText : (hasDocuments ? 'Image upload' : 'Not provided'),
                        style: TextStyle(
                          fontSize: 15,
                          color: inputText.isNotEmpty ? AppColors.textPrimary : AppColors.textSecondary,
                          fontStyle: inputText.isNotEmpty ? FontStyle.normal : FontStyle.italic,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Date
                    if (dateStr.isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.calendar_today_outlined,
                        title: 'Date',
                        child: Text(dateStr, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                      ),

                    // Theme
                    if (themeName.isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.palette_outlined,
                        title: 'Selected Theme',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(themeName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            if (themeReason.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(themeReason, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
                            ],
                          ],
                        ),
                      ),

                    // Price Range
                    if (priceRangeLabel.isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.payments_outlined,
                        title: 'Price Range',
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(priceRangeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ),
                      ),

                    // Selected Product
                    if (productName.isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.inventory_2_outlined,
                        title: 'Selected Product',
                        child: Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (productImageUrl != null)
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  color: const Color(0xFFF5F5F5),
                                  child: Image.network(
                                    productImageUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(productName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                    if (productDesc.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(productDesc, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // MOQ
                    if (moq.isNotEmpty)
                      _buildDetailSection(
                        icon: Icons.production_quantity_limits_outlined,
                        title: 'Requested Quantity (MOQ)',
                        child: Text(moq, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection({required IconData icon, required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.grey)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: child,
          ),
        ],
      ),
    );
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
