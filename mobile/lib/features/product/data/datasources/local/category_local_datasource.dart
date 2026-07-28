// lib/features/product/data/datasources/local/category_local_datasource.dart
import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:hive/hive.dart';
import 'package:mobile/features/product/data/models/category_model.dart';
import 'package:mobile/features/product/domain/entities/category.dart';

abstract class CategoryLocalDataSource {
  Future<List<Category>> getCachedCategories();
  Future<void> cacheCategories(List<Category> categories);
  Future<List<Category>> getCachedParentCategories();
  Future<void> cacheParentCategories(List<Category> categories);
  Future<List<Category>> getCachedSubcategories(String parentId);
  Future<void> cacheSubcategories(
    String parentId,
    List<Category> subcategories,
  );
  Future<Category?> getCachedCategory(String categoryId);
  Future<void> cacheCategory(Category category);
}

class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  static const String _categoryBox = 'category_cache';
  static const String _categoriesKey = 'all_categories';
  static const String _parentCategoriesKey = 'parent_categories';

  // ✅ Use Hive.box() instead of openBox()
  Box<String> get _box => Hive.box<String>(_categoryBox);

  @override
  Future<List<Category>> getCachedCategories() async {
    try {
      final jsonString = _box.get(_categoriesKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error reading cached categories: $e');
    }
    return [];
  }

  @override
  Future<void> cacheCategories(List<Category> categories) async {
    try {
      final jsonList = categories.map((c) => _categoryToJson(c)).toList();
      await _box.put(_categoriesKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching categories: $e');
    }
  }

  @override
  Future<List<Category>> getCachedParentCategories() async {
    try {
      final jsonString = _box.get(_parentCategoriesKey);
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error reading cached parent categories: $e');
    }
    return [];
  }

  @override
  Future<void> cacheParentCategories(List<Category> categories) async {
    try {
      final jsonList = categories.map((c) => _categoryToJson(c)).toList();
      await _box.put(_parentCategoriesKey, json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching parent categories: $e');
    }
  }

  @override
  Future<List<Category>> getCachedSubcategories(String parentId) async {
    try {
      final jsonString = _box.get('subcategories_$parentId');
      if (jsonString != null) {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('❌ Error reading cached subcategories for $parentId: $e');
    }
    return [];
  }

  @override
  Future<void> cacheSubcategories(
    String parentId,
    List<Category> subcategories,
  ) async {
    try {
      final jsonList = subcategories.map((c) => _categoryToJson(c)).toList();
      await _box.put('subcategories_$parentId', json.encode(jsonList));
    } catch (e) {
      debugPrint('❌ Error caching subcategories for $parentId: $e');
    }
  }

  @override
  Future<Category?> getCachedCategory(String categoryId) async {
    try {
      final jsonString = _box.get('category_$categoryId');
      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = json.decode(jsonString);
        return CategoryModel.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('❌ Error reading cached category $categoryId: $e');
    }
    return null;
  }

  @override
  Future<void> cacheCategory(Category category) async {
    try {
      final jsonMap = _categoryToJson(category);
      await _box.put('category_${category.id}', json.encode(jsonMap));
    } catch (e) {
      debugPrint('❌ Error caching category ${category.id}: $e');
    }
  }

  Map<String, dynamic> _categoryToJson(Category category) {
    return {
      'id': category.id,
      'name': category.name,
      'slug': category.slug,
      if (category.description != null) 'description': category.description,
      if (category.parentId != null) 'parentId': category.parentId,
      if (category.iconUrl != null) 'iconUrl': category.iconUrl,
    };
  }
}
