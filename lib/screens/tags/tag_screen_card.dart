import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../config/app_colors.dart';
import '../../models/tag_model.dart';
import '../../services/tag_service.dart';
import '../../widgets/generic/index.dart';
import '../../widgets/common_list_card.dart';

/// Tag list screen with card-based UI
class TagScreenCard extends StatefulWidget {
  const TagScreenCard({Key? key}) : super(key: key);

  @override
  State<TagScreenCard> createState() => _TagScreenCardState();
}

class _TagScreenCardState extends State<TagScreenCard> {
  late GenericListBloc<TagModel> _bloc;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _bloc = GenericListBloc<TagModel>(
      service: GetIt.I<TagService>(),
      sortComparator: _tagSortComparator,
      filterPredicate: _tagFilterPredicate,
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
        title: const Text('Tags'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: BlocProvider<GenericListBloc<TagModel>>(
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
                      hintText: 'Search tags...',
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
              child: BlocBuilder<GenericListBloc<TagModel>, GenericListState>(
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
                  } else if (state is GenericListLoaded<TagModel>) {
                    if (state.data.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.label_outlined, size: 64, color: AppColors.grey),
                            SizedBox(height: 16),
                            Text('No tags found', style: TextStyle(fontSize: 16)),
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
                          final tag = state.data[index];
                          return _buildTagCard(tag);
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

  Widget _buildTagCard(TagModel tag) {
    return CommonListCard(
      title: tag.name,
      statusBadge: StatusBadgeConfig.status(tag.isActive ? 'Active' : 'Inactive'),
      rows: [
        CardRowConfig(
          icon: Icons.person_outline,
          text: tag.createdBy,
          iconColor: AppColors.primary,
        ),
        CardRowConfig(
          icon: Icons.calendar_today_outlined,
          text: tag.createdAt,
          iconColor: AppColors.primary,
        ),
      ],
      onView: () => _showTagDetails(tag),
      onDelete: () => _confirmDelete(tag),
    );
  }

  void _showTagDetails(TagModel tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tag.name),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Status', tag.isActive ? 'Active' : 'Inactive'),
            _buildDetailRow('Created By', tag.createdBy),
            _buildDetailRow('Created Date', tag.createdAt),
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

  void _confirmDelete(TagModel tag) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "${tag.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _bloc.add(DeleteData(tag.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tag deleted successfully')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  int _tagSortComparator(TagModel a, TagModel b, String sortBy, String sortOrder) {
    int comparison = 0;
    switch (sortBy) {
      case 'name':
        comparison = a.name.compareTo(b.name);
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

  bool _tagFilterPredicate(TagModel tag, Map<String, dynamic> filters) {
    if (filters.containsKey('status') && filters['status'] != null) {
      final statusFilter = filters['status'];
      if (statusFilter == 'active' && !tag.isActive) return false;
      if (statusFilter == 'inactive' && tag.isActive) return false;
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
