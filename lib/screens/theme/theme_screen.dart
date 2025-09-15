import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/ShimmerLoading.dart';
import '../../widgets/theme_search_bar.dart';
import '../../widgets/theme_table.dart';
import 'theme_bloc.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ThemeBloc()..add(LoadThemes()),
      child: const ThemeView(),
    );
  }
}

class ThemeView extends StatelessWidget {
  const ThemeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            context.go(AppRoutes.home);
          },
        ),
        title: const Text('Themes'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: AppColors.primary,
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Create theme not implemented yet'),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, state) {
          if (state is ThemeLoading) {
            return const ShimmerLoading();
          }

          if (state is ThemeError) {
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
                    'Error loading themes',
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
                      context.read<ThemeBloc>().add(LoadThemes());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ThemeLoaded) {
            return Column(
              children: [
                ThemeSearchBar(
                  key: const ValueKey(
                    'theme_search_bar',
                  ), // Add key for widget identity
                  initialSearchQuery: state.search, // Pass current search query
                  onSearch: (query) {
                    context.read<ThemeBloc>().add(SearchThemes(query));
                  },
                  onApplyFilters: (filters) {
                    context.read<ThemeBloc>().add(ApplyFilters(filters));
                  },
                  currentFilters: state.filters ?? {},
                ),
                Expanded(
                  child: ThemeTable(
                    themes: state.themes,
                    total: state.total,
                    currentPage: state.page,
                    pageSize: state.take,
                    totalPages: state.totalPages,
                    sortBy: state.sortBy,
                    sortOrder: state.sortOrder,
                    onPageChange: (page) {
                      context.read<ThemeBloc>().add(ChangePage(page));
                    },
                    onPageSizeChange: (size) {
                      context.read<ThemeBloc>().add(ChangePageSize(size));
                    },
                    onSort: (sortBy, sortOrder) {
                      context.read<ThemeBloc>().add(
                        SortThemes(sortBy, sortOrder),
                      );
                    },
                    onDelete: (id) {
                      _showDeleteConfirmation(context, id);
                    },
                    onEdit: (id) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Edit theme $id not implemented yet'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(child: Text('No themes available'));
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Theme'),
        content: const Text('Are you sure you want to delete this theme?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ThemeBloc>().add(DeleteTheme(id));
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
