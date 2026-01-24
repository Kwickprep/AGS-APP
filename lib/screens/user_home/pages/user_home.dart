import 'dart:io';
import 'package:ags/config/app_colors.dart';
import 'package:ags/config/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../../config/huge_icons.dart';
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

  // Image upload state
  final List<File> _selectedImages = [];
  List<String> _uploadedDocumentIds = [];
  bool _isUploadingImages = false;

  void _handleSearch(BuildContext context) {
    final query = _controller.text.trim();
    final hasText = query.isNotEmpty;
    final hasImages = _uploadedDocumentIds.isNotEmpty;

    if (!hasText && !hasImages) {
      CustomToast.show(
        context,
        'Please provide text or upload images',
        type: ToastType.error,
      );
      return;
    }

    context.read<UserProductSearchBloc>().add(
      SearchProducts(query: query, documentIds: _uploadedDocumentIds),
    );
    _controller.clear();
    setState(() {
      _selectedImages.clear();
      _uploadedDocumentIds.clear();
    });
    FocusScope.of(context).unfocus();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 100), () {
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
      final List<XFile> images = await _imagePicker.pickMultiImage();

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(
            images.map((xFile) => File(xFile.path)).toList(),
          );
        });

        await _uploadImages();
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to pick images: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final documentIds = await _fileUploadService.uploadMultipleFiles(
        _selectedImages,
      );
      setState(() {
        _uploadedDocumentIds = documentIds;
        _isUploadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to upload images: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      if (index < _uploadedDocumentIds.length) {
        _uploadedDocumentIds.removeAt(index);
      }
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
      create: (context) => UserProductSearchBloc(),
      child: BlocConsumer<UserProductSearchBloc, UserProductSearchState>(
        listener: (context, state) {
          if (state is UserProductSearchError) {
            CustomToast.show(context, state.message, type: ToastType.error);
          }
        },
        builder: (context, state) {
          final bool isInitial = state is UserProductSearchInitial;
          final bool isLoading = state is UserProductSearchLoading;
          final bool isConversation = state is UserProductSearchConversation;

          List<ChatMessage> messages = [];
          List<AISuggestedTheme> themes = [];
          List<AISuggestedCategory> categories = [];
          String stage = 'INITIAL';
          bool canGoBack = false;

          if (isLoading) {
            messages = (state).messages;
          } else if (isConversation) {
            final convState = state;
            messages = convState.messages;
            themes = convState.suggestedThemes;
            categories = convState.suggestedCategories;
            stage = convState.stage;
            canGoBack = convState.canGoBack;
          } else if (state is UserProductSearchError) {
            messages = (state).messages;
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
              body: Stack(
                children: [
                  // Background image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/chatbot_bg.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Content
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(context, isInitial),

                        // Content area
                        Expanded(
                          child: isInitial
                              ? _buildInitialContent()
                              : _buildChatContent(
                                  context,
                                  messages,
                                  themes,
                                  categories,
                                  isLoading,
                                  stage,
                                  canGoBack,
                                ),
                        ),

                        // Input area (only show in initial state)
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

  Widget _buildHeader(BuildContext context, bool isInitial) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.transparent),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Icon(
              HugeIcons.hamBurger,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                "Product Search",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (!isInitial)
            GestureDetector(
              onTap: () {
                context.read<UserProductSearchBloc>().add(ClearSearch());
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _buildInitialContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Describe your requirements or upload an image to search an appropriate Product",
            textAlign: TextAlign.center,
            style: AppTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w400,
              color: AppColors.textPrimary.withValues(alpha: 0.8),
            ),
          ),
        ),
        const Spacer(),
        // Image preview section
        if (_selectedImages.isNotEmpty || _isUploadingImages)
          _buildImagePreview(),
      ],
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isUploadingImages)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Uploading images...',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          if (_selectedImages.isNotEmpty && !_isUploadingImages)
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatContent(
    BuildContext context,
    List<ChatMessage> messages,
    List<AISuggestedTheme> themes,
    List<AISuggestedCategory> categories,
    bool isLoading,
    String stage,
    bool canGoBack,
  ) {
    // Check if we should show empty states
    final bool showEmptyThemes =
        !isLoading && stage == 'THEME_SELECTION' && themes.isEmpty;
    final bool showEmptyCategories =
        !isLoading && stage == 'CATEGORY_SELECTION' && categories.isEmpty;

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // Chat messages
        ...messages.map((message) => _buildChatMessage(message)),

        // Loading indicator
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                _buildBotAvatar(),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Thinking...',
                        style: TextStyle(color: AppColors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // Theme selection cards or empty state
        if (themes.isNotEmpty && !isLoading)
          _buildThemeSection(context, themes),
        if (showEmptyThemes) _buildEmptyThemesState(context),

        // Category selection cards or empty state
        if (categories.isNotEmpty && !isLoading)
          _buildCategorySection(context, categories),
        if (showEmptyCategories) _buildEmptyCategoriesState(context, canGoBack),

        // Bottom padding
        SizedBox(height: MediaQuery.of(context).viewPadding.bottom + 16),
      ],
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    final isUser = message.isUser;
    final time =
        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[_buildBotAvatar(), const SizedBox(width: 12)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primary : AppColors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser
                          ? const Radius.circular(16)
                          : Radius.zero,
                      bottomRight: isUser
                          ? Radius.zero
                          : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(color: AppColors.grey, fontSize: 12),
                ),
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
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.smart_toy_outlined,
        size: 20,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.grey.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person_outline, size: 20, color: AppColors.grey),
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    List<AISuggestedTheme> themes,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SELECT A THEME',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...themes.map((theme) => _buildThemeCard(context, theme)),
      ],
    );
  }

  Widget _buildThemeCard(BuildContext context, AISuggestedTheme theme) {
    return GestureDetector(
      onTap: () {
        context.read<UserProductSearchBloc>().add(SelectTheme(theme: theme));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.category_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (theme.reason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      theme.reason!,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    List<AISuggestedCategory> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'SELECT A CATEGORY',
                style: TextStyle(
                  color: AppColors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        ...categories.map((category) => _buildCategoryCard(context, category)),
      ],
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    AISuggestedCategory category,
  ) {
    return GestureDetector(
      onTap: () {
        context.read<UserProductSearchBloc>().add(
          SelectCategory(category: category),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.lightGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_view_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      category.description!,
                      style: TextStyle(color: AppColors.grey, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyThemesState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_outlined,
              size: 32,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Matching Themes Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We couldn't find any themes that match your requirements. Please review your input or try a different approach.",
            style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.read<UserProductSearchBloc>().add(ClearSearch());
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Start with New Requirements'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<UserProductSearchBloc>().add(ClearSearch());
                _pickImages();
              },
              icon: const Icon(Icons.image_outlined, size: 20),
              label: const Text('Upload an Image'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCategoriesState(BuildContext context, bool canGoBack) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 32,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Matching Categories Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We couldn't find any categories for the selected theme. Please try changing the theme or start over.",
            style: TextStyle(fontSize: 14, color: AppColors.grey, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (canGoBack)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<UserProductSearchBloc>().add(GoBack());
                },
                icon: const Icon(Icons.arrow_back, size: 20),
                label: const Text('Change Theme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (canGoBack) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<UserProductSearchBloc>().add(ClearSearch());
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Start Over'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Plus button
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 12),
          // Expandable text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 150),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: "Describe your requirements",
                        hintStyle: TextStyle(
                          color: AppColors.grey,
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  // Send button
                  GestureDetector(
                    onTap: () => _handleSearch(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(
                        right: 6,
                        bottom: 6,
                        left: 4,
                      ),
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
