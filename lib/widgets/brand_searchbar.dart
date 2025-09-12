import 'dart:async';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';

class BrandSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final Function(String, String) onSort;
  final String currentSortBy;
  final String currentSortOrder;

  const BrandSearchBar({
    Key? key,
    required this.onSearch,
    required this.onSort,
    required this.currentSortBy,
    required this.currentSortOrder,
  }) : super(key: key);

  @override
  State<BrandSearchBar> createState() => _BrandSearchBarState();
}

class _BrandSearchBarState extends State<BrandSearchBar> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      widget.onSearch(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search brands...',
                prefixIcon: const Icon(Icons.search, color: AppColors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.lightGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.lightGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                filled: true,
                fillColor: AppColors.background,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.background,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: widget.currentSortBy,
                icon: const Icon(Icons.sort, color: AppColors.primary),
                items: const [
                  DropdownMenuItem(
                    value: 'name',
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: 'createdAt',
                    child: Text('Date'),
                  ),
                  DropdownMenuItem(
                    value: 'isActive',
                    child: Text('Status'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    widget.onSort(value, widget.currentSortOrder);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              widget.currentSortOrder == 'asc'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: AppColors.primary,
            ),
            onPressed: () {
              final newOrder = widget.currentSortOrder == 'asc' ? 'desc' : 'asc';
              widget.onSort(widget.currentSortBy, newOrder);
            },
          ),
        ],
      ),
    );
  }
}