import 'package:equatable/equatable.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();
  @override
  List<Object?> get props => [];
}

class FetchAllUsersEvent extends UserEvent {
  final String? search;
  const FetchAllUsersEvent({this.search});

  @override
  List<Object?> get props => [search];
}

class FetchUserByIdEvent extends UserEvent {
  final String userId;
  const FetchUserByIdEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateUserEvent extends UserEvent {
  final Map<String, dynamic> userData;
  const CreateUserEvent(this.userData);

  @override
  List<Object?> get props => [userData];
}

class UpdateUserEvent extends UserEvent {
  final String userId;
  final Map<String, dynamic> updateData;
  const UpdateUserEvent(this.userId, this.updateData);

  @override
  List<Object?> get props => [userId, updateData];
}

class DeleteUserEvent extends UserEvent {
  final String userId;
  const DeleteUserEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}
