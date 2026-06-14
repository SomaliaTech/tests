import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/order_details.dart';
import '../../domain/repositories/order_details_repository.dart';
import '../datasources/order_details_remote_datasource.dart';

class OrderDetailsRepositoryImpl implements OrderDetailsRepository {
  final OrderDetailsRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const OrderDetailsRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async => await storageService.getAuthToken();

  @override
  ResultFuture<OrderDetails> getOrderDetails(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final order = await remoteDataSource.getOrderDetails(token, orderId);
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
