import 'package:mobile/features/admin/domain/entities/color_entity.dart';
import 'package:mobile/features/admin/domain/entities/size_entity.dart';

abstract class AdminColorSizeRepository {
  Future<List<ColorEntity>> getAllColors();
  Future<void> createColor(Map<String, dynamic> data);
  Future<void> updateColor(String colorId, Map<String, dynamic> data);
  Future<void> deleteColor(String colorId);

  Future<List<SizeEntity>> getAllSizes();
  Future<void> createSize(Map<String, dynamic> data);
  Future<void> updateSize(String sizeId, Map<String, dynamic> data);
  Future<void> deleteSize(String sizeId);
}
