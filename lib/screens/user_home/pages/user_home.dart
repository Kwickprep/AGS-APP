import 'dart:async';
import 'dart:io';
import 'package:ags/config/app_colors.dart';
import 'package:ags/config/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_product_search_model.dart';
import '../../../services/file_upload_service.dart';
import '../../../widgets/custom_toast.dart';
import '../user_product_search_bloc.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FileUploadService _fileUploadService = GetIt.I<FileUploadService>();
  final ImagePicker _imagePicker = ImagePicker();

  final List<File> _selectedImages = [];
  List<String> _uploadedDocumentIds = [];
  bool _isUploadingImages = false;

  // Local selection state (select-then-next pattern)
  AISuggestedTheme? _pickedTheme;
  PriceRange? _pickedPriceRange;
  UserProductSearchModel? _pickedProduct;
  MoqRange? _pickedMoq;

  // Pre-signed image URL cache (S3 bucket is private)
  final Map<String, String> _imageUrlCache = {};

  // Loading timer for progress messages & cancel button
  Timer? _loadingTimer;
  int _loadingElapsedSeconds = 0;

  void _handleSearch(BuildContext context) {
    final query = _controller.text.trim();
    if (query.isEmpty && _uploadedDocumentIds.isEmpty) {
      CustomToast.show(context, 'Please enter your brand message or upload visual material', type: ToastType.error);
      return;
    }
    context.read<UserProductSearchBloc>().add(SearchProducts(query: query, documentIds: _uploadedDocumentIds));
    _controller.clear();
    setState(() {
      _selectedImages.clear();
      _uploadedDocumentIds.clear();
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() => _selectedImages.addAll(images.map((x) => File(x.path))));
        await _uploadImages();
      }
    } catch (e) {
      if (mounted) CustomToast.show(context, 'Failed to pick images', type: ToastType.error);
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isUploadingImages = true);
    try {
      final ids = await _fileUploadService.uploadMultipleFiles(_selectedImages);
      setState(() {
        _uploadedDocumentIds = ids;
        _isUploadingImages = false;
      });
    } catch (e) {
      setState(() => _isUploadingImages = false);
      if (mounted) CustomToast.show(context, 'Failed to upload images', type: ToastType.error);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _uploadedDocumentIds.length) _uploadedDocumentIds.removeAt(index);
    });
  }

  Future<void> _loadProductImages(List<UserProductSearchModel> products) async {
    print('[IMG] _loadProductImages called with ${products.length} products');
    final idsToLoad = <String>[];
    for (final p in products) {
      print('[IMG] Product "${p.name}" has ${p.images.length} images, imageUrl=${p.imageUrl}');
      for (final img in p.images) {
        print('[IMG]   image id="${img.id}" fileUrl="${img.fileUrl}"');
        if (img.id.isNotEmpty && !_imageUrlCache.containsKey(img.id)) {
          idsToLoad.add(img.id);
        }
      }
    }
    if (idsToLoad.isEmpty) {
      print('[IMG] No image IDs to load - returning early');
      return;
    }
    print('[IMG] Loading presigned URLs for ${idsToLoad.length} IDs: $idsToLoad');
    try {
      final presignedUrls = await _fileUploadService.getPresignedUrls(idsToLoad);
      print('[IMG] Got ${presignedUrls.length} presigned URLs');
      for (final entry in presignedUrls.entries) {
        print('[IMG]   ${entry.key} => ${entry.value.substring(0, 80)}...');
      }
      if (mounted) {
        setState(() => _imageUrlCache.addAll(presignedUrls));
      }
    } catch (e) {
      print('[IMG] ERROR loading presigned URLs: $e');
    }
  }

  void _startLoadingTimer() {
    _loadingElapsedSeconds = 0;
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _loadingElapsedSeconds++);
    });
  }

  void _stopLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    _loadingElapsedSeconds = 0;
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserProductSearchBloc(),
      child: BlocConsumer<UserProductSearchBloc, UserProductSearchState>(
        listener: (context, state) {
          // Manage loading timer
          if (state is UserProductSearchLoading) {
            _startLoadingTimer();
          } else {
            _stopLoadingTimer();
          }
          // Clear local selections when stage changes
          setState(() {
            _pickedTheme = null;
            _pickedPriceRange = null;
            _pickedProduct = null;
            _pickedMoq = null;
          });
          // Load presigned image URLs when products arrive
          if (state is UserProductSearchConversation && state.products.isNotEmpty) {
            _loadProductImages(state.products);
          }
        },
        builder: (context, state) {
          final isInitial = state is UserProductSearchInitial;
          final isLoading = state is UserProductSearchLoading;
          final isError = state is UserProductSearchError;

          List<AISuggestedTheme> themes = [];
          List<PriceRange> priceRanges = [];
          List<UserProductSearchModel> products = [];
          String stage = 'INITIAL';
          bool canGoBack = false;

          if (state is UserProductSearchConversation) {
            themes = state.suggestedThemes;
            priceRanges = state.availablePriceRanges;
            products = state.products;
            stage = state.stage;
            canGoBack = state.canGoBack;
          } else if (state is UserProductSearchCompleted) {
            stage = 'COMPLETED';
          }

          final showStepIndicator = !isInitial && !isLoading && !isError && stage != 'COMPLETED';

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isInitial && !isError),
                    if (showStepIndicator)
                      _buildStepIndicator(stage),
                    Expanded(
                      child: isInitial
                          ? _buildInitialForm(context)
                          : isLoading
                              ? _buildLoadingView(context)
                              : isError
                                  ? _buildErrorView(context, state.message)
                                  : _buildStageContent(context, stage, themes, priceRanges, products, canGoBack),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== HEADER =====
  Widget _buildHeader(BuildContext context, bool isInitial) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 36),
          Expanded(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/images/ags_icon.png', width: 32, height: 32),
                  const SizedBox(width: 8),
                  const Text(
                    "AGS Connect",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
          if (!isInitial)
            GestureDetector(
              onTap: () => context.read<UserProductSearchBloc>().add(ClearSearch()),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.add, size: 20, color: AppColors.primary),
              ),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  // ===== STEP INDICATOR =====
  Widget _buildStepIndicator(String stage) {
    final steps = ['THEME_SELECTION', 'PRICE_RANGE_SELECTION', 'PRODUCT_SELECTION', 'MOQ_SELECTION'];
    final stepIndex = steps.indexOf(stage);
    final currentStep = stepIndex >= 0 ? stepIndex + 2 : 2;
    const totalSteps = 5;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step $currentStep of $totalSteps', style: AppTextStyles.caption),
              Text(_getStepLabel(stage), style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: currentStep / totalSteps,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  String _getStepLabel(String stage) {
    switch (stage) {
      case 'THEME_SELECTION':
        return 'Select Theme';
      case 'PRICE_RANGE_SELECTION':
        return 'Select Budget';
      case 'PRODUCT_SELECTION':
        return 'Choose Product';
      case 'MOQ_SELECTION':
        return 'Select Quantity';
      default:
        return '';
    }
  }

  // ===== INITIAL FORM (Step 1) =====
  Widget _buildInitialForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intro section
          Center(
            child: Column(
              children: [
                Image.asset('assets/images/ags_icon.png', width: 56, height: 56),
                const SizedBox(height: 16),
                Text(
                  'Promotional Aid Ideas',
                  style: AppTextStyles.heading2.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please write your brand message or brand tagline, or upload your brand visual material to discover the perfect promotional aid.',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Requirement note
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Color(0xFFF9A825)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Either a brand message/tagline OR visual material upload is required. You can provide both for better results.',
                    style: AppTextStyles.caption.copyWith(color: const Color(0xFF6D4C00), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Brand Message field
          Text('Brand Message / Tagline', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Enter your brand message or tagline...',
              hintStyle: const TextStyle(color: AppColors.grey, fontSize: 15),
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
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),

          // Upload section
          Text('Upload Brand Visual Material', style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          _buildUploadArea(),
          const SizedBox(height: 6),
          Text(
            'Supported: Images, PDF, Documents (max 10 MB)',
            style: AppTextStyles.caption,
          ),

          // Image preview
          if (_selectedImages.isNotEmpty || _isUploadingImages) ...[
            const SizedBox(height: 12),
            _buildImagePreview(),
          ],

          const SizedBox(height: 32),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploadingImages ? null : () => _handleSearch(context),
              icon: const Icon(Icons.search, size: 20),
              label: const Text('Search Promotional Aids'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.grey,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== UPLOAD AREA =====
  Widget _buildUploadArea() {
    return GestureDetector(
      onTap: _isUploadingImages ? null : _pickImages,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_upload_outlined, size: 36, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              'Tap to upload images or documents',
              style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  // ===== IMAGE PREVIEW =====
  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isUploadingImages)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
              SizedBox(width: 12),
              Text('Uploading...', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ]),
          ),
        if (_selectedImages.isNotEmpty && !_isUploadingImages)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary),
                      image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ===== LOADING VIEW =====
  Widget _buildLoadingView(BuildContext context) {
    final elapsed = _loadingElapsedSeconds;
    final showCancel = elapsed >= 300; // 5 minutes

    // Rotating progress messages based on elapsed time
    String title;
    String subtitle;
    if (elapsed < 15) {
      title = 'Analyzing your requirements...';
      subtitle = 'This may take a few moments';
    } else if (elapsed < 45) {
      title = 'Our AI is finding the best matches...';
      subtitle = 'Searching through our product catalog';
    } else if (elapsed < 90) {
      title = 'Almost there...';
      subtitle = 'Complex queries may take a bit longer';
    } else if (elapsed < 180) {
      title = 'Still working on it...';
      subtitle = 'Our AI is carefully analyzing your needs';
    } else {
      title = 'Processing your request...';
      subtitle = 'Thank you for your patience';
    }

    // Elapsed time display (mm:ss)
    final minutes = elapsed ~/ 60;
    final seconds = elapsed % 60;
    final timeStr = minutes > 0
        ? '${minutes}m ${seconds.toString().padLeft(2, '0')}s'
        : '${seconds}s';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: AppTextStyles.caption, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text(
              'Elapsed: $timeStr',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey, fontSize: 12),
            ),
            if (showCancel) ...[
              const SizedBox(height: 32),
              Text(
                'This is taking longer than expected.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<UserProductSearchBloc>().add(ClearSearch()),
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel & Start Over'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ===== ERROR VIEW =====
  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.refresh_outlined, size: 32, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              const Text('Please Try Again', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(message, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<UserProductSearchBloc>().add(ClearSearch()),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Start New Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== STAGE ROUTER =====
  Widget _buildStageContent(
    BuildContext context,
    String stage,
    List<AISuggestedTheme> themes,
    List<PriceRange> priceRanges,
    List<UserProductSearchModel> products,
    bool canGoBack,
  ) {
    switch (stage) {
      case 'THEME_SELECTION':
        return _buildThemeSelection(context, themes, canGoBack);
      case 'PRICE_RANGE_SELECTION':
        return _buildPriceRangeSelection(context, priceRanges, canGoBack);
      case 'PRODUCT_SELECTION':
        return _buildProductSelection(context, products, canGoBack);
      case 'MOQ_SELECTION':
        return _buildMoqSelection(context, products, canGoBack);
      case 'COMPLETED':
        return _buildCompletedView(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ===== THEME SELECTION (Step 2) =====
  Widget _buildThemeSelection(BuildContext context, List<AISuggestedTheme> themes, bool canGoBack) {
    if (themes.isEmpty) {
      return _buildEmptyState(context, 'No Matching Themes', 'Try different brand information.', canGoBack);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Select the theme that best matches your brand:',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              ...themes.map((t) => _buildThemeCard(context, t)),
              if (canGoBack) _buildBackButton(context),
            ],
          ),
        ),
        if (_pickedTheme != null)
          _buildNextButton(context, () {
            context.read<UserProductSearchBloc>().add(SelectTheme(theme: _pickedTheme!));
          }),
      ],
    );
  }

  // ===== PRICE RANGE SELECTION (Step 3) =====
  Widget _buildPriceRangeSelection(BuildContext context, List<PriceRange> priceRanges, bool canGoBack) {
    // Use WhatsApp-style 4 broad price ranges
    final ranges = PriceRange.defaultOptions;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Select your preferred budget range:',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              ...ranges.map((pr) {
                final isSelected = _pickedPriceRange?.label == pr.label;
                return GestureDetector(
                  onTap: () => setState(() => _pickedPriceRange = pr),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.payments_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            pr.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                );
              }),
              if (canGoBack) _buildBackButton(context),
            ],
          ),
        ),
        if (_pickedPriceRange != null)
          _buildNextButton(context, () {
            context.read<UserProductSearchBloc>().add(SelectPriceRange(priceRange: _pickedPriceRange!));
          }),
      ],
    );
  }

  // ===== PRODUCT SELECTION (Step 4) =====
  Widget _buildProductSelection(BuildContext context, List<UserProductSearchModel> products, bool canGoBack) {
    if (products.isEmpty) {
      return _buildEmptyState(context, 'No Products Found', 'Try a different budget range or theme.', canGoBack);
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Tap a product to select it, then press Next to proceed:',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              ...products.map((p) => _buildProductCard(context, p)),
              if (canGoBack) _buildBackButton(context),
            ],
          ),
        ),
        if (_pickedProduct != null)
          _buildNextButton(context, () {
            context.read<UserProductSearchBloc>().add(SelectProduct(product: _pickedProduct!));
          }),
      ],
    );
  }

  // ===== MOQ SELECTION (Step 5) =====
  Widget _buildMoqSelection(BuildContext context, List<UserProductSearchModel> products, bool canGoBack) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'Select the approximate quantity you need:',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
              ...MoqRange.options.map((moq) {
                final isSelected = _pickedMoq?.label == moq.label;
                return GestureDetector(
                  onTap: () => setState(() => _pickedMoq = moq),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.inventory_2_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            moq.label,
                            style: TextStyle(
                              fontSize: 15,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                      ],
                    ),
                  ),
                );
              }),
              if (canGoBack) _buildBackButton(context),
            ],
          ),
        ),
        if (_pickedMoq != null)
          _buildNextButton(context, () {
            context.read<UserProductSearchBloc>().add(SubmitMoq(moq: _pickedMoq!.label));
          }),
      ],
    );
  }

  // ===== COMPLETED VIEW =====
  Widget _buildCompletedView(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_outline, size: 36, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('Request Submitted!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'Our AGS Promotional Aid Expert will connect with you within 24 working hours.',
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Please note that the displayed price ranges are approximate and may vary depending on quantity, production timeline, availability, customization, delivery charges and GST.',
                style: AppTextStyles.caption.copyWith(height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.read<UserProductSearchBloc>().add(ClearSearch()),
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('New Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== THEME CARD =====
  Widget _buildThemeCard(BuildContext context, AISuggestedTheme theme) {
    final isSelected = _pickedTheme?.id == theme.id;
    return GestureDetector(
      onTap: () => setState(() => _pickedTheme = theme),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isSelected ? Icons.check_circle : Icons.palette_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.name, style: TextStyle(color: isSelected ? AppColors.primary : AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  if (theme.reason != null) ...[
                    const SizedBox(height: 4),
                    Text(theme.reason!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22)
            else
              const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  // ===== PRODUCT CARD =====
  Widget _buildProductCard(BuildContext context, UserProductSearchModel product) {
    final desc = product.aiGeneratedDescription ?? product.description ?? '';
    final isSelected = _pickedProduct?.id == product.id;
    // Use presigned URL from cache (S3 bucket is private, raw URLs return 403)
    String? imageUrl;
    if (product.images.isNotEmpty) {
      imageUrl = _imageUrlCache[product.images.first.id];
    }
    return GestureDetector(
      onTap: () => setState(() => _pickedProduct = product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSelected)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                color: AppColors.primary,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Selected', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            if (imageUrl != null && imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: isSelected ? BorderRadius.zero : const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5F5),
                  child: Image.network(
                    imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: AppColors.lightGrey,
                      child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.grey)),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (product.brand != null) ...[
                    const SizedBox(height: 4),
                    Text(product.brand!.name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
                  ],
                  if (product.conceptAlignment.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: product.conceptAlignment.take(3).map((c) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                            child: Text(c, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                          )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState(BuildContext context, String title, String subtitle, bool canGoBack) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.search_off_outlined, size: 32, color: AppColors.error),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              if (canGoBack)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.read<UserProductSearchBloc>().add(GoBack()),
                      icon: const Icon(Icons.arrow_back, size: 20),
                      label: const Text('Go Back'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<UserProductSearchBloc>().add(ClearSearch()),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: const Text('Start Over'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== NEXT BUTTON (pinned at bottom) =====
  Widget _buildNextButton(BuildContext context, VoidCallback onNext) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Next'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ===== BACK BUTTON =====
  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Center(
        child: TextButton.icon(
          onPressed: () => context.read<UserProductSearchBloc>().add(GoBack()),
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Go Back'),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
        ),
      ),
    );
  }
}
