import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/pooja_detail_modal.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_side_drawer.dart';
import '../services/api_service.dart';

class BookScreen extends StatefulWidget {
  final String initialCategory;
  final String mode; // 'offline' or 'online'
  const BookScreen({
    super.key,
    this.initialCategory = 'ghar_jeevan',
    this.mode = 'offline',
  });

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late String selectedCategory;
  late String currentMode;
  bool _isLoading = true;
  String? _errorMessage;
  List<PoojaDetail> _allPoojas = [];
  Map<String, List<PoojaDetail>> _categoryRituals = {
    'ghar_jeevan': [],
    'sanskar': [],
    'dosh_nivaran': [],
    'festival': [],
    'business': [],
    'daily': [],
  };
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    currentMode = widget.mode;
    _fetchPoojas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPoojas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final rawList = await ApiService.getPoojas(page: 1, limit: 50);
      final List<PoojaDetail> poojas =
          rawList.map((item) => PoojaDetail.fromJson(item)).toList();

      final Map<String, List<PoojaDetail>> categorized = {
        'ghar_jeevan': [],
        'sanskar': [],
        'dosh_nivaran': [],
        'festival': [],
        'business': [],
        'daily': [],
      };

      for (final pooja in poojas) {
        final cat = pooja.category.toLowerCase();
        if (cat.contains('ghar') || cat.contains('jeevan')) {
          categorized['ghar_jeevan']!.add(pooja);
        } else if (cat.contains('sanskar')) {
          categorized['sanskar']!.add(pooja);
        } else if (cat.contains('dosh') || cat.contains('nivaran')) {
          categorized['dosh_nivaran']!.add(pooja);
        } else if (cat.contains('festival')) {
          categorized['festival']!.add(pooja);
        } else if (cat.contains('business')) {
          categorized['business']!.add(pooja);
        } else if (cat.contains('daily') || cat.contains('regular')) {
          categorized['daily']!.add(pooja);
        } else {
          categorized['ghar_jeevan']!.add(pooja);
        }
      }

      if (mounted) {
        setState(() {
          _allPoojas = poojas;
          _categoryRituals = categorized;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  List<Widget> _buildRitualCards() {
    if (_isLoading) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Column(
              children: [
                CircularProgressIndicator(color: Color(0xFFE8920A)),
                SizedBox(height: 12),
                Text(
                  'Loading sacred rituals from database...',
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 40, color: Color(0xFFD97706)),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lato(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _fetchPoojas,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF18C16),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    List<PoojaDetail> list;
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = _allPoojas.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q);
      }).toList();
    } else {
      list = _categoryRituals[selectedCategory] ?? [];
    }

    if (list.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              _searchQuery.isNotEmpty
                  ? 'No rituals found matching "$_searchQuery"'
                  : 'No rituals available in this category',
              style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF8A7060)),
            ),
          ),
        ),
      ];
    }

    return list.map((ritual) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildRitualCard(ritual),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      drawer: const AppSideDrawer(),
      body: SafeArea(
        child: Column(
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
                    const SizedBox(height: 16),
                    _buildSelectRitualTitle(),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildCategoryCards(),
                    const SizedBox(height: 14),
                    _buildOrnamentalDivider(),
                    const SizedBox(height: 12),
                    _buildTrendingRitualsHeader(),
                    const SizedBox(height: 10),
                    ..._buildRitualCards(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentPath: '/book'),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Builder(
          builder: (ctx) => GestureDetector(
            onTap: () => Scaffold.of(ctx).openDrawer(),
            child: const Icon(Icons.menu, size: 26, color: Color(0xFF5A4A3A)),
          ),
        ),
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/sarvmangal_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.self_improvement,
                        color: Color(0xFFE65100),
                        size: 18,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'SARV MANGAL',
                    style: GoogleFonts.lato(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: const Color(0xFF3D2200),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/notifications'),
          child: const Icon(
            Icons.notifications_outlined,
            size: 26,
            color: Color(0xFFE65100),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectRitualTitle() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Text(
              'Select Ritual',
              style: GoogleFonts.lato(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'VERIFIED PANDITS',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        Text(
          '100% Vedic Shastra',
          style: GoogleFonts.lato(
            fontSize: 11,
            color: const Color(0xFF7A6251),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          hintText: 'Search rituals, pandits, or locations...',
          hintStyle: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFE8920A), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFFAF0DC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE8920A), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCards() {
    final categories = [
      {'id': 'ghar_jeevan', 'label': 'Ghar & Jeevan', 'icon': Icons.home_outlined},
      {'id': 'sanskar', 'label': 'Sanskar Rituals', 'icon': Icons.favorite_outline},
      {'id': 'dosh_nivaran', 'label': 'Dosh Nivaran', 'icon': Icons.shield_outlined},
      {'id': 'festival', 'label': 'Festival Special', 'icon': Icons.auto_awesome},
      {'id': 'business', 'label': 'Business & Wealth', 'icon': Icons.storefront},
      {'id': 'daily', 'label': 'Daily & Regular', 'icon': Icons.temple_hindu},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final String id = cat['id'] as String;
          final String label = cat['label'] as String;
          final IconData icon = cat['icon'] as IconData;
          return _buildCategoryCard(icon: icon, label: label, id: id);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required String id,
  }) {
    final bool isActive = selectedCategory == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF18C16) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFFF18C16) : const Color(0xFFE8D5A3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.12 : 0.03),
              blurRadius: isActive ? 6 : 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF3D2200),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrnamentalDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFE8D5A3)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.auto_awesome, color: Color(0xFFE8920A), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8D5A3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingRitualsHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Text(
          'Available Rituals',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        Text(
          'View All',
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE8920A),
          ),
        ),
      ],
    );
  }

  Widget _buildRitualCard(PoojaDetail detail) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  detail.imageUrl,
                  width: 105,
                  height: 105,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 105,
                    height: 105,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: const Icon(
                      Icons.temple_hindu,
                      color: Color(0xFFE8920A),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            detail.title,
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3D2200),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (detail.isPopular) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE082),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'POPULAR',
                              style: GoogleFonts.lato(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3D2200),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${detail.duration} • ₹${detail.standardPrice.toInt()}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.description,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF8A7060),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Color(0xFFE8920A),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          detail.availability,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8A7060),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                showPoojaDetailBottomSheet(context, detail, mode: currentMode);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'View Details & Book',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
