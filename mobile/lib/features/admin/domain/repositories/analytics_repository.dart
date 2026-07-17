import 'package:fpdart/fpdart.dart';
import 'package:mobile/core/error/failures.dart';
import '../entities/analytics_entities.dart';

abstract class AnalyticsRepository {
  Future<Either<Failure, AnalyticsDataEntity>> getAllAnalytics({
    String period = 'week',
  });

  Future<Either<Failure, AnalyticsDataEntity>> getAnalyticsForCustomDates({
    required List<DateTime> dates,
  });
}
