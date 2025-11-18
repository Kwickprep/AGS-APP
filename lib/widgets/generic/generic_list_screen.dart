import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../config/app_colors.dart';
import '../ShimmerLoading.dart';
import 'generic_column_config.dart';
import 'generic_data_table.dart';
import 'generic_list_bloc.dart';
import 'generic_model.dart';
import 'generic_search_bar.dart';

/// Configuration for the generic list screen
class GenericListScreenConfig<T extends GenericModel> {
  final String title;
  final List<GenericColumnConfig<T>> columns;
  final GenericListBloc<T> Function() blocBuilder;
  final List<FilterConfig> filterConfigs;
  final String searchHint;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool showCreateButton;
  final String? createRoute;
  final VoidCallback? onCreatePressed;
  final bool showSerialNumber;
  final bool showTotalCount;
  final bool enableEdit;
  final bool enableDelete;

  const GenericListScreenConfig({
    required this.title,
    required this.columns,
    required this.blocBuilder,
    this.filterConfigs = const [],
    this.searchHint = 'Search...',
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyMessage = 'No data found',
    this.showCreateButton = true,
    this.createRoute,
    this.onCreatePressed,
    this.showSerialNumber = true,
    this.showTotalCount = false,
    this.enableEdit = false,
    this.enableDelete = false,
  });
}

/// Generic list screen widget that provides searching, filtering, sorting, and pagination
class GenericListScreen<T extends GenericModel> extends StatelessWidget {
  final GenericListScreenConfig<T> config;

  const GenericListScreen({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => config.blocBuilder()..add(LoadData()),
      child: GenericListView<T>(config: config),
    );
  }
}

class GenericListView<T extends GenericModel> extends StatelessWidget {
  final GenericListScreenConfig<T> config;

  const GenericListView({
    Key? key,
    required this.config,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(config.title),
        backgroundColor: AppColors.white,
        elevation: 0,
        actions: [
          if (config.showCreateButton)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              onPressed: () {
                if (config.onCreatePressed != null) {
                  config.onCreatePressed!();
                } else if (config.createRoute != null) {
                  Navigator.pushNamed(context, config.createRoute!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Create ${config.title.toLowerCase()} not implemented yet')),
                  );
                }
              },
            ),
        ],
      ),
      body: BlocBuilder<GenericListBloc<T>, GenericListState>(
        builder: (context, state) {
          if (state is GenericListLoading) {
            return const ShimmerLoading();
          }

          if (state is GenericListError) {
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
                    'Error loading ${config.title.toLowerCase()}',
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
                      context.read<GenericListBloc<T>>().add(LoadData());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is GenericListLoaded<T>) {
            return Column(
              children: [
                GenericSearchBar(
                  key: ValueKey('${config.title}_search_bar'),
                  initialSearchQuery: state.search,
                  onSearch: (query) {
                    context.read<GenericListBloc<T>>().add(SearchData(query));
                  },
                  onApplyFilters: (filters) {
                    context.read<GenericListBloc<T>>().add(ApplyFilters(filters));
                  },
                  currentFilters: state.filters ?? {},
                  searchHint: config.searchHint,
                  filterConfigs: config.filterConfigs,
                  totalCount: config.showTotalCount ? state.total : null,
                ),
                Expanded(
                  child: GenericDataTable<T>(
                    data: state.data,
                    columns: config.columns,
                    total: state.total,
                    currentPage: state.page,
                    pageSize: state.take,
                    totalPages: state.totalPages,
                    sortBy: state.sortBy,
                    sortOrder: state.sortOrder,
                    onPageChange: (page) {
                      context.read<GenericListBloc<T>>().add(ChangePage(page));
                    },
                    onPageSizeChange: (size) {
                      context.read<GenericListBloc<T>>().add(ChangePageSize(size));
                    },
                    onSort: (sortBy, sortOrder) {
                      context.read<GenericListBloc<T>>().add(SortData(sortBy, sortOrder));
                    },
                    onDelete: config.enableDelete
                        ? (id) => _showDeleteConfirmation(context, id, config.title)
                        : null,
                    onEdit: config.enableEdit
                        ? (id) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Edit ${config.title.toLowerCase()} $id not implemented yet')),
                            );
                          }
                        : null,
                    emptyIcon: config.emptyIcon,
                    emptyMessage: config.emptyMessage,
                    showSerialNumber: config.showSerialNumber,
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Text('No ${config.title.toLowerCase()} available'),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id, String entityName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${entityName.substring(0, entityName.length - 1)}'),
        content: Text('Are you sure you want to delete this ${entityName.toLowerCase().substring(0, entityName.length - 1)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<GenericListBloc<T>>().add(DeleteData(id));
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
