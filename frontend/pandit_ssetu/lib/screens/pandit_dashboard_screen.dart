import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/app_side_drawer.dart';

class PanditDashboardScreen extends StatefulWidget {
  const PanditDashboardScreen({super.key});

  @override
  State<PanditDashboardScreen> createState() => _PanditDashboardScreenState();
}

class _PanditDashboardScreenState extends State<PanditDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _hasIncomingRequest = false;
  int _requestTimerSeconds = 30;
  Timer? _requestCountdownTimer;

  // Duty Execution Flow States: none, heading_to_venue, arrived, pooja_in_progress, completed
  String _dutyState = 'none';
  int _poojaTimerMinutes = 24;
  Timer? _poojaTimer;

  // Earnings state
  double _todayEarnings = 5250.0;
  int _completedTodayCount = 3;
  final double _onlineHours = 5.2;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.18).animate(_pulseController);

    // Auto trigger sample request after 3 seconds if online
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isOnline && _dutyState == 'none') {
        _triggerIncomingRequest();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _requestCountdownTimer?.cancel();
    _poojaTimer?.cancel();
    super.dispose();
  }

  void _toggleOnlineState() {
    setState(() {
      _isOnline = !_isOnline;
      if (!_isOnline) {
        _hasIncomingRequest = false;
        _requestCountdownTimer?.cancel();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isOnline
              ? '🟢 You are now ONLINE & ready for Pooja requests!'
              : '🔴 You are OFFLINE. Duty paused.',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _isOnline ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerIncomingRequest() {
    if (!_isOnline || _dutyState != 'none') return;

    setState(() {
      _hasIncomingRequest = true;
      _requestTimerSeconds = 30;
    });

    _requestCountdownTimer?.cancel();
    _requestCountdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_requestTimerSeconds > 0) {
        setState(() => _requestTimerSeconds--);
      } else {
        _declineRequest();
      }
    });
  }

  void _acceptRequest() {
    _requestCountdownTimer?.cancel();
    setState(() {
      _hasIncomingRequest = false;
      _dutyState = 'heading_to_venue';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🎉 Booking Accepted! Navigating to Yajman location.',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF18C16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _declineRequest() {
    _requestCountdownTimer?.cancel();
    setState(() {
      _hasIncomingRequest = false;
    });
  }

  void _markArrived() {
    setState(() {
      _dutyState = 'arrived';
    });
  }

  void _startSankalpa() {
    setState(() {
      _dutyState = 'pooja_in_progress';
      _poojaTimerMinutes = 0;
    });

    _poojaTimer?.cancel();
    _poojaTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _dutyState == 'pooja_in_progress') {
        setState(() {
          _poojaTimerMinutes++;
        });
      }
    });
  }

  void _completePooja() {
    _poojaTimer?.cancel();
    setState(() {
      _dutyState = 'completed';
      _todayEarnings += 2625.0;
      _completedTodayCount++;
    });
  }

  void _finishDutyAndReset() {
    setState(() {
      _dutyState = 'none';
    });
  }

  void _showInstantPayoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFF8EE),
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet, color: Color(0xFFF18C16)),
            const SizedBox(width: 10),
            Text(
              'Instant Dakshina Payout',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transfer total available Dakshina directly to registered UPI ID / Bank account.',
              style: GoogleFonts.lato(color: const Color(0xFF8C7355), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8DCCB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available Balance',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: const Color(0xFF3D2200),
                    ),
                  ),
                  Text(
                    '₹${_todayEarnings.toStringAsFixed(0)}',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF27AE60),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF27AE60), size: 16),
                const SizedBox(width: 6),
                Text(
                  'UPI ID: acharya.shastri@okicici',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFF3D2200),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(color: const Color(0xFF8C7355)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '✅ Payout of ₹${_todayEarnings.toStringAsFixed(0)} transferred to your UPI account!',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: const Color(0xFF27AE60),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Transfer Now', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      drawer: const AppSideDrawer(),
      bottomNavigationBar: _buildBottomNavBar(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top Header Bar
                _buildHeaderBar(),

                // Duty Toggle Banner
                _buildDutyToggleBanner(),

                // Main Body Content based on Duty State
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_dutyState == 'none') ...[
                          // Demand Radar Card
                          _buildDemandRadarCard(),

                          const SizedBox(height: 16),

                          // Earnings Dashboard Overview
                          _buildEarningsDashboard(),

                          const SizedBox(height: 16),

                          // Simulate Incoming Request Test Trigger
                          if (_isOnline) ...[
                            OutlinedButton.icon(
                              onPressed: _triggerIncomingRequest,
                              icon: const Icon(Icons.bolt, color: Color(0xFFF18C16)),
                              label: Text(
                                'Simulate Incoming Pooja Request (Test Alert)',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3D2200),
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFFF18C16), width: 1.5),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Upcoming Scheduled Bookings
                          _buildUpcomingBookings(),

                          const SizedBox(height: 16),

                          // Fleet Performance Badges
                          _buildPerformanceBadges(),
                        ] else ...[
                          // Active Duty Flow View
                          _buildActiveDutyFlowView(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Uber/Rapido Style Incoming Request Overlay Modal
            if (_hasIncomingRequest) _buildIncomingRequestOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final navItems = [
      {
        'icon': Icons.space_dashboard_outlined,
        'activeIcon': Icons.space_dashboard,
        'label': 'Dashboard',
        'action': () {
          setState(() => _selectedNavIndex = 0);
        },
      },
      {
        'icon': Icons.calendar_month_outlined,
        'activeIcon': Icons.calendar_month,
        'label': 'Bookings',
        'action': () {
          setState(() => _selectedNavIndex = 1);
          context.push('/bookings');
        },
      },
      {
        'icon': Icons.headset_mic_outlined,
        'activeIcon': Icons.headset_mic,
        'label': 'Help',
        'action': () {
          setState(() => _selectedNavIndex = 2);
          context.push('/support');
        },
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
        'action': () {
          setState(() => _selectedNavIndex = 3);
          context.push('/profile');
        },
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3D2200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final isSelected = _selectedNavIndex == index;
            final item = navItems[index];
            return InkWell(
              onTap: item['action'] as VoidCallback,
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFF18C16) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.amber.shade200,
                      size: 22,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 6),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // UI Sub-components
  // ----------------------------------------------------

  Widget _buildHeaderBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8DCCB))),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const Icon(Icons.menu, size: 24, color: Color(0xFF3D2200)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Acharya Shastri Ji',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFFE0B2)),
                      ),
                      child: Text(
                        'Gold Pandit',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF18C16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      '4.92',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                    Text(
                      ' (148 Poojas)',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF8C7355),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Switch to Yajman Mode Button
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Color(0xFFF18C16)),
            tooltip: 'Switch to Yajman App',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyToggleBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _isOnline ? const Color(0xFF27AE60) : const Color(0xFF333333),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              ScaleTransition(
                scale: _isOnline ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isOnline ? Colors.greenAccent : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                    style: GoogleFonts.lato(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    _isOnline
                        ? 'Receiving instant Pooja booking requests'
                        : 'Toggle switch to go online and earn Dakshina',
                    style: GoogleFonts.lato(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: _isOnline,
            onChanged: (val) => _toggleOnlineState(),
            activeTrackColor: Colors.greenAccent[700],
            inactiveThumbColor: Colors.grey[400],
            inactiveTrackColor: Colors.grey[800],
          ),
        ],
      ),
    );
  }

  Widget _buildDemandRadarCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: Color(0xFFF18C16),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Sector 62, Noida',
                      style: GoogleFonts.lato(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        'HIGH DEMAND 🔥',
                        style: GoogleFonts.lato(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '18 Yajmans searching for Satyanarayan & Griha Pravesh Poojas nearby.',
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    color: const Color(0xFF8C7355),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsDashboard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D2200), Color(0xFF231200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D2200).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TODAY\'S DAKSHINA EARNINGS',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF18C16),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_todayEarnings.toStringAsFixed(0)}',
                    style: GoogleFonts.lato(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showInstantPayoutDialog,
                icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                label: Text(
                  'Instant Payout',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF18C16),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white12),
          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricStat('Completed', '$_completedTodayCount Poojas', Icons.task_alt),
              Container(height: 24, width: 1, color: Colors.white12),
              _buildMetricStat('Active Duty', '${_onlineHours}h', Icons.timer_outlined),
              Container(height: 24, width: 1, color: Colors.white12),
              _buildMetricStat('Acceptance', '96%', Icons.thumb_up_alt_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFFF18C16)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lato(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingBookings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pre-Scheduled Poojas',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE8DCCB)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      'TOMORROW',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF18C16),
                      ),
                    ),
                    Text(
                      '08:30 AM',
                      style: GoogleFonts.lato(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Griha Pravesh & Vastu Shanti',
                      style: GoogleFonts.lato(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Yajman: Anup Agarwal • Sector 128, Noida',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF8C7355),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹5,100',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF27AE60),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceBadges() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DCCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acharya Certifications & Badges',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3D2200),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadgeItem(Icons.verified, 'Veda Certified', const Color(0xFF27AE60)),
              _buildBadgeItem(Icons.timer, '100% On-Time', const Color(0xFFF18C16)),
              _buildBadgeItem(Icons.workspace_premium, '5-Star Acharya', Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(IconData icon, String title, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.lato(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // Uber / Rapido Style Incoming Request Overlay Modal
  // ----------------------------------------------------
  Widget _buildIncomingRequestOverlay() {
    return Container(
      color: Colors.black54,
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with 30s timer ring
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: _requestTimerSeconds / 30.0,
                        backgroundColor: Colors.grey[200],
                        color: const Color(0xFFF18C16),
                        strokeWidth: 4,
                      ),
                    ),
                    Text(
                      '${_requestTimerSeconds}s',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: const Color(0xFFF18C16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEW POOJA REQUEST!',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFF18C16),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Satyanarayan Katha with Havan',
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Container(height: 1, color: const Color(0xFFE8DCCB)),
            const SizedBox(height: 16),

            // Dakshina Earnings Display
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8EE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTIMATED DAKSHINA',
                        style: GoogleFonts.lato(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8C7355),
                        ),
                      ),
                      Text(
                        '₹2,625',
                        style: GoogleFonts.lato(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF27AE60),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF27AE60).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Samagri Kit Included',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF27AE60),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Location details & Distance
            Row(
              children: [
                const Icon(Icons.location_on, color: Color(0xFFF18C16), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ramesh Sharma (Yajman)',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      Text(
                        'Flat 402, Lotus Greens, Sector 78 Noida • 2.4 km away (8 mins)',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF8C7355),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Decline & Accept Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _declineRequest,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'DECLINE',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _acceptRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'ACCEPT BOOKING',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
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
      ),
    );
  }

  // ----------------------------------------------------
  // Active Duty Navigation & Execution Flow
  // ----------------------------------------------------
  Widget _buildActiveDutyFlowView() {
    if (_dutyState == 'heading_to_venue') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigation map card simulation
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E0D8),
              borderRadius: BorderRadius.circular(20),
              image: const DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1526778548025-fa2f459cd5c1?w=600',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF18C16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'ETA: 8 mins (2.4 km)',
                          style: GoogleFonts.lato(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.navigation, size: 16),
                        label: const Text('Open Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3D2200),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Yajman Contact details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DCCB)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E0),
                  child: Icon(Icons.person, color: Color(0xFFF18C16)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ramesh Sharma',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      Text(
                        'Flat 402, Lotus Greens, Sector 78 Noida',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF8C7355),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.phone, color: Color(0xFF27AE60)),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button: Arrived at Venue
          ElevatedButton(
            onPressed: _markArrived,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.where_to_vote),
                const SizedBox(width: 8),
                Text(
                  'I HAVE ARRIVED AT VENUE',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_dutyState == 'arrived') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8DCCB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF27AE60)),
                    const SizedBox(width: 10),
                    Text(
                      'Arrived at Yajman Venue',
                      style: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Pre-Ritual Checklist:',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8C7355),
                  ),
                ),
                const SizedBox(height: 8),
                _buildCheckItem('Unpack Samagri Kit & Kalash Sthapana'),
                _buildCheckItem('Guide Yajman for Sankalpa seat setup'),
                _buildCheckItem('Light the Sacred Agni Havan Kund'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: _startSankalpa,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.self_improvement),
                const SizedBox(width: 8),
                Text(
                  'START SANKALPA & RITUAL',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_dutyState == 'pooja_in_progress') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D2200), Color(0xFF5C3300)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.self_improvement, color: Color(0xFFF18C16), size: 48),
                const SizedBox(height: 10),
                Text(
                  'Satyanarayan Pooja In Progress',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Elapsed Ritual Time: $_poojaTimerMinutes mins',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    color: const Color(0xFFF18C16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: _completePooja,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF27AE60),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline),
                const SizedBox(width: 8),
                Text(
                  'COMPLETE POOJA & RECEIVE DAKSHINA',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    if (_dutyState == 'completed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF27AE60), width: 2),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 36,
                  backgroundColor: Color(0xFFE8F8F0),
                  child: Icon(Icons.stars, color: Color(0xFF27AE60), size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pooja Completed Successfully!',
                  style: GoogleFonts.lato(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D2200),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹2,625 Dakshina credited to your Pandit Wallet.',
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF27AE60),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _finishDutyAndReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF18C16),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Back to Online Duty',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_box, color: Color(0xFFF18C16), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFF3D2200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
