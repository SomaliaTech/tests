import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/admin_color_size_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_color_size/admin_color_size_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_color_size/admin_color_size_state.dart';

class AdminColorSizeBloc
    extends Bloc<AdminColorSizeEvent, AdminColorSizeState> {
  final AdminColorSizeRepository repository;

  AdminColorSizeBloc({required this.repository})
    : super(AdminColorSizeInitial()) {
    on<FetchAllColorsEvent>(_onFetchColors);
    on<CreateColorEvent>(_onCreateColor);
    on<UpdateColorEvent>(_onUpdateColor);
    on<DeleteColorEvent>(_onDeleteColor);

    on<FetchAllSizesEvent>(_onFetchSizes);
    on<CreateSizeEvent>(_onCreateSize);
    on<UpdateSizeEvent>(_onUpdateSize);
    on<DeleteSizeEvent>(_onDeleteSize);
  }

  // Colors
  Future<void> _onFetchColors(
    FetchAllColorsEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    emit(AdminColorsLoading());
    try {
      final colors = await repository.getAllColors();
      emit(AdminColorsLoaded(colors));
    } catch (e) {
      emit(AdminColorsError(e.toString()));
    }
  }

  Future<void> _onCreateColor(
    CreateColorEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    try {
      await repository.createColor(event.data);
      emit(const AdminColorSizeOperationSuccess('Color created successfully'));
      add(FetchAllColorsEvent());
    } catch (e) {
      emit(AdminColorsError(e.toString()));
    }
  }

  Future<void> _onUpdateColor(
    UpdateColorEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    try {
      await repository.updateColor(event.colorId, event.data);
      emit(const AdminColorSizeOperationSuccess('Color updated successfully'));
      add(FetchAllColorsEvent());
    } catch (e) {
      emit(AdminColorsError(e.toString()));
    }
  }

  Future<void> _onDeleteColor(
    DeleteColorEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    try {
      await repository.deleteColor(event.colorId);
      emit(const AdminColorSizeOperationSuccess('Color deleted successfully'));
      add(FetchAllColorsEvent());
    } catch (e) {
      emit(AdminColorsError(e.toString()));
    }
  }

  // Sizes
  Future<void> _onFetchSizes(
    FetchAllSizesEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    emit(AdminSizesLoading());
    try {
      final sizes = await repository.getAllSizes();
      emit(AdminSizesLoaded(sizes));
    } catch (e) {
      emit(AdminSizesError(e.toString()));
    }
  }

  Future<void> _onCreateSize(
    CreateSizeEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    try {
      await repository.createSize(event.data);
      emit(const AdminColorSizeOperationSuccess('Size created successfully'));
      add(FetchAllSizesEvent());
    } catch (e) {
      emit(AdminSizesError(e.toString()));
    }
  }

  Future<void> _onUpdateSize(
    UpdateSizeEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    try {
      await repository.updateSize(event.sizeId, event.data);
      emit(const AdminColorSizeOperationSuccess('Size updated successfully'));
      add(FetchAllSizesEvent());
    } catch (e) {
      emit(AdminSizesError(e.toString()));
    }
  }

  Future<void> _onDeleteSize(
    DeleteSizeEvent event,
    Emitter<AdminColorSizeState> emit,
  ) async {
    try {
      await repository.deleteSize(event.sizeId);
      emit(const AdminColorSizeOperationSuccess('Size deleted successfully'));
      add(FetchAllSizesEvent());
    } catch (e) {
      emit(AdminSizesError(e.toString()));
    }
  }
}
