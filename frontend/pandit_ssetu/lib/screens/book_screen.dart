import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/pooja_detail_modal.dart';

class BookScreen extends StatefulWidget {
  final String initialCategory;
  const BookScreen({super.key, this.initialCategory = 'wedding'});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  // Selected category for the top cards
  late String selectedCategory;
  // Selected index for the bottom navigation bar (floating pill style)
  int _currentNavIndex = 1; // Book tab is index 1

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
  }

  // Demo data for each category mapped to typed PoojaDetail objects
  final Map<String, List<PoojaDetail>> _categoryRituals = {
    'wedding': [
      const PoojaDetail(
        id: 'satyanarayan',
        title: 'Satyanarayan Pooja',
        category: 'Wedding Rituals',
        imageUrl:
            'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
        isPopular: true,
        duration: '2.5 Hours',
        durationBreakdown:
            '30 mins setup • 2.0 hours main ritual & katha recitation',
        description:
            'Shri Satyanarayan Pooja is performed to seek divine blessings of Lord Vishnu for prosperity, health, and family harmony. Conducted by certified Vedic pandits with 10+ years of experience.',
        spiritualSignificance:
            'Reciting the Satyanarayan Katha invokes truth (Satya) and divine consciousness, removing negative energy and showering infinite prosperity upon the family.',
        inclusions: [
          '2 Certified Acharyas (Vedic Scholars)',
          'Complete Sacred Havan & Samagri Kit (Pure Desi Ghee)',
          'Kalash Sthapana & Panchamrit setup',
          'Satyanarayan Vrat Katha Book & Prashad',
          'Flower Decoration & Mandap consultation',
        ],
        chantingDetails: [
          'Vishnu Sahasranama Stotram',
          'Rigveda Shlokas',
          '108 Gayatri Mantra Recitation',
          'Satyanarayan Ashtothara Shatanamavali',
        ],
        standardPrice: 2100.0,
        samagriPrice: 1100.0,
        originalPrice: 4000.0,
        availability: 'Available Tomorrow',
      ),
      const PoojaDetail(
        id: 'vaidika_vivaha',
        title: 'Vaidika Vivaha (Vedic Wedding)',
        category: 'Wedding Rituals',
        imageUrl:
            'https://images.unsplash.com/photo-1609102434313-f938d87a718b?w=500',
        isPopular: true,
        duration: '4.5 Hours',
        durationBreakdown:
            '45 mins setup • 3.75 hours complete traditional wedding rites',
        description:
            'Comprehensive Vedic marriage ceremony following traditional Shastras, complete with Kanyadaan, Saptapadi (Seven Vows), Mangal Pheras, and sacred Vivaha Havan.',
        spiritualSignificance:
            'Binds two souls in a sacred spiritual union under the witness of Agni Dev (Fire God) and chanting of holy mantras for seven lifetimes of companionate bliss.',
        inclusions: [
          'Head Pandit + Assistant Acharya',
          'Premium Vivaha Havan Kit & Sacred Herbs',
          'Saptapadi & Mangalsutra Pujan kit',
          'Veda Mantras chanting & Live Sankalpa',
        ],
        chantingDetails: [
          'Yajurveda Vivaha Suktam',
          'Mangalashtakam Chanting',
          'Agni Invocation Mantras',
        ],
        standardPrice: 5100.0,
        samagriPrice: 2400.0,
        originalPrice: 9500.0,
        availability: 'Available this Saturday',
      ),
      const PoojaDetail(
        id: 'mangal_sutra',
        title: 'Mangal Sutra Ceremony',
        category: 'Wedding Rituals',
        imageUrl:
            'https://images.unsplash.com/photo-1583307878879-9a4c4e78b7e5?w=500',
        isPopular: false,
        duration: '1.5 Hours',
        durationBreakdown: '20 mins setup • 1.10 hours sacred bond rites',
        description:
            'Traditional mangalsutra binding ritual invoking divine protection, health, and long life for the spouse with Vedic mantras and holy water sprinkling.',
        spiritualSignificance:
            'Protects the matrimonial bond against evil eyes and enhances mutual affection, respect, and devotion between partners.',
        inclusions: [
          'Experienced Vedic Pandit',
          'Mangal Sutra Pujan & Abhishekam',
          'Pure Kumkum, Haldi, Aksata & Sacred Threads',
        ],
        chantingDetails: [
          'Gauri Pujan Mantras',
          'Soubhagya Suktam',
        ],
        standardPrice: 1500.0,
        samagriPrice: 600.0,
        originalPrice: 2500.0,
        availability: 'Available Sunday',
      ),
    ],
    'housewarming': [
      const PoojaDetail(
        id: 'griha_pravesh',
        title: 'Griha Pravesha Pooja',
        category: 'Housewarming',
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
      const PoojaDetail(
        id: 'vastu_shanti',
        title: 'Vastu Shanti Puja',
        category: 'Housewarming',
        imageUrl:
            'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        isPopular: false,
        duration: '2.0 Hours',
        durationBreakdown: '20 mins setup • 1.66 hours Vastu rectifications',
        description:
            'Specialized ritual designed to rectify architectural and directional Vastu doshas in living or office spaces.',
        spiritualSignificance:
            'Harmonizes the five elements (Pancha Bhoota) within the premises for maximum comfort and mental clarity.',
        inclusions: [
          'Senior Vastu Specialist Pandit',
          'Vastu Yantra Installation Kit',
          'Havan & Copper Pyramid Setup',
        ],
        chantingDetails: [
          'Dikpalaka Invocation',
          'Panch Bhoota Mantras',
        ],
        standardPrice: 2200.0,
        samagriPrice: 900.0,
        originalPrice: 3800.0,
        availability: 'Available This Week',
      ),
      const PoojaDetail(
        id: 'navagraha_homa',
        title: 'Navagraha Homa',
        category: 'Housewarming',
        imageUrl:
            'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
        isPopular: true,
        duration: '3.5 Hours',
        durationBreakdown:
            '30 mins setup • 3.0 hours nine planets fire ritual',
        description:
            'Potent fire ritual performed to appease the nine planetary deities and neutralize unfavorable astrological influences.',
        spiritualSignificance:
            'Balances planetary energies, bestows prosperity, good health, and success in new beginnings.',
        inclusions: [
          '2 Certified Vedic Pandits',
          '9 Grains (Navadhanya) & Pure Ghee Kit',
          'Navagraha Yantra & Abhishekam',
        ],
        chantingDetails: [
          'Navagraha Stotram',
          'Rahu-Ketu Shanti Mantras',
          'Aditya Hrudayam',
        ],
        standardPrice: 3500.0,
        samagriPrice: 1500.0,
        originalPrice: 6000.0,
        availability: 'Available Saturday',
      ),
    ],
    'poojahome': [
      const PoojaDetail(
        id: 'nitya_pooja',
        title: 'Daily Nitya Pooja',
        category: 'Pooja at Home',
        imageUrl:
            'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
        isPopular: false,
        duration: '1.0 Hour',
        durationBreakdown: '15 mins setup • 45 mins ritual & aarti',
        description:
            'Daily sacred ritual to establish a peaceful spiritual aura at home, including deity abhishekam, dhup-deepa, and stotra chanting.',
        spiritualSignificance:
            'Keeps household energy elevated and purified on a consistent daily basis.',
        inclusions: [
          'Experienced Local Pandit',
          'Daily Worship Flowers & Chandan Kit',
          'Panchamrit & Aarti',
        ],
        chantingDetails: [
          'Daily Prarthana Mantras',
          'Hanuman Chalisa',
        ],
        standardPrice: 800.0,
        samagriPrice: 300.0,
        originalPrice: 1500.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'ganesh_sthapana',
        title: 'Ganesh Sthapana Pooja',
        category: 'Pooja at Home',
        imageUrl:
            'https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500',
        isPopular: true,
        duration: '2.0 Hours',
        durationBreakdown:
            '20 mins setup • 1.66 hours idol installation & havan',
        description:
            'Invocation of Lord Ganesha to remove obstacles (Vighnaharta) and ensure good fortune before launching any major endeavor or festival.',
        spiritualSignificance:
            'Lord Ganesha is Prathama Pujya (first worshipped deity). His presence guarantees smooth success and wisdom.',
        inclusions: [
          'Verified Vedic Pandit',
          'Durva Grass, Modak & Roli Chhanvan Kit',
          'Short Ganesh Havan',
        ],
        chantingDetails: [
          'Ganapati Atharvashirsha',
          '108 Ganesha Namavali',
        ],
        standardPrice: 1800.0,
        samagriPrice: 800.0,
        originalPrice: 3200.0,
        availability: 'Available Tomorrow',
      ),
      const PoojaDetail(
        id: 'lakshmi_puja',
        title: 'Lakshmi Puja',
        category: 'Pooja at Home',
        imageUrl:
            'https://images.unsplash.com/photo-1617981408346-39acb6da1b64?w=500',
        isPopular: true,
        duration: '1.5 Hours',
        durationBreakdown: '20 mins setup • 1.10 hours prosperity ritual',
        description:
            'Sacred worship of Goddess Lakshmi and Kuber for inviting abundance, wealth, business success, and financial harmony.',
        spiritualSignificance:
            'Destroys poverty mindset and opens channels of divine prosperity and abundance.',
        inclusions: [
          'Certified Vedic Scholar',
          'Lotus Flowers, Kamalgatta & Kuber Yantra Kit',
          'Shree Suktam Archana',
        ],
        chantingDetails: [
          'Shree Suktam',
          'Kuber Ashta Lakshmi Stotram',
        ],
        standardPrice: 2000.0,
        samagriPrice: 900.0,
        originalPrice: 3600.0,
        availability: 'Available Friday',
      ),
    ],
  };

  List<Widget> _buildRitualCards() {
    return (_categoryRituals[selectedCategory] ?? []).map((ritual) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildRitualCard(ritual),
      );
    }).toList();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //backgroundColor: const Color(0xFFFDF0DC),
      backgroundColor: const Color(0xFFFFF8EE),
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
                    const SizedBox(height: 24),
                    _buildSelectRitualSubtitle(),
                    const SizedBox(height: 8),
                    _buildSelectRitualTitle(),
                    const SizedBox(height: 18),
                    _buildSearchBar(),
                    const SizedBox(height: 24),
                    _buildCategoriesHeader(),
                    const SizedBox(height: 14),
                    _buildCategoryCards(),
                    const SizedBox(height: 20),
                    _buildOrnamentalDivider(),
                    const SizedBox(height: 16),
                    _buildTrendingRitualsHeader(),
                    const SizedBox(height: 12),
                    ..._buildRitualCards(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────
  // 1. TOP BAR
  // ──────────────────────────────
  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: Color(0xFFF18C16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Pandit Setu',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: const Icon(
            Icons.notifications_outlined,
            size: 28,
            color: Color(0xFFE8920A),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────
  // 2. SELECT RITUAL SUBTITLE
  // ──────────────────────────────
  Widget _buildSelectRitualSubtitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'SELECT RITUAL',
          style: GoogleFonts.lato(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: const Color(0xFFE5A93B),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFE5A93B),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────
  // 3. SELECT RITUAL TITLE (BIGGER)
  // ──────────────────────────────
  Widget _buildSelectRitualTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Select Ritual',
          style: GoogleFonts.lato(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFFFFB300),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────
  // 4. SEARCH BAR
  // ──────────────────────────────
  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search rituals, pandits, or locations...',
        hintStyle: GoogleFonts.lato(fontSize: 15, color: Colors.grey),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFE8920A)),
        filled: true,
        fillColor: const Color(0xFFFAF0DC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFFAF0DC), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFFAF0DC), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Color(0xFFE8920A), width: 1),
        ),
      ),
    );
  }

  // ──────────────────────────────
  // 5. CATEGORIES HEADER
  // ──────────────────────────────
  Widget _buildCategoriesHeader() {
    return Text(
      'CATEGORIES',
      style: GoogleFonts.lato(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
        color: const Color(0xFFE8920A),
      ),
    );
  }

  // ──────────────────────────────
  // 6. CATEGORY CARDS ROW
  // ──────────────────────────────
  Widget _buildCategoryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildCategoryCard(
            icon: Icons.favorite,
            label: 'Wedding\nRituals',
            id: 'wedding',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCategoryCard(
            icon: Icons.home_outlined,
            label: 'House\nWarming',
            id: 'housewarming',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildCategoryCard(
            icon: Icons.temple_hindu,
            label: 'Pooja\nHome',
            id: 'poojahome',
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF18C16) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isActive
              ? null
              : Border.all(color: const Color(0xFFE8D5A3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: isActive ? 8 : 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF3D2200), size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────
  // 7. ORNAMENTAL DIVIDER
  // ──────────────────────────────
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

  // ──────────────────────────────
  // 8. TRENDING RITUALS HEADER
  // ──────────────────────────────
  Widget _buildTrendingRitualsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Trending Rituals',
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

  // ──────────────────────────────
  // 9. RITUAL CARD
  // ──────────────────────────────
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
              // Image left
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

              // Right side details
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
                      '${detail.duration} • ₹${detail.totalPrice.toInt()}',
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
                            color: const Color(0xFFE8920A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    showPoojaDetailBottomSheet(context, detail);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(0, 44),
                    elevation: 0,
                  ),
                  child: Text(
                    'View Details',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3D2200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFF18C16), Color(0xFFE5A93B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/book-flow', extra: detail);
                    },
                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: const Size(0, 44),
                    ),
                    child: Text(
                      'Book Now',
                      style: GoogleFonts.lato(
                        fontSize: 14,
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
      ),
    );
  }


  // ──────────────────────────────
  // 10. FLOATING PILL NAV BAR (Kartik's Style)
  // ──────────────────────────────
  Widget _buildNavBar() {
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
        left: 16,
        right: 16,
      ),
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
            final isActive = _currentNavIndex == i;
            return GestureDetector(
              onTap: () {
                setState(() => _currentNavIndex = i);
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
