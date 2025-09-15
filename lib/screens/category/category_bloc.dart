import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/category_model.dart';
import '../../services/category_service.dart';

// Events
abstract class CategoryEvent {}

class LoadCategories extends CategoryEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;

  LoadCategories({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });
}

class SearchCategories extends CategoryEvent {
  final String query;
  SearchCategories(this.query);
}

class SortCategories extends CategoryEvent {
  final String sortBy;
  final String sortOrder;
  SortCategories(this.sortBy, this.sortOrder);
}

class ChangePageSize extends CategoryEvent {
  final int pageSize;
  ChangePageSize(this.pageSize);
}

class ChangePage extends CategoryEvent {
  final int page;
  ChangePage(this.page);
}

class DeleteCategory extends CategoryEvent {
  final String id;
  DeleteCategory(this.id);
}

class ApplyFilters extends CategoryEvent {
  final Map<String, dynamic> filters;
  ApplyFilters(this.filters);
}

// States
abstract class CategoryState {}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryModel> categories;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic>? filters;

  CategoryLoaded({
    required this.categories,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    this.filters,
  });
}

class CategoryError extends CategoryState {
  final String message;
  CategoryError(this.message);
}

// Bloc
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final CategoryService _categoryService = GetIt.I<CategoryService>();

  // Keep track of current parameters
  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';
  Map<String, dynamic> _currentFilters = {};

  // Cache original data for client-side filtering
  List<CategoryModel> _allCategories = [];
  int _originalTotal = 0;

  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SearchCategories>(_onSearchCategories);
    on<SortCategories>(_onSortCategories);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteCategory>(_onDeleteCategory);
    on<ApplyFilters>(_onApplyFilters);
  }

  Future<void> _onLoadCategories(
      LoadCategories event,
      Emitter<CategoryState> emit,
      ) async {
    emit(CategoryLoading());

    try {
      _currentPage = event.page;
      _currentPageSize = event.take;
      _currentSearch = event.search;
      _currentSortBy = event.sortBy;
      _currentSortOrder = event.sortOrder;

      final response = await _categoryService.getCategories(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      // Store all categories for client-side filtering
      _allCategories = response.records;
      _originalTotal = response.total;

      // Apply filters
      final filteredCategories = _applyClientSideFilters(_allCategories);

      emit(CategoryLoaded(
        categories: filteredCategories,
        total: filteredCategories.length,
        page: response.page,
        take: response.take,
        totalPages: (filteredCategories.length / response.take).ceil(),
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: _currentFilters,
      ));
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchCategories(
      SearchCategories event,
      Emitter<CategoryState> emit,
      ) async {
    _currentSearch = event.query;
    _currentPage = 1; // Reset to first page on search
    add(LoadCategories(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onSortCategories(
      SortCategories event,
      Emitter<CategoryState> emit,
      ) async {
    _currentSortBy = event.sortBy;
    _currentSortOrder = event.sortOrder;

    // Handle reset to default (no sort)
    if (event.sortBy.isEmpty || event.sortOrder.isEmpty) {
      _currentSortBy = 'createdAt';
      _currentSortOrder = 'desc';
    }

    // If we have cached data, sort it client-side for better performance
    if (_allCategories.isNotEmpty && state is CategoryLoaded) {
      List<CategoryModel> processedCategories = [..._allCategories];

      // Only sort if we have valid sort parameters
      if (event.sortBy.isNotEmpty && event.sortOrder.isNotEmpty) {
        processedCategories = _sortClientSide(processedCategories);
      } else {
        // Reset to original order (by createdAt desc)
        processedCategories = _sortClientSide(processedCategories);
      }

      final filteredCategories = _applyClientSideFilters(processedCategories);

      emit(CategoryLoaded(
        categories: filteredCategories,
        total: filteredCategories.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredCategories.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: event.sortBy.isEmpty ? '' : _currentSortBy,
        sortOrder: event.sortOrder.isEmpty ? '' : _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      add(LoadCategories(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  Future<void> _onChangePageSize(
      ChangePageSize event,
      Emitter<CategoryState> emit,
      ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1; // Reset to first page when changing page size
    add(LoadCategories(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePage(
      ChangePage event,
      Emitter<CategoryState> emit,
      ) async {
    _currentPage = event.page;
    add(LoadCategories(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onDeleteCategory(
      DeleteCategory event,
      Emitter<CategoryState> emit,
      ) async {
    try {
      await _categoryService.deleteCategory(event.id);
      // Reload categories after deletion
      add(LoadCategories(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    } catch (e) {
      emit(CategoryError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onApplyFilters(
      ApplyFilters event,
      Emitter<CategoryState> emit,
      ) async {
    _currentFilters = event.filters;

    // Apply filters to cached data
    if (_allCategories.isNotEmpty && state is CategoryLoaded) {
      final filteredCategories = _applyClientSideFilters(_allCategories);

      emit(CategoryLoaded(
        categories: filteredCategories,
        total: filteredCategories.length,
        page: _currentPage,
        take: _currentPageSize,
        totalPages: (filteredCategories.length / _currentPageSize).ceil(),
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
        filters: _currentFilters,
      ));
    } else {
      // If no cached data, reload from server
      add(LoadCategories(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    }
  }

  List<CategoryModel> _applyClientSideFilters(List<CategoryModel> categories) {
    List<CategoryModel> filteredCategories = [...categories];

    // Apply status filter
    if (_currentFilters.containsKey('status')) {
      final statusFilter = _currentFilters['status'];
      if (statusFilter == 'active') {
        filteredCategories = filteredCategories.where((category) => category.isActive).toList();
      } else if (statusFilter == 'inactive') {
        filteredCategories = filteredCategories.where((category) => !category.isActive).toList();
      }
    }

    // Apply other filters as needed
    // You can add more filter types here

    return filteredCategories;
  }

  List<CategoryModel> _sortClientSide(List<CategoryModel> categories) {
    categories.sort((a, b) {
      int comparison = 0;

      switch (_currentSortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'createdAt':
        // Parse dates and compare
          comparison = _parseDate(a.createdAt).compareTo(_parseDate(b.createdAt));
          break;
        case 'isActive':
          comparison = a.isActive == b.isActive ? 0 : (a.isActive ? 1 : -1);
          break;
        case 'createdBy':
          comparison = a.createdBy.compareTo(b.createdBy);
          break;
        default:
          comparison = 0;
      }

      // Apply sort order
      return _currentSortOrder == 'asc' ? comparison : -comparison;
    });

    return categories;
  }

  DateTime _parseDate(String dateStr) {
    // Parse date string in format "DD-MM-YYYY"
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]), // year
          int.parse(parts[1]), // month
          int.parse(parts[0]), // day
        );
      }
    } catch (e) {
      // Return current date if parsing fails
    }
    return DateTime.now();
  }
}