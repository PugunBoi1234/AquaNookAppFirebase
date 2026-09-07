import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/product.dart';
import '../../models/seller.dart';
import '../../models/user.dart';
import '../../widgets/bubble_background.dart';
import '../../widgets/product_card.dart';
import '../../widgets/user_avatar_button.dart';
import '../product_detail_screen.dart';

enum SortOption {
  nameAsc,
  nameDesc,
  priceAsc,
  priceDesc,
  ratingDesc,
  ratingAsc,
}

class ShopTab extends StatefulWidget {
  final List<Product> products;
  final List<Seller> sellers;
  final bool isLoading;
  final Set<int> favorites;
  final Function(int) onToggleFav;
  final Function(Product, [int]) onAddToCart;
  final AppUser user;
  final VoidCallback onAddProductTap;

  const ShopTab({
    super.key,
    required this.products,
    required this.sellers,
    required this.isLoading,
    required this.favorites,
    required this.onToggleFav,
    required this.onAddToCart,
    required this.user,
    required this.onAddProductTap,
  });

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  String _category = 'all';
  String _query = '';
  List<SortOption> _activeSorts = [SortOption.nameAsc];
  int _crossAxisCount = 2;
  final ScrollController _categoryScrollController = ScrollController();

  static const Map<SortOption, SortOption> _opposites = {
    SortOption.nameAsc: SortOption.nameDesc,
    SortOption.nameDesc: SortOption.nameAsc,
    SortOption.priceAsc: SortOption.priceDesc,
    SortOption.priceDesc: SortOption.priceAsc,
    SortOption.ratingAsc: SortOption.ratingDesc,
    SortOption.ratingDesc: SortOption.ratingAsc,
  };

  @override
  void dispose() {
    _categoryScrollController.dispose();
    super.dispose();
  }

