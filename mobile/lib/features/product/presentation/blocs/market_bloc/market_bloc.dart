// lib/features/product/presentation/blocs/market_bloc/market_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/get_markets.dart';
import 'market_event.dart';
import 'market_state.dart';

class MarketBloc extends Bloc<MarketEvent, MarketState> {
  final GetMarkets getMarkets;

  MarketBloc({required this.getMarkets}) : super(MarketInitial()) {
    on<LoadMarketsEvent>(_onLoadMarkets);
  }

  Future<void> _onLoadMarkets(
    LoadMarketsEvent event,
    Emitter<MarketState> emit,
  ) async {
    emit(MarketLoading());
    final result = await getMarkets();
    result.fold(
      (failure) => emit(MarketError(failure.message)),
      (markets) => emit(MarketsLoaded(markets)),
    );
  }
}
