import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/analytics_remote_data_source.dart';
import '../../domain/entities/analytics_entities.dart';
import '../../domain/repositories/analytics_repository.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;

  AnalyticsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AnalyticsDataEntity>> getAllAnalytics({
    String period = 'week',
  }) async {
    try {
      final data = await remoteDataSource.getAllAnalytics(period: period);
      return Right(data);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
