import 'package:flutter/material.dart';
import '../models/category_model_test.dart';

class CategoryProvider extends ChangeNotifier {
  String _selectedSubCategoryId = '';
  CategoryData? _category;

  String get selectedSubCategoryId => _selectedSubCategoryId;
  CategoryData? get category => _category;

  bool get hasSelectedSubCategory => _selectedSubCategoryId.isNotEmpty;

  void loadCategory(String slug) {
    _category = categoryData[slug];
    _selectedSubCategoryId = '';
    notifyListeners();
  }

  void toggleSubCategory(String subCategoryId) {
    if (_selectedSubCategoryId == subCategoryId) {
      _selectedSubCategoryId = '';
    } else {
      _selectedSubCategoryId = subCategoryId;
    }
    notifyListeners();
  }

  List<Product> getFilteredProducts() {
    if (_category == null) return [];

    if (_selectedSubCategoryId.isEmpty) {
      return _category!.products;
    }

    // Filter products by subcategory (in real app, you'd have product-subcategory relationship)
    // For now, return all products
    return _category!.products;
  }

  void onCartPressed() {
    debugPrint('Cart button pressed');
  }

  void onProductTap(Product product) {
    debugPrint('Product tapped: ${product.name}');
  }
}
