import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/theme_model.dart';
import '../../services/theme_service.dart';

// Events
abstract class ThemeEvent {}

class LoadThemes extends ThemeEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;

  LoadThemes({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
  });
}

class SearchThemes extends ThemeEvent {
  final String query;
  SearchThemes(this.query);
}

class SortThemes extends ThemeEvent {
  final String sortBy;
  final String sortOrder;
  SortThemes(this.sortBy, this.sortOrder);
}

class ChangePageSize extends ThemeEvent {
  final int pageSize;
  ChangePageSize(this.pageSize);
}

class ChangePage extends ThemeEvent {
  final int page;
  ChangePage(this.page);
}

class DeleteTheme extends ThemeEvent {
  final String id;
  DeleteTheme(this.id);
}

// States
abstract class ThemeState {}

class ThemeInitial extends ThemeState {}

class ThemeLoading extends ThemeState {}

class ThemeLoaded extends ThemeState {
  final List<ThemeModel> themes;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;

  ThemeLoaded({
    required this.themes,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
  });
}

class ThemeError extends ThemeState {
  final String message;
  ThemeError(this.message);
}

// Bloc
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService _themeService = GetIt.I<ThemeService>();

  // Keep track of current parameters
  int _currentPage = 1;
  int _currentPageSize = 20;
  String _currentSearch = '';
  String _currentSortBy = 'createdAt';
  String _currentSortOrder = 'desc';

  ThemeBloc() : super(ThemeInitial()) {
    on<LoadThemes>(_onLoadThemes);
    on<SearchThemes>(_onSearchThemes);
    on<SortThemes>(_onSortThemes);
    on<ChangePageSize>(_onChangePageSize);
    on<ChangePage>(_onChangePage);
    on<DeleteTheme>(_onDeleteTheme);
  }

  Future<void> _onLoadThemes(
      LoadThemes event,
      Emitter<ThemeState> emit,
      ) async {
    emit(ThemeLoading());

    try {
      _currentPage = event.page;
      _currentPageSize = event.take;
      _currentSearch = event.search;
      _currentSortBy = event.sortBy;
      _currentSortOrder = event.sortOrder;

      final response = await _themeService.getThemes(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      emit(ThemeLoaded(
        themes: response.records,
        total: response.total,
        page: response.page,
        take: response.take,
        totalPages: response.totalPages,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      ));
    } catch (e) {
      emit(ThemeError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onSearchThemes(
      SearchThemes event,
      Emitter<ThemeState> emit,
      ) async {
    _currentSearch = event.query;
    _currentPage = 1; // Reset to first page on search
    add(LoadThemes(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onSortThemes(
      SortThemes event,
      Emitter<ThemeState> emit,
      ) async {
    _currentSortBy = event.sortBy;
    _currentSortOrder = event.sortOrder;
    add(LoadThemes(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePageSize(
      ChangePageSize event,
      Emitter<ThemeState> emit,
      ) async {
    _currentPageSize = event.pageSize;
    _currentPage = 1; // Reset to first page when changing page size
    add(LoadThemes(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onChangePage(
      ChangePage event,
      Emitter<ThemeState> emit,
      ) async {
    _currentPage = event.page;
    add(LoadThemes(
      page: _currentPage,
      take: _currentPageSize,
      search: _currentSearch,
      sortBy: _currentSortBy,
      sortOrder: _currentSortOrder,
    ));
  }

  Future<void> _onDeleteTheme(
      DeleteTheme event,
      Emitter<ThemeState> emit,
      ) async {
    try {
      await _themeService.deleteTheme(event.id);
      // Reload themes after deletion
      add(LoadThemes(
        page: _currentPage,
        take: _currentPageSize,
        search: _currentSearch,
        sortBy: _currentSortBy,
        sortOrder: _currentSortOrder,
      ));
    } catch (e) {
      emit(ThemeError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}