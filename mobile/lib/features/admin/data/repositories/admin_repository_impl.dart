import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/admin_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:mobile/features/admin/domain/entities/admin_order_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AdminStatsEntity> getAdminStats() async {
    try {
      return await remoteDataSource.getDashboardStats();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<AdminOrderEntity>> getAllOrders(String? search) async {
    try {
      return await remoteDataSource.getAllOrders(search);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await remoteDataSource.updateOrderStatus(orderId, newStatus);
    } on ServerException {
      rethrow;
    }
  }
}
