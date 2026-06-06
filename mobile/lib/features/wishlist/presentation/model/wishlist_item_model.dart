import 'package:flutter/material.dart';

class WishlistItem {
  final String id;
  final String name;
  final double rating;
  final double price;
  final String imageUrl;
  final Color backgroundColor;

  WishlistItem({
    required this.id,
    required this.name,
    required this.rating,
    required this.price,
    required this.imageUrl,
    required this.backgroundColor,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(0)}';
  String get ratingString => rating.toString();
}

// Mock data
final List<WishlistItem> mockWishlistItems = [
  WishlistItem(
    id: '1',
    name: 'Beosound A1',
    rating: 4.8,
    price: 650,
    imageUrl: 'https://images.unsplash.com/photo-1546435770-a3e426bf472b?w=300',
    backgroundColor: const Color(0xFFE3ECF5),
  ),
  WishlistItem(
    id: '2',
    name: 'Beoplay H9',
    rating: 4.9,
    price: 750,
    imageUrl:
        'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300',
    backgroundColor: const Color(0xFFF3EFE9),
  ),
  WishlistItem(
    id: '3',
    name: 'Beosound EX',
    rating: 4.9,
    price: 629,
    imageUrl:
        'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=300',
    backgroundColor: const Color(0xFFEEF0F2),
  ),
  WishlistItem(
    id: '4',
    name: 'WH-XB900N',
    rating: 4.7,
    price: 564,
    imageUrl:
        'https://images.unsplash.com/photo-1484704849700-f032a568e944?w=300',
    backgroundColor: const Color(0xFFF5EBE1),
  ),
];
