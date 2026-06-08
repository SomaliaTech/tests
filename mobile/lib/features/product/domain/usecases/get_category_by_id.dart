import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoryById {
  final CategoryRepository repository;

  const GetCategoryById(this.repository);

  ResultFuture<Category> call(String id) async {
    return await repository.getCategoryById(id);
  }
}
