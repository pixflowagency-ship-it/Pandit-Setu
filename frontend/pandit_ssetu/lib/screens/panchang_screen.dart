import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_side_drawer.dart';

class PanchangScreen extends StatefulWidget {
  const PanchangScreen({super.key});

  @override
  State<PanchangScreen> createState() => _PanchangScreenState();
}

class _PanchangScreenState extends State<PanchangScreen> {
  late DateTime _selectedDate;
  late DateTime _focusedMonth;

  // Key Hindu Festivals & Vrats for 2026/2027 lookup demo
  final Map<String, Map<String, String>> _festivals = {
    '2026-09-08': {'name': 'Bhadrapada Krishna Ekadashi', 'type': 'Vrat', 'badge': '🕉️ Ekadashi'},
    '2026-09-12': {'name': 'Anant Chaturdashi', 'type': 'Festival', 'badge': '🚩 Major Festival'},
    '2026-09-16': {'name': 'Bhadrapada Purnima', 'type': 'Purnima', 'badge': '🌕 Purnima'},
    '2026-09-26': {'name': 'Navratri Ghatasthapana', 'type': 'Festival', 'badge': '🚩 Navratri Day 1'},
    '2026-10-04': {'name': 'Maha Navami', 'type': 'Festival', 'badge': '🚩 Durga Puja'},
    '2026-10-05': {'name': 'Vijayadashami / Dussehra', 'type': 'Festival', 'badge': '🏹 Dussehra'},
    '2026-10-19': {'name': 'Karwa Chauth', 'type': 'Vrat', 'badge': '💍 Vrat'},
    '2026-11-01': {'name': 'Diwali (Lakshmi Puja)', 'type': 'Festival', 'badge': '🪔 Diwali'},
    '2026-11-11': {'name': 'Dev Uthani Ekadashi', 'type': 'Vrat', 'badge': '🕉️ Ekadashi'},
    '2026-12-20': {'name': 'Gita Jayanti', 'type': 'Festival', 'badge': '📜 Sacred Day'},
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(2026, 9, 8);
    _focusedMonth = DateTime(2026, 9, 1);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _jumpToToday() {
    setState(() {
      _selectedDate = DateTime(2026, 9, 8);
      _focusedMonth = DateTime(2026, 9, 1);
    });
  }

  String _formatMonthYear(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  String _formatFullDate(DateTime dt) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _getDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _getDateKey(_selectedDate);
    final currentFest = _festivals[dateKey];

    return Scaffold(
      backgroundColor: const Color(0xFFFAEDD8),
      drawer: const AppSideDrawer(),
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
                        const SizedBox(height: 20),
                        _buildPanchangTitle(),
                        const SizedBox(height: 16),
                        _buildDivider(),
                        const SizedBox(height: 20),

                        // CALENDAR UI CARD
                        _buildCalendarCard(),

                        const SizedBox(height: 20),

                        if (currentFest != null) ...[
                          _buildFestivalBanner(currentFest),
                          const SizedBox(height: 16),
                        ],

                        _buildSunMoonCard(),
                        const SizedBox(height: 16),
                        _buildTithiCard(),
                        const SizedBox(height: 16),
                        _buildNakshatraYogaRow(),
                        const SizedBox(height: 16),
                        _buildMuhuratCard(),
                        const SizedBox(height: 20),
                        _buildUpcomingFestivalsSection(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentPath: '/panchang'),
    );
  }

  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const Icon(Icons.menu, size: 26, color: Color(0xFF5A4A3A)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF18C16),
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
                fontWeight: FontWeight.bold,
                fontSize: 20,
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

  Widget _buildPanchangTitle() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vedic Panchang',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Color(0xFFE8920A)),
                    const SizedBox(width: 4),
                    Text(
                      'Ujjain, India  •  ${_formatFullDate(_selectedDate)}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A7060),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _jumpToToday,
              icon: const Icon(Icons.today, size: 16),
              label: Text(
                'Today',
                style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

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

  Widget _buildCalendarCard() {
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_focusedMonth.year, _focusedMonth.month, 1).weekday; // 1 = Mon, 7 = Sun

    // Calculate grid items: offset for starting day (1-based Mon=0, Sun=6)
    final startOffset = (firstWeekday - 1) % 7;
    const weekdaysHeader = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          // Month navigation bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left, color: Color(0xFF3D2200), size: 28),
              ),
              Row(
                children: [
                  const Icon(Icons.calendar_month, color: Color(0xFFF18C16), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _formatMonthYear(_focusedMonth),
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: const Color(0xFF3D2200),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, color: Color(0xFF3D2200), size: 28),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Weekday Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdaysHeader.map((day) {
              return SizedBox(
                width: 38,
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFE8920A),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFE8D5A3), height: 1),
          const SizedBox(height: 10),

          // Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }

              final dayNumber = index - startOffset + 1;
              final date = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
              final isSelected = _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;
              final isToday = date.year == 2026 && date.month == 9 && date.day == 8;

              final dateKey = _getDateKey(date);
              final fest = _festivals[dateKey];

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF18C16)
                        : (isToday ? const Color(0xFFFFF3E0) : Colors.transparent),
                    borderRadius: BorderRadius.circular(14),
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFFF18C16), width: 1.5)
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF18C16).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: GoogleFonts.lato(
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                          color: isSelected
                              ? Colors.white
                              : (isToday ? const Color(0xFFF18C16) : const Color(0xFF3D2200)),
                        ),
                      ),
                      if (fest != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFFD97706),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
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

  Widget _buildFestivalBanner(Map<String, String> fest) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF3E0), Color(0xFFFAF0DC)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF18C16).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF18C16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fest['badge'] ?? 'Special Day',
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  fest['name'] ?? '',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D2200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                      fontSize: 10,
                      letterSpacing: 1.2,
                      color: const Color(0xFF8A7060),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '06:18 AM',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: const Color(0xFF3D2200),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SUNSET',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              letterSpacing: 1.0,
                              color: const Color(0xFF8A7060),
                            ),
                          ),
                          Text(
                            '06:26 PM',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF3D2200),
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.wb_twilight,
                        color: Color(0xFFE8920A),
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F0FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOONRISE',
                            style: GoogleFonts.lato(
                              fontSize: 10,
                              letterSpacing: 1.0,
                              color: const Color(0xFF8A7060),
                            ),
                          ),
                          Text(
                            '04:35 PM',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF3D2200),
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.nightlight_round,
                        color: Color(0xFF7E57C2),
                        size: 22,
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
                'TITHI FOR SELECTED DATE',
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
                  'Krishna Paksha',
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
            'Ekadashi Tithi',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: const Color(0xFF3D2200),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ends at 09:14 PM. Auspicious for fasting, Vishnu Archana & Hawan.',
            style: GoogleFonts.lato(
              fontSize: 13,
              color: const Color(0xFF8A7060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNakshatraYogaRow() {
    return Row(
      children: [
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
                  'Pushya',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Till 10:45 PM',
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
                  'Ayushman',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Till 08:30 AM',
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

  Widget _buildMuhuratCard() {
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
          Text(
            'MUHURAT TIMINGS',
            style: GoogleFonts.lato(
              fontSize: 11,
              letterSpacing: 1.2,
              color: const Color(0xFF8A7060),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Abhijit Muhurat',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '11:54 AM - 12:44 PM',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Rahu Kalam',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '03:20 PM - 04:52 PM',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingFestivalsSection() {
    final festivalList = [
      {'date': DateTime(2026, 9, 12), 'title': 'Anant Chaturdashi', 'sub': '12 Sep 2026'},
      {'date': DateTime(2026, 9, 26), 'title': 'Navratri Ghatasthapana', 'sub': '26 Sep 2026'},
      {'date': DateTime(2026, 10, 5), 'title': 'Dussehra / Vijayadashami', 'sub': '05 Oct 2026'},
      {'date': DateTime(2026, 10, 19), 'title': 'Karwa Chauth Vrat', 'sub': '19 Oct 2026'},
      {'date': DateTime(2026, 11, 1), 'title': 'Diwali Lakshmi Pujan', 'sub': '01 Nov 2026'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UPCOMING FESTIVALS & VRATS',
          style: GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: const Color(0xFFE8920A),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: festivalList.map((f) {
              final dt = f['date'] as DateTime;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = dt;
                    _focusedMonth = DateTime(dt.year, dt.month, 1);
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(14),
                  width: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE8D5A3)),
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
                      Row(
                        children: [
                          const Icon(Icons.event, color: Color(0xFFF18C16), size: 16),
                          const SizedBox(width: 6),
                          Text(
                            f['sub'] as String,
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF18C16),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        f['title'] as String,
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
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
}
