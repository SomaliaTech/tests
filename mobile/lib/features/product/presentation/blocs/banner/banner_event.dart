// lib/features/product/presentation/blocs/banner/banner_event.dart
import 'package:equatable/equatable.dart';

abstract class BannerEvent extends Equatable {
  const BannerEvent();

  @override
  List<Object?> get props => [];
}

class LoadBannersEvent extends BannerEvent {
  final BannerFilter? filter;

  const LoadBannersEvent({this.filter});

  @override
  List<Object?> get props => [filter];
}

// ✅ Filter enum for different banner types
enum BannerFilter { all, discountOnly, flashSaleOnly, activeDiscounts }
