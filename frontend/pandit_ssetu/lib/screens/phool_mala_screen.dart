import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/language_service.dart';

class PhoolMalaScreen extends StatefulWidget {
  const PhoolMalaScreen({super.key});

  @override
  State<PhoolMalaScreen> createState() => _PhoolMalaScreenState();
}

class _PhoolMalaScreenState extends State<PhoolMalaScreen> {
  int _selectedTab = 0; // 0 = Monthly Subscription, 1 = Daily Orders
  int _cartCount = 0;
  int _bannerIndex = 0;
  Timer? _bannerTimer;
  final PageController _bannerController = PageController();

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLangChange);
    _startBannerTimer();
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted && _bannerController.hasClients) {
        final next = (_bannerIndex + 1) % _adBanners.length;
        _bannerController.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    languageService.removeListener(_onLangChange);
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> _adBanners = [
    {
      'title': 'Festive Special Offers & Deals 🌸',
      'subtitle': '20% OFF on Flower Garlands for Ekadashi, Purnima & Navratri Days!',
      'tag': 'FESTIVE OFFER',
      'image': 'https://images.unsplash.com/photo-1567684014761-b65e2e59b9eb?w=600&q=80',
    },
    {
      'title': 'Spiritual Wisdom of Sacred Flowers 🌺',
      'subtitle': 'Lotus for Ma Lakshmi, Bilva for Bhagwan Shiva, Mogra for Pure Mind & Peace.',
      'tag': 'SACRED PUJA KNOWLEDGE',
      'image': 'https://images.unsplash.com/photo-1508615070457-7baeba4003ab?w=600&q=80',
    },
    {
      'title': '100% Farm-Fresh Daily Delivery 🌼',
      'subtitle': 'Handpicked at 4:00 AM from organic gardens & delivered pure to your altar by 6:30 AM.',
      'tag': 'ORGANIC & PURE',
      'image': 'https://images.unsplash.com/photo-1596567189078-43bb229ccde9?w=600&q=80',
    },
  ];

  final List<Map<String, dynamic>> _subscriptionPlans = [
    {
      'title': 'Festive Offer Subscription',
      'frequency': 'Special & Auspicious Days (Ekadashi, Purnima & Festivals)',
      'price': 399.0,
      'period': 'per month',
      'items': [
        'Exotic Mogra & Thick Marigold Garlands on Special Days',
        'Pink Kamal (Lotus) for Purnima & Lakshmi Pujas',
        'Fresh Bilva & Shami Leaves on Ekadashi & Shivratri',
        'Entrance Door Toran Garland on Auspicious Days',
        'Free Sacred Kumkum & Akshat Pack Included'
      ],
      'popular': true,
      'badge': 'SPECIAL FESTIVE OFFER 🌸',
    },
    {
      'title': 'Daily Morning Puja Essentials',
      'frequency': 'Everyday at 06:00 AM',
      'price': 499.0,
      'period': 'per month',
      'items': [
        'Fresh Marigold (Genda) Garland',
        '101 Fresh Rose Petals',
        '11 Sacred Belpatra Leaves',
        'Durva Grass for Lord Ganesha'
      ],
      'popular': false,
    },
    {
      'title': 'Grand Mandir Devotional Plan',
      'frequency': 'Everyday at 06:00 AM',
      'price': 999.0,
      'period': 'per month',
      'items': [
        '2 Premium Mogra & Rose Garlands',
        'Lotus Flower for Goddess Lakshmi (on Fridays)',
        'Fresh Bilva & Tulsi Dal Bundle',
        'Sandalwood paste & Sacred Akshat'
      ],
      'popular': false,
    },
    {
      'title': 'Weekend Festive Subscription',
      'frequency': 'Every Saturday & Sunday',
      'price': 299.0,
      'period': 'per month',
      'items': [
        '2 Fresh Thick Flower Garlands',
        'Mixed Exotic Flowers for Abhishekam',
        'Door Toran Flowers for Entrance'
      ],
      'popular': false,
    },
  ];

  final List<Map<String, dynamic>> _dailyItems = [
    {
      'name': 'Pure Marigold (Genda) Mala',
      'size': '2.5 Feet',
      'price': 60.0,
      'image': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400',
      'tag': 'MOST POPULAR',
    },
    {
      'name': 'Exotic Jasmine & Mogra Mala',
      'size': '2.0 Feet',
      'price': 120.0,
      'image': 'https://images.unsplash.com/photo-1596567189078-43bb229ccde9?w=400',
      'tag': 'FRAGRANT',
    },
    {
      'name': 'Pink Lotus Flower (Kamal)',
      'size': '2 Stems',
      'price': 80.0,
      'image': 'https://images.unsplash.com/photo-1508615070457-7baeba4003ab?w=400',
      'tag': 'LAKSHMI PUJA',
    },
    {
      'name': 'Fresh Bilva Leaves (Belpatra)',
      'size': '21 Leaves',
      'price': 40.0,
      'image': 'https://images.unsplash.com/photo-1609130767012-004463453a4c?w=400',
      'tag': 'SHIVA PUJA',
    },
    {
      'name': 'Rose Petals Pack (Gulab)',
      'size': '250 grams',
      'price': 90.0,
      'image': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=400',
      'tag': 'FRESH',
    },
    {
      'name': 'Sacred Tulsi Dal Bundle',
      'size': '5 Bundles',
      'price': 35.0,
      'image': 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=400',
      'tag': 'VISHNU PUJA',
    },
  ];

  void _showSubscriptionSuccessModal(Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFF8EE),
        title: Row(
          children: [
            const Icon(Icons.local_florist, color: Color(0xFFF18C16)),
            const SizedBox(width: 8),
            Text(
              'Subscription Active!',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'You have subscribed to "${plan['title']}". Fresh flowers will be delivered to your doorstep every morning at 6:00 AM.',
          style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF5A4A3A)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Done', style: GoogleFonts.lato(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 16),
            _buildHeaderBanner(),
            const SizedBox(height: 16),
            _buildTabSwitch(),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedTab == 0
                  ? _buildSubscriptionList()
                  : _buildDailyItemList(),
            ),
            _buildNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF3D2200), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Phool Mala Store',
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
                icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF3D2200), size: 26),
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
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 155,
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _adBanners.length,
              onPageChanged: (idx) {
                setState(() {
                  _bannerIndex = idx;
                });
              },
              itemBuilder: (context, index) {
                final banner = _adBanners[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            banner['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: const Color(0xFFE28A00),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.black.withValues(alpha: 0.8),
                                  Colors.black.withValues(alpha: 0.35),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF18C16),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  banner['tag']!,
                                  style: GoogleFonts.lato(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                banner['title']!,
                                style: GoogleFonts.lato(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                banner['subtitle']!,
                                style: GoogleFonts.lato(
                                  fontSize: 10.5,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Slideshow indicator dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _adBanners.length,
              (idx) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _bannerIndex == idx ? 16 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _bannerIndex == idx
                      ? const Color(0xFFE8920A)
                      : const Color(0xFFE8D5A3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF0DC),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? const Color(0xFFF18C16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Monthly Subscription',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 0 ? Colors.white : const Color(0xFF8A7060),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = 1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? const Color(0xFFF18C16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Daily Single Orders',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _selectedTab == 1 ? Colors.white : const Color(0xFF8A7060),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _subscriptionPlans.length,
      itemBuilder: (context, index) {
        final plan = _subscriptionPlans[index];
        final bool isPopular = plan['popular'] == true;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPopular ? const Color(0xFFF18C16) : const Color(0xFFE8D5A3),
              width: isPopular ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan['title'],
                      style: GoogleFonts.lato(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                  ),
                  if (isPopular)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE082),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'POPULAR',
                        style: GoogleFonts.lato(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 14, color: Color(0xFFE8920A)),
                  const SizedBox(width: 4),
                  Text(
                    plan['frequency'],
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFE8920A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFFFAF0DC), height: 1),
              const SizedBox(height: 12),

              ...(plan['items'] as List<String>).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFFF18C16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: const Color(0xFF5A4A3A),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 14),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${(plan['price'] as double).toInt()}',
                        style: GoogleFonts.lato(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF18C16),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/${plan['period']}',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF8A7060),
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () => _showSubscriptionSuccessModal(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF18C16),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      elevation: 0,
                    ),
                    child: Text(
                      'Subscribe Now',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyItemList() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _dailyItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemBuilder: (context, index) {
        final item = _dailyItems[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: Image.network(
                  item['image'],
                  height: 105,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 105,
                    color: const Color(0xFFFFF3E0),
                    child: const Icon(Icons.local_florist, color: Color(0xFFF18C16), size: 36),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item['size'],
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: const Color(0xFF8A7060),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₹${(item['price'] as double).toInt()}',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFF18C16),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() => _cartCount++);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item['name']} added to cart!'),
                                backgroundColor: const Color(0xFFF18C16),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF18C16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 16),
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
      },
    );
  }

  Widget _buildNavBar(BuildContext context) {
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
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', () => context.go('/home')),
            _buildNavItem(Icons.menu_book_outlined, 'Book', () => context.go('/book')),
            _buildNavItem(Icons.calendar_month_outlined, 'Panchang', () => context.go('/panchang')),
            _buildNavItem(Icons.shopping_bag_outlined, 'Shop', () => context.go('/shop')),
            _buildNavItem(Icons.person_outline, 'Profile', () => context.go('/profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
