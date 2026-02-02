import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../config/app_text_styles.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final int? totalItems;
  final int? itemsPerPage;
  final Function(int)? onPageChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final int maxVisiblePages;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    this.totalItems,
    this.itemsPerPage,
    this.onPageChanged,
    this.onPrevious,
    this.onNext,
    this.maxVisiblePages = 6,
  });

  List<int> _getVisiblePages() {
    if (totalPages <= maxVisiblePages) {
      return List.generate(totalPages, (i) => i + 1);
    }

    int start = max(1, currentPage - (maxVisiblePages ~/ 2));
    int end = min(totalPages, start + maxVisiblePages - 1);

    if (end - start < maxVisiblePages - 1) {
      start = max(1, end - maxVisiblePages + 1);
    }

    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final canGoPrevious = currentPage > 1;
    final canGoNext = currentPage < totalPages;
    final visiblePages = _getVisiblePages();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pageButtonsWidth = visiblePages.length * 48;
          final navButtonsWidth = 40 * 2 + 16;
          final totalWidth = pageButtonsWidth + navButtonsWidth;

          final shouldScroll = totalWidth > constraints.maxWidth;

          Widget pageButtons = Row(
            mainAxisSize: MainAxisSize.min,
            children: visiblePages.map((pageNum) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _PageNumberButton(
                  pageNumber: pageNum,
                  isActive: pageNum == currentPage,
                  onTap: () => onPageChanged?.call(pageNum),
                ),
              );
            }).toList(),
          );

          if (shouldScroll) {
            pageButtons = SizedBox(
              width: constraints.maxWidth - navButtonsWidth,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: pageButtons,
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Item count info
              if (totalItems != null && itemsPerPage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Showing ${((currentPage - 1) * itemsPerPage!) + 1}-${currentPage * itemsPerPage! > totalItems! ? totalItems : currentPage * itemsPerPage!} of $totalItems',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              // Page controls
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavigationButton(
                      onTap: canGoPrevious
                          ? () {
                        onPrevious?.call();
                        onPageChanged?.call(currentPage - 1);
                      }
                          : null,
                      icon: Icons.chevron_left,
                    ),

                    const SizedBox(width: 8),

                    pageButtons,

                    const SizedBox(width: 8),

                    _NavigationButton(
                      onTap: canGoNext
                          ? () {
                        onNext?.call();
                        onPageChanged?.call(currentPage + 1);
                      }
                          : null,
                      icon: Icons.chevron_right,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// PAGE NUMBER BUTTON
class _PageNumberButton extends StatelessWidget {
  final int pageNumber;
  final bool isActive;
  final VoidCallback onTap;

  const _PageNumberButton({
    required this.pageNumber,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          '$pageNumber',
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// NAV BUTTON
class _NavigationButton extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;

  const _NavigationButton({
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? AppColors.textSecondary : AppColors.lightGrey,
        ),
      ),
    );
  }
}
