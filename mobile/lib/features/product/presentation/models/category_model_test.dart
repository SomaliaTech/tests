import 'package:equatable/equatable.dart';

class SubCategory extends Equatable {
  final String id;
  final String name;
  final String iconUrl;

  const SubCategory({
    required this.id,
    required this.name,
    required this.iconUrl,
  });

  @override
  List<Object?> get props => [id, name, iconUrl];
}

class Product extends Equatable {
  final String id;
  final String name;
  final double price;
  final String imageUrl;
  final bool hasBadge;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.hasBadge = false,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  @override
  List<Object?> get props => [id, name, price, imageUrl, hasBadge];
}

class CategoryData extends Equatable {
  final String slug;
  final String title;
  final List<SubCategory> subCategories;
  final List<Product> products;

  const CategoryData({
    required this.slug,
    required this.title,
    required this.subCategories,
    required this.products,
  });

  @override
  List<Object?> get props => [slug, title, subCategories, products];
}

// Mock Data
final Map<String, CategoryData> categoryData = {
  'electronics': CategoryData(
    slug: 'electronics',
    title: 'ELECTRONICS',
    subCategories: const [
      SubCategory(
        id: '1',
        name: 'ACCESSORIES',
        iconUrl:
            'https://images.unsplash.com/photo-1572569511254-d8f925fe2cbb?w=100&h=100&fit=crop',
      ),
      SubCategory(
        id: '2',
        name: 'SAACADO',
        iconUrl:
            'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=100&h=100&fit=crop',
      ),
      SubCategory(
        id: '3',
        name: 'OTHERS',
        iconUrl:
            'https://images.unsplash.com/photo-1491933382434-500287f9b54b?w=100&h=100&fit=crop',
      ),
    ],
    products: [
      Product(
        id: '3',
        name: 'Apple Smart Watch',
        price: 425.00,
        imageUrl:
            'https://mtunda.ug/cdn/shop/files/Tel1.jpg?v=1718689385&width=533',
        hasBadge: false,
      ),
      Product(
        id: 'e2',
        name: 'The Best Casio Watch',
        price: 8.00,
        imageUrl:
            'https://twobrokewatchsnobs.com/wp-content/uploads/2025/08/best-casio-watches-feature.png',
        hasBadge: false,
      ),
      Product(
        id: 'e3',
        name: 'SELFIE STICK R1',
        price: 8.00,
        imageUrl:
            'https://images.unsplash.com/photo-1596703343725-7ca01bda9a45?w=400&h=400&fit=crop',
        hasBadge: false,
      ),
      Product(
        id: 'e4',
        name: 'AIRPODS 3RD.GENERATION',
        price: 10.00,
        imageUrl:
            'https://images.unsplash.com/photo-1600294037681-c80b4cb5b434?w=400&h=400&fit=crop',
        hasBadge: false,
      ),
      Product(
        id: 'e5',
        name: 'GOLDEN WATCH',
        price: 25.00,
        imageUrl:
            'https://images.unsplash.com/photo-1524592094714-0f0654e20314?w=400&h=400&fit=crop',
        hasBadge: false,
      ),
      Product(
        id: 'e6',
        name: 'ELECTRIC COOKER',
        price: 18.00,
        imageUrl:
            'https://images.unsplash.com/photo-1585515320310-259814833e62?w=400&h=400&fit=crop',
        hasBadge: false,
      ),
    ],
  ),
  'internet': CategoryData(
    slug: 'internet',
    title: 'INTERNET',
    subCategories: const [
      SubCategory(
        id: '1',
        name: 'HOME WIFI',
        iconUrl:
            'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=100&h=100&fit=crop',
      ),
      SubCategory(
        id: '2',
        name: 'MOBILE DATA',
        iconUrl:
            'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=100&h=100&fit=crop',
      ),
      SubCategory(
        id: '3',
        name: 'ROUTERS',
        iconUrl:
            'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=100&h=100&fit=crop',
      ),
    ],
    products: [
      Product(
        id: 'i1',
        name: 'HOME FIBER 10MB',
        price: 45.00,
        imageUrl:
            'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=400&h=400&fit=crop',
        hasBadge: false,
      ),
      Product(
        id: 'i2',
        name: 'MOBILE 4G DATA',
        price: 15.00,
        imageUrl:
            'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=400&h=400&fit=crop',
        hasBadge: false,
      ),
      Product(
        id: 'i3',
        name: 'WIFI ROUTER PRO',
        price: 35.00,
        imageUrl:
            'https://images.unsplash.com/photo-1544197150-b99a580bb7a8?w=400&h=400&fit=crop',
        hasBadge: false,
      ),
    ],
  ),
};
