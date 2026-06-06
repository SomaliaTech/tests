class Product {
  final int id;
  final String name;
  final double price;
  final String imageUrl;
  final bool hasBadge;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.hasBadge = false,
  });
}

final List<Product> hotDeals = [
  Product(
    id: 1,
    name: "MIISAANKA BODY+ FAT",
    price: 15.0,
    imageUrl:
        "https://i5.walmartimages.com/seo/HBF-306C-Handheld-Body-Fat-Loss-Monitor-Measures-body-fat-weight-and-percentage-with-clinically-Proven-accuracy-By-Omron-USA_8eea4f75-3376-4b45-bc3e-2d695d34870f_1.7ecb760caac21e2e5260c47369760f23.jpeg",
    hasBadge: false,
  ),
  Product(
    id: 2,
    name: "ABDOMINAL WHEEL ROLLER",
    price: 16.0,
    imageUrl:
        "https://images.unsplash.com/photo-1598289431512-b97b0917affc?w=400&h=400&fit=crop",
    hasBadge: false,
  ),
  Product(
    id: 3,
    name: 'Beoplay H9',

    price: 750,
    imageUrl:
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300',
  ),
  Product(
    id: 4,
    name: 'Beosound EX',

    price: 629,
    imageUrl:
        'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=300',
  ),
  Product(
    id: 5,
    name: 'WH-XB900N',

    price: 564,
    imageUrl:
        'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=300',
  ),
];
