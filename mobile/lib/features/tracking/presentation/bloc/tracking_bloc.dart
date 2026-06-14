import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/tracking/domain/usecases/get_tracking_info.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final GetTrackingInfo getTrackingInfo;

  TrackingBloc({required this.getTrackingInfo}) : super(TrackingInitial()) {
    on<LoadTrackingEvent>(_onLoadTracking);
    on<RefreshTrackingEvent>(_onRefreshTracking);
  }

  Future<void> _onLoadTracking(
    LoadTrackingEvent event,
    Emitter<TrackingState> emit,
  ) async {
    emit(TrackingLoading());
    final result = await getTrackingInfo(event.orderId);
    result.fold(
      (failure) => emit(TrackingError(failure.message)),
      (tracking) => emit(TrackingLoaded(tracking)),
    );
  }

  Future<void> _onRefreshTracking(
    RefreshTrackingEvent event,
    Emitter<TrackingState> emit,
  ) async {
    final result = await getTrackingInfo(event.orderId);
    result.fold(
      (failure) => emit(TrackingError(failure.message)),
      (tracking) => emit(TrackingLoaded(tracking)),
    );
  }
}
