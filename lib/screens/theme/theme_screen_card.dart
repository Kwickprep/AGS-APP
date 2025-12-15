import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/theme_model.dart';
import '../../services/theme_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common_list_card.dart';

/// Theme list screen with card-based UI
class ThemeScreenCard extends StatefulWidget {
  const ThemeScreenCard({Key? key}) : super(key: key);

  @override
  State<ThemeScreenCard> createState() => _ThemeScreenCardState();
}

class _ThemeScreenCardState extends State<ThemeScreenCard> {
  late GenericListBloc<ThemeModel> _bloc;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _bloc = GenericListBloc<ThemeModel>(
      service: GetIt.I<ThemeService>(),
      sortComparator: _themeSortComparator,
      filterPredicate: _themeFilterPredicate,
    );
    _bloc.add(LoadData());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Themes'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: BlocProvider<GenericListBloc<ThemeModel>>(
        create: (_) => _bloc,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search themes...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _bloc.add(SearchData(''));
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightGrey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.lightGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                    onChanged: (value) {
                      _bloc.add(SearchData(value));
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', 'active'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Inactive', 'inactive'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocBuilder<GenericListBloc<ThemeModel>, GenericListState>(
                builder: (context, state) {
                  if (state is GenericListLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is GenericListError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(state.message, style: const TextStyle(fontSize: 16)),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _bloc.add(LoadData()),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (state is GenericListLoaded<ThemeModel>) {
                    if (state.data.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.palette_outlined, size: 64, color: AppColors.grey),
                            SizedBox(height: 16),
                            Text('No themes found', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _bloc.add(LoadData());
                        await Future.delayed(const Duration(milliseconds: 500));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: state.data.length,
                        itemBuilder: (context, index) {
                          final theme = state.data[index];
                          return _buildThemeCard(theme);
                        },
                      ),
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _statusFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _statusFilter = value;
          _bloc.add(ApplyFilters({'status': value == 'all' ? null : value}));
        });
      },
      backgroundColor: AppColors.white,
      selectedColor: AppColors.primary.withOpacity(0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.lightGrey,
      ),
    );
  }

  Widget _buildThemeCard(ThemeModel theme) {
    return CommonListCard(
      title: theme.name,
      statusBadge: StatusBadgeConfig.status(theme.isActive ? 'Active' : 'Inactive'),
      rows: [
        if (theme.description.isNotEmpty)
          CardRowConfig(
            icon: Icons.description_outlined,
            text: theme.description,
            iconColor: AppColors.primary,
          ),
        CardRowConfig(
          icon: Icons.person_outline,
          text: theme.createdBy,
          iconColor: AppColors.primary,
        ),
        CardRowConfig(
          icon: Icons.calendar_today_outlined,
          text: theme.createdAt,
          iconColor: AppColors.primary,
        ),
      ],
      onView: () => _showThemeDetails(theme),
      onDelete: () => _confirmDelete(theme),
    );
  }

  void _showThemeDetails(ThemeModel theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(theme.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Description', theme.description.isEmpty ? '-' : theme.description),
            _buildDetailRow('Status', theme.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Created By', theme.createdBy),
            _buildDetailRow('Created Date', theme.createdAt),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  void _confirmDelete(ThemeModel theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${theme.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteData(theme.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  int _themeSortComparator(ThemeModel a, ThemeModel b, String sortBy, String sortOrder) {
    int comparison = 0;
    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
        break;
      case 'description':
        comparison = a.description.compareTo(b.description);
        break;
      case 'isActive':
        comparison = a.isActive == b.isActive ? 0 : (a.isActive ? 1 : -1);
        break;
      case 'createdAt':
        comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
        break;
      default:
        comparison = 0;
    }
    return sortOrder == 'asc' ? comparison : -comparison;
  }

  bool _themeFilterPredicate(ThemeModel theme, Map<String, dynamic> filters) {
    if (filters.containsKey('status') && filters['status'] != null) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !theme.isActive) return false;
      if (statusFilter == 'inactive' && theme.isActive) return false;
    }
    return true;
  }

  DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      }
    } catch (e) {}
    return DateTime.now();
  }
}
