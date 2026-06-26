import 'package:equatable/equatable.dart';
import 'package:mobile/features/admin/domain/entities/market_entity.dart';

abstract class AdminMarketState extends Equatable {
  const AdminMarketState();
  @override
  List<Object?> get props => [];
}

class AdminMarketInitial extends AdminMarketState {}

class AdminMarketsLoading extends AdminMarketState {}

class AdminMarketsLoaded extends AdminMarketState {
  final List<MarketEntity> markets;
  const AdminMarketsLoaded(this.markets);

  @override
  List<Object?> get props => [markets];
}

class AdminMarketsError extends AdminMarketState {
  final String message;
  const AdminMarketsError(this.message);

  @override
  List<Object?> get props => [message];
}

class AdminMarketOperationSuccess extends AdminMarketState {
  final String message;
  const AdminMarketOperationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}
