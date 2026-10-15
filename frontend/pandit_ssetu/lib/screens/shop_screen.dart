import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../services/cart_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  // Pagination state
  int _currentPage = 1;
  static const int _pageSize = 30;
  bool _hasMore = true;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _allProducts = [];

  // Available curated categories in store catalog
  final List<String> _baseCategories = [
    'All',
    'Havan Samagri',
    'Idols & Murtis',
    'Dhoop & Agarbatti',
    'Diya & Batti',
    'Pooja Thali & Kalash',
    'Sacred Threads & Vastra',
    'General Pooja Material',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadProducts(page: 1);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      if (!_isLoading && !_isLoadingMore && _hasMore) {
        _loadMore();
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _resetAndFetch();
    });
  }

  Future<void> _resetAndFetch() async {
    setState(() {
      _currentPage = 1;
      _hasMore = true;
      _errorMessage = null;
      _allProducts = [];
    });
    await _loadProducts(page: 1);
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    await _loadProducts(page: _currentPage + 1, isNextPage: true);
  }

  Future<void> _loadProducts({required int page, bool isNextPage = false}) async {
    if (!isNextPage) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final queryCategory = _selectedCategory == 'All' ? null : _selectedCategory;
      final querySearch = _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null;

      final rawItems = await ApiService.getProducts(
        page: page,
        limit: _pageSize,
        category: queryCategory,
        search: querySearch,
      );

      final List<Map<String, dynamic>> loadedProducts = [];

      for (var item in rawItems) {
        final double price = double.tryParse(item['price']?.toString() ?? '150') ?? 150.0;
        final bool isActive = item['isActive'] == true || item['status'] == 'Active';
        final List<dynamic> rawSamagri = item['samagri'] is List ? item['samagri'] : [];
        final List<String> samagriList = rawSamagri.map((e) => e.toString()).toList();
        if (samagriList.isEmpty && item['unit'] != null) {
          samagriList.add('Unit: ${item['unit']}');
        }

        loadedProducts.add({
          'id': item['id']?.toString() ?? item['productId']?.toString() ?? '',
          'productId': item['productId']?.toString() ?? '',
          'name': item['name']?.toString() ?? 'Pooja Samagri',
          'description': item['description']?.toString() ?? '',
          'price': price,
          'category': item['category']?.toString() ?? 'General Pooja Material',
          'subCategory': item['subCategory']?.toString() ?? '',
          'badge': item['badge']?.toString() ?? (isActive ? 'AVAILABLE' : 'OUT OF STOCK'),
          'badgeColor': isActive ? 4280926393 : 4294020118,
          'samagri': samagriList,
          'imageUrl': item['imageUrl']?.toString() ?? '',
          'unit': item['unit']?.toString(),
        });
      }

      if (mounted) {
        setState(() {
          if (isNextPage) {
            // Deduplicate items
            final Set<String> existingIds = _allProducts.map((p) => p['id'].toString()).toSet();
            for (var item in loadedProducts) {
              if (!existingIds.contains(item['id'].toString())) {
                _allProducts.add(item);
                existingIds.add(item['id'].toString());
              }
            }
            _currentPage = page;
            _isLoadingMore = false;
          } else {
            _allProducts = loadedProducts;
            _currentPage = 1;
            _isLoading = false;
          }

          if (loadedProducts.length < _pageSize) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _sortedProducts {
    List<Map<String, dynamic>> list = [..._allProducts];

    if (_sortBy == 'Category') {
      list.sort((a, b) {
        int catCompare = (a['category'] as String? ?? '').compareTo(b['category'] as String? ?? '');
        if (catCompare != 0) return catCompare;
        return (a['name'] as String? ?? '').compareTo(b['name'] as String? ?? '');
      });
    } else if (_sortBy == 'Lowest Price') {
      list.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
    } else if (_sortBy == 'Highest Price') {
      list.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      drawer: const AppSideDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFF18C16),
          onRefresh: _resetAndFetch,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                if (_isLoadingMore) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFF18C16),
                      strokeWidth: 2.5,
                    ),
                  ),
                ],
                if (!_hasMore && _allProducts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Showing all ${_allProducts.length} sacred items',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF8A7060),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
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
        ListenableBuilder(
          listenable: CartService.instance,
          builder: (context, _) {
            final cartCount = CartService.instance.totalItemCount;
            return Stack(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    size: 26,
                    color: Color(0xFF3D2200),
                  ),
                  onPressed: () => context.push('/cart'),
                ),
                if (cartCount > 0)
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
                        '$cartCount',
                        style: GoogleFonts.lato(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search 1,200+ sacred items & samagri...',
          hintStyle: GoogleFonts.lato(fontSize: 14, color: Colors.grey),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xFFE8920A),
            size: 22,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Color(0xFF8A7060)),
                  onPressed: () {
                    _searchController.clear();
                    _resetAndFetch();
                  },
                )
              : null,
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
    final Set<String> uniqueCategories = {..._baseCategories};
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
                onTap: () {
                  if (_selectedCategory != cat) {
                    setState(() => _selectedCategory = cat);
                    _resetAndFetch();
                  }
                },
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
                      color: isActive ? const Color(0xFFF18C16) : const Color(0xFFE8D5A3),
                      width: 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF18C16).withValues(alpha: 0.3),
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
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFFF18C16)),
                SizedBox(height: 12),
                Text(
                  'Loading sacred store products...',
                  style: TextStyle(color: Color(0xFF7A6251)),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    if (_errorMessage != null) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                const Icon(
                  Icons.cloud_off,
                  color: Color(0xFFD97706),
                  size: 54,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to Load Products',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _resetAndFetch,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF18C16),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final products = _sortedProducts;
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
                const SizedBox(height: 6),
                Text(
                  'Try searching for another item or resetting the filter.',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: const Color(0xFF8A7060),
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _selectedCategory = 'All');
                    _resetAndFetch();
                  },
                  child: Text(
                    'Reset Search & Filters',
                    style: GoogleFonts.lato(
                      color: const Color(0xFFF18C16),
                      fontWeight: FontWeight.bold,
                    ),
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
                CartService.instance.addItem(
                  productId: p['id'].toString(),
                  name: p['name'].toString(),
                  price: (p['price'] as num).toDouble(),
                  imageUrl: p['imageUrl'].toString(),
                  unit: p['unit']?.toString(),
                  quantity: 1,
                );
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                    action: SnackBarAction(
                      label: 'VIEW CART',
                      textColor: Colors.white,
                      onPressed: () => context.push('/cart'),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2E6D0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: Image.network(
                    _getProductImageUrl(product),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFFFAF0DC),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Color(0xFFD4A373),
                        size: 32,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
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
