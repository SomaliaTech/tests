import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/entities/no_params.dart';
import 'package:mobile/features/product/domain/usecases/banner/create_banner.dart';
import 'package:mobile/features/product/domain/usecases/banner/delete_banner.dart';
import 'package:mobile/features/product/domain/usecases/banner/get_all_banners.dart';
import 'package:mobile/features/product/domain/usecases/banner/toggle_banner_status.dart';
import 'package:mobile/features/product/domain/usecases/banner/update_banner.dart';

import 'admin_banner_event.dart';
import 'admin_banner_state.dart';

class AdminBannerBloc extends Bloc<AdminBannerEvent, AdminBannerState> {
  final GetAllBanners getAllBanners;
  final CreateBanner createBanner;
  final UpdateBanner updateBanner;
  final DeleteBanner deleteBanner;
  final ToggleBannerStatus toggleBannerStatus;

  AdminBannerBloc({
    required this.getAllBanners,
    required this.createBanner,
    required this.updateBanner,
    required this.deleteBanner,
    required this.toggleBannerStatus,
  }) : super(AdminBannerInitial()) {
    on<LoadAllBannersEvent>(_onLoadAllBanners);
    on<CreateBannerEvent>(_onCreateBanner);
    on<UpdateBannerEvent>(_onUpdateBanner);
    on<DeleteBannerEvent>(_onDeleteBanner);
    on<ToggleBannerStatusEvent>(_onToggleBannerStatus);
  }

  Future<void> _onLoadAllBanners(
    LoadAllBannersEvent event,
    Emitter<AdminBannerState> emit,
  ) async {
    emit(AdminBannersLoading());
    final result = await getAllBanners(const NoParams());
    result.fold(
      (failure) => emit(AdminBannerError(failure.message)),
      (banners) => emit(AdminBannersLoaded(banners)),
    );
  }

  Future<void> _onCreateBanner(
    CreateBannerEvent event,
    Emitter<AdminBannerState> emit,
  ) async {
    emit(AdminBannerOperationLoading());
    final result = await createBanner(
      CreateBannerParams(bannerData: event.bannerData),
    );
    result.fold((failure) => emit(AdminBannerError(failure.message)), (banner) {
      emit(const AdminBannerOperationSuccess('Banner created successfully'));
      add(const LoadAllBannersEvent());
    });
  }

  Future<void> _onUpdateBanner(
    UpdateBannerEvent event,
    Emitter<AdminBannerState> emit,
  ) async {
    emit(AdminBannerOperationLoading());
    final result = await updateBanner(
      UpdateBannerParams(id: event.id, bannerData: event.bannerData),
    );
    result.fold((failure) => emit(AdminBannerError(failure.message)), (banner) {
      emit(const AdminBannerOperationSuccess('Banner updated successfully'));
      add(const LoadAllBannersEvent());
    });
  }

  Future<void> _onDeleteBanner(
    DeleteBannerEvent event,
    Emitter<AdminBannerState> emit,
  ) async {
    emit(AdminBannerOperationLoading());
    final result = await deleteBanner(DeleteBannerParams(id: event.id));
    result.fold((failure) => emit(AdminBannerError(failure.message)), (_) {
      emit(const AdminBannerOperationSuccess('Banner deleted successfully'));
      add(const LoadAllBannersEvent());
    });
  }

  Future<void> _onToggleBannerStatus(
    ToggleBannerStatusEvent event,
    Emitter<AdminBannerState> emit,
  ) async {
    final result = await toggleBannerStatus(ToggleBannerParams(id: event.id));
    result.fold((failure) => emit(AdminBannerError(failure.message)), (banner) {
      emit(
        AdminBannerOperationSuccess(
          'Banner ${banner.isActive ? 'activated' : 'deactivated'}',
        ),
      );
      add(const LoadAllBannersEvent());
    });
  }

  @override
  void onChange(Change<AdminBannerState> change) {
    // TODO: implement onChange
    super.onChange(change);
    print(change);
  }
}
