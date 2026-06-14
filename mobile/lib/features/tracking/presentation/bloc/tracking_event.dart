import 'package:equatable/equatable.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();
  @override
  List<Object?> get props => [];
}

class LoadTrackingEvent extends TrackingEvent {
  final String orderId;
  const LoadTrackingEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}

class RefreshTrackingEvent extends TrackingEvent {
  final String orderId;
  const RefreshTrackingEvent(this.orderId);
  @override
  List<Object?> get props => [orderId];
}
