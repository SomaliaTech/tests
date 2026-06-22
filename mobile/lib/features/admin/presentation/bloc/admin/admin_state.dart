import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:mobile/features/admin/domain/entities/admin_order_entity.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object?> get props => [];
}

class AdminInitial extends AdminState {}

// Stats States
class AdminStatsLoading extends AdminState {}

class AdminStatsLoaded extends AdminState {
  final AdminStatsEntity stats;
  const AdminStatsLoaded(this.stats);
  @override
  List<Object?> get props => [stats];
}

class AdminStatsError extends AdminState {
  final String message;
  const AdminStatsError(this.message);
  @override
  List<Object?> get props => [message];
}

// Orders States
class AdminOrdersLoading extends AdminState {}

class AdminOrdersLoaded extends AdminState {
  final List<AdminOrderEntity> orders;
  const AdminOrdersLoaded(this.orders);
  @override
  List<Object?> get props => [orders];
}

class AdminOrdersError extends AdminState {
  final String message;
  const AdminOrdersError(this.message);
  @override
  List<Object?> get props => [message];
}

// 👇 ADD STATUS UPDATE STATES 👇
class AdminStatusUpdating extends AdminState {}

class AdminStatusUpdated extends AdminState {
  final String message;
  final String newStatus; // ✅ Added newStatus field
  final String orderId;

  const AdminStatusUpdated({
    required this.message,
    required this.newStatus,
    required this.orderId,
  });

  @override
  List<Object?> get props => [message, newStatus, orderId];
}

class AdminStatusUpdateError extends AdminState {
  final String message;
  const AdminStatusUpdateError(this.message);
  @override
  List<Object?> get props => [message];
}
