import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/features/admin/data/datasources/admin_color_size_remote_data_source.dart';
import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';
import 'package:mobile/features/admin/domain/repositories/admin_color_size_repository.dart';

class AdminColorSizeRepositoryImpl implements AdminColorSizeRepository {
  final AdminColorSizeRemoteDataSource remoteDataSource;

  AdminColorSizeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ColorEntity>> getAllColors() async {
    try {
      return await remoteDataSource.getAllColors();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> createColor(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.createColor(data);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> updateColor(String colorId, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateColor(colorId, data);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> deleteColor(String colorId) async {
    try {
      await remoteDataSource.deleteColor(colorId);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<List<SizeEntity>> getAllSizes() async {
    try {
      return await remoteDataSource.getAllSizes();
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> createSize(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.createSize(data);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> updateSize(String sizeId, Map<String, dynamic> data) async {
    try {
      await remoteDataSource.updateSize(sizeId, data);
    } on ServerException {
      rethrow;
    }
  }

  @override
  Future<void> deleteSize(String sizeId) async {
    try {
      await remoteDataSource.deleteSize(sizeId);
    } on ServerException {
      rethrow;
    }
  }
}
