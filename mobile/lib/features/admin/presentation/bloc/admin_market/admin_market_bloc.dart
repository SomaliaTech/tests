import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/admin_market_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_market/admin_market_event.dart';
import 'package:mobile/features/admin/presentation/bloc/admin_market/admin_market_state.dart';

class AdminMarketBloc extends Bloc<AdminMarketEvent, AdminMarketState> {
  final AdminMarketRepository repository;

  AdminMarketBloc({required this.repository}) : super(AdminMarketInitial()) {
    on<FetchAllMarketsEvent>(_onFetchAll);
    on<CreateMarketEvent>(_onCreate);
    on<UpdateMarketEvent>(_onUpdate);
    on<DeleteMarketEvent>(_onDelete);
  }

  Future<void> _onFetchAll(
    FetchAllMarketsEvent event,
    Emitter<AdminMarketState> emit,
  ) async {
    emit(AdminMarketsLoading());
    try {
      final markets = await repository.getAllMarkets();
      emit(AdminMarketsLoaded(markets));
    } catch (e) {
      emit(AdminMarketsError(e.toString()));
    }
  }

  Future<void> _onCreate(
    CreateMarketEvent event,
    Emitter<AdminMarketState> emit,
  ) async {
    try {
      await repository.createMarket(event.data);
      emit(const AdminMarketOperationSuccess('Market created successfully'));
      add(FetchAllMarketsEvent());
    } catch (e) {
      emit(AdminMarketsError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateMarketEvent event,
    Emitter<AdminMarketState> emit,
  ) async {
    try {
      await repository.updateMarket(event.marketId, event.data);
      emit(const AdminMarketOperationSuccess('Market updated successfully'));
      add(FetchAllMarketsEvent());
    } catch (e) {
      emit(AdminMarketsError(e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteMarketEvent event,
    Emitter<AdminMarketState> emit,
  ) async {
    try {
      await repository.deleteMarket(event.marketId);
      emit(const AdminMarketOperationSuccess('Market deleted successfully'));
      add(FetchAllMarketsEvent());
    } catch (e) {
      emit(AdminMarketsError(e.toString()));
    }
  }
}
