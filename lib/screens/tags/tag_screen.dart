import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../../widgets/ShimmerLoading.dart';
import '../../widgets/tag_search_bar.dart';
import '../../widgets/tag_table.dart';
import 'tag_bloc.dart';

class TagScreen extends StatelessWidget {
  const TagScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TagBloc()..add(LoadTags()),
      child: const TagView(),
    );
  }
}

class TagView extends StatelessWidget {
  const TagView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tags'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create tag not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<TagBloc, TagState>(
        builder: (context, state) {
          if (state is TagLoading) {
            return const ShimmerLoading();
          }

          if (state is TagError) {
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
                    'Error loading tags',
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
                      context.read<TagBloc>().add(LoadTags());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TagLoaded) {
            return Column(
              children: [
                TagSearchBar(
                  onSearch: (query) {
                    context.read<TagBloc>().add(SearchTags(query));
                  },
                  onApplyFilters: (filters) {
                    context.read<TagBloc>().add(ApplyFilters(filters));
                  },
                  currentFilters: state.filters ?? {},
                ),
                Expanded(
                  child: TagTable(
                    tags: state.tags,
                    total: state.total,
                    currentPage: state.page,
                    pageSize: state.take,
                    totalPages: state.totalPages,
                    sortBy: state.sortBy,
                    sortOrder: state.sortOrder,
                    onPageChange: (page) {
                      context.read<TagBloc>().add(ChangePage(page));
                    },
                    onPageSizeChange: (size) {
                      context.read<TagBloc>().add(ChangePageSize(size));
                    },
                    onSort: (sortBy, sortOrder) {
                      context.read<TagBloc>().add(SortTags(sortBy, sortOrder));
                    },
                    onDelete: (id) {
                      _showDeleteConfirmation(context, id);
                    },
                    onEdit: (id) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit tag $id not implemented yet')),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const Center(
            child: Text('No tags available'),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Tag'),
        content: const Text('Are you sure you want to delete this tag?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TagBloc>().add(DeleteTag(id));
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
