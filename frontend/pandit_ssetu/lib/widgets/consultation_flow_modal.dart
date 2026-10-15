import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';

class ConsultationFlowModal extends StatefulWidget {
  const ConsultationFlowModal({super.key});

  @override
  State<ConsultationFlowModal> createState() => _ConsultationFlowModalState();
}

class _ConsultationFlowModalState extends State<ConsultationFlowModal> {
  // Step 0: Mode selection (Online vs Offline)
  // Step 1: Sub-flow (Online details or Offline details)
  // Step 2: Final direct consultation / confirmation
  int _currentView = 0; // 0 = main choice, 1 = online flow, 2 = offline flow, 3 = direct online active, 4 = offline confirmed

  // --- ONLINE STATE ---
  String _onlineTiming = 'immediate'; // 'immediate' or 'schedule'
  int _selectedDuration = 15; // 15, 30, 60 minutes
  String _onlineMedium = 'phone'; // 'phone' or 'meet'
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _scheduledTimeSlot = '11:30 AM';
  final _userNameController = TextEditingController(text: 'Yajman Devotee');
  final _userPhoneController = TextEditingController(text: '+91 98765 43210');
  String _selectedTopic = 'Marriage & Kundli Dosha';

  // --- OFFLINE STATE ---
  String _offlinePlaceChoice = 'office'; // 'office' or 'doorstep'
  int _selectedOfficeIndex = 0;
  final _addressController = TextEditingController(text: 'Flat 402, Lotus Heights, MG Road');
  final _cityController = TextEditingController(text: 'Mumbai');
  final _pincodeController = TextEditingController(text: '400001');
  final _consultationReasonController = TextEditingController(
    text: 'Need complete Vastu inspection of our new residence and horoscope guidance for child education.',
  );
  DateTime _offlineDate = DateTime.now().add(const Duration(days: 1));
  String _offlineTimeSlot = '11:00 AM';
  int _offlineDuration = 30; // 15, 30, 60 mins

  final List<Map<String, dynamic>> _sarvMangalOffices = [
    {
      'name': 'SARV MANGAL Central Kendra - Ujjain',
      'address': 'Plot 14, Mahakal Temple Marg, Near Ved Shala, Ujjain, MP - 456006',
      'distance': '0.8 km away',
      'hours': '08:00 AM - 08:00 PM',
      'phone': '+91 734 2551234',
    },
    {
      'name': 'SARV MANGAL Vedic Bhavan - Mumbai',
      'address': 'Shop 4-5, Near Siddhivinayak Temple, SK Bole Marg, Dadar West, Mumbai - 400028',
      'distance': '2.4 km away',
      'hours': '09:00 AM - 08:30 PM',
      'phone': '+91 22 24305678',
    },
    {
      'name': 'SARV MANGAL Kashi Kendra - Varanasi',
      'address': 'Kashi Vishwanath Corridor Road, Godowlia, Varanasi, UP - 221001',
      'distance': '1.5 km away',
      'hours': '07:30 AM - 09:00 PM',
      'phone': '+91 542 2398765',
    },
    {
      'name': 'SARV MANGAL Delhi Dham - New Delhi',
      'address': 'B-12, Inner Circle, Connaught Place, New Delhi - 110001',
      'distance': '3.2 km away',
      'hours': '09:30 AM - 07:30 PM',
      'phone': '+91 11 41509988',
    },
  ];

  final List<String> _topics = [
    'Marriage & Kundli Dosha',
    'Career, Job & Business Growth',
    'Health, Family Peace & Prosperity',
    'Griha Vastu Dosha Remedy',
    'Child Education & Higher Studies',
    'Navagraha & Rahu-Ketu Shanti',
  ];

  final List<String> _timeSlots = [
    '09:00 AM',
    '11:00 AM',
    '02:00 PM',
    '04:30 PM',
    '06:30 PM',
    '08:00 PM',
  ];

