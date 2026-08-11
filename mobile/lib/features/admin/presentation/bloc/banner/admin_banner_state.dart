import 'package:equatable/equatable.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';

abstract class AdminBannerState extends Equatable {
  const AdminBannerState();

  @override
  List<Object?> get props => [];
}

class AdminBannerInitial extends AdminBannerState {}

class AdminBannersLoading extends AdminBannerState {}

class AdminBannersLoaded extends AdminBannerState {
  final List<AppBanner> banners;
  const AdminBannersLoaded(this.banners);

  @override
  List<Object?> get props => [banners];
}

class AdminBannerOperationLoading extends AdminBannerState {}

class AdminBannerOperationSuccess extends AdminBannerState {
  final String message;
  const AdminBannerOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminBannerError extends AdminBannerState {
  final String message;
  const AdminBannerError(this.message);

  @override
  List<Object?> get props => [message];
}
