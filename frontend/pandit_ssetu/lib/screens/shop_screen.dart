import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'All';
  String _sortBy = 'Popularity';
  bool _showSortMenu = false;
  int _cartCount = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allProducts = [
    {
      'id': 1,
      'name': 'Satyanarayan Pooja Kit',
      'description':
          'Complete set for the sacred Satyanarayan Katha and ritual.',
      'price': 2499.0,
      'category': 'Marriage',
      'badge': 'BESTSELLER',
      'badgeColor': 0xFFF18C16,
      'samagri': [
        'Puja Devi Ghee',
        'Premium Incense',
        'Sindhoor-Khikan',
        'Sacred Thread',
      ],
      'imagePath': 'assets/images/satyanarayan_kit.jpg',
    },
    {
      'id': 2,
      'name': 'Griha Pravesh Essentials',
      'description':
          'Curated collection for house-warming ceremonies to invite prosperity.',
      'price': 1850.0,
      'category': 'Hawan',
      'badge': 'NEW',
      'badgeColor': 0xFF4CAF50,
      'samagri': [
        'Mango Leaves',
        'Turmeric & Kashmiri',
        'Brass Diya',
        'Kapoor Sine',
      ],
      'imagePath': 'assets/images/griha_pravesh.jpg',
    },
    {
      'id': 3,
      'name': 'Vivah Sanskar Bundle',
      'description':
          'Traditional collection of wedding essentials for Vedic marriage ceremony.',
      'price': 5999.0,
      'category': 'Marriage',
      'badge': 'BESTSELLER',
      'badgeColor': 0xFFF18C16,
      'samagri': ['Sindoor', 'Sacred Thread', 'Ghee Diya', 'Havan Samagri'],
      'imagePath': 'assets/images/vivah_bundle.jpg',
    },
    {
      'id': 4,
      'name': 'Navratri Puja Combo',
      'description':
          'Complete kit for nine nights of Devi worship with all essentials.',
      'price': 1299.0,
      'category': 'Hawan',
      'badge': '',
      'badgeColor': 0xFF000000,
      'samagri': ['Red Chunri', 'Coconut', 'Camphor', 'Agarbatti'],
      'imagePath': 'assets/images/navratri_combo.jpg',
    },
    {
      'id': 5,
      'name': 'Hawan Samagri Premium',
      'description':
          'Premium hawan ingredients sourced from Himalayan herbs and sacred woods.',
      'price': 899.0,
      'category': 'Hawan',
      'badge': 'NEW',
      'badgeColor': 0xFF4CAF50,
      'samagri': ['Til (Sesame)', 'Ghee', 'Jau (Barley)', 'Sandalwood'],
      'imagePath': 'assets/images/hawan_samagri.jpg',
    },
    {
      'id': 6,
      'name': 'Marriage Ceremony Mega Kit',
      'description':
          'All-in-one sacred bundle for traditional Hindu wedding ceremonies.',
      'price': 8499.0,
      'category': 'Marriage',
      'badge': 'BESTSELLER',
      'badgeColor': 0xFFF18C16,
      'samagri': ['Haldi Pack', 'Rose Petals', 'Brass Kalash', 'Holy Thread'],
      'imagePath': 'assets/images/marriage_kit.jpg',
    },
  ];

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

    if (_sortBy == 'Popularity') {
      list =
          list.where((p) => (p['badge'] as String) == 'BESTSELLER').toList() +
          list.where((p) => (p['badge'] as String) != 'BESTSELLER').toList();
    } else {
      list = [
        ...list,
      ]..sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildNavBar(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        Row(
          children: [
            const Icon(Icons.menu, color: Color(0xFFE8920A), size: 24),
            const SizedBox(width: 12),
            Text(
              'Pandit Setu',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                color: const Color(0xFF3D2200),
              ),
            ),
          ],
        ),

        Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              color: Color(0xFFE8920A),
              size: 24,
            ),
            if (_cartCount > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF18C16),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$_cartCount',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
        border: Border.all(color: const Color(0xFFE8D5A3), width: 1),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF3D2200)),
        decoration: InputDecoration(
          hintText: 'Search for Pooja Kits, Samagri...',
          hintStyle: GoogleFonts.lato(
            fontSize: 14,
            color: Colors.grey.shade400,
          ),
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
    final categories = ['All', 'Marriage', 'Hawan'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OCCASION:',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.0,
            color: const Color(0xFF8A7060),
          ),
        ),
        const SizedBox(height: 10),
        Row(
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
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isActive ? Colors.white : const Color(0xFF3D2200),
                  ),
                ),
              ),
            );
          }).toList(),
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
              children: ['Popularity', 'Lowest Price'].map((opt) {
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
                  'No Pooja Kits Found',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                Text(
                  'Try adjusting your filters.',
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

  Widget _buildNavBar(BuildContext context) {
    final items = [
      {'icon': Icons.home_outlined, 'activeIcon': Icons.home, 'label': 'Home'},
      {
        'icon': Icons.menu_book_outlined,
        'activeIcon': Icons.menu_book,
        'label': 'Book',
      },
      {
        'icon': Icons.calendar_month_outlined,
        'activeIcon': Icons.calendar_month,
        'label': 'Panchang',
      },
      {
        'icon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag,
        'label': 'Shop',
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
      },
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 16, top: 8, left: 16, right: 16),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF3D2200),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final isActive = i == 3;
            return GestureDetector(
              onTap: () {
                switch (i) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/book');
                    break;
                  case 2:
                    context.go('/panchang');
                    break;
                  case 3:
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
              child: isActive
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF18C16),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            items[i]['activeIcon'] as IconData,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            items[i]['label'] as String,
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      items[i]['icon'] as IconData,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 22,
                    ),
            );
          }),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;

  const _ProductCard({required this.product, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    final hasBadge = (product['badge'] as String).isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8D5A3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Image.asset(
                  product['imagePath'] as String,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7EA),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18),
                      ),
                    ),
                    child: const Icon(
                      Icons.temple_hindu,
                      color: Color(0xFFE8920A),
                      size: 60,
                    ),
                  ),
                ),
              ),
              if (hasBadge)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Color(product['badgeColor'] as int),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      product['badge'],
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product['description'],
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: const Color(0xFF8A7060),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF0DC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8D5A3),
                      width: 0.8,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INCLUDED SAMAGRI',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          color: const Color(0xFF8A7060),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._buildSamagriGrid(product['samagri'] as List<String>),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹${_formatPrice(product['price'] as double)}',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 26,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF18C16), Color(0xFFE5A93B)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF18C16,
                              ).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.add_shopping_cart,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Add to Cart',
                              style: GoogleFonts.lato(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
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
    );
  }

  List<Widget> _buildSamagriGrid(List<String> items) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      '•',
                      style: TextStyle(
                        color: Color(0xFFE8920A),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        items[i],
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF3D2200),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (i + 1 < items.length)
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        '•',
                        style: TextStyle(
                          color: Color(0xFFE8920A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          items[i + 1],
                          style: GoogleFonts.lato(
                            fontSize: 12,
                            color: const Color(0xFF3D2200),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return price.toStringAsFixed(0);
  }
}