  @override
  void dispose() {
    _userNameController.dispose();
    _userPhoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _consultationReasonController.dispose();
    super.dispose();
  }

  int _getPrice(int duration) {
    if (duration == 15) return 199;
    if (duration == 30) return 349;
    return 599;
  }

  int _getOfflinePrice(int duration) {
    if (duration == 15) return 299;
    if (duration == 30) return 499;
    return 899;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isHindi = languageService.isHindi;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Color(0xFFFAF6EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD4C2AA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          _buildHeader(isHindi),

          const Divider(height: 1, color: Color(0xFFEADBCA)),

          // Body Views
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentView(isHindi),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isHindi) {
    String title = isHindi ? 'ज्योतिष एवं वैदिक परामर्श' : 'Vedic Consultation';
    String subtitle = 'SARV MANGALS • सर्व मंगल';

    if (_currentView == 1) {
      title = isHindi ? 'ऑनलाइन परामर्श (Online)' : 'Online Consultation';
    } else if (_currentView == 2) {
      title = isHindi ? 'ऑफलाइन परामर्श (Offline)' : 'Offline Consultation';
    } else if (_currentView == 3) {
      title = isHindi ? 'परामर्श कक्ष (Direct Session)' : 'Live Consultation Session';
    } else if (_currentView == 4) {
      title = isHindi ? 'परामर्श पुष्टि (Confirmed)' : 'Consultation Confirmed';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          if (_currentView != 0 && _currentView != 3 && _currentView != 4)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF3D2200)),
              onPressed: () => setState(() => _currentView = 0),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF57C00).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_alt, color: Color(0xFFE65100), size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.lato(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'POPULAR',
                        style: GoogleFonts.lato(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: const Color(0xFF8A7060),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF8A7060)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentView(bool isHindi) {
    switch (_currentView) {
      case 0:
        return _buildMainChoiceView(isHindi);
      case 1:
        return _buildOnlineFlowView(isHindi);
      case 2:
        return _buildOfflineFlowView(isHindi);
      case 3:
        return _buildDirectOnlineConsultationView(isHindi);
      case 4:
        return _buildOfflineConfirmedView(isHindi);
      default:
        return _buildMainChoiceView(isHindi);
    }
  }

  // --- STEP 0: MAIN SELECTION (ONLINE VS OFFLINE) ---
  Widget _buildMainChoiceView(bool isHindi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isHindi
              ? 'आप किस प्रकार परामर्श लेना चाहते हैं?'
              : 'Choose Your Preferred Consultation Mode',
          style: GoogleFonts.lato(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'वाराणसी एवं उज्जैन के वरिष्ठ वैदिक आचार्यों से सीधे मार्गदर्शन प्राप्त करें।'
              : 'Receive direct Vedic guidance from certified Acharyas & Jyotish scholars.',
          style: GoogleFonts.lato(
            fontSize: 13,
            color: const Color(0xFF6B5B52),
          ),
        ),
        const SizedBox(height: 20),

        // OPTION A: ONLINE
        GestureDetector(
          onTap: () => setState(() => _currentView = 1),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF57C00), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF57C00).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF57C00).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.video_call_rounded,
                    color: Color(0xFFE65100),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isHindi ? 'A. ऑनलाइन परामर्श' : 'A. ONLINE Consultation',
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
                              color: const Color(0xFFE65100),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'INSTANT',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHindi
                            ? 'तत्काल या बाद में • फ़ोन कॉल या गूगल मीट • 15/30/60 मिनट'
                            : 'Immediate or Schedule Later • Phone Call or Google Meet • 15/30/60 Mins',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF6B5B52),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFE65100)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // OPTION B: OFFLINE
        GestureDetector(
          onTap: () => setState(() => _currentView = 2),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0D0BE), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF0DC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(
                    Icons.location_city_rounded,
                    color: Color(0xFFB45309),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isHindi ? 'B. ऑफलाइन परामर्श' : 'B. OFFLINE Consultation',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHindi
                            ? 'सर्वमंगल कार्यालय में या आपके स्थान पर • समय एवं तारीख चयन'
                            : 'At SARV MANGAL Office or At Your Place • Date & Time Selection',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF6B5B52),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFFB45309)),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Trust features
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3E7D3)),
          ),
          child: Column(
            children: [
              _buildFeatureBullet(Icons.verified, '100% Certified Acharyas from Kashi & Ujjain Vidyapeeth'),
              const SizedBox(height: 8),
              _buildFeatureBullet(Icons.lock_outline, 'Strict Confidentiality & 1-on-1 Personalized Remedies'),
              const SizedBox(height: 8),
              _buildFeatureBullet(Icons.admin_panel_settings, 'Pandit directly assigned from SARV MANGAL Admin Panel'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE65100), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.lato(
              fontSize: 12,
              color: const Color(0xFF5A4A3A),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 1: ONLINE FLOW ---
  Widget _buildOnlineFlowView(bool isHindi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Timing Choice: Immediate vs Schedule Later
        Text(
          isHindi ? '1. समय प्रकार चुनें' : '1. Choose Consultation Timing',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _onlineTiming = 'immediate'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _onlineTiming == 'immediate' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _onlineTiming == 'immediate' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _onlineTiming == 'immediate' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.flash_on, color: Color(0xFFE65100), size: 24),
                      const SizedBox(height: 6),
                      Text(
                        isHindi ? 'तत्काल परामर्श' : 'Immediate',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      Text(
                        isHindi ? '5 मिनट में जुड़ें' : 'Connect in 5m',
                        style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _onlineTiming = 'schedule'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: _onlineTiming == 'schedule' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _onlineTiming == 'schedule' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _onlineTiming == 'schedule' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFFE65100), size: 24),
                      const SizedBox(height: 6),
                      Text(
                        isHindi ? 'बाद में शेड्यूल करें' : 'Schedule Later',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      Text(
                        isHindi ? 'तारीख व समय चुनें' : 'Pick Date & Time',
                        style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 2. Duration Selection: 15 min, 30 min, 60 min
        Text(
          isHindi ? '2. परामर्श अवधि चुनें' : '2. Select Duration',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [15, 30, 60].map((duration) {
            final isSelected = _selectedDuration == duration;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDuration = duration),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE65100) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$duration Mins',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF3D2200),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_getPrice(duration)}',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFFE65100),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // 3. Medium Choice: On Phone Call vs On Google Meet
        Text(
          isHindi ? '3. माध्यम चुनें (Call or Meet)' : '3. Choose Communication Mode',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _onlineMedium = 'phone'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _onlineMedium == 'phone' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _onlineMedium == 'phone' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _onlineMedium == 'phone' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_in_talk, color: Color(0xFFE65100), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'फ़ोन कॉल पर' : 'On Phone Call',
                              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              isHindi ? 'सीधा ऑडियो कॉल' : 'Direct Voice Call',
                              style: GoogleFonts.lato(fontSize: 10.5, color: const Color(0xFF8A7060)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _onlineMedium = 'meet'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _onlineMedium == 'meet' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _onlineMedium == 'meet' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _onlineMedium == 'meet' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.video_camera_front, color: Color(0xFFE65100), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'गूगल मीट पर' : 'On Google Meet',
                              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              isHindi ? 'HD वीडियो कॉल' : 'Admin Video Link',
                              style: GoogleFonts.lato(fontSize: 10.5, color: const Color(0xFF8A7060)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // 4. Date & Time Picker if Schedule Later
        if (_onlineTiming == 'schedule') ...[
          const SizedBox(height: 20),
          Text(
            isHindi ? '4. तारीख एवं समय चुनें' : '4. Select Date & Time Slot',
            style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _scheduledDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 60)),
                    );
                    if (picked != null) {
                      setState(() => _scheduledDate = picked);
                    }
                  },
                  icon: const Icon(Icons.event, size: 18, color: Color(0xFFE65100)),
                  label: Text(
                    '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year}',
                    style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _scheduledTimeSlot,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _timeSlots
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.lato(fontSize: 13))))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _scheduledTimeSlot = val);
                  },
                ),
              ),
            ],
          ),
        ],

        const SizedBox(height: 20),

        // 5. Concern Topic
        Text(
          isHindi ? 'परामर्श का विषय चुनें' : 'Select Topic of Concern',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedTopic,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
          ),
          items: _topics
              .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.lato(fontSize: 13))))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedTopic = val);
          },
        ),

        const SizedBox(height: 24),

        // Action CTA
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // Proceed to Direct Online Consultation / Allocation
              setState(() => _currentView = 3);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _onlineTiming == 'immediate'
                      ? (isHindi ? 'तत्काल पंडित जी से जुड़ें • ₹${_getPrice(_selectedDuration)}' : 'Connect to Pandit Ji • ₹${_getPrice(_selectedDuration)}')
                      : (isHindi ? 'शेड्यूल कन्फर्म करें • ₹${_getPrice(_selectedDuration)}' : 'Confirm Schedule • ₹${_getPrice(_selectedDuration)}'),
                  style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: OFFLINE FLOW ---
  Widget _buildOfflineFlowView(bool isHindi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 1. Duration Selection
        Text(
          isHindi ? '1. परामर्श अवधि चुनें' : '1. Select Consultation Duration',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [15, 30, 60].map((dur) {
            final isSel = _offlineDuration == dur;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _offlineDuration = dur),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFFB45309) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isSel ? const Color(0xFFB45309) : const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$dur Mins',
                        style: GoogleFonts.lato(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : const Color(0xFF3D2200),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_getOfflinePrice(dur)}',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSel ? Colors.white : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // 2. Date & Time Selection
        Text(
          isHindi ? '2. तारीख एवं समय चुनें' : '2. Select Date & Time',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _offlineDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setState(() => _offlineDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 18, color: Color(0xFFB45309)),
                label: Text(
                  '${_offlineDate.day}/${_offlineDate.month}/${_offlineDate.year}',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _offlineTimeSlot,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _timeSlots
                    .map((t) => DropdownMenuItem(value: t, child: Text(t, style: GoogleFonts.lato(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _offlineTimeSlot = val);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // 3. Place Selection: At SarvMangal Office vs At Your Place
        Text(
          isHindi ? '3. परामर्श का स्थान चुनें' : '3. Choose Place for Consultation',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _offlinePlaceChoice = 'office'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _offlinePlaceChoice == 'office' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _offlinePlaceChoice == 'office' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _offlinePlaceChoice == 'office' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.apartment, color: Color(0xFFE65100), size: 26),
                      const SizedBox(height: 6),
                      Text(
                        'At SARV MANGAL Office',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      Text(
                        isHindi ? 'निकटतम केंद्र' : 'Nearest Centers',
                        style: GoogleFonts.lato(fontSize: 10.5, color: const Color(0xFF8A7060)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _offlinePlaceChoice = 'doorstep'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: _offlinePlaceChoice == 'doorstep' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _offlinePlaceChoice == 'doorstep' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _offlinePlaceChoice == 'doorstep' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.home_outlined, color: Color(0xFFE65100), size: 26),
                      const SizedBox(height: 6),
                      Text(
                        'At your place',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      Text(
                        isHindi ? 'घर / प्रतिष्ठान पर' : 'At Your Doorstep',
                        style: GoogleFonts.lato(fontSize: 10.5, color: const Color(0xFF8A7060)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Dynamic Sub-sections based on Place Selection
        if (_offlinePlaceChoice == 'office') ...[
          // LIST OF NEAREST SARVMANGAL OFFICES
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isHindi ? 'निकटतम सर्वमंगल कार्यालय' : 'Nearest SARV MANGAL Offices',
                style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
              ),
              Text(
                '4 Centers Found',
                style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(_sarvMangalOffices.length, (idx) {
            final off = _sarvMangalOffices[idx];
            final isChosen = _selectedOfficeIndex == idx;
            return GestureDetector(
              onTap: () => setState(() => _selectedOfficeIndex = idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isChosen ? const Color(0xFFFFF8EE) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isChosen ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                    width: isChosen ? 2 : 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      isChosen ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isChosen ? const Color(0xFFE65100) : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  off['name']!,
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: const Color(0xFF3D2200),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  off['distance']!,
                                  style: GoogleFonts.lato(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            off['address']!,
                            style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFF6B5B52)),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 12, color: Color(0xFF8A7060)),
                              const SizedBox(width: 4),
                              Text(off['hours']!, style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060))),
                              const SizedBox(width: 12),
                              const Icon(Icons.phone, size: 12, color: Color(0xFF8A7060)),
                              const SizedBox(width: 4),
                              Text(off['phone']!, style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ] else ...[
          // AT YOUR PLACE FORM: Address, Phone, Devotee, Reason
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'आपके पते एवं विवरण की जानकारी' : 'Address & Devotee Details',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13.5, color: const Color(0xFF3D2200)),
                ),
                const SizedBox(height: 12),
                _buildTextField('Complete Street Address', _addressController, icon: Icons.location_on),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildTextField('City', _cityController, icon: Icons.location_city)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('Pincode', _pincodeController, icon: Icons.pin_drop)),
                  ],
                ),
                const SizedBox(height: 10),
                _buildTextField('Contact Phone Number', _userPhoneController, icon: Icons.phone),
                const SizedBox(height: 14),
                Text(
                  isHindi ? 'परामर्श का कारण (Reason for Consultancy)*' : 'Reason for Consultancy*',
                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 12.5, color: const Color(0xFFE65100)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _consultationReasonController,
                  maxLines: 3,
                  style: GoogleFonts.lato(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter reason: e.g. Griha Vastu inspection, Kundli Milan, Child education...',
                    filled: true,
                    fillColor: const Color(0xFFFAF6EE),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Action CTA
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              setState(() => _currentView = 4);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isHindi
                      ? 'ऑफलाइन परामर्श बुक करें • ₹${_getOfflinePrice(_offlineDuration)}'
                      : 'Book Offline Consultation • ₹${_getOfflinePrice(_offlineDuration)}',
                  style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 3: DIRECT ONLINE CONSULTATION SCREEN (Admin Panel Assigned) ---
  Widget _buildDirectOnlineConsultationView(bool isHindi) {
    final bool isImmediate = _onlineTiming == 'immediate';
    final bool isMeet = _onlineMedium == 'meet';
    const meetUrl = 'https://meet.google.com/smg-vedic-session-7842';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Allocation Badge Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'PANDIT ASSIGNED FROM ADMIN PANEL',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Pandit Avatar & Credentials
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE65100), width: 2),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/pandit_1.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: const Color(0xFFFFF3E0),
                          child: const Icon(Icons.person, color: Color(0xFFE65100), size: 36),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acharya Devratna Shastri',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3D2200),
                          ),
                        ),
                        Text(
                          'Senior Jyotish & Kundli Specialist (18+ yrs)',
                          style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060)),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '4.9 (1,420+ Consultations)',
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5A4A3A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Session Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF3E7D3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Topic', _selectedTopic),
              _buildDetailRow('Duration', '$_selectedDuration Minutes (₹${_getPrice(_selectedDuration)})'),
              _buildDetailRow(
                'Schedule',
                isImmediate
                    ? 'Immediate (Connecting now)'
                    : '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year} at $_scheduledTimeSlot',
              ),
              _buildDetailRow(
                'Medium',
                isMeet ? '📹 Google Meet (Video Call)' : '📞 Direct Phone Call (Audio)',
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // SPECIFIC ACTION FOR PHONE VS MEET
        if (isMeet) ...[
          // GOOGLE MEET ACTIVE LINK CREATED BY ADMIN
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1976D2), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.video_call, color: Color(0xFF1976D2), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Google Meet Link Created by Admin',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                          Text(
                            meetUrl,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: const Color(0xFF1E88E5),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Joining SARV MANGAL Google Meet consultation room...'),
                              backgroundColor: Color(0xFF1976D2),
                            ),
                          );
                        },
                        icon: const Icon(Icons.videocam, color: Colors.white, size: 18),
                        label: Text(
                          isImmediate ? 'Join Google Meet Now' : 'Open Scheduled Meet',
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Meet link copied to clipboard!'),
                            backgroundColor: Color(0xFFE65100),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16, color: Color(0xFF1976D2)),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ] else ...[
          // PHONE CALL OPTION
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.phone_in_talk, color: Color(0xFF2E7D32), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Direct Phone Consultation',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: const Color(0xFF2E7D32),
                            ),
                          ),
                          Text(
                            'Acharya is connected. Calling ${_userPhoneController.text}...',
                            style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF6B5B52)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connecting phone call with Acharya Devratna Shastri...'),
                          backgroundColor: Color(0xFF2E7D32),
                        ),
                      );
                    },
                    icon: const Icon(Icons.call, color: Colors.white, size: 18),
                    label: Text(
                      isImmediate ? 'Start Direct Call Now' : 'Confirm Phone Call',
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Done & Close',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: const Color(0xFF8A7060)),
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 4: OFFLINE CONFIRMED VIEW ---
  Widget _buildOfflineConfirmedView(bool isHindi) {
    final bool isOffice = _offlinePlaceChoice == 'office';
    final office = _sarvMangalOffices[_selectedOfficeIndex];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 40),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isHindi ? 'ऑफलाइन परामर्श सफलतापूर्वक बुक हुआ!' : 'Offline Consultation Confirmed!',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'प्रशासक द्वारा वरिष्ठ पंडित जी आवंटित कर दिए गए हैं।'
              : 'Senior Acharya has been allotted from SARV MANGAL Admin Panel.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B5B52)),
        ),
        const SizedBox(height: 20),

        // Details Container
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEADBCA)),
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
              _buildDetailRow('Booking ID', 'SMG-CNS-7709'),
              _buildDetailRow(
                'Date & Time',
                '${_offlineDate.day}/${_offlineDate.month}/${_offlineDate.year} at $_offlineTimeSlot ($_offlineDuration mins)',
              ),
              _buildDetailRow(
                'Venue Mode',
                isOffice ? '🏢 At SARV MANGAL Office' : '🏡 At Your Place (Doorstep)',
              ),
              if (isOffice) ...[
                _buildDetailRow('Selected Kendra', office['name']!),
                _buildDetailRow('Address', office['address']!),
                _buildDetailRow('Office Phone', office['phone']!),
              ] else ...[
                _buildDetailRow('Your Address', '${_addressController.text}, ${_cityController.text} - ${_pincodeController.text}'),
                _buildDetailRow('Phone Number', _userPhoneController.text),
                _buildDetailRow('Reason', _consultationReasonController.text),
              ],
              _buildDetailRow('Assigned Pandit', 'Acharya Ramakant Shukla (Admin Allotted)'),
              _buildDetailRow('Consultation Fee', '₹${_getOfflinePrice(_offlineDuration)} (Payable at venue)'),
            ],
          ),
        ),

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              isHindi ? 'पूर्ण (Done)' : 'Done & Return',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8A7060),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3D2200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon}) {
    return TextField(
      controller: controller,
      style: GoogleFonts.lato(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060)),
        prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFFE65100)) : null,
        filled: true,
        fillColor: const Color(0xFFFAF6EE),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      ),
    );
  }
}
