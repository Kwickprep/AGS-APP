import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/ShimmerLoading.dart';

/// Product list screen with responsive card-based layout
class ProductScreen extends StatelessWidget {
  const ProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GenericListBloc<ProductModel>(
        service: GetIt.I<ProductService>(),
        sortComparator: _productSortComparator,
        filterPredicate: _productFilterPredicate,
      )..add(LoadData()),
      child: const ProductView(),
    );
  }

  static int _productSortComparator(
    ProductModel a,
    ProductModel b,
    String sortBy,
    String sortOrder,
  ) {
    int comparison = 0;
    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'price':
        comparison = a.priceValue.compareTo(b.priceValue);
        break;
      case 'category':
        comparison = a.category.compareTo(b.category);
        break;
      case 'brand':
        comparison = a.brand.compareTo(b.brand);
        break;
      case 'createdAt':
        comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
        break;
      case 'isActive':
        comparison = a.isActive == b.isActive ? 0 : (a.isActive ? 1 : -1);
        break;
      case 'createdBy':
        comparison = a.createdBy.compareTo(b.createdBy);
        break;
      default:
        comparison = 0;
    }
    return sortOrder == 'asc' ? comparison : -comparison;
  }

  static bool _productFilterPredicate(
    ProductModel product,
    Map<String, dynamic> filters,
  ) {
    if (filters.containsKey('status')) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !product.isActive) return false;
      if (statusFilter == 'inactive' && product.isActive) return false;
    }
    if (filters.containsKey('priceRange')) {
      final priceRange = filters['priceRange'] as String;
      final parts = priceRange.split('-');
      if (parts.length == 2) {
        final min = int.tryParse(parts[0]) ?? 0;
        final max = int.tryParse(parts[1]) ?? 999999;
        if (product.priceValue < min || product.priceValue > max) {
          return false;
        }
      }
    }
    return true;
  }

  static DateTime _parseDate(String dateStr) {
    try {
      if (dateStr.contains('T')) {
        return DateTime.parse(dateStr);
      }
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (e) {
      // Return current date if parsing fails
    }
    return DateTime.now();
  }
}

