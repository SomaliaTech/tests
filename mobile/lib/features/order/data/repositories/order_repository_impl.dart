// lib/features/order/data/repositories/order_repository_impl.dart
import 'dart:developer' as developer;
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_remote_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  ResultFuture<Map<String, dynamic>> createOrder(
    Map<String, dynamic> orderData,
  ) async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));

      final result = await remoteDataSource.createOrder(token, orderData);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
