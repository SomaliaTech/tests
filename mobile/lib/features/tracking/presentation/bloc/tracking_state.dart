import 'package:equatable/equatable.dart';
import '../../domain/entities/tracking.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();
  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingLoading extends TrackingState {}

class TrackingLoaded extends TrackingState {
  final TrackingInfo tracking;
  const TrackingLoaded(this.tracking);
  @override
  List<Object?> get props => [tracking];
}

class TrackingError extends TrackingState {
  final String message;
  const TrackingError(this.message);
  @override
  List<Object?> get props => [message];
}
