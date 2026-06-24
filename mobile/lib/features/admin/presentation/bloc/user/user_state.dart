import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/admin_user_entity.dart';

abstract class UserState extends Equatable {
  const UserState();
  @override
  List<Object?> get props => [];
}

class UserInitial extends UserState {}

class UsersLoading extends UserState {}

class UsersLoaded extends UserState {
  final List<AdminUserEntity> users;
  const UsersLoaded(this.users);

  @override
  List<Object?> get props => [users];
}

class UserLoaded extends UserState {
  final AdminUserEntity user;
  const UserLoaded(this.user);

  @override
  List<Object?> get props => [user];
}

class UserError extends UserState {
  final String message;
  const UserError(this.message);

  @override
  List<Object?> get props => [message];
}

class UserOperationSuccess extends UserState {
  final String message;
  const UserOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
