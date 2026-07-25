import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _fadeController.forward();

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/role-select');
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // FULL SCREEN BACKGROUND
          Image.asset(
            'assets/images/splash_bg.png',
            fit: BoxFit.cover,
          ),

          // TOP-LEFT MARIGOLD FLOWER
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 40, left: 16),
              child: _buildMarigold(size.width * 0.38),
            ),
          ),

          // BOTTOM-RIGHT MARIGOLD FLOWER
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 60, right: 16),
              child: _buildMarigold(size.width * 0.42),
            ),
          ),

          // CENTER TEXT OVERLAY
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Pandit Setu',
                    style: GoogleFonts.dancingScript(
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB22222),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'connecting pandits with yajmans',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8A7060),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a marigold flower using layered petal rings
  Widget _buildMarigold(double diameter) {
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CustomPaint(
        painter: _MarigoldPainter(),
      ),
    );
  }
}

class _MarigoldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // ── OUTER PETALS (large, lighter orange) ──────────
    _drawPetalRing(
      canvas,
      center: center,
      petalCount: 18,
      petalLength: radius * 0.95,
      petalWidth: radius * 0.38,
      color: const Color(0xFFE8920A),
      rotationOffset: 0,
    );

    // ── MIDDLE PETALS (medium, deeper orange) ─────────
    _drawPetalRing(
      canvas,
      center: center,
      petalCount: 14,
      petalLength: radius * 0.7,
      petalWidth: radius * 0.32,
      color: const Color(0xFFD4800A),
      rotationOffset: 0.15,
    );

    // ── INNER PETALS (small, warm gold) ───────────────
    _drawPetalRing(
      canvas,
      center: center,
      petalCount: 10,
      petalLength: radius * 0.48,
      petalWidth: radius * 0.26,
      color: const Color(0xFFF5A623),
      rotationOffset: 0.3,
    );

    // ── CENTER CIRCLE (dark core) ─────────────────────
    final corePaint = Paint()..color = const Color(0xFFC47000);
    canvas.drawCircle(center, radius * 0.15, corePaint);

    final innerCorePaint = Paint()..color = const Color(0xFFE8A040);
    canvas.drawCircle(center, radius * 0.08, innerCorePaint);
  }

  void _drawPetalRing(
    Canvas canvas, {
    required Offset center,
    required int petalCount,
    required double petalLength,
    required double petalWidth,
    required Color color,
    required double rotationOffset,
  }) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < petalCount; i++) {
      final angle =
          (2 * math.pi / petalCount) * i + rotationOffset;

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);

      final petalPath = Path();
      petalPath.moveTo(0, 0);
      petalPath.quadraticBezierTo(
        petalWidth / 2,
        petalLength * 0.5,
        0,
        petalLength,
      );
      petalPath.quadraticBezierTo(
        -petalWidth / 2,
        petalLength * 0.5,
        0,
        0,
      );
      petalPath.close();

      canvas.drawPath(petalPath, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
