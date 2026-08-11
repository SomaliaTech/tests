// lib/features/product/presentation/blocs/banner/banner_state.dart
import 'package:equatable/equatable.dart';
import 'package:mobile/features/product/domain/entities/banner.dart';

abstract class BannerState extends Equatable {
  const BannerState();

  @override
  List<Object?> get props => [];
}

class BannerInitial extends BannerState {}

class BannersLoading extends BannerState {}

class BannersLoaded extends BannerState {
  final List<AppBanner> banners;
  const BannersLoaded(this.banners);

  @override
  List<Object?> get props => [banners];
}

class BannersError extends BannerState {
  final String message;
  const BannersError(this.message);

  @override
  List<Object?> get props => [message];
}
