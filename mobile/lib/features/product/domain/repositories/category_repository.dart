import '../../../../core/utils/typedefs.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  ResultFuture<List<Category>> getCategories();
  ResultFuture<List<Category>> getParentCategories();
  ResultFuture<List<Category>> getSubcategories(String parentId);
  ResultFuture<Category> getCategoryById(String id); // Make sure this exists
  ResultFuture<Category> getCategoryBySlug(String slug);
}
