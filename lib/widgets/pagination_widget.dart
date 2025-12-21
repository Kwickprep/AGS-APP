import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Reusable pagination widget for lists
class PaginationWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final int totalItems;
  final Function(int) onPageChange;
  final Function(int) onPageSizeChange;

  const PaginationWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.pageSize,
    required this.totalItems,
    required this.onPageChange,
    required this.onPageSizeChange,
  });

  @override
  Widget build(BuildContext context) {
    final startItem = ((currentPage - 1) * pageSize) + 1;
    final endItem = (currentPage * pageSize > totalItems)
        ? totalItems
        : currentPage * pageSize;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16).copyWith(bottom: MediaQuery.of(context).viewPadding.bottom + 16),
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
            totalItems > 0 ? '$startItem-$endItem of $totalItems' : '0 of 0',
            style: const TextStyle(color: AppColors.grey),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey),
                  borderRadius: BorderRadius.circular(4),
                  color: AppColors.white,
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
                        onPageSizeChange(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: currentPage > 1
                    ? () => onPageChange(currentPage - 1)
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
                    ? () => onPageChange(currentPage + 1)
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
