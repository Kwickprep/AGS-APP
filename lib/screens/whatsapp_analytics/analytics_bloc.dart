import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../../services/whatsapp_service.dart';

// Events
abstract class AnalyticsEvent {}

class LoadAnalytics extends AnalyticsEvent {
  final String fromDate;
  final String toDate;

  LoadAnalytics({required this.fromDate, required this.toDate});
}

// States
abstract class AnalyticsState {}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final Map<String, dynamic> data;

  AnalyticsLoaded(this.data);
}

class AnalyticsError extends AnalyticsState {
  final String message;

  AnalyticsError(this.message);
}

// BLoC
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final WhatsAppService _whatsAppService = GetIt.I<WhatsAppService>();

  AnalyticsBloc() : super(AnalyticsInitial()) {
    on<LoadAnalytics>(_onLoadAnalytics);
  }

  Future<void> _onLoadAnalytics(
    LoadAnalytics event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());
    try {
      final data = await _whatsAppService.getAnalytics(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );
      emit(AnalyticsLoaded(data));
    } catch (e) {
      emit(AnalyticsError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
