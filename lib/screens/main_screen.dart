import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

import '../models/product.dart';
import '../models/seller.dart';
import '../models/user.dart';
import 'add_product_screen.dart';
import 'tabs/shop_tab.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/cart_tab.dart';

class MainScreen extends StatefulWidget {
  final AppUser user;

  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<Product> _products = [];
  List<Product> _localCatalog = [];
  List<Product> _firestoreProducts = [];
  List<Seller> _sellers = [];
  bool _isLoading = true;
  final Set<int> _favorites = {};
  final Map<int, int> _cart = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _productsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sellersSub;

  @override
  void initState() {
    super.initState();
    _localCatalog = fallbackProducts;
    _loadLocalCatalog();

    // Live streams instead of one-off fetches: when this user (or anyone
    // else) adds/edits a product or seller, every screen picks it up
    // automatically without needing to manually refetch or splice a new
    // item into a list.
    _productsSub = FirebaseFirestore.instance
        .collection('products')
        .snapshots()
        .listen(
          (snapshot) {
            setState(() {
              final products = snapshot.docs
                  .map((doc) => Product.fromFirestore(doc))
                  .toList();
              _firestoreProducts = products;
              _products = _mergeProducts();
              _isLoading = false;
            });
          },
          onError: (error) {
            _useFallbackProducts('Failed to load products: $error');
          },
        );

    _sellersSub = FirebaseFirestore.instance
        .collection('sellers')
        .snapshots()
        .listen(
          (snapshot) {
            setState(() {
              _sellers = snapshot.docs
                  .map((doc) => Seller.fromFirestore(doc.id, doc.data()))
                  .toList();
            });
          },
          onError: (error) {
            // Sellers are secondary info (used for "Sold by") — fail quietly.
          },
        );
  }

