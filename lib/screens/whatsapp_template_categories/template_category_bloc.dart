import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/whatsapp_models.dart';
import '../../services/whatsapp_template_category_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class TemplateCatEvent {}

/// Main event to load template categories with all parameters
class LoadTemplateCats extends TemplateCatEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadTemplateCats({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteTemplateCat extends TemplateCatEvent {
  final String id;
  DeleteTemplateCat(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class TemplateCatState {}

class TemplateCatInitial extends TemplateCatState {}

class TemplateCatLoading extends TemplateCatState {}

class TemplateCatLoaded extends TemplateCatState {
  final List<WhatsAppTemplateCategoryModel> records;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  TemplateCatLoaded({
    required this.records,
    required this.total,
    required this.page,
    required this.take,
    required this.totalPages,
    required this.search,
    required this.sortBy,
    required this.sortOrder,
    required this.filters,
  });

  TemplateCatLoaded copyWith({
    List<WhatsAppTemplateCategoryModel>? records,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return TemplateCatLoaded(
      records: records ?? this.records,
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

class TemplateCatError extends TemplateCatState {
  final String message;
  TemplateCatError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class TemplateCategoryBloc extends Bloc<TemplateCatEvent, TemplateCatState> {
  final WhatsAppTemplateCategoryService _service =
      GetIt.I<WhatsAppTemplateCategoryService>();

  TemplateCategoryBloc() : super(TemplateCatInitial()) {
    on<LoadTemplateCats>(_onLoadTemplateCats);
    on<DeleteTemplateCat>(_onDeleteTemplateCat);
  }

  /// Load template categories from API with given parameters
  Future<void> _onLoadTemplateCats(
    LoadTemplateCats event,
    Emitter<TemplateCatState> emit,
  ) async {
    emit(TemplateCatLoading());

    try {
      final response = await _service.getAll(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      emit(TemplateCatLoaded(
        records: response.records,
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
      emit(TemplateCatError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete template category and reload current page
  Future<void> _onDeleteTemplateCat(
    DeleteTemplateCat event,
    Emitter<TemplateCatState> emit,
  ) async {
    try {
      await _service.delete(event.id);

      // Reload with current parameters if we have a loaded state
      if (state is TemplateCatLoaded) {
        final currentState = state as TemplateCatLoaded;
        add(LoadTemplateCats(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadTemplateCats());
      }
    } catch (e) {
      emit(TemplateCatError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
