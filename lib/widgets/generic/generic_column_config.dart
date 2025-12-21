import 'package:flutter/material.dart';
import 'generic_model.dart';

/// Configuration for a single column in the generic data table
class GenericColumnConfig<T extends GenericModel> {
  /// Column header label
  final String label;

  /// Field name for sorting (must match the API field name)
  final String fieldKey;

  /// Whether this column is sortable
  final bool sortable;

  /// Custom widget renderer for this column
  /// If null, will use default text rendering with getFieldValue
  final Widget Function(T model, int index)? customRenderer;

  /// Column width (optional)
  final double? width;

  /// Whether to show this column
  final bool visible;

  const GenericColumnConfig({
    required this.label,
    required this.fieldKey,
    this.sortable = false,
    this.customRenderer,
    this.width,
    this.visible = true,
  });

  /// Helper to create a serial number column
  static GenericColumnConfig<T> serialNumber<T extends GenericModel>() {
    return GenericColumnConfig<T>(
      label: 'SR',
      fieldKey: 'serialNumber',
      sortable: false,
    );
  }

  /// Helper to create a status column with badge
  static GenericColumnConfig<T> statusBadge<T extends GenericModel>({
    required String Function(T) getStatus,
    required bool Function(T) isActive,
  }) {
    return GenericColumnConfig<T>(
      label: 'Status',
      fieldKey: 'isActive',
      sortable: true,
      customRenderer: (model, index) {
        final active = isActive(model);
        final status = getStatus(model);
        return _buildStatusBadge(status, active);
      },
    );
  }

  static Widget _buildStatusBadge(String status, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive
            ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
            : const Color(0xFFF44336).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          width: 1,
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFF44336),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
