import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';
import '../repositories/product_repository.dart';

class GetSubcategories {
  final ProductRepository repository;

  const GetSubcategories(this.repository);

  ResultFuture<List<Category>> call(String parentId) async {
    return await repository.getSubcategories(parentId);
  }
}
