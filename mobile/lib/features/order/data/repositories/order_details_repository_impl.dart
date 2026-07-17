import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../domain/entities/order_details.dart';
import '../../domain/repositories/order_details_repository.dart';
import '../datasources/order_details_remote_datasource.dart';

class OrderDetailsRepositoryImpl implements OrderDetailsRepository {
  final OrderDetailsRemoteDataSource remoteDataSource;
  final StorageService storageService;

  OrderDetailsRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<Either<Failure, OrderDetails>> getOrderDetails(
    String orderId, {
    bool isAdmin = false,
    bool isSuperAdmin = false,
  }) async {
    try {
      final token = await storageService.getAuthToken();
      if (token == null || token.isEmpty) {
        return const Left(ServerFailure('Authentication token not found'));
      }
      final order = await remoteDataSource.getOrderDetails(
        token,
        orderId,
        isAdmin: isAdmin,
        isSuperAdmin: isSuperAdmin,
      );
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to load order details: $e'));
    }
  }
}
