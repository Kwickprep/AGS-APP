import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/routes.dart';
import '../../widgets/ShimmerLoading.dart';
import '../../widgets/activity_search_bar.dart';
import '../../widgets/activity_table.dart';
import 'activity_bloc.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ActivityBloc()..add(LoadActivities()),
      child: const ActivityView(),
    );
  }
}

class ActivityView extends StatelessWidget {
  const ActivityView({Key? key}) : super(key: key);

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
        title: const Text('Activities'),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () {
              context.go(AppRoutes.createActivity);
            },
          ),
        ],
      ),
      body: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          print('ActivityScreen: Current state: ${state.runtimeType}');

          if (state is ActivityLoading) {
            print('ActivityScreen: Showing loading state');
            return const ShimmerLoading();
          }

          if (state is ActivityError) {
            print('ActivityScreen: Showing error state - ${state.message}');
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
                    'Error loading activities',
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
                      context.read<ActivityBloc>().add(LoadActivities());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ActivityLoaded) {
            print('ActivityScreen: Showing loaded state - ${state.activities.length} activities');
            return Column(
              children: [
                ActivitySearchBar(
                  key: const ValueKey('activity_search_bar'),
                  initialSearchQuery: state.search,
                  onSearch: (query) {
                    context.read<ActivityBloc>().add(SearchActivities(query));
                  },
                  onApplyFilters: (filters) {
                    context.read<ActivityBloc>().add(ApplyFilters(filters));
                  },
                  currentFilters: state.filters ?? {},
                  totalCount: state.total,
                ),
                Expanded(
                  child: ActivityTable(
                    activities: state.activities,
                    total: state.total,
                    currentPage: state.page,
                    pageSize: state.take,
                    totalPages: state.totalPages,
                    sortBy: state.sortBy,
                    sortOrder: state.sortOrder,
                    onPageChange: (page) {
                      context.read<ActivityBloc>().add(ChangePage(page));
                    },
                    onPageSizeChange: (size) {
                      context.read<ActivityBloc>().add(ChangePageSize(size));
                    },
                    onSort: (sortBy, sortOrder) {
                      context.read<ActivityBloc>().add(SortActivities(sortBy, sortOrder));
                    },
                    onDelete: (id) {
                      _showDeleteConfirmation(context, id);
                    },
                    onEdit: (id) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Edit activity $id not implemented yet')),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          print('ActivityScreen: Default state - showing no activities message');
          return const Center(
            child: Text('No activities available'),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<ActivityBloc>().add(DeleteActivity(id));
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
