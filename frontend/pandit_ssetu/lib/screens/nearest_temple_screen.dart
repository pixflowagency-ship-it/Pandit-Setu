import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class NearestTempleScreen extends StatefulWidget {
  const NearestTempleScreen({super.key});

  @override
  State<NearestTempleScreen> createState() => _NearestTempleScreenState();
}

class _NearestTempleScreenState extends State<NearestTempleScreen> {
  bool _isDetectingLocation = false;
  String _userLocation = 'Ujjain, Madhya Pradesh';

  final List<Map<String, dynamic>> _temples = [
    {
      'name': 'Mahakaleshwar Jyotirlinga Temple',
      'deity': 'Lord Shiva (Jyotirlinga)',
      'distance': '1.2 km away',
      'address': 'Jaisinghpura, Ujjain, Madhya Pradesh 456006',
      'darshanTimings': '04:00 AM - 11:00 PM',
      'bhasmaAarti': '04:00 AM Daily',
      'rating': 4.9,
      'reviews': '45K+',
      'image': 'https://dynamic-media-cdn.tripadvisor.com/media/photo-o/29/7d/4e/42/birla-temple-from-outside.jpg?w=900&h=500&s=1',
      'crowdStatus': 'Moderate Crowd',
      'crowdColor': 0xFFFFB300,
    },
    {
      'name': 'Harsiddhi Mata Temple (Shaktipeeth)',
      'deity': 'Goddess Harsiddhi',
      'distance': '1.8 km away',
      'address': 'Near Mahakal Temple, Ujjain, MP',
      'darshanTimings': '05:00 AM - 10:00 PM',
      'bhasmaAarti': 'Deepmalika Aarti at 07:00 PM',
      'rating': 4.8,
      'reviews': '18K+',
      'image': 'https://images.unsplash.com/photo-1621252179027-94459d278660?w=400',
      'crowdStatus': 'Low Crowd',
      'crowdColor': 0xFF4CAF50,
    },
    {
      'name': 'Kal Bhairav Temple',
      'deity': 'Lord Kal Bhairav',
      'distance': '4.5 km away',
      'address': 'Jail Road, Bhairav Garh, Ujjain, MP',
      'darshanTimings': '06:00 AM - 09:30 PM',
      'bhasmaAarti': 'Evening Aarti at 07:30 PM',
      'rating': 4.7,
      'reviews': '22K+',
      'image': 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=400',
      'crowdStatus': 'High Crowd',
      'crowdColor': 0xFFF44336,
    },
    {
      'name': 'Chintaman Ganesh Temple',
      'deity': 'Lord Ganesha',
      'distance': '6.2 km away',
      'address': 'Fatehabad Road, Ujjain, MP',
      'darshanTimings': '06:00 AM - 09:00 PM',
      'bhasmaAarti': 'Morning Aarti at 07:00 AM',
      'rating': 4.8,
      'reviews': '12K+',
      'image': 'https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=400',
      'crowdStatus': 'Low Crowd',
      'crowdColor': 0xFF4CAF50,
    },
    {
      'name': 'Sri Sri Radha Madan Mohan Temple (ISKCON)',
      'deity': 'Lord Krishna & Radha Ji',
      'distance': '3.1 km away',
      'address': 'Hare Krishna Land, Bharatpuri, Ujjain, MP',
      'darshanTimings': '04:30 AM - 08:30 PM',
      'bhasmaAarti': 'Mangala Aarti 04:30 AM',
      'rating': 4.9,
      'reviews': '15K+',
      'image': 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=400',
      'crowdStatus': 'Moderate Crowd',
      'crowdColor': 0xFFFFB300,
    },
  ];

