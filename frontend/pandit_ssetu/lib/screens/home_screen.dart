import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/pooja_detail_modal.dart';
import '../widgets/pandit_chat_modal.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_side_drawer.dart';
import '../widgets/neumorphic_button.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class ArcClipShape extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 35);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 15,
      0,
      size.height - 35,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoadingBookings = true;
  Timer? _countdownTimer;
  Timer? _carouselTimer;
  Timer? _rarestTimer;
  int _secondsRemaining = 21 * 3600 + 14 * 60 + 5;
  int _currentSlideIndex = 0;
  int _currentRarestIndex = 0;
  final PageController _pageController = PageController();
  final PageController _rarestPageController = PageController(viewportFraction: 0.86);

  final List<Map<String, String>> _heroSlides = [
    {
      'title': 'Grand Navratri & Durga Puja 2026',
      'subtitle': 'Book Authentic Vedic Chandi Path & Havan by Certified Acharyas',
      'tag': 'FESTIVAL SPECIAL',
      'image': 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900',
      'poojaId': 'navratri_pooja',
    },
    {
      'title': 'Shri Satyanarayan Vrat Katha',
      'subtitle': 'Invite Infinite Health, Peace & Family Harmony',
      'tag': 'MOST POPULAR',
      'image': 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=900',
      'poojaId': 'satyanarayan_katha',
    },
    {
      'title': 'Griha Pravesh & Vastu Shanti',
      'subtitle': 'Purify Your New Residence with Vedic Mantras & Havan',
      'tag': 'HOUSEWARMING',
      'image': 'https://images.unsplash.com/photo-1621252179027-94459d278660?w=900',
      'poojaId': 'griha_pravesh_pooja',
    },
    {
      'title': 'Mahamrityunjaya Healing Havan',
      'subtitle': 'Conquer Illness & Invoke Divine Life Energy of Bhagwan Shiva',
      'tag': 'SACRED FIRE RITUAL',
      'image': 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=900',
      'poojaId': 'mahamrityunjaya_jaap',
    },
  ];

  void _onLanguageChange() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    languageService.addListener(_onLanguageChange);
    _loadBookings();
    _startTimer();
    _startCarouselTimer();
    _startRarestTimer();
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _countdownTimer?.cancel();
          }
        });
      }
    });
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients) {
        final nextSlide = (_currentSlideIndex + 1) % _heroSlides.length;
        _pageController.animateToPage(
          nextSlide,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _startRarestTimer() {
    _rarestTimer = Timer.periodic(const Duration(milliseconds: 3500), (timer) {
      if (mounted && _rarestPageController.hasClients) {
        final nextIndex = (_currentRarestIndex + 1) % 3;
        _rarestPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    languageService.removeListener(_onLanguageChange);
    _countdownTimer?.cancel();
    _carouselTimer?.cancel();
    _rarestTimer?.cancel();
    _pageController.dispose();
    _rarestPageController.dispose();
    super.dispose();
  }

  String _getCountdownString() {
    final hours = _secondsRemaining ~/ 3600;
    final minutes = (_secondsRemaining % 3600) ~/ 60;
    final seconds = _secondsRemaining % 60;
    return 'Starts in ${hours}h ${minutes}m ${seconds}s';
  }

  Future<void> _loadBookings() async {
    try {
      final list = await ApiService.getUserBookings();
      if (mounted) {
        setState(() {
          _bookings = list;
          _isLoadingBookings = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingBookings = false);
      }
    }
  }

  static const List<PoojaDetail> _trendingRituals = [
    PoojaDetail(
      id: 'griha_pravesh_pooja',
      title: 'Griha Pravesh Pooja',
      category: 'Ghar & Jeevan',
      imageUrl:
          'https://images.unsplash.com/photo-1621252179027-94459d278660?w=500',
      isPopular: true,
      duration: '1-3 Hour',
      durationBreakdown: '30 mins setup • 2.5 hours Vastu Shanti & Havan by 2 Pandits',
      description:
          'Auspicious ritual for entering a new home. Purifies the space of negative energies, establishes positive vibrations, and invokes Mahalakshmi & Ganesha.',
      spiritualSignificance:
          'Ensures that the new residence is filled with peace, wealth, health, and protection from all subtle negative forces.',
      inclusions: [
        '2 Certified Vedic Scholars',
        'Complete Sacred Vastu Shanti & Havan Samagri Kit',
        'Milk Boiling Rites (Doodh Ufalna) Guidance',
        'Toran & Threshold (Dwar Pujan) Kit',
      ],
      chantingDetails: [
        'Vastu Purusha Mantras',
        'Ganapati Atharvashirsha',
        'Navagraha Mantra Jaap',
      ],
      standardPrice: 5100.0,
      samagriPrice: 1275.0,
      originalPrice: 7650.0,
      availability: 'Available Tomorrow',
    ),
    PoojaDetail(
      id: 'satyanarayan_katha',
      title: 'Satyanarayan Katha',
      category: 'Ghar & Jeevan',
      imageUrl:
          'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
      isPopular: true,
      duration: '1-3 Hour',
      durationBreakdown:
          '30 mins setup • 2.0 hours main ritual & katha recitation by 1 Pandit',
      description:
          'Shri Satyanarayan Pooja is performed to seek divine blessings of Lord Vishnu for prosperity, health, and family harmony.',
      spiritualSignificance:
          'Reciting the Satyanarayan Katha invokes truth (Satya) and divine consciousness, removing negative energy and showering infinite prosperity.',
      inclusions: [
        '1 Certified Acharya (Vedic Scholar)',
        'Complete Sacred Havan & Samagri Kit (Pure Desi Ghee)',
        'Kalash Sthapana & Panchamrit setup',
        'Satyanarayan Vrat Katha Book & Prashad',
      ],
      chantingDetails: [
        'Vishnu Sahasranama Stotram',
        '108 Gayatri Mantra Recitation',
        'Satyanarayan Ashtothara Shatanamavali',
      ],
      standardPrice: 2100.0,
      samagriPrice: 525.0,
      originalPrice: 3150.0,
      availability: 'Available Daily',
    ),
    PoojaDetail(
      id: 'vastu_shanti_pooja',
      title: 'Vastu Shanti Pooja',
      category: 'Ghar & Jeevan',
      imageUrl:
          'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
      isPopular: true,
      duration: '1-7 Days',
      durationBreakdown: 'Full traditional Vastu rectifications & grand Havan by 5 to 7 Pandits',
      description:
          'Specialized ritual designed to rectify architectural and directional Vastu doshas in living or office premises.',
      spiritualSignificance:
          'Harmonizes the five elements (Pancha Bhoota) within the premises for maximum comfort, prosperity, and peace.',
      inclusions: [
        '5 to 7 Senior Vedic Acharyas',
        'Grand Vastu Shanti Havan & Herbs Kit',
        'Vastu Yantra Installation & Copper Pyramid Setup',
      ],
      chantingDetails: [
        'Dikpalaka Invocation & Vastu Purusha Suktam',
        'Panch Bhoota & Navagraha Mantras',
      ],
      standardPrice: 51000.0,
      samagriPrice: 12750.0,
      originalPrice: 76500.0,
      availability: 'Book 3 Days Prior',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      drawer: const AppSideDrawer(),
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroSlideshowBanner(),
                    const SizedBox(height: 14),
                    _buildSixBoxServiceGrid(),
                    const SizedBox(height: 8),
                    _buildLifeProblemsBanner(),
                    const SizedBox(height: 10),
                    _buildUpcomingBookingBanner(
                      _bookings.isNotEmpty ? _bookings.first : null,
                    ),
                    const SizedBox(height: 20),
                    _buildCategoryMenuSection(),
                    const SizedBox(height: 20),
                    _buildEnhancedPanchangSection(),
                    const SizedBox(height: 20),
                    _buildRarestItemsSection(),
                    const SizedBox(height: 20),
                    _buildTrendingRitualsSection(),
                    const SizedBox(height: 20),
                    _buildBlogSection(),
                    const SizedBox(height: 20),
                    _buildTrustBadgesSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentPath: '/home'),
    );
  }

  Widget _buildTopBar() {
    final isHindi = languageService.isHindi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const Icon(Icons.menu, size: 26, color: Color(0xFF5A4A3A)),
            ),
          ),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8920A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.self_improvement,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isHindi ? 'पंडित सेतु' : 'Pandit Setu',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D1A00),
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Language Switcher Pill Toggle
              GestureDetector(
                onTap: () {
                  languageService.toggleLanguage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isHindi ? const Color(0xFFFFF3E0) : const Color(0xFFF3E7D3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8920A),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.language, size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        isHindi ? 'हिंदी' : 'EN',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: const Icon(
                  Icons.notifications_outlined,
                  size: 26,
                  color: Color(0xFFE8920A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. SLIDESHOW CAROUSEL WITH CTA BUTTON
  Widget _buildHeroSlideshowBanner() {
    final isHindi = languageService.isHindi;
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(35),
        topRight: Radius.circular(35),
      ),
      child: ClipPath(
        clipper: ArcClipShape(),
        child: Container(
          width: double.infinity,
          height: 290,
          color: const Color(0xFF2E1A11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (idx) {
                  setState(() => _currentSlideIndex = idx);
                },
                itemCount: _heroSlides.length,
                itemBuilder: (context, index) {
                  final slide = _heroSlides[index];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        slide['image']!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF6B3A00), Color(0xFFB8860B)],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.85),
                              Colors.black.withValues(alpha: 0.30),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 45,
                        left: 24,
                        right: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF18C16),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                slide['tag']!,
                                style: GoogleFonts.lato(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              slide['title']!,
                              style: GoogleFonts.lato(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              slide['subtitle']!,
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 14),

                            // CTA BUTTON TO BOOK POOJA
                            NeumorphicButton(
                              text: isHindi ? 'पूजा बुक करें' : 'Book Pooja Now',
                              icon: Icons.auto_awesome,
                              height: 40,
                              onTap: () {
                                final poojaId = slide['poojaId'];
                                final match = _trendingRituals.firstWhere(
                                  (r) => r.id == poojaId,
                                  orElse: () => _trendingRituals[0],
                                );
                                showPoojaDetailBottomSheet(context, match);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // CAROUSEL INDICATOR DOTS
              Positioned(
                bottom: 25,
                left: 24,
                child: Row(
                  children: List.generate(_heroSlides.length, (idx) {
                    final isActive = _currentSlideIndex == idx;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      width: isActive ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0xFFF18C16) : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. SIX BOX GRID WITH REAL IMAGES & BILINGUAL SUPPORT
  Widget _buildSixBoxServiceGrid() {
    final isHindi = languageService.isHindi;
    final gridItems = [
      {
        'id': 'A',
        'image': 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=300&q=80',
        'icon': Icons.menu_book,
        'label': isHindi ? 'पूजा बुक करें' : 'Book Pooja',
        'sublabel': isHindi ? '26 शास्त्रोक्त अनुष्ठान' : '26 Shastra Rituals',
        'badge': '',
        'color': const Color(0xFFD97706),
        'onTap': () => context.go('/book'),
      },
      {
        'id': 'B',
        'image': 'https://images.unsplash.com/photo-1596704017254-9b121068fb31?w=300&q=80',
        'icon': Icons.flash_on,
        'label': isHindi ? 'त्वरित डिलीवरी' : 'Instant Delivery',
        'sublabel': isHindi ? 'सामग्री एवं किट' : 'Samagri & Kits',
        'badge': isHindi ? '⚡ 30 मिनट' : '⚡ 30 MINS',
        'color': const Color(0xFFE28A00),
        'onTap': () => context.go('/shop'),
      },
      {
        'id': 'C',
        'image': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=300&q=80',
        'icon': Icons.videocam,
        'label': isHindi ? 'ऑनलाइन पूजा' : 'Online Pooja',
        'sublabel': isHindi ? 'लाइव आचार्य द्वारा' : 'Live Virtual Pandits',
        'badge': isHindi ? 'लाइव' : 'LIVE',
        'color': const Color(0xFFC25E00),
        'onTap': () {
          final pooja = _trendingRituals.firstWhere(
            (r) => r.id == 'satyanarayan_katha',
            orElse: () => _trendingRituals[0],
          );
          showPoojaDetailBottomSheet(context, pooja);
        },
      },
      {
        'id': 'D',
        'image': 'https://images.unsplash.com/photo-1567684014761-b65e2e59b9eb?w=300&q=80',
        'icon': Icons.local_florist,
        'label': isHindi ? 'फूल माला' : 'Phool Mala',
        'sublabel': isHindi ? 'मासिक माला सेवा' : 'Garlands & Subs',
        'badge': isHindi ? 'दैनिक' : 'DAILY',
        'color': const Color(0xFFD97706),
        'onTap': () => context.push('/phool-mala'),
      },
      {
        'id': 'E',
        'image': 'https://images.unsplash.com/photo-1532012197267-da84d127e765?w=300&q=80',
        'icon': Icons.auto_graph,
        'label': isHindi ? 'कुंडली' : 'Kundli',
        'sublabel': isHindi ? 'कुंडली एवं ज्योतिष' : 'Kundli & Handmade',
        'badge': isHindi ? 'हस्तनिर्मित' : 'HANDMADE',
        'color': const Color(0xFFE28A00),
        'onTap': () => context.push('/kundli'),
      },
      {
        'id': 'F',
        'image': 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=300&q=80',
        'icon': Icons.temple_hindu,
        'label': isHindi ? 'निकटतम मंदिर' : 'Nearest Temple',
        'sublabel': isHindi ? 'दर्शन एवं समय' : 'Map & Darshan',
        'badge': isHindi ? 'मानचित्र' : 'MAPS',
        'color': const Color(0xFFC25E00),
        'onTap': () => context.push('/nearest-temple'),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'वैदिक सेवाएं एवं स्टोर' : 'VEDIC SERVICES & STORE',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFFE8920A),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: gridItems.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.90,
            ),
            itemBuilder: (context, index) {
              final item = gridItems[index];
              final String imageUrl = item['image'] as String;
              return GestureDetector(
                onTap: item['onTap'] as VoidCallback,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8D5A3).withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: (item['color'] as Color).withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: (item['color'] as Color).withValues(alpha: 0.12),
                                    child: Icon(
                                      item['icon'] as IconData,
                                      color: item['color'] as Color,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['label'] as String,
                              style: GoogleFonts.lato(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3D2200),
                                height: 1.15,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              softWrap: true,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['sublabel'] as String,
                              style: GoogleFonts.lato(
                                fontSize: 9.5,
                                color: const Color(0xFF8A7060),
                                height: 1.15,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              softWrap: true,
                            ),
                          ],
                        ),
                      ),
                      if ((item['badge'] as String).isNotEmpty)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF18C16),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['badge'] as String,
                              style: GoogleFonts.lato(
                                fontSize: 7.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Horizontal Banner: "Life Problems?" with Green "FREE" Tag & CTA "GET SOLUTION"
  Widget _buildLifeProblemsBanner() {
    final isHindi = languageService.isHindi;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFFF9F0),
              Color(0xFFFFF3E2),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF3DFBF),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8920A).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isHindi ? 'मुफ्त' : 'FREE',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          isHindi ? 'जीवन में परेशानियां?' : 'Life Problems?',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3D2200),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHindi
                        ? 'अनुभवी वैदिक आचार्यों से त्वरित समाधान पाएं'
                        : 'Chat with verified Vedic Pandits for instant remedies',
                    style: GoogleFonts.lato(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF7A604D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            NeumorphicButton(
              text: isHindi ? 'समाधान पाएं' : 'GET SOLUTION',
              icon: Icons.arrow_forward_rounded,
              height: 38,
              borderRadius: 14,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const PanditChatModal(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 3. ROUND PRODUCT CATEGORIES (FIXED SUBTEXT SIZING & FULL VISIBILITY)
  Widget _buildCategoryMenuSection() {
    final isHindi = languageService.isHindi;
    final categories = [
      {
        'title': isHindi ? 'पूजा किट' : 'Pooja Kits',
        'sub': isHindi ? 'संपूर्ण सामग्री' : 'Complete Kits',
        'image': 'https://images.unsplash.com/photo-1596704017254-9b121068fb31?w=200&q=80',
        'icon': Icons.inventory_2_outlined,
        'route': '/shop?category=hawan',
      },
      {
        'title': isHindi ? 'पूजा सामग्री' : 'Accessories',
        'sub': isHindi ? 'रुद्राक्ष माला' : 'Rudraksha Mala',
        'image': 'https://images.unsplash.com/photo-1596567189078-43bb229ccde9?w=200&q=80',
        'icon': Icons.spa_outlined,
        'route': '/shop?category=accessories',
      },
      {
        'title': isHindi ? 'आवश्यक वस्तुएं' : 'Essentials',
        'sub': isHindi ? 'घी एवं धूप' : 'Ghee & Dhoop',
        'image': 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=200&q=80',
        'icon': Icons.local_fire_department_outlined,
        'route': '/shop?category=essentials',
      },
      {
        'title': isHindi ? 'मूर्ति एवं यंत्र' : 'Idols & Yantras',
        'sub': isHindi ? 'पीतल मूर्तियां' : 'Brass Statues',
        'image': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=200&q=80',
        'icon': Icons.temple_hindu_outlined,
        'route': '/shop?category=special',
      },
      {
        'title': isHindi ? 'ताजा पुष्प' : 'Fresh Flowers',
        'sub': isHindi ? 'माला एवं पत्र' : 'Fresh Garlands',
        'image': 'https://images.unsplash.com/photo-1567684014761-b65e2e59b9eb?w=200&q=80',
        'icon': Icons.local_florist_outlined,
        'route': '/phool-mala',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'उत्पाद श्रेणियां' : 'PRODUCT CATEGORIES',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFFE8920A),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/shop'),
                child: Text(
                  isHindi ? 'सभी देखें >' : 'Explore All >',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: categories.map((cat) {
                final String imageUrl = cat['image'] as String;
                return GestureDetector(
                  onTap: () => context.go(cat['route'] as String),
                  child: Container(
                    width: 82,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        // Round Circular Avatar Card
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: const Color(0xFFE8920A).withValues(alpha: 0.35),
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFFFF3E0),
                                child: Icon(
                                  cat['icon'] as IconData,
                                  color: const Color(0xFFF18C16),
                                  size: 26,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat['title'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3D2200),
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          softWrap: true,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          cat['sub'] as String,
                          style: GoogleFonts.lato(
                            fontSize: 9,
                            color: const Color(0xFF8A7060),
                            height: 1.15,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 4. ENHANCED TODAY'S PANCHANG WITH RICH DETAILS & CALENDAR LINK
  Widget _buildEnhancedPanchangSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S VEDIC PANCHANG",
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFFE8920A),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/panchang'),
                child: Text(
                  'Full Calendar >',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.wb_sunny, color: Color(0xFFF18C16), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bhadrapada Krishna Ekadashi',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF3D2200),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Shukla Paksha • Ujjain, MP',
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: const Color(0xFF8A7060),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE082),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'AUSPICIOUS',
                        style: GoogleFonts.lato(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(color: Color(0xFFFAF0DC), height: 1),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildPanchangMiniMetric('Sunrise', '06:18 AM', Icons.wb_sunny_outlined),
                    _buildPanchangMiniMetric('Sunset', '06:26 PM', Icons.wb_twilight),
                    _buildPanchangMiniMetric('Nakshatra', 'Pushya', Icons.auto_awesome),
                    _buildPanchangMiniMetric('Abhijit', '11:54 AM', Icons.check_circle_outline),
                  ],
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/panchang'),
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: Text(
                      'View Detailed Panchang & Calendar',
                      style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF18C16),
                      side: const BorderSide(color: Color(0xFFF18C16)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanchangMiniMetric(String label, String val, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF18C16)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF8A7060)),
        ),
        Text(
          val,
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
      ],
    );
  }

  // 5. RAREST SACRED ARTIFACTS WITH AUTO SLIDE
  Widget _buildRarestItemsSection() {
    final rareItems = [
      {
        'name': 'Nepal Ek Mukhi Rudraksha',
        'price': 5001.0,
        'originalPrice': 8000.0,
        'description': 'Sourced from Nepal, certified authentic. Invokes immense focus and divine blessings.',
        'badge': 'RAREST',
        'image': 'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=400&q=80',
      },
      {
        'name': 'Parad Shivling (Mercury)',
        'price': 3500.0,
        'originalPrice': 5500.0,
        'description': 'Pure mercury Shivling. Ideal for removing Vastu doshas & bringing peace.',
        'badge': 'LIMITED',
        'image': 'https://images.unsplash.com/photo-1609130767012-004463453a4c?w=400&q=80',
      },
      {
        'name': 'Siddh Sphatik Mala',
        'price': 1250.0,
        'originalPrice': 2200.0,
        'description': '108+1 beads pure crystal mala for Japa, healing & calm meditation.',
        'badge': 'SACRED',
        'image': 'https://images.unsplash.com/photo-1596567189078-43bb229ccde9?w=400&q=80',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RAREST SACRED ARTIFACTS',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFFE8920A),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/shop'),
                child: Text(
                  'View Shop >',
                  style: GoogleFonts.lato(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: PageView.builder(
            controller: _rarestPageController,
            itemCount: rareItems.length,
            onPageChanged: (index) {
              setState(() {
                _currentRarestIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = rareItems[index];
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE8D5A3).withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        item['image'] as String,
                        width: 100,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 100,
                          color: const Color(0xFFFFF3E0),
                          child: const Icon(Icons.spa, color: Color(0xFFD97706), size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFFD199)),
                                ),
                                child: Text(
                                  item['badge'] as String,
                                  style: GoogleFonts.lato(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['name'] as String,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3D2200),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['description'] as String,
                                style: GoogleFonts.lato(
                                  fontSize: 10.5,
                                  color: const Color(0xFF8A7060),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '₹${(item['price'] as double).toInt()}',
                                    style: GoogleFonts.lato(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                  Text(
                                    '₹${(item['originalPrice'] as double).toInt()}',
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () => context.go('/shop'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE8920A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Buy Now',
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
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
            },
          ),
        ),
        const SizedBox(height: 8),
        // Indicator Dots for Rarest sacred artifacts auto slide
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            rareItems.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentRarestIndex == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentRarestIndex == index
                    ? const Color(0xFFE8920A)
                    : const Color(0xFFE8D5A3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingRitualsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRENDING RITUALS',
                style: GoogleFonts.lato(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: const Color(0xFFE8920A),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/book'),
                child: Text(
                  'View All >',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._trendingRituals.map((ritual) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildTrendingRitualCard(ritual),
              )),
        ],
      ),
    );
  }

  Widget _buildTrendingRitualCard(PoojaDetail detail) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  detail.imageUrl,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    color: const Color(0xFFFFF3E0),
                    child: const Icon(
                      Icons.temple_hindu,
                      color: Color(0xFFD97706),
                      size: 36,
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
                      children: [
                        Expanded(
                          child: Text(
                            detail.title,
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D1A00),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (detail.isPopular)
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
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${detail.duration} • ₹${detail.totalPrice.toInt()}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.description,
                      style: GoogleFonts.lato(
                        fontSize: 11.5,
                        color: const Color(0xFF8A7060),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showPoojaDetailBottomSheet(context, detail);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFAF6EE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: const Color(0xFFD97706).withValues(alpha: 0.4),
                      ),
                    ),
                    minimumSize: const Size(0, 38),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/book-flow', extra: detail);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 38),
                    elevation: 0,
                  ),
                  child: Text(
                    'Book Now',
                    style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  // 5. SPIRITUAL BLOG SECTION
  Widget _buildBlogSection() {
    final blogs = [
      {
        'title': 'Vedic Significance of Griha Pravesh & Vastu Shanti',
        'readTime': '5 min read',
        'category': 'Vastu Shastra',
        'image': 'https://images.unsplash.com/photo-1621252179027-94459d278660?w=400',
      },
      {
        'title': 'How to Perform Daily Nitya Pooja at Home Correctly',
        'readTime': '4 min read',
        'category': 'Daily Rituals',
        'image': 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=400',
      },
      {
        'title': 'Spiritual Benefits of Navgraha Shanti & Planetary Remedies',
        'readTime': '6 min read',
        'category': 'Astrology',
        'image': 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=400',
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPIRITUAL WISDOM & ARTICLES',
            style: GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: const Color(0xFFE8920A),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: blogs.map((blog) {
                return Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
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
                          blog['image']!,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  blog['category']!,
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF18C16),
                                  ),
                                ),
                                Text(
                                  blog['readTime']!,
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
                                    color: const Color(0xFF8A7060),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              blog['title']!,
                              style: GoogleFonts.lato(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3D2200),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 5. THREE TRUST LOGOS/BADGES
  Widget _buildTrustBadgesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D5A3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTrustBadgeItem(
            icon: Icons.workspace_premium,
            title: 'Trusted Vedic\nAcharyas',
            sub: 'Certified 10+ Yrs Exp',
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE8D5A3)),
          _buildTrustBadgeItem(
            icon: Icons.support_agent,
            title: '24*7 Customer\nSupport',
            sub: 'Dedicated Helpline',
          ),
          Container(width: 1, height: 40, color: const Color(0xFFE8D5A3)),
          _buildTrustBadgeItem(
            icon: Icons.verified_user_outlined,
            title: 'Transparent\nPricing',
            sub: 'Zero Hidden Costs',
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadgeItem({
    required IconData icon,
    required String title,
    required String sub,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF3E0),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFFF18C16), size: 22),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          sub,
          style: GoogleFonts.lato(
            fontSize: 9,
            color: const Color(0xFF8A7060),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUpcomingBookingBanner(Map<String, dynamic>? booking) {
    final b = booking ?? {
      'poojaTitle': 'Satyanarayan Katha with Havan',
      'panditName': 'Pt. Rameshwar Sharma',
      'timeSlot': 'Tomorrow • 09:30 AM',
    };
    return GestureDetector(
      onTap: () => context.push('/tracking'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD97706), Color(0xFFB45309)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.live_tv, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'BOOKED POOJA',
                          style: GoogleFonts.lato(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _getCountdownString(),
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    b['poojaTitle'] ?? 'Vedic Pooja',
                    style: GoogleFonts.lato(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${b['panditName'] ?? 'Pt. Rameshwar Sharma'} • ${b['timeSlot'] ?? '09:30 AM'}',
                    style: GoogleFonts.lato(
                      fontSize: 10.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Track',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFFB45309)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
