import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_bloc.dart';
import 'package:mobile/features/product/presentation/blocs/category_event.dart';
import 'package:mobile/features/product/presentation/blocs/category_state.dart';
import 'package:mobile/features/product/presentation/widgets/home/category_item.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'All Categories',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocProvider(
        create: (context) =>
            context.read<CategoryBloc>()..add(GetParentCategoriesEvent()),
        child: BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            if (state is ParentCategoriesLoaded) {
              if (state.categories.isEmpty) {
                return const Center(child: Text('No categories available.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemCount: state.categories.length,
                itemBuilder: (context, index) {
                  return CategoryItem(category: state.categories[index]);
                },
              );
            } else if (state is CategoriesLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is CategoriesError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<CategoryBloc>().add(
                          GetParentCategoriesEvent(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ED573),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
