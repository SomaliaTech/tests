import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetSubcategories {
  final CategoryRepository repository;

  const GetSubcategories(this.repository);

  ResultFuture<List<Category>> call(String parentId) async {
    return await repository.getSubcategories(parentId);
  }
}
