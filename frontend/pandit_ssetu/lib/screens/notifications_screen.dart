import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'all';

  final List<Map<String, String>> _notifications = [
    {
      'id': '1',
      'category': 'bookings',
      'title': 'Booking Confirmed!',
      'description': 'Pt. Rameshwar Sharma has accepted your request for Satyanarayan Pooja on 25 July at 09:30 AM.',
      'time': '10 mins ago',
      'icon': 'check_circle',
    },
    {
      'id': '2',
      'category': 'muhurat',
      'title': 'Upcoming Shubh Muhurat',
      'description': 'Abhijit Muhurat starts at 11:45 AM today. Auspicious for daily rituals and prayers.',
      'time': '1 hour ago',
      'icon': 'star',
    },
    {
      'id': '3',
      'category': 'festivals',
      'title': 'Sawan Shivratri Special',
      'description': 'Book a Special Rudrabhishek Pooja for peace & prosperity this Shivratri. Limited Pandit slots available.',
      'time': '3 hours ago',
      'icon': 'local_fire_department',
    },
    {
      'id': '4',
      'category': 'bookings',
      'title': 'Pooja Completed',
      'description': 'Your Lakshmi Puja completed successfully. Prasad has been dispatched via courier.',
      'time': 'Yesterday',
      'icon': 'celebration',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedFilter == 'all'
        ? _notifications
        : (_selectedFilter == 'muhurat_festivals'
            ? _notifications.where((n) => n['category'] == 'muhurat' || n['category'] == 'festivals').toList()
            : _notifications.where((n) => n['category'] == _selectedFilter).toList());

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
          'Notifications',
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

            _buildFilterChips(),

            Expanded(
              child: filteredList.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final notif = filteredList[index];
                        return _buildNotificationCard(notif);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 'all', 'label': 'All'},
      {'id': 'bookings', 'label': 'Bookings'},
      {'id': 'muhurat_festivals', 'label': 'Muhurat & Festivals'},
    ];

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(filter['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilter = filter['id']!);
                }
              },
              selectedColor: const Color(0xFFD97706),
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF1F2937),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFD97706) : const Color(0xFFE5E7EB),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, String> notif) {
    IconData getIcon(String name) {
      switch (name) {
        case 'check_circle':
          return Icons.check_circle_outline;
        case 'star':
          return Icons.auto_awesome;
        case 'local_fire_department':
          return Icons.local_fire_department_outlined;
        case 'celebration':
          return Icons.celebration_outlined;
        default:
          return Icons.notifications_none;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getIcon(notif['icon']!),
              color: const Color(0xFFD97706),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      notif['title']!,
                      style: GoogleFonts.lato(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      notif['time']!,
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif['description']!,
                  style: GoogleFonts.lato(
                    fontSize: 12.5,
                    color: const Color(0xFF6B5B52),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3E0),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 44,
              color: Color(0xFFD97706),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Alerts Available',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Check back later for festival updates & Astro tips.',
            style: GoogleFonts.lato(
              fontSize: 12,
              color: const Color(0xFF6B5B52),
            ),
          ),
        ],
      ),
    );
  }
}
