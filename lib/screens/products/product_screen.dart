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
        scrolledUnderElevation: 0,
        leading: BackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Products'),
        backgroundColor: AppColors.white,
        elevation: 0,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
        //     onPressed: () {
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         const SnackBar(content: Text('Create product not implemented yet')),
        //       );
        //     },
        //   ),
        // ],
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final product = products[index];
                final serialNumber = (currentPage - 1) * pageSize + index + 1;
                return ProductListTile(
                  product: product,
                  serialNumber: serialNumber,
                  onTap: () => _showProductDetailsDialog(context, product),
                );
              },
            ),
          ),
          _buildPagination(context),
        ],
      ),
    );
  }

  void _showProductDetailsDialog(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Product Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      if (product.image.isNotEmpty)
                        Center(
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5E6D3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.network(
                              product.image,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.inventory_2_outlined,
                                size: 60,
                                color: Colors.brown[300],
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      // Product Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 20),
                      // Details
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
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
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
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Edit ${product.name}')),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    final startItem = ((currentPage - 1) * pageSize) + 1;
    final endItem = (currentPage * pageSize > total) ? total : currentPage * pageSize;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$startItem-$endItem of $total',
            style: const TextStyle(color: AppColors.grey),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: pageSize,
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
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => context.read<GenericListBloc<ProductModel>>().add(ChangePage(currentPage - 1))
                    : null,
                color: AppColors.primary,
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$currentPage / $totalPages',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: currentPage < totalPages
                    ? () => context.read<GenericListBloc<ProductModel>>().add(ChangePage(currentPage + 1))
                    : null,
                color: AppColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductListTile extends StatelessWidget {
  final ProductModel product;
  final int serialNumber;
  final VoidCallback onTap;

  const ProductListTile({
    super.key,
    required this.product,
    required this.serialNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: isCompact
              ? _buildCompactLayout()
              : _buildWideLayout(),
        ),
      ),
    );
  }

  Widget _buildCompactLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6D3),
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: product.image.isNotEmpty
                  ? Image.network(
                      product.image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.inventory_2_outlined,
                        size: 30,
                        color: Colors.brown[300],
                      ),
                    )
                  : Icon(
                      Icons.inventory_2_outlined,
                      size: 30,
                      color: Colors.brown[300],
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#$serialNumber',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              product.price,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            _buildStatusBadge(),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildInfoItem('Category', product.category),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoItem(
                'Brand',
                product.brand.isEmpty || product.brand == '-' ? 'N/A' : product.brand,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        // Serial Number
        SizedBox(
          width: 50,
          child: Text(
            '#$serialNumber',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Image
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF5E6D3),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: product.image.isNotEmpty
              ? Image.network(
                  product.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.inventory_2_outlined,
                    size: 30,
                    color: Colors.brown[300],
                  ),
                )
              : Icon(
                  Icons.inventory_2_outlined,
                  size: 30,
                  color: Colors.brown[300],
                ),
        ),
        const SizedBox(width: 16),
        // Product Name
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Price
        SizedBox(
          width: 100,
          child: Text(
            product.price,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Category
        Expanded(
          flex: 2,
          child: Text(
            product.category,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        // Brand
        Expanded(
          flex: 2,
          child: Text(
            product.brand.isEmpty || product.brand == '-' ? 'N/A' : product.brand,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        // Status
        _buildStatusBadge(),
        const SizedBox(width: 8),
        // Arrow icon
        const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF94A3B8),
        ),
      ],
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: product.isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: product.isActive ? AppColors.success : AppColors.error,
          width: 1,
        ),
      ),
      child: Text(
        product.isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: product.isActive ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
