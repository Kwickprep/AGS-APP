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
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final FileUploadService _fileUploadService = GetIt.I<FileUploadService>();
  final ImagePicker _imagePicker = ImagePicker();

  final List<File> _selectedImages = [];
  List<String> _uploadedDocumentIds = [];
  bool _isUploadingImages = false;

  void _handleSearch(BuildContext context) {
    final query = _controller.text.trim();
    if (query.isEmpty && _uploadedDocumentIds.isEmpty) {
      CustomToast.show(context, 'Please describe your requirements or upload images', type: ToastType.error);
      return;
    }
    context.read<UserProductSearchBloc>().add(SearchProducts(query: query, documentIds: _uploadedDocumentIds));
    _controller.clear();
    setState(() {
      _selectedImages.clear();
      _uploadedDocumentIds.clear();
    });
    FocusScope.of(context).unfocus();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
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

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserProductSearchBloc(),
      child: BlocConsumer<UserProductSearchBloc, UserProductSearchState>(
        listener: (context, state) {
          if (state is UserProductSearchError) {
            CustomToast.show(context, state.message, type: ToastType.error);
          }
          if (state is UserProductSearchConversation || state is UserProductSearchCompleted) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          final isInitial = state is UserProductSearchInitial;
          final isLoading = state is UserProductSearchLoading;

          List<ChatMessage> messages = [];
          List<AISuggestedTheme> themes = [];
          List<PriceRange> priceRanges = [];
          List<UserProductSearchModel> products = [];
          String stage = 'INITIAL';
          bool canGoBack = false;

          if (state is UserProductSearchLoading) {
            messages = state.messages;
          } else if (state is UserProductSearchConversation) {
            messages = state.messages;
            themes = state.suggestedThemes;
            priceRanges = state.availablePriceRanges;
            products = state.products;
            stage = state.stage;
            canGoBack = state.canGoBack;
          } else if (state is UserProductSearchCompleted) {
            messages = state.messages;
            stage = 'COMPLETED';
          } else if (state is UserProductSearchError) {
            messages = state.messages;
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(child: Image.asset('assets/images/chatbot_bg.png', fit: BoxFit.cover)),
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _buildHeader(context, isInitial),
                        Expanded(
                          child: isInitial
                              ? _buildInitialContent()
                              : _buildChatContent(context, messages, themes, priceRanges, products, isLoading, stage, canGoBack),
                        ),
                        if (isInitial) _buildInputArea(context),
                      ],
                    ),
                  ),
                ],
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
      child: Row(
        children: [
          const SizedBox(width: 36),
          const Expanded(
            child: Center(
              child: Text(
                "Promotional Aid Ideas",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
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

  // ===== INITIAL CONTENT =====
  Widget _buildInitialContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Describe your brand message or tagline, or upload a brand visual to discover the perfect Promotional Aid.",
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w400, color: AppColors.textPrimary.withValues(alpha: 0.8)),
          ),
        ),
        const Spacer(),
        if (_selectedImages.isNotEmpty || _isUploadingImages) _buildImagePreview(),
      ],
    );
  }

  // ===== CHAT CONTENT =====
  Widget _buildChatContent(
    BuildContext context,
    List<ChatMessage> messages,
    List<AISuggestedTheme> themes,
    List<PriceRange> priceRanges,
    List<UserProductSearchModel> products,
    bool isLoading,
    String stage,
    bool canGoBack,
  ) {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        ...messages.map((m) => _buildChatMessage(m)),

        // Loading
        if (isLoading) _buildLoadingIndicator(),

        // Theme selection
        if (themes.isNotEmpty && !isLoading) _buildSectionHeader('SELECT A THEME'),
        if (themes.isNotEmpty && !isLoading) ...themes.map((t) => _buildThemeCard(context, t)),
        if (!isLoading && stage == 'THEME_SELECTION' && themes.isEmpty) _buildEmptyState(context, 'No Matching Themes', 'Try different requirements.', canGoBack),

        // Price range selection
        if (priceRanges.isNotEmpty && !isLoading) _buildSectionHeader('SELECT YOUR BUDGET'),
        if (priceRanges.isNotEmpty && !isLoading) _buildPriceRangeGrid(context, priceRanges),

        // Product browsing
        if (products.isNotEmpty && !isLoading && (stage == 'PRODUCT_SELECTION' || stage == 'MOQ_SELECTION'))
          _buildSectionHeader('RECOMMENDED PRODUCTS'),
        if (products.isNotEmpty && !isLoading && (stage == 'PRODUCT_SELECTION' || stage == 'MOQ_SELECTION'))
          ...products.map((p) => _buildProductCard(context, p, stage)),

        if (!isLoading && stage == 'PRODUCT_SELECTION' && products.isEmpty)
          _buildEmptyState(context, 'No Products Found', 'Try a different budget range or theme.', canGoBack),

        // MOQ selection
        if (stage == 'MOQ_SELECTION' && !isLoading) _buildMoqSection(context),

        // Completed
        if (stage == 'COMPLETED' && !isLoading) _buildCompletedSection(context),

        SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
      ],
    );
  }

  // ===== CHAT BUBBLE =====
  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.isUser;
    final time = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildBotAvatar(), const SizedBox(width: 12)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(color: isUser ? Colors.white : AppColors.textPrimary, fontSize: 15, height: 1.4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(time, style: TextStyle(color: AppColors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 12), _buildUserAvatar()],
        ],
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: const Icon(Icons.smart_toy_outlined, size: 20, color: AppColors.primary),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: AppColors.grey.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: const Icon(Icons.person_outline, size: 20, color: AppColors.grey),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(children: [
        _buildBotAvatar(),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
            const SizedBox(width: 12),
            Text('Analyzing...', style: TextStyle(color: AppColors.grey, fontSize: 14)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(children: [
        Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(color: AppColors.grey, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
      ]),
    );
  }

  // ===== THEME CARDS =====
  Widget _buildThemeCard(BuildContext context, AISuggestedTheme theme) {
    return GestureDetector(
      onTap: () => context.read<UserProductSearchBloc>().add(SelectTheme(theme: theme)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.palette_outlined, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(theme.name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              if (theme.reason != null) ...[
                const SizedBox(height: 4),
                Text(theme.reason!, style: TextStyle(color: AppColors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
          const Icon(Icons.chevron_right, color: AppColors.grey),
        ]),
      ),
    );
  }

  // ===== PRICE RANGE GRID =====
  Widget _buildPriceRangeGrid(BuildContext context, List<PriceRange> priceRanges) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: priceRanges.map((pr) {
        return GestureDetector(
          onTap: () => context.read<UserProductSearchBloc>().add(SelectPriceRange(priceRange: pr)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
            ),
            child: Text(
              pr.label,
              style: const TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ===== PRODUCT CARDS =====
  Widget _buildProductCard(BuildContext context, UserProductSearchModel product, String stage) {
    final desc = product.aiGeneratedDescription ?? product.description ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          if (product.imageUrl != null && product.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                product.imageUrl!,
                height: 180, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120, color: AppColors.lightGrey,
                  child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 40, color: AppColors.grey)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              if (product.brand != null) ...[
                const SizedBox(height: 4),
                Text(product.brand!.name, style: TextStyle(fontSize: 13, color: AppColors.grey)),
              ],
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5), maxLines: 4, overflow: TextOverflow.ellipsis),
              ],
              if (product.conceptAlignment.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: product.conceptAlignment.take(3).map((c) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(c, style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32), fontWeight: FontWeight.w500)),
                  )).toList(),
                ),
              ],
              if (stage == 'PRODUCT_SELECTION') ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.read<UserProductSearchBloc>().add(SelectProduct(product: product)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('I WANT THIS', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  // ===== MOQ SECTION =====
  Widget _buildMoqSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SELECT QUANTITY'),
        const SizedBox(height: 4),
        ...MoqRange.options.map((moq) => GestureDetector(
          onTap: () => context.read<UserProductSearchBloc>().add(SubmitMoq(moq: moq.label)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(children: [
              const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(moq.label, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: AppColors.grey, size: 20),
            ]),
          ),
        )),
      ],
    );
  }

  // ===== COMPLETED =====
  Widget _buildCompletedSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: const Color(0xFF2E7D32).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline, size: 32, color: Color(0xFF2E7D32)),
        ),
        const SizedBox(height: 16),
        const Text('Request Submitted!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Text(
          'Our AGS Promotional Aid Expert will connect with you within 24 working hours.',
          style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.read<UserProductSearchBloc>().add(ClearSearch()),
            icon: const Icon(Icons.search, size: 20),
            label: const Text('New Search'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }

  // ===== EMPTY STATE =====
  Widget _buildEmptyState(BuildContext context, String title, String subtitle, bool canGoBack) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.search_off_outlined, size: 32, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.4), textAlign: TextAlign.center),
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
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
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
      ]),
    );
  }

  // ===== IMAGE PREVIEW =====
  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_isUploadingImages)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary))),
              SizedBox(width: 12),
              Text('Uploading images...', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
            ]),
          ),
        if (_selectedImages.isNotEmpty && !_isUploadingImages)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => Stack(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary),
                    image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                  ),
                ),
                Positioned(
                  top: 4, right: 4,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  // ===== INPUT AREA =====
  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).viewPadding.bottom + 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            width: 40, height: 40,
            margin: const EdgeInsets.only(bottom: 4),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            constraints: const BoxConstraints(minHeight: 48, maxHeight: 150),
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  decoration: const InputDecoration(
                    hintText: "Describe your requirements",
                    hintStyle: TextStyle(color: AppColors.grey, fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _handleSearch(context),
                child: Container(
                  width: 36, height: 36,
                  margin: const EdgeInsets.only(right: 6, bottom: 6, left: 4),
                  decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_upward, color: AppColors.primary, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
