import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetParentCategories {
  final CategoryRepository repository;

  const GetParentCategories(this.repository);

  ResultFuture<List<Category>> call() async {
    return await repository.getParentCategories();
  }
}
