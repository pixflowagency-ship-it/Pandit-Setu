import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/pooja_detail_modal.dart';
import '../user_data.dart';
import '../services/api_service.dart';

class ArcClipShape extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 20,
      0,
      size.height - 40,
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
  int _currentIndex = 0;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoadingBookings = true;
  Timer? _countdownTimer;
  int _secondsRemaining = 21 * 3600 + 14 * 60 + 5;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _startTimer();
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
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
      id: 'satyanarayan',
      title: 'Satyanarayan Pooja',
      category: 'Trending Ritual',
      imageUrl:
          'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
      isPopular: true,
      duration: '2.5 Hours',
      durationBreakdown:
          '30 mins setup • 2.0 hours main ritual & katha recitation',
      description:
          'Shri Satyanarayan Pooja is performed to seek divine blessings of Lord Vishnu for prosperity, health, and family harmony. Conducted by certified Vedic pandits.',
      spiritualSignificance:
          'Reciting the Satyanarayan Katha invokes truth (Satya) and divine consciousness, removing negative energy and showering infinite prosperity.',
      inclusions: [
        '2 Certified Acharyas (Vedic Scholars)',
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
      samagriPrice: 1100.0,
      originalPrice: 4000.0,
      availability: 'Available Tomorrow',
    ),
    PoojaDetail(
      id: 'griha_pravesh',
      title: 'Griha Pravesha Pooja',
      category: 'Trending Ritual',
      imageUrl:
          'https://images.unsplash.com/photo-1621252179027-94459d278660?w=500',
      isPopular: true,
      duration: '3.0 Hours',
      durationBreakdown: '30 mins setup • 2.5 hours Vastu Shanti & Havan',
      description:
          'Auspicious ritual for entering a new home. Purifies the space of negative energies, establishes positive vibrations, and invokes Mahalakshmi & Ganesha.',
      spiritualSignificance:
          'Ensures that the new residence is filled with peace, wealth, health, and protection from all subtle negative forces.',
      inclusions: [
        '2 Vedic Scholars',
        'Complete Vastu Shanti & Havan Samagri',
        'Milk Boiling Rites (Doodh Ufalna) Guidance',
        'Toran & Threshold (Dwar Pujan) Kit',
      ],
      chantingDetails: [
        'Vastu Purusha Mantras',
        'Ganapati Atharvashirsha',
        'Navagraha Mantra Jaap',
      ],
      standardPrice: 3100.0,
      samagriPrice: 1400.0,
      originalPrice: 5500.0,
      availability: 'Available Tomorrow',
    ),
    PoojaDetail(
      id: 'maha_mrityunjaya',
      title: 'Maha Mrityunjaya Havan',
      category: 'Sacred Fire Ritual',
      imageUrl:
          'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
      isPopular: true,
      duration: '3.5 Hours',
      durationBreakdown: '30 mins setup • 3.0 hours 108 Ahuti Havan',
      description:
          'Potent Vedic healing fire ritual dedicated to Lord Shiva for longevity, overcoming severe illness, and total spiritual liberation.',
      spiritualSignificance:
          'Conquers fear of illness or untoward events by connecting consciousness with the immortal life force of Bhagwan Tryambaka.',
      inclusions: [
        '3 Senior Vedic Acharyas',
        'Special Amrita & Herbal Havan Samagri',
        'Shiva Linga Abhishekam Kit',
      ],
      chantingDetails: [
        'Maha Mrityunjaya Mantra (108 Ahuti)',
        'Rudra Prashna Recitation',
      ],
      standardPrice: 3500.0,
      samagriPrice: 1500.0,
      originalPrice: 6500.0,
      availability: 'Available Today',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
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
                    _buildHeroBanner(),
                    if (!_isLoadingBookings && _bookings.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildUpcomingBookingBanner(_bookings.first),
                    ],
                    const SizedBox(height: 24),
                    _buildServiceGrid(),
                    const SizedBox(height: 24),
                    _buildPanchangSection(),
                    const SizedBox(height: 24),
                    _buildRarestItemsSection(),
                    const SizedBox(height: 24),
                    _buildKundliQuickWidget(),
                    const SizedBox(height: 24),
                    _buildTrendingRitualsSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.menu, size: 24, color: Color(0xFF5A4A3A)),

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
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
                'Pandit Setu',
                style: GoogleFonts.lato(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D1A00),
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => context.push('/notifications'),
            child: const Icon(
              Icons.notifications_outlined,
              size: 28,
              color: Color(0xFFE8920A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(35),
        topRight: Radius.circular(35),
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(0),
      ),
      child: ClipPath(
        clipper: ArcClipShape(),
        child: Container(
          width: double.infinity,
          height: 280,
          color: const Color(0xFF2E1A11),
          child: Stack(
            fit: StackFit.expand,
            children: [

              Image.network(
                'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/29/7d/4e/42/birla-temple-from-outside.jpg?w=900&h=500&s=1',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6B3A00),
                        Color(0xFFB8860B),
                        Color(0xFFDAA520),
                        Color(0xFF8B6914),
                      ],
                    ),
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFF6B3A00),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE8920A),
                      ),
                    ),
                  );
                },
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.80),
                      Colors.black.withValues(alpha: 0.20),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              Positioned(
                bottom: 40,
                left: 24,
                right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SACRED EXPERIENCE',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFCC4D),
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecting Tradition\nwith Trusted Pandits',
                      style: GoogleFonts.lato(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    GestureDetector(
                      onTap: () {
                        showPoojaDetailBottomSheet(
                          context,
                          _trendingRituals.firstWhere(
                            (r) => r.id == 'maha_mrityunjaya',
                            orElse: () => _trendingRituals[0],
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: const Color(0xFFFFD480),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Book Havan',
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanchangSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              "Today's Panchang",
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,

            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFEF9F3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFE8920A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shukla Paksha',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D1A00),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Chaturthi • 10:30 AM',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF8A7060),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFE8920A),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    'View Details >',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFE8920A),
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
  Widget _buildRarestItemsSection() {
    final rareItems = [
      {
        'name': 'Nepal Ek Mukhi Rudraksha',
        'price': 5001.0,
        'originalPrice': 8000.0,
        'description': 'Sourced from Nepal, certified authentic. Invokes immense focus and blessings.',
        'badge': 'RAREST',
        'image': 'https://images.unsplash.com/photo-1590073844006-33379778ae09?w=300',
      },
      {
        'name': 'Parad Shivling (Mercury)',
        'price': 3500.0,
        'originalPrice': 5500.0,
        'description': 'Pure mercury Shivling. Ideal for removing Vastu doshas.',
        'badge': 'LIMITED',
        'image': 'https://images.unsplash.com/photo-1609130767012-004463453a4c?w=300',
      },
      {
        'name': 'Siddh Sphatik Mala',
        'price': 1250.0,
        'originalPrice': 2200.0,
        'description': '108+1 beads pure crystal mala for Japa and meditation.',
        'badge': 'SACRED',
        'image': 'https://images.unsplash.com/photo-1596567189078-43bb229ccde9?w=300',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rarest Spiritual Items',
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Certified authentic & highly auspicious artifacts',
                    style: GoogleFonts.lato(
                      fontSize: 11.5,
                      color: const Color(0xFF8A7060),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => context.go('/shop'),
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
        const SizedBox(height: 10),
        SizedBox(
          height: 195,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: rareItems.length,
            itemBuilder: (context, index) {
              final item = rareItems[index];
              return Container(
                width: 250,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE8D5A3).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        item['image'] as String,
                        width: 90,
                        height: 170,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 90,
                          color: const Color(0xFFFFF3E0),
                          child: const Icon(Icons.spa, color: Color(0xFFD97706)),
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
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['badge'] as String,
                                  style: GoogleFonts.lato(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['name'] as String,
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1F2937),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['description'] as String,
                                style: GoogleFonts.lato(
                                  fontSize: 10,
                                  color: const Color(0xFF6B5B52),
                                ),
                                maxLines: 3,
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
                                    '₹${(item['originalPrice'] as double).toInt()}',
                                    style: GoogleFonts.lato(
                                      fontSize: 10,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    '₹${(item['price'] as double).toInt()}',
                                    style: GoogleFonts.lato(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  context.go('/shop');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD97706),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(40, 28),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Get',
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
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
                'Trending Rituals',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D1A00),
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/book'),
                child: Text(
                  'View All >',
                  style: GoogleFonts.lato(
                    fontSize: 14,
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

  Widget _buildUpcomingBookingBanner(Map<String, dynamic> booking) {
    final createdAtStr = booking['createdAt'];
    bool isAllocating = false;
    int remainingSecs = 0;
    if (booking['allocationMode'] == 'auto' && createdAtStr != null) {
      final createdAt = DateTime.parse(createdAtStr);
      final diff = DateTime.now().difference(createdAt);
      if (diff.inSeconds < 180) {
        isAllocating = true;
        remainingSecs = 180 - diff.inSeconds;
      }
    }

    return GestureDetector(
      onTap: () => context.push('/tracking'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD97706), Color(0xFFB45309)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.live_tv, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'UPCOMING POOJA LIVE STATUS',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Track Live >',
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking['poojaTitle'] ?? 'Vedic Pooja',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),

            isAllocating
                ? Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Finding Best Vedic Acharya...',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Automatic allocation completes in ${remainingSecs ~/ 60}m ${remainingSecs % 60}s',
                                style: GoogleFonts.lato(
                                  fontSize: 10.5,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 36,
                              height: 36,
                              color: Colors.white24,
                              child: const Icon(Icons.person, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['panditName'] ?? 'Pt. Rameshwar Sharma',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Rigveda Acharya • Vastu Specialist',
                                style: GoogleFonts.lato(
                                  fontSize: 10.5,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white70, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _getCountdownString(),
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  booking['timeSlot'] ?? '09:30 AM',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGrid() {
    final gridItems = [
      {
        'icon': Icons.menu_book,
        'label': 'Book Pooja',
        'color': const Color(0xFFD97706),
        'onTap': () => context.go('/book'),
      },
      {
        'icon': Icons.bolt,
        'label': '45 mins delivery',
        'color': const Color(0xFFE28A00),
        'onTap': () => context.go('/shop'),
      },
      {
        'icon': Icons.brightness_7,
        'label': 'Kundli',
        'color': const Color(0xFFC25E00),
        'onTap': () => context.push('/kundli'),
      },
      {
        'icon': Icons.videocam,
        'label': 'Online Pooja',
        'color': const Color(0xFFD97706),
        'onTap': () => context.go('/book?category=online'),
      },
      {
        'icon': Icons.temple_hindu,
        'label': 'Nearest Temple',
        'color': const Color(0xFFE28A00),
        'onTap': () => _showNearestTemplesBottomSheet(context),
      },
      {
        'icon': Icons.spa,
        'label': 'Pooja mala',
        'color': const Color(0xFFC25E00),
        'onTap': () => context.go('/shop?search=mala'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 12),
          child: Text(
            'Sacred Services',
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A1A1A),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.05,
            children: gridItems.map((item) {
              return GestureDetector(
                onTap: item['onTap'] as VoidCallback,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE8D5A3).withValues(alpha: 0.4),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: item['color'] as Color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _showNearestTemplesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFAF6EE),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final temples = [
          {
            'name': 'Shree Siddhivinayak Temple',
            'distance': '1.2 km away',
            'deity': 'Lord Ganesha',
            'timings': '6:00 AM - 10:00 PM',
            'address': 'Prabhadevi, Mumbai, Maharashtra',
            'imageUrl': 'https://images.unsplash.com/photo-1608976328267-e673d3ec06ce?w=200',
          },
          {
            'name': 'Mahalakshmi Temple',
            'distance': '3.4 km away',
            'deity': 'Goddess Mahalakshmi',
            'timings': '6:00 AM - 9:30 PM',
            'address': 'Bhulabhai Desai Road, Mumbai',
            'imageUrl': 'https://images.unsplash.com/photo-1621252179027-94459d278660?w=200',
          },
          {
            'name': 'Mumbadevi Temple',
            'distance': '4.1 km away',
            'deity': 'Goddess Mumbadevi',
            'timings': '6:00 AM - 9:00 PM',
            'address': 'Bhuleshwar, Mumbai',
            'imageUrl': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200',
          },
        ];

        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearest Vedic Temples',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const Icon(Icons.temple_hindu, color: Color(0xFFD97706)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Sacred shrines near your registered address.',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  color: const Color(0xFF6B5B52),
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: temples.length,
                  itemBuilder: (context, idx) {
                    final t = temples[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE8D5A3).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              t['imageUrl']!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(
                                width: 60,
                                height: 60,
                                color: const Color(0xFFFFF3E0),
                                child: const Icon(Icons.temple_hindu, color: Color(0xFFD97706)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t['name']!,
                                  style: GoogleFonts.lato(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${t['deity']} • ${t['distance']}',
                                  style: GoogleFonts.lato(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFD97706),
                                  ),
                                ),
                                Text(
                                  t['timings']!,
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.navigation, color: Color(0xFFD97706)),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Launching directions to ${t['name']}...', style: GoogleFonts.lato()),
                                  backgroundColor: const Color(0xFFD97706),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKundliQuickWidget() {
    final gotra = UserData.gotra.isNotEmpty ? UserData.gotra : 'Kashyap';
    final zodiac = UserData.zodiac.isNotEmpty ? UserData.zodiac : 'Simha (Leo)';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D5A3).withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Astrological Quick-View',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2D1A00),
                    ),
                  ),
                  Text(
                    'Gotra: $gotra • Zodiac: $zodiac',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      color: const Color(0xFF8A7060),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/kundli'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD97706)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 40),
                  ),
                  child: Text(
                    'Kundli Chart',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.go('/profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(0, 40),
                    elevation: 0,
                  ),
                  child: Text(
                    'Open Profile',
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
    );
  }

  Widget _buildFloatingNavBar() {

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
      color: const Color(0xFFFFF8EE),
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
            final isActive = _currentIndex == i;
            return GestureDetector(
              onTap: () {
                setState(() => _currentIndex = i);
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
                    context.go('/shop');
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
