import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import 'generic_column_config.dart';
import 'generic_model.dart';

/// Generic data table with sorting and pagination
class GenericDataTable<T extends GenericModel> extends StatefulWidget {
  final List<T> data;
  final List<GenericColumnConfig<T>> columns;
  final int total;
  final int currentPage;
  final int pageSize;
  final int totalPages;
  final String sortBy;
  final String sortOrder;
  final Function(int) onPageChange;
  final Function(int) onPageSizeChange;
  final Function(String, String) onSort;
  final Function(String)? onDelete;
  final Function(String)? onEdit;
  final IconData emptyIcon;
  final String emptyMessage;
  final bool showSerialNumber;

  const GenericDataTable({
    super.key,
    required this.data,
    required this.columns,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.totalPages,
    required this.sortBy,
    required this.sortOrder,
    required this.onPageChange,
    required this.onPageSizeChange,
    required this.onSort,
    this.onDelete,
    this.onEdit,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyMessage = 'No data found',
    this.showSerialNumber = true,
  });

  @override
  State<GenericDataTable<T>> createState() => _GenericDataTableState<T>();
}

class _GenericDataTableState<T extends GenericModel>
    extends State<GenericDataTable<T>> {
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
      margin: const EdgeInsets.symmetric(vertical: 16),
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
            child: widget.data.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                          AppColors.background,
                        ),
                        columns: _buildColumns(),
                        rows: _buildRows(context),
                        horizontalMargin: 20,
                        columnSpacing: 30,
                        dividerThickness: 1,
                        showBottomBorder: true,
                      ),
                    ),
                  ),
          ),
          if (widget.data.isNotEmpty) _buildPagination(context),
        ],
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    final columns = <DataColumn>[];

    // Add serial number column if enabled
    if (widget.showSerialNumber) {
      columns.add(
        const DataColumn(
          label: Text(
            'SR',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // Add configured columns
    for (final config in widget.columns) {
      if (!config.visible) continue;

      if (config.sortable) {
        columns.add(
          DataColumn(
            label: _buildSortableHeader(config.label, config.fieldKey),
          ),
        );
      } else {
        columns.add(
          DataColumn(
            label: Text(
              config.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }
    }

    // Add actions column if edit or delete is enabled
    if (widget.onEdit != null || widget.onDelete != null) {
      columns.add(
        const DataColumn(
          label: Text(
            'Actions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return columns;
  }

  List<DataRow> _buildRows(BuildContext context) {
    final startIndex = (widget.currentPage - 1) * widget.pageSize;

    return widget.data.asMap().entries.map((entry) {
      final index = entry.key;
      final model = entry.value;
      final serialNumber = startIndex + index + 1;

      final cells = <DataCell>[];

      // Add serial number cell if enabled
      if (widget.showSerialNumber) {
        cells.add(
          DataCell(
            Text(
              serialNumber.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        );
      }

      // Add data cells
      for (final config in widget.columns) {
        if (!config.visible) continue;

        if (config.customRenderer != null) {
          // Use custom renderer
          cells.add(DataCell(config.customRenderer!(model, index)));
        } else {
          // Use default text renderer
          final value = model.getFieldValue(config.fieldKey);
          cells.add(DataCell(Text(value?.toString() ?? '')));
        }
      }

      // Add actions cell if needed
      if (widget.onEdit != null || widget.onDelete != null) {
        cells.add(
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppColors.primary,
                    onPressed: () => widget.onEdit!(model.id),
                    tooltip: 'Edit',
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    color: AppColors.error,
                    onPressed: () => widget.onDelete!(model.id),
                    tooltip: 'Delete',
                  ),
              ],
            ),
          ),
        );
      }

      return DataRow(cells: cells);
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.emptyIcon,
            size: 80,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: const TextStyle(fontSize: 18, color: AppColors.grey),
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
      margin: const EdgeInsets.only(bottom: 16),
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
            widget.total > 0 ? '$startItem-$endItem of ${widget.total}' : '0 items',
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
