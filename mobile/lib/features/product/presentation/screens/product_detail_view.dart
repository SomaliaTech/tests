import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mobile/features/product/presentation/models/product_model.dart';
import 'package:mobile/features/product/presentation/screens/product_detail_screen.dart';
import 'package:mobile/features/product/presentation/widgets/product/bottom_action_bar.dart';
import 'package:mobile/features/product/presentation/widgets/product/description_tab.dart';
import 'package:mobile/features/product/presentation/widgets/product/image_carousel.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_header.dart';
import 'package:mobile/features/product/presentation/widgets/product/product_info.dart';
import 'package:mobile/features/product/presentation/widgets/shared/related_products.dart';
import 'package:mobile/features/product/presentation/widgets/home/selection_options.dart';

class ProductDetailView extends StatefulWidget {
  final String productId;

  const ProductDetailView({super.key, required this.productId});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  late Product product;
  int selectedImageIndex = 0;
  String? selectedColor;
  String? selectedSize;
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    // Get product data
    product = products[widget.productId] ?? products["1"]!;
  }

  @override
  Widget build(BuildContext context) {
    final relatedProductsList = relatedProducts
        .where((p) => p.category == product.category)
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              ProductHeader(productName: product.name),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Carousel
                      ImageCarousel(
                        images: product.images,
                        onImageChanged: (index) {
                          setState(() {
                            selectedImageIndex = index;
                          });
                        },
                      ),

                      // Product Info Section
                      ProductInfo(product: product),

                      const SizedBox(height: 8),

                      // Selection Options
                      if (product.colors != null && product.colors!.isNotEmpty)
                        SelectionOptions(
                          title: "Select Color:",
                          options: product.colors!,
                          selectedOption: selectedColor,
                          onOptionSelected: (color) {
                            setState(() {
                              selectedColor = color;
                            });
                          },
                          optionType: OptionType.color,
                        ),

                      if (product.sizes != null && product.sizes!.isNotEmpty)
                        SelectionOptions(
                          title: "Select Size:",
                          options: product.sizes!,
                          selectedOption: selectedSize,
                          onOptionSelected: (size) {
                            setState(() {
                              selectedSize = size;
                            });
                          },
                          optionType: OptionType.size,
                        ),

                      // Description Tab
                      DescriptionTab(
                        description: product.description,
                        features: product.features,
                      ),

                      // Rxxelated Products
                      RelatedProducts(
                        products: relatedProductsList,
                        onProductTap: (productId) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProductDetailScreen(productId: productId),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: BottomActionBar(
              onFavoriteTap: () {
                // Handle favorite
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Added to favorites")),
                );
              },
              onBuyNowTap: () {
                // Handle buy now
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Buying ${product.name} - ${selectedColor != null ? "Color: $selectedColor, " : ""}${selectedSize != null ? "Size: $selectedSize" : ""}",
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
