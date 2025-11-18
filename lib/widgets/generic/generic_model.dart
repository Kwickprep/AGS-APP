/// Base interface that all models must implement to work with generic widgets
abstract class GenericModel {
  String get id;
  String get createdBy;
  String get createdAt;
  Map<String, dynamic> toJson();

  /// Get the value of a field by its key
  dynamic getFieldValue(String fieldKey);
}

/// Generic response wrapper for paginated data
class GenericResponse<T extends GenericModel> {
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final List<T> records;

  GenericResponse({
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.records,
  });
}
