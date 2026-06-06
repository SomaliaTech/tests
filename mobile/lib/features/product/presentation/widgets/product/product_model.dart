class Product {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final double rating;
  final int reviews;
  final String description;
  final List<String> features;
  final String image;
  final List<String> images;
  final List<String>? colors;
  final List<String>? sizes;
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviews,
    required this.description,
    required this.features,
    required this.image,
    required this.images,
    this.colors,
    this.sizes,
    this.category,
  });

  double get discountPercentage {
    if (originalPrice == null) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }
}

// Mock Products Data
final Map<String, Product> products = {
  "1": Product(
    id: "1",
    name: "MIISAANKA BODY+ FAT",
    price: 15.0,
    originalPrice: 22.0,
    rating: 4.8,
    reviews: 124,
    description:
        "High-precision digital body weight scale with advanced sensor technology. Track your BMI, body fat, and more with the SOOMAR health app integration. Features tempered glass surface and auto-calibration.",
    features: [
      "High-precision sensors",
      "Tempered glass surface",
      "LCD Display with backlight",
      "Measures up to 180kg",
      "Auto-on and auto-off",
    ],
    image:
        "https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=600&h=600&fit=crop",
    images: [
      "https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=600&h=600&fit=crop",
      "https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=600&h=600&fit=crop",
      "https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=600&h=600&fit=crop",
      "https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=600&h=600&fit=crop",
    ],
    colors: ["PINK", "YELLOW", "GREEN"],
    category: "Electronics",
  ),
  "2": Product(
    id: "2",
    name: "ABDOMINAL WHEEL ROLLER",
    price: 16.0,
    originalPrice: 25.0,
    rating: 4.5,
    reviews: 89,
    description:
        "Professional grade abdominal wheel designed for core strength and stability. Features dual wheels for balance, ergonomic handles to reduce wrist strain, and a knee pad for comfort during intense workouts.",
    features: [
      "Dual-wheel stability",
      "Ergonomic foam handles",
      "Includes knee pad",
      "Heavy duty steel core",
      "Non-slip rubber tires",
    ],
    image:
        "https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=600&h=600&fit=crop",
    images: [
      "https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=600&h=600&fit=crop",
      "https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=600&h=600&fit=crop",
      "https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=600&h=600&fit=crop",
    ],
    sizes: ["S", "M", "L", "XL"],
    category: "Jirdhis",
  ),
};

final List<Product> relatedProducts = [
  Product(
    id: "3",
    name: "Yoga Mat Premium",
    price: 25.0,
    originalPrice: 35.0,
    rating: 4.7,
    reviews: 156,
    description: "Premium yoga mat",
    features: [],
    image:
        "https://images.unsplash.com/photo-1601925260368-ae2f83cf8b7f?w=400&h=400&fit=crop",
    images: [],
    category: "Jirdhis",
  ),
  Product(
    id: "4",
    name: "Resistance Bands Set",
    price: 12.0,
    originalPrice: 18.0,
    rating: 4.6,
    reviews: 98,
    description: "Resistance bands",
    features: [],
    image:
        "https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=400&h=400&fit=crop",
    images: [],
    category: "Jirdhis",
  ),
  Product(
    id: "5",
    name: "Smart Watch Pro",
    price: 89.0,
    originalPrice: 120.0,
    rating: 4.9,
    reviews: 234,
    description: "Smart watch",
    features: [],
    image:
        "https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400&h=400&fit=crop",
    images: [],
    category: "Electronics",
  ),
  Product(
    id: "6",
    name: "Digital Thermometer",
    price: 18.0,
    originalPrice: 25.0,
    rating: 4.4,
    reviews: 67,
    description: "Digital thermometer",
    features: [],
    image:
        "https://images.unsplash.com/photo-1576243345690-8e4b879f2c6e?w=400&h=400&fit=crop",
    images: [],
    category: "Electronics",
  ),
];
