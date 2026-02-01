import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/whatsapp_models.dart';
import '../../services/whatsapp_auto_reply_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class AutoReplyEvent {}

/// Main event to load auto replies with all parameters
class LoadAutoReplies extends AutoReplyEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadAutoReplies({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteAutoReply extends AutoReplyEvent {
  final String id;
  DeleteAutoReply(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class AutoReplyState {}

class AutoReplyInitial extends AutoReplyState {}

class AutoReplyLoading extends AutoReplyState {}

class AutoReplyLoaded extends AutoReplyState {
  final List<WhatsAppAutoReplyModel> records;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  AutoReplyLoaded({
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

  AutoReplyLoaded copyWith({
    List<WhatsAppAutoReplyModel>? records,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return AutoReplyLoaded(
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

class AutoReplyError extends AutoReplyState {
  final String message;
  AutoReplyError(this.message);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class AutoReplyBloc extends Bloc<AutoReplyEvent, AutoReplyState> {
  final WhatsAppAutoReplyService _service =
      GetIt.I<WhatsAppAutoReplyService>();

  AutoReplyBloc() : super(AutoReplyInitial()) {
    on<LoadAutoReplies>(_onLoadAutoReplies);
    on<DeleteAutoReply>(_onDeleteAutoReply);
  }

  /// Load auto replies from API with given parameters
  Future<void> _onLoadAutoReplies(
    LoadAutoReplies event,
    Emitter<AutoReplyState> emit,
  ) async {
    emit(AutoReplyLoading());

    try {
      final response = await _service.getAll(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      emit(AutoReplyLoaded(
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
      emit(AutoReplyError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete auto reply and reload current page
  Future<void> _onDeleteAutoReply(
    DeleteAutoReply event,
    Emitter<AutoReplyState> emit,
  ) async {
    try {
      await _service.delete(event.id);

      // Reload with current parameters if we have a loaded state
      if (state is AutoReplyLoaded) {
        final currentState = state as AutoReplyLoaded;
        add(LoadAutoReplies(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadAutoReplies());
      }
    } catch (e) {
      emit(AutoReplyError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
