import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/core/common/widgets/navigation.dart';
import 'package:mobile/core/theme/theme.dart';
import 'package:mobile/features/product/data/datasources/product_remote_datasource.dart';
import 'package:mobile/features/product/data/repositories/product_repository_impl.dart';
import 'package:mobile/features/product/domain/repositories/product_repository.dart';
import 'package:mobile/features/product/domain/usecases/get_categories.dart';
import 'package:mobile/features/product/domain/usecases/get_featured_products.dart';
import 'package:mobile/features/product/domain/usecases/get_products_by_category.dart';
import 'package:mobile/features/product/domain/usecases/search_products.dart';
import 'package:mobile/features/product/presentation/blocs/product_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (context) => _initProductBloc())],
      child: MaterialApp(
        title: 'HALDOOR',
        debugShowCheckedModeBanner: false,

        theme: AppTheme.lightTheme,
        home: const MainNavigationScreen(),
      ),
    );
  }
}
//   Widget build(BuildContext context) {
//     return BlocConsumer<SubjectBloc, SubjectState>(
//       listener: (context, state) {
//         // TODO: implement listener
//       },
//       builder: (context, state) {
//         return MaterialApp(
//           title: 'Flutter Bottom Nav',
//           theme: AppTheme.lightTheme,
//           home: const MainNavigationScreen(),
//           debugShowCheckedModeBanner: false,
//         );
//       },
//     );
//   }
// }

ProductBloc _initProductBloc() {
  // Initialize dependencies
  final http.Client client = http.Client();
  final ProductRemoteDataSource remoteDataSource = ProductRemoteDataSourceImpl(
    client: client,
  );
  final ProductRepository repository = ProductRepositoryImpl(
    remoteDataSource: remoteDataSource,
  );

  // Initialize use cases
  final getCategories = GetCategories(repository);
  final getFeaturedProducts = GetFeaturedProducts(repository);
  final getProductsByCategory = GetProductsByCategory(repository);
  final searchProducts = SearchProducts(repository);

  return ProductBloc(
    getCategories: getCategories,
    getFeaturedProducts: getFeaturedProducts,
    getProductsByCategory: getProductsByCategory,
    searchProducts: searchProducts,
  );
}
