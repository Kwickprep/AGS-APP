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

  CategoryLoaded({
    required this.categories,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
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

  CategoryBloc() : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<SearchCategories>(_onSearchCategories);
    on<SortCategories>(_onSortCategories);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteCategory>(_onDeleteCategory);
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

      emit(CategoryLoaded(
        categories: response.records,
        total: response.total,
        page: response.page,
        take: response.take,
        totalPages: response.totalPages,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
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
    _currentPage = 1;
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
    add(LoadCategories(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePageSize(
      ChangePageSize event,
      Emitter<CategoryState> emit,
      ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1;
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
}