import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../models/whatsapp_models.dart';
import '../../services/whatsapp_campaign_service.dart';

// ============================================================================
// Events
// ============================================================================

abstract class CampaignEvent {}

/// Main event to load campaigns with all parameters
class LoadCampaigns extends CampaignEvent {
  final int page;
  final int take;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  LoadCampaigns({
    this.page = 1,
    this.take = 20,
    this.search = '',
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.filters = const {},
  });
}

class DeleteCampaign extends CampaignEvent {
  final String id;
  DeleteCampaign(this.id);
}

class ExecuteCampaign extends CampaignEvent {
  final String id;
  ExecuteCampaign(this.id);
}

class StopCampaign extends CampaignEvent {
  final String id;
  StopCampaign(this.id);
}

// ============================================================================
// States
// ============================================================================

abstract class CampaignState {}

class CampaignInitial extends CampaignState {}

class CampaignLoading extends CampaignState {}

class CampaignLoaded extends CampaignState {
  final List<WhatsAppCampaignModel> records;
  final int total;
  final int page;
  final int take;
  final int totalPages;
  final String search;
  final String sortBy;
  final String sortOrder;
  final Map<String, dynamic> filters;

  CampaignLoaded({
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

  CampaignLoaded copyWith({
    List<WhatsAppCampaignModel>? records,
    int? total,
    int? page,
    int? take,
    int? totalPages,
    String? search,
    String? sortBy,
    String? sortOrder,
    Map<String, dynamic>? filters,
  }) {
    return CampaignLoaded(
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

class CampaignError extends CampaignState {
  final String message;
  CampaignError(this.message);
}

class CampaignExecuting extends CampaignState {}

class CampaignExecuted extends CampaignState {
  final Map<String, dynamic> result;
  CampaignExecuted(this.result);
}

// ============================================================================
// BLoC - Simple approach: Every change triggers API call
// ============================================================================

class CampaignBloc extends Bloc<CampaignEvent, CampaignState> {
  final WhatsAppCampaignService _service =
      GetIt.I<WhatsAppCampaignService>();

  CampaignBloc() : super(CampaignInitial()) {
    on<LoadCampaigns>(_onLoadCampaigns);
    on<DeleteCampaign>(_onDeleteCampaign);
    on<ExecuteCampaign>(_onExecuteCampaign);
    on<StopCampaign>(_onStopCampaign);
  }

  /// Load campaigns from API with given parameters
  Future<void> _onLoadCampaigns(
    LoadCampaigns event,
    Emitter<CampaignState> emit,
  ) async {
    emit(CampaignLoading());

    try {
      final response = await _service.getAll(
        page: event.page,
        take: event.take,
        search: event.search,
        sortBy: event.sortBy,
        sortOrder: event.sortOrder,
      );

      emit(CampaignLoaded(
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
      emit(CampaignError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Delete campaign and reload current page
  Future<void> _onDeleteCampaign(
    DeleteCampaign event,
    Emitter<CampaignState> emit,
  ) async {
    try {
      await _service.delete(event.id);

      // Reload with current parameters if we have a loaded state
      if (state is CampaignLoaded) {
        final currentState = state as CampaignLoaded;
        add(LoadCampaigns(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        // Otherwise just reload with defaults
        add(LoadCampaigns());
      }
    } catch (e) {
      emit(CampaignError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Execute campaign and reload
  Future<void> _onExecuteCampaign(
    ExecuteCampaign event,
    Emitter<CampaignState> emit,
  ) async {
    emit(CampaignExecuting());

    try {
      final result = await _service.execute(event.id);
      emit(CampaignExecuted(result));

      // Reload the list after execution
      add(LoadCampaigns());
    } catch (e) {
      emit(CampaignError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// Stop campaign and reload
  Future<void> _onStopCampaign(
    StopCampaign event,
    Emitter<CampaignState> emit,
  ) async {
    try {
      await _service.stop(event.id);

      // Reload with current parameters if we have a loaded state
      if (state is CampaignLoaded) {
        final currentState = state as CampaignLoaded;
        add(LoadCampaigns(
          page: currentState.page,
          take: currentState.take,
          search: currentState.search,
          sortBy: currentState.sortBy,
          sortOrder: currentState.sortOrder,
          filters: currentState.filters,
        ));
      } else {
        add(LoadCampaigns());
      }
    } catch (e) {
      emit(CampaignError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
