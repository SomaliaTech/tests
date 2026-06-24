import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/admin_user_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_event.dart';
import 'package:mobile/features/admin/presentation/bloc/user/user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final AdminUserRepository repository;

  UserBloc({required this.repository}) : super(UserInitial()) {
    on<FetchAllUsersEvent>(_onFetchAllUsers);
    on<FetchUserByIdEvent>(_onFetchUserById);
    on<CreateUserEvent>(_onCreateUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
  }

  Future<void> _onFetchAllUsers(
    FetchAllUsersEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UsersLoading());
    try {
      final users = await repository.getAllUsers(event.search);
      emit(UsersLoaded(users));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onFetchUserById(
    FetchUserByIdEvent event,
    Emitter<UserState> emit,
  ) async {
    emit(UsersLoading());
    try {
      final user = await repository.getUserById(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onCreateUser(
    CreateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.createUser(event.userData);
      // Emit success state cleanly without mixing consecutive loading sequences
      emit(const UserOperationSuccess('User created successfully'));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUser(
    UpdateUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.updateUser(event.userId, event.updateData);
      emit(const UserOperationSuccess('User updated successfully'));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onDeleteUser(
    DeleteUserEvent event,
    Emitter<UserState> emit,
  ) async {
    try {
      await repository.deleteUser(event.userId);
      emit(const UserOperationSuccess('User deleted successfully'));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }
}
