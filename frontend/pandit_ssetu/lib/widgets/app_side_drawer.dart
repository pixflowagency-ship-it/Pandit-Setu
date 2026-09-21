import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../user_data.dart';

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({super.key});

  void _showFaqsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFFFFF8EE),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Frequently Asked Questions',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF3D2200)),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE8D5A3)),
            Expanded(
              child: ListView(
                children: const [
                  _FaqTile(
                    question: 'How are Pandits verified on Pandit Setu?',
                    answer:
                        'All Acharyas undergo strict background checks, Vedic Shastra certification verification, and mandatory oral examination by senior Gurus.',
                  ),
                  _FaqTile(
                    question: 'Can I bring my own Samagri for Pooja?',
                    answer:
                        'Yes! For physical in-person poojas, Samagri kit is optional. You can uncheck the Samagri option during booking. For Online Poojas, consecrated Samagri kit is mandatory.',
                  ),
                  _FaqTile(
                    question: 'How do Online / Virtual Poojas work?',
                    answer:
                        'Pandit Ji conducts the complete Vedic ritual via HD live interactive stream while chanting mantras with your specific Name & Gotra Sankalpa.',
                  ),
                  _FaqTile(
                    question: 'What if I need to reschedule my Pooja?',
                    answer:
                        'You can reschedule up to 6 hours before the scheduled time slot free of cost directly from the My Bookings section.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8EE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.gavel_rounded, color: Color(0xFFF18C16)),
            const SizedBox(width: 10),
            Text(
              'Terms & Privacy Policy',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sacred Trust & Code of Ethics',
                style: GoogleFonts.lato(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '1. Sacred Purity: All rituals are conducted adhering strictly to authentic Vedic Vidhi without shortcuts.\n\n'
                '2. Transparent Dakshina: No hidden charges or extra demands on the day of the pooja.\n\n'
                '3. Privacy Guarantee: Devotee Personal details, Gotra, and Horoscope data are 100% encrypted and confidential.\n\n'
                '4. Certified Samagri: All herbs, ghee, and Havan samagri are lab-tested and organic.',
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  height: 1.45,
                  color: const Color(0xFF5A4A3A),
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Accept & Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFFFF8EE),
      child: Column(
        children: [
          // DRAWER HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3D2200), Color(0xFF2E1906)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF18C16),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            UserData.name.isNotEmpty ? UserData.name : 'Devotee / Yajman',
                            style: GoogleFonts.lato(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            UserData.phone.isNotEmpty ? UserData.phone : '+91 Verified Devotee',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: const Color(0xFFE8D5A3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // DRAWER ITEMS LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _DrawerTile(
                  icon: Icons.person_outline,
                  title: 'Account / Profile',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/profile');
                  },
                ),
                _DrawerTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'My Bookings',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/bookings');
                  },
                ),
                _DrawerTile(
                  icon: Icons.help_outline_rounded,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/support');
                  },
                ),
                _DrawerTile(
                  icon: Icons.quiz_outlined,
                  title: 'FAQs (Frequent Questions)',
                  onTap: () {
                    Navigator.pop(context);
                    _showFaqsModal(context);
                  },
                ),
                _DrawerTile(
                  icon: Icons.gavel_outlined,
                  title: 'Terms & Conditions',
                  onTap: () {
                    Navigator.pop(context);
                    _showTermsModal(context);
                  },
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(color: Color(0xFFE8D5A3)),
                ),
                _DrawerTile(
                  icon: Icons.storefront_outlined,
                  title: 'Pooja Store & Kits',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/shop');
                  },
                ),
                _DrawerTile(
                  icon: Icons.calendar_month_outlined,
                  title: 'Vedic Panchang',
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/panchang');
                  },
                ),
              ],
            ),
          ),

          // FOOTER APP VERSION DETAILS
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF7ECE0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Color(0xFFD97706)),
                    const SizedBox(width: 6),
                    Text(
                      'Pandit Setu • v1.2.4',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '100% Vedic Shastra Certified • Made for Devotees',
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    color: const Color(0xFF8A7060),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD97706), size: 22),
      title: Text(
        title,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3D2200),
        ),
      ),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF8A7060), size: 18),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: GoogleFonts.lato(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF3D2200),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Text(
            answer,
            style: GoogleFonts.lato(
              fontSize: 13,
              height: 1.4,
              color: const Color(0xFF5A4A3A),
            ),
          ),
        ),
      ],
    );
  }
}
