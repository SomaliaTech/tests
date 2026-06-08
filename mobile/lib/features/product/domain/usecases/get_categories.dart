import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';
import '../repositories/product_repository.dart';

class GetCategories {
  final ProductRepository repository;

  const GetCategories(this.repository);

  ResultFuture<List<Category>> call() async {
    return await repository.getCategories();
  }
}
