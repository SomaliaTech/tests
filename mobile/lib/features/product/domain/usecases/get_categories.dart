import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';
import '../repositories/product_repository.dart';

class GetCategories {
  final ProductRepository repository;

  GetCategories(this.repository);

  ResultFuture<List<Category>> call() async {
    return await repository.getCategories();
  }
}
