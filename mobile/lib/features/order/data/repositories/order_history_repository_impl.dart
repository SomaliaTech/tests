import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/order_history.dart';
import '../../domain/repositories/order_history_repository.dart';
import '../datasources/order_history_remote_datasource.dart';

class OrderHistoryRepositoryImpl implements OrderHistoryRepository {
  final OrderHistoryRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const OrderHistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async => await storageService.getAuthToken();

  @override
  ResultFuture<List<OrderHistory>> getOrders() async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final orders = await remoteDataSource.getOrders(token);
      return Right(orders);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<OrderHistory> getOrderById(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final order = await remoteDataSource.getOrderById(token, orderId);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
