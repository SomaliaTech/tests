import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/dashboard_remote_data_source.dart';
import 'package:mobile/features/admin/domain/repositories/dashboard_repository.dart';
import 'package:mobile/features/admin/presentation/bloc/dashborad/dashboard_state.dart';
import 'package:flutter/foundation.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardLoaded> getAllDashboardData(String period) async {
    if (kDebugMode)
      debugPrint(
        '🔄 [Repository] Getting all dashboard data for period: $period',
      );
    try {
      final result = await remoteDataSource.getAllDashboardData(period);
      if (kDebugMode)
        debugPrint('✅ [Repository] All dashboard data retrieved successfully');
      return result;
    } on ServerException catch (e) {
      if (kDebugMode)
        debugPrint('❌ [Repository] ServerException: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('❌ [Repository] Unexpected error: $e');
      if (kDebugMode) debugPrint('📚 [Repository] Stack trace: $stackTrace');
      rethrow;
    }
  }
}
