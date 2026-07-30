import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class LivePoojaTrackingScreen extends StatefulWidget {
  const LivePoojaTrackingScreen({super.key});

  @override
  State<LivePoojaTrackingScreen> createState() => _LivePoojaTrackingScreenState();
}

class _LivePoojaTrackingScreenState extends State<LivePoojaTrackingScreen> {
  int _currentProgressStep = 2;

  final List<Map<String, String>> _steps = [
    {
      'title': 'Pandit Assigned',
      'subtitle': 'Pt. Rameshwar Sharma has accepted your booking request.',
    },
    {
      'title': 'Samagri Dispatched / Prepared',
      'subtitle': 'Vedic Samagri Kit prepared & loaded from central storage.',
    },
    {
      'title': 'Pandit En Route / Arrived',
      'subtitle': 'Pandit Ji has departed & will arrive shortly.',
    },
    {
      'title': 'Pooja In Progress',
      'subtitle': 'Sacred fire havan chanting has commenced.',
    },
    {
      'title': 'Ritual Completed & Prashad Distributed',
      'subtitle': 'Arti completed, Prasad distributed & blessings given.',
    },
  ];

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
          'Live Pooja Tracking',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [

                  _buildLocationMapCard(),

                  const SizedBox(height: 16),

                  _buildPanditCard(),

                  const SizedBox(height: 16),

                  _buildTimelineWidget(),
                ],
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMapCard() {
    double left = 40;
    double top = 50;
    String statusText = 'Pandit at Temple';
    String arrivalOverlay = 'Arriving in 1 hr';

    if (_currentProgressStep == 0) {
      left = 40;
      top = 35;
      statusText = 'Pt. Assigned';
      arrivalOverlay = 'Allocated';
    } else if (_currentProgressStep == 1) {
      left = 100;
      top = 70;
      statusText = 'At Samagri Hub';
      arrivalOverlay = 'Preparing Kit';
    } else if (_currentProgressStep == 2) {
      left = 160;
      top = 45;
      statusText = 'En Route (12 Mins)';
      arrivalOverlay = 'Arriving in 12 Mins';
    } else if (_currentProgressStep >= 3) {
      left = 265;
      top = 70;
      statusText = 'Arrived at Home';
      arrivalOverlay = _currentProgressStep == 3 ? 'Ritual In Progress' : 'Completed';
    }

    return Container(
      height: 180,
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
      child: Stack(
        fit: StackFit.expand,
        children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: GridPaper(
              color: const Color(0xFFD97706).withValues(alpha: 0.08),
              interval: 40,
              subdivisions: 4,
              child: Container(color: Colors.white),
            ),
          ),

          CustomPaint(
            painter: MapTrackingPainter(_currentProgressStep),
          ),

          Positioned(
            left: left,
            top: top,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFD97706),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(
                    Icons.self_improvement,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6EE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFD97706), width: 0.5),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.lato(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFFD97706)),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            right: 40,
            bottom: 40,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1F2937),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6EE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
                  ),
                  child: Text(
                    'Your Home',
                    style: GoogleFonts.lato(fontSize: 8, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFD97706),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.navigation_outlined, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    arrivalOverlay,
                    style: GoogleFonts.lato(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  Widget _buildPanditCard() {
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
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Image.network(
              'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 50,
                height: 50,
                color: const Color(0xFFFFF3E0),
                child: const Icon(Icons.person, color: Color(0xFFD97706)),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pt. Rameshwar Sharma',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                Text(
                  'Rigveda Acharya & Vastu Specialist',
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: const Color(0xFF6B5B52),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFD97706), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '4.9 (128 reviews)',
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

          Row(
            children: [
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Calling Pt. Rameshwar Sharma...', style: GoogleFonts.lato()),
                      backgroundColor: const Color(0xFFD97706),
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.phone, color: Color(0xFFD97706), size: 18),
                ),
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening Chat with Pandit Ji...', style: GoogleFonts.lato()),
                      backgroundColor: const Color(0xFFD97706),
                    ),
                  );
                },
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD97706), size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineWidget() {
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
                'Ritual Milestones',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.remove, size: 16, color: Color(0xFFD97706)),
                      onPressed: () {
                        if (_currentProgressStep > 0) {
                          setState(() => _currentProgressStep--);
                        }
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        'Step ${_currentProgressStep + 1}/5',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ),
                    IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.add, size: 16, color: Color(0xFFD97706)),
                      onPressed: () {
                        if (_currentProgressStep < 4) {
                          setState(() => _currentProgressStep++);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              final isCompleted = _currentProgressStep >= index;
              final isCurrent = _currentProgressStep == index;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? const Color(0xFFD97706)
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isCompleted
                                ? const Color(0xFFD97706)
                                : const Color(0xFFE5E7EB),
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(Icons.check, size: 12, color: Colors.white)
                            : null,
                      ),
                      if (index < _steps.length - 1)
                        Container(
                          width: 2,
                          height: 48,
                          color: _currentProgressStep > index
                              ? const Color(0xFFD97706)
                              : const Color(0xFFE5E7EB),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _steps[index]['title']!,
                          style: GoogleFonts.lato(
                            fontSize: 14,
                            fontWeight:
                                isCurrent ? FontWeight.bold : FontWeight.w600,
                            color: isCurrent
                                ? const Color(0xFFD97706)
                                : (isCompleted
                                    ? const Color(0xFF1F2937)
                                    : const Color(0xFF9CA3AF)),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _steps[index]['subtitle']!,
                          style: GoogleFonts.lato(
                            fontSize: 11.5,
                            color: const Color(0xFF6B5B52),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening Pandit Setu Support Chat...',
                    style: GoogleFonts.lato(),
                  ),
                  backgroundColor: const Color(0xFFD97706),
                ),
              );
            },
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFD97706), size: 18),
            label: Text(
              'Chat with Support Assistant',
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD97706),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD97706), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapTrackingPainter extends CustomPainter {
  final int step;
  MapTrackingPainter(this.step);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD97706)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(40, 50)
      ..quadraticBezierTo(100, 100, 160, 60)
      ..quadraticBezierTo(220, 20, 270, 95)
      ..lineTo(315, 115);

    canvas.drawPath(path, dotPaint);

    final activePath = Path()..moveTo(40, 50);
    if (step == 0) {

    } else if (step == 1) {
      activePath.quadraticBezierTo(100, 100, 100, 70);
    } else if (step == 2) {
      activePath.quadraticBezierTo(100, 100, 160, 60);
    } else {
      activePath.quadraticBezierTo(100, 100, 160, 60);
      activePath.quadraticBezierTo(220, 20, 270, 95);
      activePath.lineTo(315, 115);
    }

    canvas.drawPath(activePath, paint);
  }

  @override
  bool shouldRepaint(covariant MapTrackingPainter oldDelegate) => oldDelegate.step != step;
}