class ProductView extends StatelessWidget {
  const ProductView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Products'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create product not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<GenericListBloc<ProductModel>, GenericListState>(
        builder: (context, state) {
          if (state is GenericListLoading) {
            return const ShimmerLoading();
          }

          if (state is GenericListError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  const Text('Error loading products'),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      state.message,
                      style: const TextStyle(color: AppColors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<GenericListBloc<ProductModel>>().add(LoadData());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is GenericListLoaded<ProductModel>) {
            return Column(
              children: [
                GenericSearchBar(
                  key: const ValueKey('product_search_bar'),
                  initialSearchQuery: state.search,
                  onSearch: (query) {
                    context.read<GenericListBloc<ProductModel>>().add(SearchData(query));
                  },
                  onApplyFilters: (filters) {
                    context.read<GenericListBloc<ProductModel>>().add(ApplyFilters(filters));
                  },
                  currentFilters: state.filters ?? {},
                  searchHint: 'Search products...',
                  filterConfigs: [
                    FilterConfig.statusFilter(),
                    FilterConfig(
                      key: 'priceRange',
                      label: 'Price Range',
                      options: [
                        FilterOption(label: 'All', value: 'all'),
                        FilterOption(label: '₹0 - ₹500', value: '0-500'),
                        FilterOption(label: '₹501 - ₹1,000', value: '501-1000'),
                        FilterOption(label: '₹1,001 - ₹2,500', value: '1001-2500'),
                        FilterOption(label: '₹2,501 - ₹5,000', value: '2501-5000'),
                        FilterOption(label: '₹5,001 & above', value: '5001-999999'),
                      ],
                    ),
                  ],
                  totalCount: state.total,
                ),
                Expanded(
                  child: state.data.isEmpty
                      ? _buildEmptyState()
                      : ProductCardList(
                          products: state.data,
                          total: state.total,
                          currentPage: state.page,
                          pageSize: state.take,
                          totalPages: state.totalPages,
                        ),
                ),
              ],
            );
          }

          return const Center(child: Text('No products available'));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No products found',
            style: TextStyle(fontSize: 18, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}

class ProductCardList extends StatelessWidget {
  final List<ProductModel> products;
  final int total;
  final int currentPage;
  final int pageSize;
  final int totalPages;

  const ProductCardList({
    super.key,
    required this.products,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 600;
              final padding = isCompact ? 12.0 : 16.0;

              return ListView.builder(
                padding: EdgeInsets.all(padding),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final serialNumber = (currentPage - 1) * pageSize + index + 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isCompact ? 12 : 16),
                    child: ProductCard(
                      product: product,
                      serialNumber: serialNumber,
                      isCompact: isCompact,
                    ),
                  );
                },
              );
            },
          ),
        ),
        _buildPagination(context),
      ],
    );
  }

  Widget _buildPagination(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final startItem = ((currentPage - 1) * pageSize) + 1;
    final endItem = (currentPage * pageSize > total) ? total : currentPage * pageSize;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 20,
        vertical: isCompact ? 12 : 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.lightGrey, width: 1)),
      ),
      child: isCompact
          ? Column(
              children: [
                Text(
                  '$startItem-$endItem of $total',
                  style: const TextStyle(color: AppColors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildPageSizeDropdown(context, isCompact),
                    const SizedBox(width: 12),
                    _buildPaginationControls(context, isCompact),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$startItem-$endItem of $total',
                  style: const TextStyle(color: AppColors.grey),
                ),
                Row(
                  children: [
                    _buildPageSizeDropdown(context, isCompact),
                    const SizedBox(width: 16),
                    _buildPaginationControls(context, isCompact),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildPageSizeDropdown(BuildContext context, bool isCompact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: pageSize,
          isDense: isCompact,
          style: TextStyle(fontSize: isCompact ? 12 : 14, color: AppColors.black),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 20, child: Text('20')),
            DropdownMenuItem(value: 50, child: Text('50')),
            DropdownMenuItem(value: 100, child: Text('100')),
          ],
          onChanged: (value) {
            if (value != null) {
              context.read<GenericListBloc<ProductModel>>().add(ChangePageSize(value));
            }
          },
        ),
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context, bool isCompact) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, size: isCompact ? 20 : 24),
          onPressed: currentPage > 1
              ? () => context.read<GenericListBloc<ProductModel>>().add(ChangePage(currentPage - 1))
              : null,
          color: AppColors.primary,
          padding: EdgeInsets.all(isCompact ? 4 : 8),
          constraints: BoxConstraints(
            minWidth: isCompact ? 32 : 40,
            minHeight: isCompact ? 32 : 40,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 12,
            vertical: isCompact ? 4 : 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$currentPage / $totalPages',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: isCompact ? 11 : 13,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, size: isCompact ? 20 : 24),
          onPressed: currentPage < totalPages
              ? () => context.read<GenericListBloc<ProductModel>>().add(ChangePage(currentPage + 1))
              : null,
          color: AppColors.primary,
          padding: EdgeInsets.all(isCompact ? 4 : 8),
          constraints: BoxConstraints(
            minWidth: isCompact ? 32 : 40,
            minHeight: isCompact ? 32 : 40,
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final int serialNumber;
  final bool isCompact;

  const ProductCard({
    super.key,
    required this.product,
    required this.serialNumber,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
      elevation: 2,
      shadowColor: Colors.grey.withValues(alpha: 0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
        onTap: () => _showProductDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            // Main content
            Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: _buildMainContent(),
            ),
            // Footer
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isCompact ? 10 : 12),
          topRight: Radius.circular(isCompact ? 10 : 12),
        ),
      ),
      child: Row(
        children: [

          // Serial number
          Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#$serialNumber',
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Category
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.category,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Status
          Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 10, vertical: 3),
            decoration: BoxDecoration(
              color: product.isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: product.isActive ? AppColors.success : AppColors.error,
                width: 1,
              ),
            ),
            child: Text(
              product.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: product.isActive ? AppColors.success : AppColors.error,
                fontSize: isCompact ? 9 : 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final imageSize = isCompact ? 70.0 : 80.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
        Container(
          width: imageSize,
          height: imageSize,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: product.image.isNotEmpty
              ? Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 28);
                  },
                )
              : Icon(Icons.image_outlined, color: Colors.grey[400], size: 32),
        ),
        SizedBox(width: isCompact ? 10 : 12),
        // Product details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: isCompact ? 14 : 15,
                  color: AppColors.primary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: TextStyle(fontSize: isCompact ? 11 : 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              // Price and badges
              Row(
                children: [
                  Text(
                    product.price,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: isCompact ? 15 : 16,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  // Tags badge
                  _buildSmallBadge(Icons.local_offer, '${product.tagCount}', Colors.blue),
                  const SizedBox(width: 6),
                  // Themes badge
                  _buildSmallBadge(Icons.palette_outlined, '${product.themeCount}', Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallBadge(IconData icon, String label, MaterialColor color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 5 : 6, vertical: 2),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isCompact ? 10 : 11, color: color[700]),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 9 : 10,
              fontWeight: FontWeight.w600,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(isCompact ? 10 : 12),
          bottomRight: Radius.circular(isCompact ? 10 : 12),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: isCompact ? 11 : 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              product.createdBy,
              style: TextStyle(
                fontSize: isCompact ? 10 : 11,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.calendar_today_outlined, size: isCompact ? 10 : 11, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            product.createdAt,
            style: TextStyle(fontSize: isCompact ? 9 : 10, color: Colors.grey[600]),
          ),
          const Spacer(),
          // Edit button
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Edit product ${product.id}')),
              );
            },
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.edit_outlined, size: isCompact ? 16 : 18, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 8),
          // Delete button
          InkWell(
            onTap: () => _showDeleteConfirmation(context),
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.delete_outline, size: isCompact ? 16 : 18, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dialog header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, color: AppColors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Product Details',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Dialog content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product image
                      Center(
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: product.image.isNotEmpty
                              ? Image.network(product.image, fit: BoxFit.cover)
                              : Icon(Icons.image_outlined, size: 60, color: Colors.grey[400]),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      // Details grid
                      _buildDetailRow('Price', product.price),
                      if (product.priceRange.isNotEmpty && product.priceRange != '-')
                        _buildDetailRow('Price Range', product.priceRange),
                      _buildDetailRow('Category', product.category),
                      if (product.brand.isNotEmpty && product.brand != '-')
                        _buildDetailRow('Brand', product.brand),
                      _buildDetailRow('Tags', '${product.tagCount}'),
                      _buildDetailRow('Themes', '${product.themeCount}'),
                      _buildDetailRow('Status', product.isActive ? 'Active' : 'Inactive'),
                      _buildDetailRow('Created By', product.createdBy),
                      _buildDetailRow('Created At', product.createdAt),
                      if (product.aop.isNotEmpty && product.aop != '-')
                        _buildDetailRow('AOP', product.aop),
                      if (product.landed.isNotEmpty && product.landed != '-')
                        _buildDetailRow('Landed', product.landed),
                    ],
                  ),
                ),
              ),
              // Dialog actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Edit product ${product.id}')),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GenericListBloc<ProductModel>>().add(DeleteData(product.id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