  Future<void> _loadLocalCatalog() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetPaths =
          manifest
              .listAssets()
              .where(
                (path) =>
                    path.startsWith('assets/images/') &&
                    !_knownAssetPaths.contains(path),
              )
              .toList()
            ..sort();
      final generated = <Product>[];
      for (var index = 0; index < assetPaths.length; index++) {
        final path = assetPaths[index];
        final parts = path.split('/');
        final folder = parts[2];
        final fileName = parts.last;
        final name = fileName
            .replaceFirst(RegExp(r'\.[^.]+$'), '')
            .replaceAll(RegExp(r'[-_]'), ' ');
        generated.add(
          Product(
            id: fallbackProducts.length + index + 1,
            name: name,
            category: folder == 'fish food'
                ? 'fish_food'
                : folder == 'gear'
                ? 'equipment'
                : folder == 'fish'
                ? 'fish'
                : 'decor',
            price: 5.99,
            rating: 4.6,
            stock: 10,
            imageUrl: path,
            blurb: 'A useful addition for your aquarium.',
          ),
        );
      }
      if (mounted) {
        setState(() {
          _localCatalog = [...fallbackProducts, ...generated];
          _products = _mergeProducts();
        });
      }
    } catch (_) {
      // The Firestore stream still supplies any seeded catalogue entries.
    }
  }

  List<Product> _mergeProducts() {
    final productsById = <int, Product>{
      for (final product in _localCatalog) product.id: product,
    };
    for (final product in _firestoreProducts) {
      productsById[product.id] = product;
    }
    return productsById.values.toList();
  }

  static const _knownAssetPaths = {
    'assets/images/fish/fancy-goldfish-on-gravel.jpg',
    'assets/images/fish/Blue guppy pair.jpg',
    'assets/images/fish/crowntail.jpg',
    'assets/images/fish/school_of_green_neon_tetras.jpg',
    'assets/images/decoration/Driftwood Branch.jpg',
    'assets/images/decoration/Sunken Castle Ornament.jpg',
    'assets/images/gear/Whisper air pump.jpg',
    'assets/images/gear/Mini-Hang-On-Aquarium-Filter.jpg',
  };

  @override
  void dispose() {
    _productsSub?.cancel();
    _sellersSub?.cancel();
    super.dispose();
  }

  void _useFallbackProducts(String message) {
    if (mounted) {
      setState(() {
        _products = fallbackProducts;
        _isLoading = false;
      });
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$message. Showing local products.')),
      );
    }
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favorites.contains(id)) {
        _favorites.remove(id);
      } else {
        _favorites.add(id);
      }
    });
  }

  void _addToCart(Product p, [int qty = 1]) {
    setState(() {
      _cart[p.id] = (_cart[p.id] ?? 0) + qty;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $qty ${p.name} to cart'),
        backgroundColor: const Color(0xFF146873),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openAddProductScreen() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddProductScreen(user: widget.user)),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your product is now listed in the shop!'),
          backgroundColor: Color(0xFF2EC4B6),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Used only if Firestore can't be reached — sellerId values are strings
  // "1".."8" to match the seeded built-in sellers.
  static final fallbackProducts = <Product>[
    Product(
      id: 1,
      name: 'Fancy Goldfish',
      category: 'fish',
      price: 9.99,
      rating: 4.5,
      stock: 14,
      imageUrl: 'assets/images/fish/fancy-goldfish-on-gravel.jpg',
      blurb: 'A plump, round classic goldfish in varieties like Oranda and Ryukin — hardy, sociable, and known to recognize its keeper over time.',
      sellerId: '1',
    ),
    Product(
      id: 2,
      name: 'Blue Guppy Pair',
      category: 'fish',
      price: 7.49,
      rating: 4.7,
      stock: 22,
      imageUrl: 'assets/images/fish/Blue guppy pair.jpg',
      blurb: 'A pair of guppies in deep metallic blue with broad, flowing tails — easy to keep and quick to breed, perfect for beginners.',
      sellerId: '2',
    ),
    Product(
      id: 3,
      name: 'Crown Tail Betta',
      category: 'fish',
      price: 18.99,
      rating: 4.9,
      stock: 9,
      imageUrl: 'assets/images/fish/crowntail.jpg',
      blurb: 'Known for its spiky, crown-like tail and bold colors — a striking solo centerpiece best kept alone in a small tank.',
      isNew: true,
      sellerId: '3',
    ),
    Product(
      id: 4,
      name: 'Neon Tetra (School of 6)',
      category: 'fish',
      price: 16.99,
      rating: 4.3,
      stock: 30,
      imageUrl: 'assets/images/fish/school_of_green_neon_tetras.jpg',
      blurb: 'A shimmering green-blue stripe runs the length of each fish — schools beautifully together and looks stunning in a planted tank.',
      sellerId: '4',
    ),
    Product(
      id: 5,
      name: 'Driftwood Branch',
      category: 'decor',
      price: 14.99,
      rating: 4.6,
      stock: 17,
      imageUrl: 'assets/images/decoration/Driftwood Branch.jpg',
      blurb: "Real driftwood with natural branching — forms the tank's hardscape and releases mild tannins that mimic a wild blackwater stream.",
      sellerId: '5',
    ),
    Product(
      id: 6,
      name: 'Sunken Castle Ornament',
      category: 'decor',
      price: 12.49,
      rating: 4.2,
      stock: 12,
      imageUrl: 'assets/images/decoration/Sunken Castle Ornament.jpg',
      blurb: 'A weathered resin ruin with archways for fish to swim through — adds a touch of fantasy to the tank.',
      sellerId: '6',
    ),
    Product(
      id: 7,
      name: 'Whisper Air Pump',
      category: 'equipment',
      price: 13.99,
      rating: 4.8,
      stock: 20,
      imageUrl: 'assets/images/gear/Whisper air pump.jpg',
      blurb: 'Built for near-silent operation with steady airflow — boosts oxygen levels without disturbing the room.',
      sellerId: '7',
    ),
    Product(
      id: 8,
      name: 'Compact Aquarium Filter',
      category: 'equipment',
      price: 27.99,
      rating: 5.0,
      stock: 10,
      imageUrl: 'assets/images/gear/Mini-Hang-On-Aquarium-Filter.jpg',
      blurb: 'A compact hang-on-back filter that saves inside space, installs easily, and runs quietly — great for small tanks and betta bowls.',
      isNew: true,
      sellerId: '8',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      ShopTab(
        products: _products,
        sellers: _sellers,
        isLoading: _isLoading,
        favorites: _favorites,
        onToggleFav: _toggleFavorite,
        onAddToCart: _addToCart,
        user: widget.user,
        onAddProductTap: _openAddProductScreen,
      ),
      FavoritesTab(
        products: _products.where((p) => _favorites.contains(p.id)).toList(),
        favorites: _favorites,
        onToggleFav: _toggleFavorite,
        onAddToCart: _addToCart,
        user: widget.user,
      ),
      CartTab(
        products: _products,
        cart: _cart,
        user: widget.user,
        onUpdateQty: (id, qty) {
          setState(() {
            if (qty <= 0) {
              _cart.remove(id);
            } else {
              _cart[id] = qty;
            }
          });
        },
        onClearCart: () => setState(() => _cart.clear()),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFEAF7F5),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF123138).withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          backgroundColor: Colors.white,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: const Color(0xFF2EC4B6),
          unselectedItemColor: const Color(0xFF4C6B70),
          selectedLabelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.store),
              label: 'Shop',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('${_favorites.length}'),
                isLabelVisible: _favorites.isNotEmpty,
                child: const Icon(Icons.favorite),
              ),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Badge(
                label: Text('${_cart.values.fold(0, (a, b) => a + b)}'),
                isLabelVisible: _cart.isNotEmpty,
                child: const Icon(Icons.shopping_bag),
              ),
              label: 'Cart',
            ),
          ],
        ),
      ),
    );
  }
}
