import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/product.dart';
import '../models/seller.dart';
import '../models/user.dart';
import '../widgets/avatar_display.dart';
import '../widgets/product_card.dart';
import '../widgets/user_avatar_button.dart';
import 'product_detail_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  final Seller seller;
  final List<Product> products;
  final Set<int> favorites;
  final Function(int) onToggleFav;
  final Function(Product, [int]) onAddToCart;
  final List<Seller> sellers;
  final List<Product> allProducts;
  final AppUser user;

  const SellerProfileScreen({
    super.key,
    required this.seller,
    required this.products,
    required this.favorites,
    required this.onToggleFav,
    required this.onAddToCart,
    required this.sellers,
    required this.allProducts,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F5),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF0B3B42),
            pinned: true,
            expandedHeight: 190,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16, left: 4),
                child: UserAvatarButton(user: user),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0B3B42), Color(0xFF146873)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: ClipOval(child: AvatarDisplay(avatar: seller.avatar, size: 26)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          seller.name,
                          style: GoogleFonts.baloo2(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seller.tagline,
                          style: GoogleFonts.inter(color: const Color(0xFFCBEAE6), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                '${products.length} product${products.length == 1 ? '' : 's'} from this seller',
                style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF4C6B70), fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (products.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text('No products listed yet.', style: GoogleFonts.inter(color: const Color(0xFF4C6B70))),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.66,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = products[index];
                    final isFav = favorites.contains(p.id);
                    return ProductCard(
                      product: p,
                      isFavorite: isFav,
                      showDescription: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailScreen(
                              product: p,
                              favorites: favorites,
                              onToggleFav: onToggleFav,
                              onAddToCart: onAddToCart,
                              sellers: sellers,
                              allProducts: allProducts,
                              user: user,
                            ),
                          ),
                        );
                      },
                      onToggleFavorite: () => onToggleFav(p.id),
                      onQuickAdd: () => onAddToCart(p, 1),
                    );
                  },
                  childCount: products.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