  void _toggleSort(
    SortOption option,
    void Function(void Function()) refreshSheet,
  ) {
    setState(() {
      if (_activeSorts.contains(option)) {
        _activeSorts.remove(option);
      } else {
        final opposite = _opposites[option];
        final oppositeIndex = opposite == null
            ? -1
            : _activeSorts.indexOf(opposite);
        if (oppositeIndex >= 0) {
          _activeSorts[oppositeIndex] = option;
        } else {
          _activeSorts.add(option);
        }
      }
    });
    refreshSheet(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.products.where((product) {
      final matchesCategory =
          _category == 'all' || product.category == _category;
      final matchesQuery = product.name.toLowerCase().contains(
        _query.toLowerCase(),
      );
      return matchesCategory && matchesQuery;
    }).toList();

    filtered.sort((a, b) {
      for (final option in _activeSorts) {
        final comparison = switch (option) {
          SortOption.nameAsc => a.name.toLowerCase().compareTo(
            b.name.toLowerCase(),
          ),
          SortOption.nameDesc => b.name.toLowerCase().compareTo(
            a.name.toLowerCase(),
          ),
          SortOption.priceAsc => a.price.compareTo(b.price),
          SortOption.priceDesc => b.price.compareTo(a.price),
          SortOption.ratingDesc => b.rating.compareTo(a.rating),
          SortOption.ratingAsc => a.rating.compareTo(b.rating),
        };
        if (comparison != 0) return comparison;
      }
      return 0;
    });

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 44,
                bottom: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B3B42), Color(0xFF146873)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'COZY TANK CORNER',
                              style: GoogleFonts.inter(
                                color: const Color(0xFF8FE3D8),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'AquaNook',
                              style: GoogleFonts.baloo2(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Fish, decor & gear for a calmer tank',
                              style: GoogleFonts.inter(
                                color: const Color(0xFFCBEAE6),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Sell a product',
                            onPressed: widget.onAddProductTap,
                            icon: const Icon(
                              Icons.add_business_rounded,
                              color: Color(0xFF8FE3D8),
                              size: 22,
                            ),
                          ),
                          UserAvatarButton(user: widget.user),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      return Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _query = value),
                              style: GoogleFonts.inter(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search fish, decor, gear...',
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFF4C6B70),
                                ),
                                fillColor: Colors.white,
                                filled: true,
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Color(0xFF146873),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                          ),
                          if (!compact) ...[
                            const SizedBox(width: 10),
                            _buildLayoutToggleButton(),
                          ],
                          const SizedBox(width: 10),
                          _buildSortButton(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: BubbleBackground()),
            ),
          ],
        ),
        SizedBox(
          height: 68,
          child: Listener(
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                final offset =
                    _categoryScrollController.offset + signal.scrollDelta.dy;
                _categoryScrollController.jumpTo(
                  offset.clamp(
                    0.0,
                    _categoryScrollController.position.maxScrollExtent,
                  ),
                );
              }
            },
            child: SingleChildScrollView(
              controller: _categoryScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildCategoryChip('all', 'All', Icons.apps),
                  _buildCategoryChip('equipment', 'Equipment', Icons.settings),
                  _buildCategoryChip('fish', 'Fish', Icons.phishing),
                  _buildCategoryChip(
                    'fish_food',
                    'Fish Food',
                    Icons.restaurant,
                  ),
                  _buildCategoryChip('decor', 'Tank Decor', Icons.fort),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: widget.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2EC4B6)),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    childAspectRatio: _crossAxisCount == 1 ? 1.0 : 0.72,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final product = filtered[index];
                    return ProductCard(
                      product: product,
                      isFavorite: widget.favorites.contains(product.id),
                      imageHeight: _crossAxisCount == 1 ? 200 : 110,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailScreen(
                            product: product,
                            favorites: widget.favorites,
                            onToggleFav: widget.onToggleFav,
                            onAddToCart: widget.onAddToCart,
                            sellers: widget.sellers,
                            allProducts: widget.products,
                            user: widget.user,
                          ),
                        ),
                      ),
                      onToggleFavorite: () => widget.onToggleFav(product.id),
                      onQuickAdd: () => widget.onAddToCart(product, 1),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLayoutToggleButton() {
    return IconButton(
      tooltip: _crossAxisCount == 2
          ? 'Switch to one column'
          : 'Switch to two columns',
      onPressed: () =>
          setState(() => _crossAxisCount = _crossAxisCount == 2 ? 1 : 2),
      icon: Icon(
        _crossAxisCount == 2
            ? Icons.view_agenda_rounded
            : Icons.grid_view_rounded,
        color: const Color(0xFF8FE3D8),
      ),
    );
  }

  Widget _buildSortButton() {
    return IconButton(
      tooltip: 'Sort and filter',
      onPressed: _showSortSheet,
      icon: Badge(
        isLabelVisible: _activeSorts.length > 1,
        label: Text('${_activeSorts.length}'),
        child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF146873)),
      ),
      style: IconButton.styleFrom(backgroundColor: Colors.white),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sort & Filter',
                          style: GoogleFonts.baloo2(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B3B42),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _activeSorts = [SortOption.nameAsc]);
                            setSheetState(() {});
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                  ),
                  _sortSheetTile(
                    SortOption.nameAsc,
                    'Name: A to Z',
                    Icons.sort_by_alpha_rounded,
                    setSheetState,
                  ),
                  _sortSheetTile(
                    SortOption.nameDesc,
                    'Name: Z to A',
                    Icons.sort_by_alpha_rounded,
                    setSheetState,
                  ),
                  _sortSheetTile(
                    SortOption.priceAsc,
                    'Price: Low to High',
                    Icons.arrow_upward_rounded,
                    setSheetState,
                  ),
                  _sortSheetTile(
                    SortOption.priceDesc,
                    'Price: High to Low',
                    Icons.arrow_downward_rounded,
                    setSheetState,
                  ),
                  _sortSheetTile(
                    SortOption.ratingDesc,
                    'Rating: High to Low',
                    Icons.star_rounded,
                    setSheetState,
                  ),
                  _sortSheetTile(
                    SortOption.ratingAsc,
                    'Rating: Low to High',
                    Icons.star_border_rounded,
                    setSheetState,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sortSheetTile(
    SortOption option,
    String label,
    IconData icon,
    void Function(void Function()) setSheetState,
  ) {
    final checked = _activeSorts.contains(option);
    return CheckboxListTile(
      value: checked,
      onChanged: (_) => _toggleSort(option, setSheetState),
      activeColor: const Color(0xFF2EC4B6),
      controlAffinity: ListTileControlAffinity.trailing,
      title: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: checked ? const Color(0xFF2EC4B6) : const Color(0xFF4C6B70),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: checked ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label, IconData icon) {
    final active = _category == key;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 18,
          color: active ? Colors.white : const Color(0xFF146873),
        ),
        label: Text(label, softWrap: false),
        selected: active,
        selectedColor: const Color(0xFF2EC4B6),
        backgroundColor: Colors.white,
        onSelected: (_) => setState(() => _category = key),
      ),
    );
  }
}
