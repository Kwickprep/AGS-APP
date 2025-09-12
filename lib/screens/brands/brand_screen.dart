import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/ShimmerLoading.dart';
import '../../widgets/brand_list.dart';
import '../../widgets/brand_searchbar.dart';
import 'brand_bloc.dart';

class BrandScreen extends StatelessWidget {
  const BrandScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BrandBloc()..add(LoadBrands()),
      child: const BrandView(),
    );
  }
}

class BrandView extends StatelessWidget {
  const BrandView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: (){
            context.go(AppRoutes.home);
          },
        ),
        title: const Text('Brands'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create brand not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<BrandBloc, BrandState>(
        builder: (context, state) {
          if (state is BrandLoading) {
            return const ShimmerLoading();
          }

          if (state is BrandError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading brands',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: const TextStyle(color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<BrandBloc>().add(LoadBrands());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is BrandLoaded) {
            return Column(
              children: [
                BrandSearchBar(
                  onSearch: (query) {
                    context.read<BrandBloc>().add(SearchBrands(query));
                  },
                  onSort: (sortBy, sortOrder) {
                    context.read<BrandBloc>().add(SortBrands(sortBy, sortOrder));
                  },
                  currentSortBy: state.sortBy,
                  currentSortOrder: state.sortOrder,
                ),
                Expanded(
                  child: BrandList(
                    brands: state.brands,
                    total: state.total,
                    currentPage: state.page,
                    pageSize: state.take,
                    totalPages: state.totalPages,
                    onPageChange: (page) {
                      context.read<BrandBloc>().add(ChangePage(page));
                    },
                    onPageSizeChange: (size) {
                      context.read<BrandBloc>().add(ChangePageSize(size));
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: Text('No brands available'),
          );
        },
      ),
    );
  }
}