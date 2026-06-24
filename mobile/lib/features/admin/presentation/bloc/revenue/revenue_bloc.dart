import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/admin/domain/repositories/admin_revenue_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/revenue/revenue_event.dart';
import 'package:mobile/features/admin/presentation/bloc/revenue/revenue_state.dart';

class RevenueBloc extends Bloc<RevenueEvent, RevenueState> {
  final AdminRevenueRepository repository;

  RevenueBloc({required this.repository}) : super(RevenueInitial()) {
    on<FetchRevenueSummaryEvent>(_onFetchSummary);
    on<FetchAllRevenueEvent>(_onFetchAll);
    on<FetchRevenueDetailsEvent>(_onFetchDetails);
  }

  Future<void> _onFetchSummary(
    FetchRevenueSummaryEvent event,
    Emitter<RevenueState> emit,
  ) async {
    emit(RevenueSummaryLoading());
    try {
      final summary = await repository.getRevenueSummary(event.period);
      emit(RevenueSummaryLoaded(summary, event.period));
    } catch (e) {
      emit(RevenueSummaryError(e.toString()));
    }
  }

  Future<void> _onFetchAll(
    FetchAllRevenueEvent event,
    Emitter<RevenueState> emit,
  ) async {
    emit(RevenueListLoading());
    try {
      final result = await repository.getAllRevenue(
        search: event.search,
        paymentMethod: event.paymentMethod,
        status: event.status,
        limit: event.limit,
        offset: event.offset,
      );
      emit(RevenueListLoaded(result.data, result.total));
    } catch (e) {
      emit(RevenueListError(e.toString()));
    }
  }

  Future<void> _onFetchDetails(
    FetchRevenueDetailsEvent event,
    Emitter<RevenueState> emit,
  ) async {
    emit(RevenueDetailsLoading());
    try {
      final revenue = await repository.getRevenueById(event.orderId);
      emit(RevenueDetailsLoaded(revenue));
    } catch (e) {
      emit(RevenueDetailsError(e.toString()));
    }
  }
}
