import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/app_colors.dart';
import '../../../models/category_model.dart';

class CategoryTable extends StatefulWidget {
  final List<CategoryModel> categories;
  final int total;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final String sortBy;
  final String sortOrder;
  final Function(int) onPageChange;
  final Function(int) onPageSizeChange;
  final Function(String) onDelete;
  final Function(String) onEdit;
  final Function(String, String) onSort;

  const CategoryTable({
    super.key,
    required this.categories,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.sortBy,
    required this.sortOrder,
    required this.onPageChange,
    required this.onPageSizeChange,
    required this.onDelete,
    required this.onEdit,
    required this.onSort,
  });

  @override
  State<CategoryTable> createState() => _CategoryTableState();
}

class _CategoryTableState extends State<CategoryTable> {
  final Set<int> _expandedRows = {};

  Widget _buildSortableHeader(String label, String field) {
    final isActive = widget.sortBy == field;
    final isAsc = widget.sortOrder == 'asc';

    return InkWell(
      onTap: () {
        if (!isActive) {
          // First tap - sort ascending
          widget.onSort(field, 'asc');
        } else if (isAsc) {
          // Second tap - sort descending
          widget.onSort(field, 'desc');
        } else {
          // Third tap - reset to default (no sort)
          widget.onSort('', '');
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? AppColors.primary : AppColors.black,
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (isActive)
                Icon(
                  isAsc ? CupertinoIcons.sort_up : CupertinoIcons.sort_down,
                  size: 14,
                  color: AppColors.primary,
                )
              else
                Icon(
                  CupertinoIcons.arrow_up_arrow_down,
                  size: 14,
                  color: AppColors.grey,
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: widget.categories.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        dataRowMaxHeight: double.infinity,
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.background,
                        ),
                        columns: [
                          const DataColumn(
                            label: Text(
                              'SR',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: _buildSortableHeader(
                              'Category Name',
                              'name',
                            ),
                          ),
                          const DataColumn(
                            label: Text(
                              'Description',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          DataColumn(
                            label: _buildSortableHeader('Status', 'isActive'),
                          ),
                          DataColumn(
                            label: _buildSortableHeader(
                              'Created By',
                              'createdBy',
                            ),
                          ),
                          DataColumn(
                            label: _buildSortableHeader(
                              'Created Date',
                              'createdAt',
                            ),
                          ),
                          // const DataColumn(
                          //   label: Text(
                          //     'Actions',
                          //     style: TextStyle(fontWeight: FontWeight.bold),
                          //   ),
                          // ),
                        ],
                        rows: _buildRows(context),
                        horizontalMargin: 20,
                        columnSpacing: 30,
                        dividerThickness: 1,
                        showBottomBorder: true,
                      ),
                    ),
                  ),
          ),
          _buildPagination(context),
        ],
      ),
    );
  }

  List<DataRow> _buildRows(BuildContext context) {
    final startIndex = (widget.currentPage - 1) * widget.pageSize;

    return widget.categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      final serialNumber = startIndex + index + 1;
      final isExpanded = _expandedRows.contains(index);

      // Calculate description height for proper row expansion
      final descriptionLines = _getDescriptionLines(
        category.description,
        isExpanded,
      );

      return DataRow(
        cells: [
          DataCell(
            Container(
              height: isExpanded ? descriptionLines * 20.0 : null,
              alignment: Alignment.centerLeft,
              child: Text(
                serialNumber.toString(),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          DataCell(
            Container(
              height: isExpanded ? descriptionLines * 20.0 : null,
              alignment: Alignment.centerLeft,
              child: Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ),
          DataCell(
            InkWell(
              splashColor: Colors.transparent,
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedRows.remove(index);
                  } else {
                    _expandedRows.add(index);
                  }
                });
              },
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isExpanded ? 400 : 250,
                  minHeight: isExpanded ? descriptionLines * 20.0 : 40.0,
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  category.description,
                  maxLines: isExpanded ? null : 2,
                  overflow: isExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              height: isExpanded ? descriptionLines * 20.0 : null,
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: category.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: category.isActive
                        ? AppColors.success
                        : AppColors.error,
                    width: 1,
                  ),
                ),
                child: Text(
                  category.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: category.isActive
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          DataCell(
            Container(
              height: isExpanded ? descriptionLines * 20.0 : null,
              alignment: Alignment.centerLeft,
              child: Text(category.createdBy),
            ),
          ),
          DataCell(
            Container(
              height: isExpanded ? descriptionLines * 20.0 : null,
              alignment: Alignment.centerLeft,
              child: Text(category.createdAt),
            ),
          ),
          // DataCell(
          //   Container(
          //     height: isExpanded ? descriptionLines * 20.0 : null,
          //     alignment: Alignment.centerLeft,
          //     child: Row(
          //       mainAxisSize: MainAxisSize.min,
          //       children: [
          //         IconButton(
          //           icon: const Icon(Icons.edit, size: 18),
          //           color: AppColors.primary,
          //           onPressed: () => widget.onEdit(category.id),
          //           tooltip: 'Edit',
          //         ),
          //         IconButton(
          //           icon: const Icon(Icons.delete, size: 18),
          //           color: AppColors.error,
          //           onPressed: () => widget.onDelete(category.id),
          //           tooltip: 'Delete',
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        ],
      );
    }).toList();
  }

  // Helper method to calculate number of lines for description
  double _getDescriptionLines(String description, bool isExpanded) {
    if (!isExpanded) return 2.0;

    // Estimate lines based on character count and average characters per line
    const avgCharsPerLine = 50;
    final estimatedLines = (description.length / avgCharsPerLine).ceil();
    return estimatedLines.toDouble().clamp(
      3.0,
      10.0,
    ); // Min 3 lines, max 10 lines
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 80,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No categories found',
            style: TextStyle(fontSize: 18, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context) {
    final startItem = ((widget.currentPage - 1) * widget.pageSize) + 1;
    final endItem = (widget.currentPage * widget.pageSize > widget.total)
        ? widget.total
        : widget.currentPage * widget.pageSize;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
            '$startItem-$endItem of ${widget.total}',
            style: const TextStyle(color: AppColors.grey),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightGrey),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: widget.pageSize,
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 20, child: Text('20')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                      DropdownMenuItem(value: 100, child: Text('100')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        widget.onPageSizeChange(value);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: widget.currentPage > 1
                    ? () => widget.onPageChange(widget.currentPage - 1)
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
                  '${widget.currentPage} / ${widget.totalPages}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: widget.currentPage < widget.totalPages
                    ? () => widget.onPageChange(widget.currentPage + 1)
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
