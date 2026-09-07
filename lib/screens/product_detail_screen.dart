import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product.dart';
import '../models/seller.dart';
import '../models/user.dart';
import '../widgets/avatar_display.dart';
import '../widgets/product_image.dart';
import '../widgets/user_avatar_button.dart';
import 'seller_profile_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final Set<int> favorites;
  final Function(int) onToggleFav;
  final Function(Product, [int]) onAddToCart;
  final List<Seller> sellers;
  final List<Product> allProducts;
  final AppUser user;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.favorites,
    required this.onToggleFav,
    required this.onAddToCart,
    required this.sellers,
    required this.allProducts,
    required this.user,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.favorites.contains(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    Seller? seller;
    if (p.sellerId != null) {
      try {
        seller = widget.sellers.firstWhere((s) => s.id == p.sellerId);
      } catch (_) {
        seller = null;
      }
    }
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF146873)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite
                  ? const Color(0xFFFF8A5B)
                  : const Color(0xFF146873),
            ),
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              widget.onToggleFav(p.id);
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: UserAvatarButton(
              user: widget.user,
              background: const Color(0xFFEAF7F5),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF123138).withOpacity(0.06),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: ProductImage(product: p, iconSize: 110),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2EC4B6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.category.replaceAll('_', ' ').toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF146873),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      p.hasRating
                          ? Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  color: Color(0xFFFFD166),
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${p.rating}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF123138),
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              'No Rate',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4C6B70),
                              ),
                            ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    p.name,
                    style: GoogleFonts.baloo2(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF146873),
                    ),
                  ),
                  Text(
                    'In Stock: ${p.stock} units available',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: p.stock > 0 ? const Color(0xFF2EC4B6) : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF123138),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    p.blurb,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF4C6B70),
                      height: 1.5,
                    ),
                  ),
                  if (seller != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Sold by',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF123138),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openSellerProfile(context, seller!),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE3F1EE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEAF7F5),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: ClipOval(
                                child: AvatarDisplay(
                                  avatar: seller!.avatar,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    seller!.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: const Color(0xFF123138),
                                    ),
                                  ),
                                  Text(
                                    seller!.tagline,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: const Color(0xFF4C6B70),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF4C6B70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Price',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4C6B70),
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '\$${(p.price * _quantity).toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF146873),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A5B),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    widget.onAddToCart(p, _quantity);
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Add to Cart',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSellerProfile(BuildContext context, Seller seller) {
    final sellerProducts = widget.allProducts
        .where((prod) => prod.sellerId == seller.id)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SellerProfileScreen(
          seller: seller,
          products: sellerProducts,
          favorites: widget.favorites,
          onToggleFav: widget.onToggleFav,
          onAddToCart: widget.onAddToCart,
          sellers: widget.sellers,
          allProducts: widget.allProducts,
          user: widget.user,
        ),
      ),
    );
  }
}
