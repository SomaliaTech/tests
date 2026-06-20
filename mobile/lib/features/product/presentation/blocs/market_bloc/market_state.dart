// lib/features/product/presentation/bloc/market_bloc/market_state.dart
import 'package:equatable/equatable.dart';
import '../../../domain/entities/market.dart';

abstract class MarketState extends Equatable {
  const MarketState();
  @override
  List<Object?> get props => [];
}

class MarketInitial extends MarketState {}

class MarketLoading extends MarketState {}

class MarketsLoaded extends MarketState {
  final List<Market> markets;
  const MarketsLoaded(this.markets);
  @override
  List<Object?> get props => [markets];
}

class MarketError extends MarketState {
  final String message;
  const MarketError(this.message);
  @override
  List<Object?> get props => [message];
}
