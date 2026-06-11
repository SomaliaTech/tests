import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/order.dart' as domain;
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async => await storageService.getAuthToken();

  @override
  ResultFuture<domain.DomainOrder> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final order = await remoteDataSource.createOrder(token, orderData);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  ResultFuture<Map<String, dynamic>> processPayment(
    String orderId,
    String paymentMethod, {
    String? phoneNumber,
  }) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final result = await remoteDataSource.processPayment(
        token,
        orderId,
        paymentMethod,
        phoneNumber: phoneNumber,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
