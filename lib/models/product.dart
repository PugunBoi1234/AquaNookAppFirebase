import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  static const localCatalogLastId = 78;

  final int id;
  final String name;
  final String category;
  final double price;
  final double rating;
  final int stock;
  final String? imageUrl;
  final String blurb;
  final bool isNew;
  final String?
  sellerId; // Firestore seller doc id (built-in "1".."8" or a user's uid)

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.rating,
    required this.stock,
    this.imageUrl,
    required this.blurb,
    this.isNew = false,
    this.sellerId,
  });

  bool get hasRating {
    final seller = sellerId;
    return seller == null || int.tryParse(seller) != null;
  }

  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      id: (data['id'] as num?)?.toInt() ?? int.tryParse(doc.id) ?? 0,
      name: data['name'] as String? ?? 'Unnamed product',
      category: data['category'] as String? ?? 'fish',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 4.5,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      imageUrl: data['imageUrl'] as String?,
      blurb: data['blurb'] as String? ?? '',
      isNew: data['isNew'] as bool? ?? false,
      sellerId: data['sellerId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'rating': rating,
      'stock': stock,
      'imageUrl': imageUrl,
      'blurb': blurb,
      'isNew': isNew,
      'sellerId': sellerId,
    };
  }
}
