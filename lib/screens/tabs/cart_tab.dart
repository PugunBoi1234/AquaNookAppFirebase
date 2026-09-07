import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product.dart';
import '../../models/user.dart';
import '../../widgets/product_image.dart';
import '../../widgets/bubble_background.dart';
import '../../widgets/user_avatar_button.dart';
import '../thank_you_screen.dart';

class CartTab extends StatefulWidget {
  final List<Product> products;
  final Map<int, int> cart;
  final Function(int, int) onUpdateQty;
  final VoidCallback onClearCart;
  final AppUser user;

  const CartTab({
    super.key,
    required this.products,
    required this.cart,
    required this.onUpdateQty,
    required this.onClearCart,
    required this.user,
  });

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cart.entries.map((e) {
      final product = widget.products.firstWhere((p) => p.id == e.key);
      return {'product': product, 'qty': e.value};
    }).toList();

    final filteredCartItems = cartItems
        .where((item) => (item['product'] as Product).name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    // Total always reflects the whole cart, not just what the search matches.
    double total = cartItems.fold(0, (sum, item) => sum + ((item['product'] as Product).price * (item['qty'] as int)));

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
                    'Your Cart',
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
                  hintText: 'Search cart...',
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
          child: cartItems.isEmpty
              ? Center(
                  child: Text('Your cart is empty', style: GoogleFonts.inter(color: const Color(0xFF4C6B70))),
                )
              : filteredCartItems.isEmpty
                  ? Center(
                      child: Text('No cart items match "$_query"', style: GoogleFonts.inter(color: const Color(0xFF4C6B70))),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredCartItems.length,
                      itemBuilder: (ctx, i) {
                        final p = filteredCartItems[i]['product'] as Product;
                        final qty = filteredCartItems[i]['qty'] as int;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ProductImage(product: p, iconSize: 40),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                      Text('\$${p.price.toStringAsFixed(2)}'),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      onPressed: () => widget.onUpdateQty(p.id, qty - 1),
                                    ),
                                    Text('$qty', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      onPressed: () => widget.onUpdateQty(p.id, qty + 1),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
        if (cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total: \$${total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A5B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  onPressed: () {
                    final orderTotal = total;
                    final orderItemCount = cartItems.fold<int>(
                      0,
                      (sum, item) => sum + (item['qty'] as int),
                    );
                    widget.onClearCart();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ThankYouScreen(
                          total: orderTotal,
                          itemCount: orderItemCount,
                        ),
                      ),
                    );
                  },
                  child: const Text('Checkout', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          )
      ],
    );
  }
}
