import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/ShimmerLoading.dart';
import '../../widgets/category_search_bar.dart';
import '../../widgets/category_table.dart';
import 'category_bloc.dart';


class CategoryScreen extends StatelessWidget {
  const CategoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryBloc()..add(LoadCategories()),
      child: const CategoryView(),
    );
  }
}

class CategoryView extends StatelessWidget {
  const CategoryView({Key? key}) : super(key: key);

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
        title: const Text('Categories'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create category not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryLoading) {
            return const ShimmerLoading();
          }

          if (state is CategoryError) {
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
                    'Error loading categories',
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
                      context.read<CategoryBloc>().add(LoadCategories());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is CategoryLoaded) {
            return Column(
              children: [
                CategorySearchBar(
                  onSearch: (query) {
                    context.read<CategoryBloc>().add(SearchCategories(query));
                  },
                  onSort: (sortBy, sortOrder) {
                    context.read<CategoryBloc>().add(SortCategories(sortBy, sortOrder));
                  },
                  currentSortBy: state.sortBy,
                  currentSortOrder: state.sortOrder,
                  totalCount: state.total,
                ),
                Expanded(
                  child: CategoryTable(
                    categories: state.categories,
                    total: state.total,
                    currentPage: state.page,
                    pageSize: state.take,
                    totalPages: state.totalPages,
                    onPageChange: (page) {
                      context.read<CategoryBloc>().add(ChangePage(page));
                    },
                    onPageSizeChange: (size) {
                      context.read<CategoryBloc>().add(ChangePageSize(size));
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: Text('No categories available'),
          );
        },
      ),
    );
  }
}