import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../user_data.dart';

class KundliScreen extends StatefulWidget {
  const KundliScreen({super.key});

  @override
  State<KundliScreen> createState() => _KundliScreenState();
}

class _KundliScreenState extends State<KundliScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _dobController = TextEditingController(text: UserData.dob.isNotEmpty ? UserData.dob : '24/05/1995');
  final _tobController = TextEditingController(text: UserData.tob.isNotEmpty ? UserData.tob : '09:30 AM');
  final _pobController = TextEditingController(text: UserData.pob.isNotEmpty ? UserData.pob : 'Mumbai, Maharashtra');
  final _gotraController = TextEditingController(text: UserData.gotra.isNotEmpty ? UserData.gotra : 'Kashyap');
  final _zodiacController = TextEditingController(text: UserData.zodiac.isNotEmpty ? UserData.zodiac : 'Simha (Leo)');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _pobController.dispose();
    _gotraController.dispose();
    _zodiacController.dispose();
    super.dispose();
  }

  void _saveAstroProfile() {
    UserData.save(
      name: UserData.name,
      phone: UserData.phone,
      email: UserData.email,
      dob: _dobController.text,
      tob: _tobController.text,
      pob: _pobController.text,
      gotra: _gotraController.text,
      zodiac: _zodiacController.text,
      city: UserData.city,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Astrological Profile updated successfully!',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFD97706),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vedic Kundli Generator',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
            fontSize: 20,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD97706),
          labelColor: const Color(0xFFD97706),
          unselectedLabelColor: const Color(0xFF6B7280),
          labelStyle: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Kundli Overview'),
            Tab(text: 'Dosha Analysis'),
            Tab(text: 'Favorable Timings (Shubh Muhurat)'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildKundliChartTab(),
            _buildDoshaAnalysisTab(),
            _buildShubhMuhuratTab(),
          ],
        ),
      ),
    );
  }

  // 1. Kundli Chart Tab
  Widget _buildKundliChartTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Graphic chart card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Lagna Chart (Ascendant)',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 14),

              // Traditional Indian Astrology Chart (Custom Drawn Style)
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                  ),
                  child: CustomPaint(
                    painter: KundliChartPainter(),
                    child: Stack(
                      children: [
                        _astroPositionText('12\nMe', Alignment.topCenter),
                        _astroPositionText('1\nAr', Alignment.centerLeft),
                        _astroPositionText('2\nTa', Alignment.topLeft),
                        _astroPositionText('3\nGe', Alignment.bottomLeft),
                        _astroPositionText('4\nCn', Alignment.bottomCenter),
                        _astroPositionText('5\nLe', Alignment.bottomRight),
                        _astroPositionText('6\nVi', Alignment.topRight),
                        _astroPositionText('7\nLi', Alignment.centerRight),
                        _astroPositionText('Su\nMa', Alignment.center),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Purva Phalguni Nakshatra • Simha Rashi',
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Birth details form
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
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
              Text(
                'Birth & Astrological Parameters',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 14),
              _buildInputField('Date of Birth (DD/MM/YYYY)', _dobController),
              const SizedBox(height: 10),
              _buildInputField('Time of Birth (HH:MM AM/PM)', _tobController),
              const SizedBox(height: 10),
              _buildInputField('Place of Birth (City)', _pobController),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildInputField('Gotra', _gotraController)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildInputField('Zodiac Sign', _zodiacController)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _saveAstroProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Re-Calculate Kundli Chart',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _astroPositionText(String text, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.lato(fontSize: 13.5, color: const Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.lato(fontSize: 12.5, color: const Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFFAF6EE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD97706)),
        ),
      ),
    );
  }

  // 2. Dosha Analysis Tab
  Widget _buildDoshaAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildDoshaCard('Manglik Dosha', 'LOW RISK', 'Your Mangal (Mars) position is highly favorable. Minor corrections can be done by daily Hanuman Chalisa chanting.', Colors.green),
        const SizedBox(height: 14),
        _buildDoshaCard('Kaal Sarp Dosha', 'NO DOSHA DETECTED', 'No planetary alignment forming Kaal Sarp Yog exists in your birth chart.', Colors.blue),
        const SizedBox(height: 14),
        _buildDoshaCard('Sade Sati Status', 'PEAK PERIOD', 'Saturn is currently in transit over your natal Moon. Recommended Pooja: Shani Sade Sati Puja & Rudrabhishek.', Colors.red),
      ],
    );
  }

  Widget _buildDoshaCard(String name, String status, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: GoogleFonts.lato(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFF6B5B52),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // 3. Shubh Muhurat Tab
  Widget _buildShubhMuhuratTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildMuhuratCard('Abhijit Muhurat', '11:45 AM - 12:35 PM', 'Highly auspicious for starting any general business, purchasing assets or gold.'),
        const SizedBox(height: 14),
        _buildMuhuratCard('Rahu Kaal (Avoid)', '01:30 PM - 03:00 PM', 'Inauspicious. Avoid making crucial signatures, monetary transfers, or scheduling havan rituals.'),
        const SizedBox(height: 14),
        _buildMuhuratCard('Amrit Kaal', '05:40 PM - 07:15 PM', 'Auspicious. Excellent for recitation of stotram, daily home prayers and evening Sandhya aarti.'),
      ],
    );
  }

  Widget _buildMuhuratCard(String name, String time, String details) {
    final isAvoid = name.contains('Avoid');
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isAvoid ? Colors.red.shade50 : const Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAvoid ? Icons.warning_amber_rounded : Icons.schedule,
              color: isAvoid ? Colors.red : const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isAvoid ? Colors.red : const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  details,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFF6B5B52),
                    height: 1.4,
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

class KundliChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFFFAF6EE)
      ..style = PaintingStyle.fill;

    // Draw background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, paint);

    // Draw secondary outer border for premium look
    final outerRect = Rect.fromLTWH(-4, -4, size.width + 8, size.height + 8);
    canvas.drawRect(outerRect, paint..strokeWidth = 1.0);
    paint.strokeWidth = 2.0;

    // Diagonals
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Inner diamond
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, paint);

    // Draw small traditional circle in the absolute center
    final centerCirclePaint = Paint()
      ..color = const Color(0xFFD97706)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 6, centerCirclePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
