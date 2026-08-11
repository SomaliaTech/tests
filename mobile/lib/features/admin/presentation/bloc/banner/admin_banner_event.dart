import 'package:equatable/equatable.dart';

abstract class AdminBannerEvent extends Equatable {
  const AdminBannerEvent();

  @override
  List<Object?> get props => [];
}

class LoadAllBannersEvent extends AdminBannerEvent {
  const LoadAllBannersEvent();
}

class CreateBannerEvent extends AdminBannerEvent {
  final Map<String, dynamic> bannerData;
  const CreateBannerEvent({required this.bannerData});

  @override
  List<Object?> get props => [bannerData];
}

class UpdateBannerEvent extends AdminBannerEvent {
  final String id;
  final Map<String, dynamic> bannerData;
  const UpdateBannerEvent({required this.id, required this.bannerData});

  @override
  List<Object?> get props => [id, bannerData];
}

class DeleteBannerEvent extends AdminBannerEvent {
  final String id;
  const DeleteBannerEvent({required this.id});

  @override
  List<Object?> get props => [id];
}

class ToggleBannerStatusEvent extends AdminBannerEvent {
  final String id;
  const ToggleBannerStatusEvent({required this.id});

  @override
  List<Object?> get props => [id];
}
