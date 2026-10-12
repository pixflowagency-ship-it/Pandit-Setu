import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_side_drawer.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'Category';
  bool _showSortMenu = false;
  int _cartCount = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final String response = await rootBundle.loadString('assets/data/products.json');
      final List<dynamic> data = json.decode(response);
      final List<Map<String, dynamic>> loadedProducts = [];

      for (var i = 0; i < data.length; i++) {
        var item = data[i];
        loadedProducts.add({
          'id': item['Product_ID'] ?? i.toString(),
          'name': item['Item_Name'] ?? 'Unknown Item',
          'description': item['Product_Description'] ?? 'No description available',
          'price': 150.0 + (i % 10) * 20, // Dummy price since the sheet doesn't seem to have one
          'category': item['Category'] ?? 'General',
          'badge': item['Status'] == 'Active' ? 'AVAILABLE' : 'OUT OF STOCK',
          'badgeColor': item['Status'] == 'Active' ? 4280926393 : 4294020118,
          'samagri': [(item['Unit'] != null ? "Unit: ${item['Unit']}" : 'Standard')],
          'imageUrl': 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500', // Default generic image
        });
      }

      setState(() {
        _allProducts = loadedProducts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    List<Map<String, dynamic>> list = _allProducts;

    if (_selectedCategory != 'All') {
      list = list.where((p) => p['category'] == _selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (p) =>
                (p['name'] as String).toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (p['description'] as String).toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    if (_sortBy == 'Category') {
      list = [...list]..sort((a, b) {
        int catCompare = (a['category'] as String? ?? '').compareTo(b['category'] as String? ?? '');
        if (catCompare != 0) return catCompare;
        return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
      });
    } else if (_sortBy == 'Lowest Price') {
      list = [...list]..sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortBy == 'Highest Price') {
      list = [...list]..sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
    } else {
      list = [...list];
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      drawer: const AppSideDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 20),
                        _buildSearchBar(),
                        const SizedBox(height: 18),
                        _buildOccasionRow(),
                        const SizedBox(height: 14),
                        _buildSortRow(),
                        const SizedBox(height: 16),
                        ..._buildProductCards(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentPath: '/shop'),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: const Icon(Icons.menu, size: 26, color: Color(0xFF5A4A3A)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF18C16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Pooja Store',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(
                Icons.shopping_cart_outlined,
                size: 26,
                color: Color(0xFF3D2200),
              ),
              onPressed: () {},
            ),
            if (_cartCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF18C16),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_cartCount',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0DC),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: 'Search 156+ sacred items & samagri...',
          hintStyle: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFE8920A),
            size: 22,
          ),
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 4,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildOccasionRow() {
    final Set<String> uniqueCategories = {'All'};
    for (var p in _allProducts) {
      if (p['category'] != null && (p['category'] as String).isNotEmpty) {
        uniqueCategories.add(p['category'] as String);
      }
    }
    final categories = uniqueCategories.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATEGORY:',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
            color: const Color(0xFF8A7060),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories.map((cat) {
              final isActive = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFFF18C16) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFF18C16)
                          : const Color(0xFFE8D5A3),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFF18C16,
                              ).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    cat,
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isActive ? Colors.white : const Color(0xFF3D2200),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSortRow() {
    return Row(
      children: [
        Text(
          'Sort by: ',
          style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF8A7060)),
        ),
        GestureDetector(
          onTap: () => setState(() => _showSortMenu = !_showSortMenu),
          child: Row(
            children: [
              Text(
                _sortBy,
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFFE8920A),
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFFE8920A),
                size: 20,
              ),
            ],
          ),
        ),
        if (_showSortMenu)
          Container(
            margin: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: ['Category', 'Lowest Price', 'Highest Price'].map((opt) {
                return GestureDetector(
                  onTap: () => setState(() {
                    _sortBy = opt;
                    _showSortMenu = false;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      opt,
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildProductCards() {
    if (_isLoading) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: CircularProgressIndicator(color: Color(0xFFF18C16)),
          ),
        ),
      ];
    }
    final products = _filteredProducts;
    if (products.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                const Icon(
                  Icons.search_off,
                  color: Color(0xFFE8D5A3),
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  'No Items Found',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                Text(
                  'Try adjusting your category or search filter.',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: const Color(0xFF8A7060),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    return products
        .map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _ProductCard(
              product: p,
              onAddToCart: () {
                setState(() => _cartCount++);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${p['name']} added to cart!',
                      style: GoogleFonts.lato(color: Colors.white),
                    ),
                    backgroundColor: const Color(0xFFF18C16),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        )
        .toList();
  }


}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;

  const _ProductCard({
    required this.product,
    required this.onAddToCart,
  });

  String _getProductImageUrl(Map<String, dynamic> product) {
    if (product['imageUrl'] != null && (product['imageUrl'] as String).isNotEmpty) {
      return product['imageUrl'];
    }
    final cat = (product['category'] as String? ?? '');
    final name = (product['name'] as String? ?? '');
    
    if (cat.contains('Kalash') || name.contains('कलश')) {
      return 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=400&q=80';
    } else if (name.contains('नारियल') || name.contains('अक्षत') || name.contains('चावल')) {
      return 'https://images.unsplash.com/photo-1617981408346-39acb6da1b64?w=400&q=80';
    } else if (name.contains('फूल') || name.contains('पत्ते') || cat.contains('पुष्प')) {
      return 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400&q=80';
    } else if (name.contains('हल्दी') || name.contains('कुमकुम') || name.contains('रोली')) {
      return 'https://images.unsplash.com/photo-1596704017254-9b121068fb31?w=400&q=80';
    } else if (cat.contains('हवन') || name.contains('हवन')) {
      return 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=400&q=80';
    } else if (cat.contains('दीपक') || name.contains('दीपक') || name.contains('आरती')) {
      return 'https://images.unsplash.com/photo-1609102434313-f938d87a718b?w=400&q=80';
    }
    return 'https://images.unsplash.com/photo-1596704017254-9b121068fb31?w=400&q=80';
  }

  @override
  Widget build(BuildContext context) {
    final List<String> samagri = (product['samagri'] as List? ?? []).cast<String>();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  _getProductImageUrl(product),
                  width: 85,
                  height: 85,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 85,
                    height: 85,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        color: Color(0xFFF18C16),
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product['name'],
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF3D2200),
                            ),
                          ),
                        ),
                        if ((product['badge'] as String).isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Color(product['badgeColor'] as int),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              product['badge'],
                              style: GoogleFonts.lato(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product['description'],
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF8A7060),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${(product['price'] as double).toInt()}',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: const Color(0xFFF18C16),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF18C16), Color(0xFFE65100)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFF18C16).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: onAddToCart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Add to Cart',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (samagri.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: samagri.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE8D5A3),
                    ),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      color: const Color(0xFF8A7060),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
