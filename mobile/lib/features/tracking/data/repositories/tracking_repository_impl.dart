import 'package:fpdart/fpdart.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/storage/storage_service.dart';
import '../../../../core/utils/typedefs.dart';
import '../../domain/entities/tracking.dart';
import '../../domain/repositories/tracking_repository.dart';
import '../datasources/tracking_remote_datasource.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  final TrackingRemoteDataSource remoteDataSource;
  final StorageService storageService;

  const TrackingRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  Future<String?> _getToken() async => await storageService.getAuthToken();

  @override
  ResultFuture<TrackingInfo> getTrackingInfo(String orderId) async {
    try {
      final token = await _getToken();
      if (token == null) return Left(ServerFailure('Not authenticated'));
      final tracking = await remoteDataSource.getTrackingInfo(token, orderId);
      return Right(tracking);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }
}
