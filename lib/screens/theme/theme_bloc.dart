import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/theme_model.dart';
import '../../services/theme_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class ThemeEvent {}

/// Main event to load themes with all parameters
class LoadThemes extends ThemeEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadThemes({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteTheme extends ThemeEvent {
  final String id;
  DeleteTheme(this.id);
}

// ============================================================================
// States
// ============================================================================

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
  final Map<String, dynamic> filters;

  ThemeLoaded({
    required this.themes,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  ThemeLoaded copyWith({
    List<ThemeModel>? themes,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return ThemeLoaded(
      themes: themes ?? this.themes,
      total: total ?? this.total,
      page: page ?? this.page,
      take: take ?? this.take,
      totalPages: totalPages ?? this.totalPages,
      search: search ?? this.search,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      filters: filters ?? this.filters,
    );
  }
}

class ThemeError extends ThemeState {
  final String message;
  ThemeError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeService _themeService = GetIt.I<ThemeService>();

  ThemeBloc() : super(ThemeInitial()) {
    on<LoadThemes>(_onLoadThemes);
    on<DeleteTheme>(_onDeleteTheme);
  }

  /// Load themes from API with given parameters
  Future<void> _onLoadThemes(
    LoadThemes event,
    Emitter<ThemeState> emit,
  ) async {
    emit(ThemeLoading());

    try {
      final response = await _themeService.getThemes(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
        filters: event.filters,
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
        filters: event.filters,
      ));
    } catch (e) {
      emit(ThemeError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete theme and reload current page
  Future<void> _onDeleteTheme(
    DeleteTheme event,
    Emitter<ThemeState> emit,
  ) async {
    try {
      await _themeService.deleteTheme(event.id);
      
      // Reload with current parameters if we have a loaded state
      if (state is ThemeLoaded) {
        final currentState = state as ThemeLoaded;
        add(LoadThemes(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadThemes());
      }
    } catch (e) {
      emit(ThemeError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
