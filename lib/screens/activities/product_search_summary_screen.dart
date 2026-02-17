import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/activity_model.dart';
import '../../services/file_upload_service.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/custom_button.dart';

class ProductSearchSummaryScreen extends StatefulWidget {
  final ActivityModel activity;

  const ProductSearchSummaryScreen({
    super.key,
    required this.activity,
  });

  @override
  State<ProductSearchSummaryScreen> createState() =>
      _ProductSearchSummaryScreenState();
}

class _ProductSearchSummaryScreenState
    extends State<ProductSearchSummaryScreen> {
  final FileUploadService _fileUploadService = GetIt.I<FileUploadService>();
  String? _productImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProductImage();
  }

  Future<void> _loadProductImage() async {
    final fileId = widget.activity.productImageFileId;
    if (fileId != null && fileId.isNotEmpty) {
      final url = await _fileUploadService.getPresignedUrl(fileId);
      if (mounted && url != null) {
        setState(() {
          _productImageUrl = url;
        });
      }
    }
  }

  ActivityBody get _body => widget.activity.body!;

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
          'Activity Summary',
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
                    _buildSuccessHeader(),
                    const SizedBox(height: 20),
                    _buildCompletedStepper(),
                    const SizedBox(height: 20),
                    _buildSelectionsCard(),
                    const SizedBox(height: 16),
                    if (_body.selectedProduct != null) ...[
                      _buildProductCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildActivityInfoCard(),
                    const SizedBox(height: 16),
                    _buildMetadataCard(),
                  ],
                ),
              ),
            ),
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
                text: 'Back to Activities',
                onPressed: () => Navigator.pop(context),
                icon: Icons.arrow_back,
                variant: ButtonVariant.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Product Search Complete',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedStepper() {
    const steps = ['Details', 'Theme', 'Category', 'Price', 'Product'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGrey),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            return Expanded(
              child: Container(
                height: 2,
                color: AppColors.success,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIndex],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSelectionsCard() {
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
          const Text(
            'Selections',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryItem(
            'THEME',
            _body.selectedTheme?['name'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'CATEGORY',
            _body.selectedCategory?['name'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'PRICE RANGE',
            _body.selectedPriceRange?['label'] ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'MOQ',
            _body.moq ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    final product = _body.selectedProduct!;
    final productName = product['name'] ?? '';
    final brandName = product['brand'] is Map
        ? product['brand']['name'] ?? ''
        : '';
    final aiDescription = product['aiGeneratedDescription'] ?? '';
    final conceptAlignment = product['conceptAlignment'] as List<dynamic>?;

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
          const Text(
            'Selected Product',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _productImageUrl != null
                    ? Image.network(
                        _productImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildImagePlaceholder();
                        },
                      )
                    : _buildImagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (brandName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Brand: $brandName',
                        style: const TextStyle(
                          color: AppColors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (aiDescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.lightGrey),
            const SizedBox(height: 12),
            const Text(
              'AI Description',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              aiDescription,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
              ),
            ),
          ],
          if (conceptAlignment != null && conceptAlignment.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Concept Alignment',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            ...conceptAlignment.map((concept) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '\u2022 ',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        concept.toString(),
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
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.image,
        color: AppColors.grey,
      ),
    );
  }

  Widget _buildActivityInfoCard() {
    final activity = widget.activity;
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
          const Text(
            'Activity Information',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Type', activity.activityType),
          if (activity.company.isNotEmpty && activity.company != '-')
            _buildInfoRow('Company', activity.company),
          if (activity.user.isNotEmpty && activity.user != '-')
            _buildInfoRow('User', activity.user),
          if (activity.source.isNotEmpty && activity.source != '-')
            _buildInfoRow('Source', activity.source),
          if (activity.note.isNotEmpty && activity.note != '-')
            _buildInfoRow('Note', activity.note),
          if (_body.inputText != null && _body.inputText!.isNotEmpty)
            _buildInfoRow('Requirements', _body.inputText!),
        ],
      ),
    );
  }

  Widget _buildMetadataCard() {
    final activity = widget.activity;
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
          _buildInfoRow('Created By', activity.createdBy),
          _buildInfoRow('Created At', formatDate(activity.createdAt)),
          if (activity.updatedBy != null && activity.updatedBy!.isNotEmpty)
            _buildInfoRow('Updated By', activity.updatedBy!),
          if (activity.updatedAt != null)
            _buildInfoRow('Updated At', formatDate(activity.updatedAt!)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.grey,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
}