  List<Map<String, dynamic>> _liveTemples = [];
  bool _isLoadingTemples = false;
  String? _locationStatusMessage;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationStatusMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isDetectingLocation = false;
            _locationStatusMessage = 'Location services disabled. Showing curated Vedic pilgrimage shrines.';
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isDetectingLocation = false;
              _locationStatusMessage = 'Location permission denied. Showing curated Vedic pilgrimage shrines.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isDetectingLocation = false;
            _locationStatusMessage = 'Location permission permanently denied. Showing curated Vedic pilgrimage shrines.';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 7),
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = '${position.latitude.toStringAsFixed(3)}°N, ${position.longitude.toStringAsFixed(3)}°E (GPS Active)';
          _isDetectingLocation = false;
        });
      }

      await _fetchNearbyTemples(position.latitude, position.longitude);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
          _locationStatusMessage = 'Unable to acquire GPS coordinates ($e). Showing curated Vedic pilgrimage shrines.';
        });
      }
    }
  }

  Future<void> _fetchNearbyTemples(double lat, double lng) async {
    setState(() => _isLoadingTemples = true);
    try {
      final results = await ApiService.getNearbyTemples(lat: lat, lng: lng, radiusKm: 15);
      if (mounted) {
        setState(() {
          _liveTemples = results;
          _isLoadingTemples = false;
          if (_liveTemples.isEmpty) {
            _locationStatusMessage = 'No live Google Places temples found in this 15km radius. Showing curated ancient Vedic shrines.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTemples = false;
          _locationStatusMessage = 'Temple search offline ($e). Showing curated ancient Vedic shrines.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTemples = _liveTemples.isNotEmpty ? _liveTemples : _temples;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const SizedBox(height: 12),
            _buildLocationBar(),
            if (_locationStatusMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFB74D)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFFE65100)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _locationStatusMessage!,
                          style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFF8A5300)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Expanded(
              child: _isLoadingTemples
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF18C16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: displayTemples.length,
                      itemBuilder: (context, index) {
                        return _buildTempleCard(displayTemples[index]);
                      },
                    ),
            ),
            _buildNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF3D2200), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nearest Temples',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D2200),
                ),
              ),
            ],
          ),
          const Icon(Icons.map_outlined, color: Color(0xFFF18C16), size: 26),
        ],
      ),
    );
  }

  Widget _buildLocationBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          const Icon(Icons.my_location, color: Color(0xFFF18C16), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR LOCATION',
                  style: GoogleFonts.lato(
                    fontSize: 9,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8A7060),
                  ),
                ),
                Text(
                  _userLocation,
                  style: GoogleFonts.lato(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D2200),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _isDetectingLocation ? null : _detectLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isDetectingLocation
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text('Locate', style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTempleCard(Map<String, dynamic> temple) {
    final imageUrl = (temple['image'] ?? 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=400').toString();
    final distanceStr = (temple['distance'] ?? temple['vicinity'] ?? 'Ancient Shrine').toString();
    final crowdStatusStr = (temple['crowdStatus'] ?? 'Darshan Open').toString();
    final crowdColorInt = (temple['crowdColor'] is int ? temple['crowdColor'] as int : 0xFF4CAF50);
    final templeName = (temple['name'] ?? 'Vedic Temple').toString();
    final ratingVal = (temple['rating'] != null ? temple['rating'].toString() : '4.8');
    final deityStr = (temple['deity'] ?? 'Vedic Deity • Ancient Gurukul').toString();
    final darshanTimings = (temple['darshanTimings'] ?? '05:00 AM - 09:30 PM').toString();
    final specialAarti = (temple['bhasmaAarti'] ?? temple['vicinity'] ?? 'Daily Aarti & Darshan').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 140,
                    color: const Color(0xFFFFF3E0),
                    child: const Icon(Icons.temple_hindu, color: Color(0xFFF18C16), size: 48),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.near_me, color: Color(0xFFFFE082), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        distanceStr,
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(crowdColorInt),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    crowdStatusStr,
                    style: GoogleFonts.lato(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        templeName,
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFB300), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          ratingVal,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3D2200),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  deityStr,
                  style: GoogleFonts.lato(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF18C16),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Color(0xFF8A7060)),
                    const SizedBox(width: 6),
                    Text(
                      'Darshan: $darshanTimings',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF5A4A3A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF8A7060)),
                    const SizedBox(width: 6),
                    Text(
                      'Details: $specialAarti',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF5A4A3A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening Maps directions to ${temple['name']}'),
                              backgroundColor: const Color(0xFFF18C16),
                            ),
                          );
                        },
                        icon: const Icon(Icons.directions, size: 16),
                        label: Text('Get Directions', style: GoogleFonts.lato(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF18C16),
                          side: const BorderSide(color: Color(0xFFF18C16)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go('/book'),
                        icon: const Icon(Icons.temple_hindu, size: 16),
                        label: Text('Book Temple Puja', style: GoogleFonts.lato(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF18C16),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context) {
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
          children: [
            _buildNavItem(Icons.home_outlined, 'Home', () => context.go('/home')),
            _buildNavItem(Icons.menu_book_outlined, 'Book', () => context.go('/book')),
            _buildNavItem(Icons.calendar_month_outlined, 'Panchang', () => context.go('/panchang')),
            _buildNavItem(Icons.shopping_bag_outlined, 'Shop', () => context.go('/shop')),
            _buildNavItem(Icons.person_outline, 'Profile', () => context.go('/profile')),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 22),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
