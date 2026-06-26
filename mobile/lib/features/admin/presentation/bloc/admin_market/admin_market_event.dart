import 'package:equatable/equatable.dart';

abstract class AdminMarketEvent extends Equatable {
  const AdminMarketEvent();
  @override
  List<Object?> get props => [];
}

class FetchAllMarketsEvent extends AdminMarketEvent {}

class CreateMarketEvent extends AdminMarketEvent {
  final Map<String, dynamic> data;
  const CreateMarketEvent(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateMarketEvent extends AdminMarketEvent {
  final String marketId;
  final Map<String, dynamic> data;
  const UpdateMarketEvent(this.marketId, this.data);

  @override
  List<Object?> get props => [marketId, data];
}

class DeleteMarketEvent extends AdminMarketEvent {
  final String marketId;
  const DeleteMarketEvent(this.marketId);

  @override
  List<Object?> get props => [marketId];
}
