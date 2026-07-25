import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  String _selectedRole = 'yajman';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── BACKGROUND IMAGE ───────────────────────────────
          Image.asset(
            'assets/images/role_select_bg.png',
            fit: BoxFit.cover,
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const SizedBox(height: 24),

                                  // ─── TOP LOGO ──────────────────────────────
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Pandit Setu',
                                        style: GoogleFonts.lato(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF3D2000),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 16),

                                  // ─── SELECT PROFILE LABEL ──────────────────
                                  Text(
                                    'SELECT PROFILE',
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFFB8860B),
                                      letterSpacing: 2,
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // ─── HEADING ───────────────────────────────
                                  RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      style: GoogleFonts.lato(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF2D1A00),
                                        height: 1.15,
                                      ),
                                      children: const [
                                        TextSpan(text: 'How would you like to\nuse\n'),
                                        TextSpan(
                                          text: 'Pandit Setu?',
                                          style: TextStyle(color: Color(0xFFE8920A)),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // ─── YAJMAN CARD ───────────────────────────
                                  _RoleCard(
                                    icon: Icons.device_hub,
                                    title: 'Yajman',
                                    subtitle: 'BOOK POOJA SAMAGRI &\nPANDIT',
                                    isSelected: _selectedRole == 'yajman',
                                    onTap: () => setState(() => _selectedRole = 'yajman'),
                                  ),

                                  const SizedBox(height: 14),

                                  // ─── PANDIT CARD ───────────────────────────
                                  _RoleCard(
                                    icon: Icons.temple_hindu,
                                    title: 'Pandit',
                                    subtitle: 'Become the member of Pandit\nfamily',
                                    isSelected: _selectedRole == 'pandit',
                                    onTap: () => setState(() => _selectedRole = 'pandit'),
                                  ),

                                  const SizedBox(height: 28),

                                  // ─── SACRED BRIDGE DIVIDER (Decorative Dots Pattern) ───
                                  Column(
                                    children: [
                                      Text(
                                        'SACRED BRIDGE TO TRADITIONAL',
                                        style: GoogleFonts.lato(
                                          fontSize: 10,
                                          color: const Color(0xFF8A5C00),
                                          fontStyle: FontStyle.italic,
                                          letterSpacing: 2.0,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: const Color(0xFFB07F00).withValues(alpha: 0.8),
                                              thickness: 1.2,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              '❧ ✦ ❧',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Color(0xFFB07F00),
                                                letterSpacing: 6,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: const Color(0xFFB07F00).withValues(alpha: 0.8),
                                              thickness: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // ─── CONTINUE BUTTON & TERMS GROUP ───────────────────
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFC87000), Color(0xFF9A4800)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(30),
                                            border: Border.all(
                                              color: const Color(0xFFFFF3E0).withValues(alpha: 0.35),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFFC87000).withValues(alpha: 0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              if (_selectedRole == 'yajman') {
                                                context.go('/yajman-register');
                                              } else {
                                                context.go('/pandit-login');
                                              }
                                            },
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  'Continue',
                                                  style: GoogleFonts.lato(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 22,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                          style: GoogleFonts.lato(
                                            fontSize: 12,
                                            color: const Color(0xFF8A7060),
                                          ),
                                          children: const [
                                            TextSpan(text: 'By continuing, you agree to our '),
                                            TextSpan(
                                              text: 'Terms of Sanctity.',
                                              style: TextStyle(
                                                color: Color(0xFFE8920A),
                                                decoration: TextDecoration.underline,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
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

// ═══════════════════════════════════════════════════════════
//  REUSABLE ROLE CARD WIDGET
// ═══════════════════════════════════════════════════════════

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Base container containing layout/colors
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFFFF3E0)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFFE8920A),
                      width: 2,
                    )
                  : null, // Dashed border drawn separately when unselected
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ICON BOX
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFFFE0B2)
                        : const Color(0xFFF0EAE0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFFE8920A)
                        : const Color(0xFF9E8870),
                    size: 28,
                  ),
                ),

                const SizedBox(width: 16),

                // TEXT COLUMN
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2D1A00),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF8A7060),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(height: 8),
                        Container(
                          height: 1.5,
                          width: double.infinity,
                          color: const Color(0xFFE8920A).withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
                ),

                // CHECKMARK (top-aligned, only when selected)
                if (isSelected)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8920A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),

          // Dashed border overlays base container when unselected
          if (!isSelected)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _DashedBorderPainter(
                    color: const Color(0xFFDDCCBB),
                    strokeWidth: 1.2,
                    gap: 5.0,
                    dashLength: 5.0,
                    borderRadius: 16.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  CUSTOM PAINTER FOR DASHED BORDER
// ═══════════════════════════════════════════════════════════

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 4.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.dashLength != dashLength ||
        oldDelegate.borderRadius != borderRadius;
  }
}
