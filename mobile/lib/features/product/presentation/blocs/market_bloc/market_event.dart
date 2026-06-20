// lib/features/product/presentation/bloc/market_bloc/market_event.dart
import 'package:equatable/equatable.dart';

abstract class MarketEvent extends Equatable {
  const MarketEvent();
  @override
  List<Object?> get props => [];
}

class LoadMarketsEvent extends MarketEvent {}
