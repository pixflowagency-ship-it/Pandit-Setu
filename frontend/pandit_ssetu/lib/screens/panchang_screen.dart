import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class PanchangScreen extends StatelessWidget {
  const PanchangScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAEDD8),
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
                        const SizedBox(height: 24),
                        _buildPanchangTitle(),
                        const SizedBox(height: 16),
                        _buildDivider(),
                        const SizedBox(height: 20),
                        _buildSunMoonCard(),
                        const SizedBox(height: 16),
                        _buildTithiCard(),
                        const SizedBox(height: 16),
                        _buildNakshatraYogaRow(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildNavBar(context),
              ],
            ),

            // Floating AI button
            Positioned(
              right: 20,
              bottom: 90,
              child: GestureDetector(
                onTap: () {},
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF18C16), Color(0xFFE5A93B)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF18C16).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────────────
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
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
        const Align(
          alignment: Alignment.centerRight,
          child: Icon(
            Icons.notifications_outlined,
            size: 28,
            color: Color(0xFFE8920A),
          ),
        ),
      ],
    );
  }

  // ── Panchang Title ─────────────────────────────────────────────────
  Widget _buildPanchangTitle() {
    return Column(
      children: [
        Center(
          child: Text(
            'Panchang',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: const Color(0xFF3D2200),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Ujjain, India  •  Oct 24, 2023',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFF8A7060),
            ),
          ),
        ),
      ],
    );
  }

  // ── Decorative Divider ─────────────────────────────────────────────
  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: const Color(0xFFE8D5A3))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.auto_awesome, color: Color(0xFFE8920A), size: 14),
        ),
        Expanded(child: Container(height: 1, color: const Color(0xFFE8D5A3))),
      ],
    );
  }

  Widget _buildSunMoonCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // LEFT — SUNRISE tall card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.wb_sunny_outlined,
                    color: Color(0xFFE8920A),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'SUNRISE',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8A7060),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '06:24 AM',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: const Color(0xFF3D2200),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // RIGHT — SUNSET + MOONRISE stacked
          Expanded(
            child: Column(
              children: [
                // SUNSET
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'SUNSET',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              color: const Color(0xFF8A7060),
                              ),
                            ),
                          const Spacer(),
                          const Icon(
                            Icons.wb_twilight,
                            color: Color(0xFFE8920A),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '05:48 PM',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // MOONRISE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'MOONRISE',
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              letterSpacing: 1.2,
                              color: const Color(0xFF8A7060),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.nightlight_round,
                            color: Color(0xFF7E57C2),
                            size: 24,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '04:12 PM',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Current Tithi Card ─────────────────────────────────────────────
  Widget _buildTithiCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CURRENT TITHI',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  letterSpacing: 1.2,
                  color: const Color(0xFF8A7060),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE082),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Shukla Paksha',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: const Color(0xFF3D2200),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Ekadashi',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 30,
              color: const Color(0xFF3D2200),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ends at 08:14 PM. Most auspicious for fasting and Vishnu Puja.',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFF8A7060),
            ),
          ),
        ],
      ),
    );
  }

  // ── Nakshatra + Yoga Row ───────────────────────────────────────────
  Widget _buildNakshatraYogaRow() {
    return Row(
      children: [
        // NAKSHATRA
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF4),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAKSHATRA',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: const Color(0xFF8A7060),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rohini',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Till 11:30 PM',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFFE8920A),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // YOGA
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF4),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOGA',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: const Color(0xFF8A7060),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vriddhi',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Till 09:05 AM',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFFE8920A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Nav Bar ────────────────────────────────────────────────────────
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
            final isActive = i == 2; // Panchang is index 2
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
                    break; // already on panchang
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
