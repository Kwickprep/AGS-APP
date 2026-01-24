import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';
import '../../services/product_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/brand_service.dart';
import '../../services/category_service.dart';
import '../../services/tag_service.dart';
import '../../services/theme_service.dart';
import '../../models/theme_model.dart';
import '../../models/product_model.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_toast.dart';

class ProductCreateScreen extends StatefulWidget {
  final ProductModel? product;
  final bool isEdit;

  const ProductCreateScreen({super.key, this.product, this.isEdit = false});

  @override
  State<ProductCreateScreen> createState() => _ProductCreateScreenState();
}

class _ProductCreateScreenState extends State<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProductService _productService = GetIt.I<ProductService>();
  final FileUploadService _fileUploadService = GetIt.I<FileUploadService>();
  final BrandService _brandService = GetIt.I<BrandService>();
  final CategoryService _categoryService = GetIt.I<CategoryService>();
  final TagService _tagService = GetIt.I<TagService>();
  final ThemeService _themeService = GetIt.I<ThemeService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _aopController = TextEditingController();
  final _landedController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Dropdown values
  String? _selectedPriceRange;
  String? _selectedBrandId;
  List<String> _selectedCategoryIds = [];
  List<String> _selectedTagIds = [];
  bool _isActive = true;

  // Image upload
  final List<File> _selectedImages = [];
  List<String> _uploadedImageIds = [];
  List<String> _existingImageIds = [];
  final Map<String, String> _existingImageUrls = {};
  bool _isUploadingImages = false;

  // Dropdown data
  List<DropdownItem<String>> _brandOptions = [];
  List<CategoryOption> _categoryOptions = [];
  List<TagOption> _tagOptions = [];

  // Themes data
  List<ThemeModel> _themes = [];
  int _themesCurrentPage = 1;
  int _themesTotalPages = 1;
  int _themesTotal = 0;
  final int _themesPerPage = 10;
  final Map<String, TextEditingController> _relevanceScoreControllers = {};
  final Map<String, int?> _themeRelevanceScores = {};
  final TextEditingController _themeSearchController = TextEditingController();
  String _themeSearchQuery = '';
  Timer? _themeSearchDebounce;

  // Price range options
  final List<DropdownItem<String>> _priceRangeOptions = [
    DropdownItem(value: '₹0 - ₹100', label: '₹0 - ₹100'),
    DropdownItem(value: '₹101 - ₹200', label: '₹101 - ₹200'),
    DropdownItem(value: '₹201 - ₹300', label: '₹201 - ₹300'),
    DropdownItem(value: '₹301 - ₹500', label: '₹301 - ₹500'),
    DropdownItem(value: '₹501 - ₹750', label: '₹501 - ₹750'),
    DropdownItem(value: '₹751 - ₹1,000', label: '₹751 - ₹1,000'),
    DropdownItem(value: '₹1,001 - ₹1,500', label: '₹1,001 - ₹1,500'),
    DropdownItem(value: '₹1,501 - ₹2,500', label: '₹1,501 - ₹2,500'),
    DropdownItem(value: '₹2,501 - ₹5,000', label: '₹2,501 - ₹5,000'),
    DropdownItem(value: '₹5,001 - ₹10,000', label: '₹5,001 - ₹10,000'),
    DropdownItem(value: '₹10,001 & above', label: '₹10,001 & above'),
  ];

  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.isEdit && widget.product != null) {
      _prefillFormData();
    }
  }

  void _prefillFormData() {
    final product = widget.product!;

    // Set text fields
    _nameController.text = product.name;
    if (product.price != '-' && product.price.isNotEmpty) {
      // Remove ₹ symbol if present
      _priceController.text = product.price
          .replaceAll('₹', '')
          .replaceAll(',', '')
          .trim();
    }
    if (product.aop != '-' && product.aop.isNotEmpty) {
      _aopController.text = product.aop
          .replaceAll('₹', '')
          .replaceAll(',', '')
          .trim();
    }
    if (product.landed != '-' && product.landed.isNotEmpty) {
      _landedController.text = product.landed
          .replaceAll('₹', '')
          .replaceAll(',', '')
          .trim();
    }
    if (product.description != '-' && product.description.isNotEmpty) {
      _descriptionController.text = product.description;
    }

    // Set dropdowns and selections
    _isActive = product.isActive;
    if (product.priceRange.isNotEmpty && product.priceRange != '-') {
      _selectedPriceRange = product.priceRange;
    }

    // Set brand (will be set after brands are loaded)
    if (product.brandObject != null &&
        product.brandObject!.id.isNotEmpty &&
        product.brandObject!.id != '-') {
      _selectedBrandId = product.brandObject!.id;
    }

    // Set categories (will be selected after categories are loaded)
    _selectedCategoryIds = product.categories
        .where((c) => c.id.isNotEmpty && c.id != '-')
        .map((c) => c.id)
        .toList();

    // Set tags (will be selected after tags are loaded)
    _selectedTagIds = product.tags
        .where((t) => t.id.isNotEmpty && t.id != '-')
        .map((t) => t.id)
        .toList();

    // Set existing images
    _existingImageIds = product.images
        .where((i) => i.id.isNotEmpty && i.id != '-')
        .map((i) => i.id)
        .toList();

    // Set theme relevance scores
    for (final theme in product.themes) {
      if (theme.id.isNotEmpty && theme.id != '-') {
        _themeRelevanceScores[theme.id] = theme.relevanceScore;
      }
    }

    // Load existing images
    if (_existingImageIds.isNotEmpty) {
      _loadExistingImages();
    }
  }

  Future<void> _loadExistingImages() async {
    if (_existingImageIds.isEmpty) return;

    try {
      final presignedUrls = await _fileUploadService.getPresignedUrls(
        _existingImageIds,
      );
      setState(() {
        _existingImageUrls.addAll(presignedUrls);
      });
    } catch (e) {
      debugPrint('Failed to load existing images: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _aopController.dispose();
    _landedController.dispose();
    _descriptionController.dispose();
    _themeSearchDebounce?.cancel();
    _themeSearchController.dispose();
    // Dispose all relevance score controllers
    for (var controller in _relevanceScoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      // Load brands, categories, tags, and themes in parallel
      final results = await Future.wait([
        _brandService.getActiveBrands(),
        _categoryService.getActiveCategories(),
        _tagService.getActiveTags(),
        _themeService.getThemes(
          page: _themesCurrentPage,
          take: _themesPerPage,
          filters: {'isActive': true},
        ),
      ]);

      final brands = results[0] as List;
      final categories = results[1] as List;
      final tags = results[2] as List;
      final themesResponse = results[3] as ThemeResponse;

      setState(() {
        _brandOptions = brands
            .map(
              (brand) =>
                  DropdownItem<String>(value: brand.id, label: brand.name),
            )
            .toList();

        _categoryOptions = categories
            .map(
              (category) =>
                  CategoryOption(id: category.id, name: category.name),
            )
            .toList();

        _tagOptions = tags
            .map((tag) => TagOption(id: tag.id, name: tag.name))
            .toList();

        _themes = themesResponse.records;
        _themesCurrentPage = themesResponse.page;
        _themesTotalPages = themesResponse.totalPages;
        _themesTotal = themesResponse.total;

        // Sort themes to show ones with scores first when in edit mode
        if (widget.isEdit && _themeRelevanceScores.isNotEmpty) {
          _sortThemesByRelevanceScore();
        }

        // Initialize relevance score controllers for each theme
        for (var theme in _themes) {
          if (!_relevanceScoreControllers.containsKey(theme.id)) {
            final controller = TextEditingController();
            // Prefill score if it exists
            if (_themeRelevanceScores.containsKey(theme.id)) {
              final score = _themeRelevanceScores[theme.id];
              if (score != null && score > 0) {
                controller.text = score.toString();
              }
            }
            _relevanceScoreControllers[theme.id] = controller;
          }
        }

        _isLoadingData = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingData = false;
      });
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to load data: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _loadThemes({int page = 1, String? search}) async {
    try {
      final themesResponse = await _themeService.getThemes(
        page: page,
        take: _themesPerPage,
        search: search ?? _themeSearchQuery,
        filters: {'isActive': true},
      );

      setState(() {
        _themes = themesResponse.records;
        _themesCurrentPage = themesResponse.page;
        _themesTotalPages = themesResponse.totalPages;
        _themesTotal = themesResponse.total;

        // Sort themes to show ones with scores first when in edit mode
        if (widget.isEdit && _themeRelevanceScores.isNotEmpty) {
          _sortThemesByRelevanceScore();
        }

        // Initialize relevance score controllers for new themes
        for (var theme in _themes) {
          if (!_relevanceScoreControllers.containsKey(theme.id)) {
            final controller = TextEditingController();
            // Prefill score if it exists
            if (_themeRelevanceScores.containsKey(theme.id)) {
              final score = _themeRelevanceScores[theme.id];
              if (score != null && score > 0) {
                controller.text = score.toString();
              }
            }
            _relevanceScoreControllers[theme.id] = controller;
          }
        }
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          'Failed to load themes: ${e.toString()}',
          type: ToastType.error,
        );
      }
    }
  }

  void _onThemeSearchChanged(String value) {
    // Cancel previous timer
    _themeSearchDebounce?.cancel();

    // Set new timer - wait 500ms before searching
    _themeSearchDebounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _themeSearchQuery = value.trim();
        _themesCurrentPage = 1;
      });
      _loadThemes(page: 1, search: _themeSearchQuery);
    });
  }

  void _sortThemesByRelevanceScore() {
    // Sort themes: ones with scores first, then the rest
    _themes.sort((a, b) {
      final aHasScore =
          _themeRelevanceScores.containsKey(a.id) &&
          _themeRelevanceScores[a.id] != null &&
          _themeRelevanceScores[a.id]! > 0;
      final bHasScore =
          _themeRelevanceScores.containsKey(b.id) &&
          _themeRelevanceScores[b.id] != null &&
          _themeRelevanceScores[b.id]! > 0;

      if (aHasScore && !bHasScore) {
        return -1; // a comes first
      } else if (!aHasScore && bHasScore) {
        return 1; // b comes first
      } else if (aHasScore && bHasScore) {
        // Both have scores, sort by score value (descending)
        return _themeRelevanceScores[b.id]!.compareTo(
          _themeRelevanceScores[a.id]!,
        );
      }
      return 0; // Keep original order for themes without scores
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(String imageId) {
    setState(() {
      _existingImageIds.remove(imageId);
      _existingImageUrls.remove(imageId);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploadingImages = true;
    });

    try {
      final uploadedIds = await _fileUploadService.uploadMultipleFiles(
        _selectedImages,
      );

      setState(() {
        _uploadedImageIds = uploadedIds;
        _isUploadingImages = false;
      });
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      throw Exception('Failed to upload images: ${e.toString()}');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryIds.isEmpty) {
      CustomToast.show(
        context,
        'Please select at least one category',
        type: ToastType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images first if any
      if (_selectedImages.isNotEmpty) {
        await _uploadImages();
      }

      // Parse optional number fields
      int? price;
      double? aop;
      double? landed;

      if (_priceController.text.trim().isNotEmpty) {
        price = int.tryParse(_priceController.text.trim());
      }

      if (_aopController.text.trim().isNotEmpty) {
        aop = double.tryParse(_aopController.text.trim());
      }

      if (_landedController.text.trim().isNotEmpty) {
        landed = double.tryParse(_landedController.text.trim());
      }

      // Build themes array with relevance scores
      final List<Map<String, dynamic>> themesData = [];
      _themeRelevanceScores.forEach((themeId, score) {
        if (score != null && score > 0) {
          themesData.add({'themeId': themeId, 'relevanceScore': score});
        }
      });

      // Combine existing and newly uploaded image IDs
      final allImageIds = [..._existingImageIds, ..._uploadedImageIds];

      // Build request data matching the API payload structure
      final data = {
        if (widget.isEdit) 'id': widget.product!.id,
        if (widget.isEdit) 'createdBy': widget.product!.createdBy,
        if (widget.isEdit) 'createdAt': widget.product!.createdAt,
        if (widget.isEdit) 'updatedBy': widget.product!.updater?.id ?? '',
        if (widget.isEdit) 'updatedAt': widget.product!.updatedAt,
        if (!widget.isEdit) 'id': '',
        if (!widget.isEdit) 'createdBy': '',
        if (!widget.isEdit) 'updatedBy': '',
        if (!widget.isEdit) 'createdAt': '',
        if (!widget.isEdit) 'updatedAt': '',
        'name': _nameController.text.trim(),
        'categoryIds': _selectedCategoryIds,
        'isActive': _isActive,
        if (allImageIds.isNotEmpty) 'imageIds': allImageIds,
        if (price != null) 'price': price,
        if (_selectedPriceRange != null) 'priceRange': _selectedPriceRange,
        if (_selectedBrandId != null) 'brandId': _selectedBrandId,
        if (_selectedTagIds.isNotEmpty) 'tagIds': _selectedTagIds,
        if (aop != null) 'aop': aop,
        if (landed != null) 'landed': landed,
        if (_descriptionController.text.trim().isNotEmpty)
          'description': _descriptionController.text.trim(),
        if (themesData.isNotEmpty) 'themes': themesData,
      };

      if (widget.isEdit) {
        await _productService.updateProduct(widget.product!.id, data);
      } else {
        await _productService.createProduct(data);
      }

      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit
              ? 'Product updated successfully'
              : 'Product created successfully',
          type: ToastType.success,
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(
          context,
          widget.isEdit
              ? 'Failed to update product: ${e.toString()}'
              : 'Failed to create product: ${e.toString()}',
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
    if (_isLoadingData) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.isEdit ? 'Edit Product' : 'Create Product',
            style: AppTextStyles.heading3,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isEdit ? 'Edit Product' : 'Create Product',
          style: AppTextStyles.heading3,
        ),
        bottom: const PreferredSize(
          preferredSize: Size(double.infinity, 1),
          child: Divider(height: 0.5, thickness: 1, color: AppColors.divider),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Images Section
                        _buildImageSection(),
                        const SizedBox(height: 24),

                        // Product Name (Required)
                        CustomTextField(
                          controller: _nameController,
                          label: 'Name',
                          hint: 'Enter product name',
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter product name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Price
                        CustomTextField(
                          controller: _priceController,
                          label: 'Price (₹)',
                          hint: 'Enter price',
                          isRequired: false,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final number = int.tryParse(value.trim());
                              if (number == null || number < 0) {
                                return 'Please enter a valid price';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Price Range Dropdown
                        CustomDropdown<String>(
                          label: 'Price Range',
                          hint: 'Select price range',
                          value: _selectedPriceRange,
                          isRequired: false,
                          items: _priceRangeOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedPriceRange = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Categories (Required - Multiselect)
                        _buildCategoriesSection(),
                        const SizedBox(height: 24),

                        // Brand Dropdown
                        CustomDropdown<String>(
                          label: 'Brand',
                          hint: 'Select brand',
                          value: _selectedBrandId,
                          isRequired: false,
                          items: _brandOptions,
                          onChanged: (value) {
                            setState(() {
                              _selectedBrandId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Tags (Multiselect)
                        _buildTagsSection(),
                        const SizedBox(height: 24),

                        // AOP
                        CustomTextField(
                          controller: _aopController,
                          label: 'AOP',
                          hint: 'Enter AOP',
                          isRequired: false,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final number = double.tryParse(value.trim());
                              if (number == null || number < 0) {
                                return 'Please enter a valid AOP';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Landed
                        CustomTextField(
                          controller: _landedController,
                          label: 'Landed',
                          hint: 'Enter landed',
                          isRequired: false,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final number = double.tryParse(value.trim());
                              if (number == null || number < 0) {
                                return 'Please enter a valid landed value';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Status Dropdown
                        CustomDropdown<bool>(
                          label: 'Status',
                          hint: 'Select status',
                          value: _isActive,
                          isRequired: true,
                          items: [
                            DropdownItem(value: true, label: 'Active'),
                            DropdownItem(value: false, label: 'Inactive'),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _isActive = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 24),

                        // Description
                        CustomTextField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Enter description',
                          isRequired: false,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),

                        // Themes Table Section
                        _buildThemesSection(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),

              // Sticky Submit Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: CustomButton(
                    text: 'Submit',
                    onPressed: _handleSubmit,
                    isLoading: _isLoading || _isUploadingImages,
                    icon: Icons.check,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Images',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Images grid (existing + newly selected)
        if (_existingImageIds.isNotEmpty || _selectedImages.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _existingImageIds.length + _selectedImages.length,
            itemBuilder: (context, index) {
              // Show existing images first, then newly selected ones
              if (index < _existingImageIds.length) {
                final imageId = _existingImageIds[index];
                final imageUrl = _existingImageUrls[imageId];

                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        color: AppColors.grey.withValues(alpha: 0.1),
                      ),
                      child: imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error_outline),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      );
                                    },
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeExistingImage(imageId),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // Newly selected file images
                final fileIndex = index - _existingImageIds.length;
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[fileIndex]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(fileIndex),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),
        ],

        // Upload box with dashed border
        InkWell(
          onTap: _pickImages,
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: AppColors.border,
              strokeWidth: 1.5,
              dashWidth: 5,
              dashSpace: 3,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Upload icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: AppColors.textLight.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Upload text
                  Text(
                    'Upload product images (JPG, PNG,',
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.textLight.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'GIF, WEBP). Max file size: 10MB.',
                    style: AppTextStyles.buttonSmall.copyWith(
                      color: AppColors.textLight.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Categories',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '*',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected categories chips
        if (_selectedCategoryIds.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedCategoryIds.map((id) {
              final category = _categoryOptions.firstWhere((c) => c.id == id);
              return Chip(
                label: Text(category.name),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedCategoryIds.remove(id);
                  });
                },
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Select categories button
        OutlinedButton.icon(
          onPressed: () => _showCategorySelection(),
          icon: const Icon(Icons.category_outlined, size: 20),
          label: Text(
            _selectedCategoryIds.isEmpty
                ? 'Select Categories'
                : 'Add More Categories',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Tags',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Selected tags chips
        if (_selectedTagIds.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTagIds.map((id) {
              final tag = _tagOptions.firstWhere((t) => t.id == id);
              return Chip(
                label: Text(tag.name),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _selectedTagIds.remove(id);
                  });
                },
                backgroundColor: AppColors.success.withValues(alpha: 0.1),
                labelStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.success,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: AppColors.success.withValues(alpha: 0.3),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],

        // Select tags button
        OutlinedButton.icon(
          onPressed: () => _showTagSelection(),
          icon: const Icon(Icons.label_outline, size: 20),
          label: Text(
            _selectedTagIds.isEmpty ? 'Select Tags' : 'Add More Tags',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }

  void _showCategorySelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CategorySelectionSheet(
        options: _categoryOptions,
        selectedIds: _selectedCategoryIds,
        onSelectionChanged: (selected) {
          setState(() {
            _selectedCategoryIds = selected;
          });
        },
      ),
    );
  }

  void _showTagSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TagSelectionSheet(
        options: _tagOptions,
        selectedIds: _selectedTagIds,
        onSelectionChanged: (selected) {
          setState(() {
            _selectedTagIds = selected;
          });
        },
      ),
    );
  }

  Widget _buildThemesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              'Product Themes',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(Optional)',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search field
        TextField(
          controller: _themeSearchController,
          decoration: InputDecoration(
            hintText: 'search',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _themeSearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _themeSearchController.clear();
                      _themeSearchDebounce?.cancel();
                      setState(() {
                        _themeSearchQuery = '';
                        _themesCurrentPage = 1;
                      });
                      _loadThemes(page: 1, search: '');
                    },
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            isDense: true,
          ),
          style: AppTextStyles.bodyMedium,
          onChanged: _onThemeSearchChanged,
        ),
        const SizedBox(height: 12),

        // Results count
        if (_themes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Showing ${(_themesCurrentPage - 1) * _themesPerPage + 1}-${(_themesCurrentPage - 1) * _themesPerPage + _themes.length} of $_themesTotal',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textLight.withValues(alpha: 0.7),
              ),
            ),
          ),

        // Themes table
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              // Table header
              Container(
                decoration: BoxDecoration(
                  color: AppColors.grey.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        'No.',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'Theme Name',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 120,
                      child: Text(
                        'Relevance Score',
                        style: AppTextStyles.buttonSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Table rows
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _themes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final theme = _themes[index];
                  final serialNumber =
                      (_themesCurrentPage - 1) * _themesPerPage + index + 1;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Serial number
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$serialNumber.',
                            style: AppTextStyles.buttonSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),

                        // Theme name
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                theme.name,
                                style: AppTextStyles.buttonSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (theme.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  theme.description,
                                  style: AppTextStyles.label.copyWith(
                                    color: AppColors.textLight.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Relevance score input
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _relevanceScoreControllers[theme.id],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: 'Enter Score',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: const BorderSide(
                                  color: AppColors.primary,
                                ),
                              ),
                              isDense: true,
                            ),
                            style: AppTextStyles.buttonSmall,
                            onChanged: (value) {
                              if (value.trim().isNotEmpty) {
                                final score = int.tryParse(value.trim());
                                if (score != null &&
                                    score >= 0 &&
                                    score <= 10) {
                                  setState(() {
                                    _themeRelevanceScores[theme.id] = score;
                                  });
                                }
                              } else {
                                setState(() {
                                  _themeRelevanceScores.remove(theme.id);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Pagination controls
        if (_themesTotalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous button
              IconButton(
                onPressed: _themesCurrentPage > 1
                    ? () => _loadThemes(page: _themesCurrentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left),
                color: AppColors.textPrimary,
                disabledColor: AppColors.textLight.withValues(alpha: 0.3),
              ),

              // Page numbers
              ...List.generate(_themesTotalPages > 5 ? 5 : _themesTotalPages, (
                index,
              ) {
                int pageNumber;
                if (_themesTotalPages <= 5) {
                  pageNumber = index + 1;
                } else if (_themesCurrentPage <= 3) {
                  pageNumber = index + 1;
                } else if (_themesCurrentPage >= _themesTotalPages - 2) {
                  pageNumber = _themesTotalPages - 4 + index;
                } else {
                  pageNumber = _themesCurrentPage - 2 + index;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: InkWell(
                    onTap: () => _loadThemes(page: pageNumber),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: pageNumber == _themesCurrentPage
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: pageNumber == _themesCurrentPage
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        '$pageNumber',
                        style: AppTextStyles.buttonSmall.copyWith(
                          color: pageNumber == _themesCurrentPage
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Next button
              IconButton(
                onPressed: _themesCurrentPage < _themesTotalPages
                    ? () => _loadThemes(page: _themesCurrentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right),
                color: AppColors.textPrimary,
                disabledColor: AppColors.textLight.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// Category Selection Sheet
class _CategorySelectionSheet extends StatefulWidget {
  final List<CategoryOption> options;
  final List<String> selectedIds;
  final Function(List<String>) onSelectionChanged;

  const _CategorySelectionSheet({
    required this.options,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<_CategorySelectionSheet> createState() =>
      _CategorySelectionSheetState();
}

class _CategorySelectionSheetState extends State<_CategorySelectionSheet> {
  late List<String> _tempSelectedIds;

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Categories',
                    style: AppTextStyles.heading3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Category list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final category = widget.options[index];
                final isSelected = _tempSelectedIds.contains(category.id);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _tempSelectedIds.add(category.id);
                      } else {
                        _tempSelectedIds.remove(category.id);
                      }
                    });
                  },
                  title: Text(category.name),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: CustomButton(
                text: 'Apply',
                onPressed: () {
                  widget.onSelectionChanged(_tempSelectedIds);
                  Navigator.pop(context);
                },
                icon: Icons.check,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Tag Selection Sheet
class _TagSelectionSheet extends StatefulWidget {
  final List<TagOption> options;
  final List<String> selectedIds;
  final Function(List<String>) onSelectionChanged;

  const _TagSelectionSheet({
    required this.options,
    required this.selectedIds,
    required this.onSelectionChanged,
  });

  @override
  State<_TagSelectionSheet> createState() => _TagSelectionSheetState();
}

class _TagSelectionSheetState extends State<_TagSelectionSheet> {
  late List<String> _tempSelectedIds;

  @override
  void initState() {
    super.initState();
    _tempSelectedIds = List.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Tags',
                    style: AppTextStyles.heading3,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Tag list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(20),
              itemCount: widget.options.length,
              itemBuilder: (context, index) {
                final tag = widget.options[index];
                final isSelected = _tempSelectedIds.contains(tag.id);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _tempSelectedIds.add(tag.id);
                      } else {
                        _tempSelectedIds.remove(tag.id);
                      }
                    });
                  },
                  title: Text(tag.name),
                  activeColor: AppColors.primary,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),

          // Apply button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: CustomButton(
                text: 'Apply',
                onPressed: () {
                  widget.onSelectionChanged(_tempSelectedIds);
                  Navigator.pop(context);
                },
                icon: Icons.check,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper classes
class CategoryOption {
  final String id;
  final String name;

  CategoryOption({required this.id, required this.name});
}

class TagOption {
  final String id;
  final String name;

  TagOption({required this.id, required this.name});
}

// Dashed Border Widget
class DashedBorder extends StatelessWidget {
  final Widget child;

  const DashedBorder({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DashedBorderPainter(
        color: AppColors.border,
        strokeWidth: 1.5,
        dashWidth: 5,
        dashSpace: 3,
      ),
      child: child,
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.dashWidth,
    required this.dashSpace,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(8),
        ),
      );

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final dashPaint = Paint()
      ..color = paint.color
      ..strokeWidth = paint.strokeWidth
      ..style = PaintingStyle.stroke;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final nextDash = distance + dashWidth;
        final nextSpace = nextDash + dashSpace;

        if (nextDash > metric.length) {
          canvas.drawPath(
            metric.extractPath(distance, metric.length),
            dashPaint,
          );
          break;
        }

        canvas.drawPath(metric.extractPath(distance, nextDash), dashPaint);
        distance = nextSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
