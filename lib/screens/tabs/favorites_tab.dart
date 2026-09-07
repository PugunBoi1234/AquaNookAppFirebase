import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product.dart';
import '../../models/user.dart';
import '../../widgets/product_image.dart';
import '../../widgets/bubble_background.dart';
import '../../widgets/user_avatar_button.dart';

class FavoritesTab extends StatefulWidget {
  final List<Product> products;
  final Set<int> favorites;
  final Function(int) onToggleFav;
  final Function(Product, [int]) onAddToCart;
  final AppUser user;

  const FavoritesTab({
    super.key,
    required this.products,
    required this.favorites,
    required this.onToggleFav,
    required this.onAddToCart,
    required this.user,
  });

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products
        .where((p) => p.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Column(
      children: [
        Stack(
          children: [
            Container(
          width: double.infinity,
          padding: const EdgeInsets.only(left: 20, right: 20, top: 48, bottom: 20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0B3B42), Color(0xFF146873)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Favorites',
                    style: GoogleFonts.baloo2(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  UserAvatarButton(
                    user: widget.user,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) => setState(() => _query = v),
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search favorites...',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF4C6B70)),
                  fillColor: Colors.white,
                  filled: true,
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF146873)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
            const Positioned.fill(child: IgnorePointer(child: BubbleBackground())),
          ],
        ),
        Expanded(
          child: widget.products.isEmpty
              ? Center(
                  child: Text('No favorites yet!', style: GoogleFonts.inter(color: const Color(0xFF4C6B70))),
                )
              : filtered.isEmpty
                  ? Center(
                      child: Text('No favorites match "$_query"', style: GoogleFonts.inter(color: const Color(0xFF4C6B70))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final p = filtered[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: SizedBox(
                              width: 56,
                              height: 56,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: ProductImage(product: p, iconSize: 36),
                              ),
                            ),
                            title: Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                            subtitle: Text('\$${p.price.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.favorite, color: Color(0xFFFF8A5B)),
                              onPressed: () => widget.onToggleFav(p.id),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
