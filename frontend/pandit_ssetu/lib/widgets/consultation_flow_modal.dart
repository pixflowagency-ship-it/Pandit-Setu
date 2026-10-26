import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';

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

  // --- PERSISTENCE STATE ---
  bool _isSubmitting = false;
  String? _submissionError;
  Map<String, dynamic>? _persistedConsultation;

  // --- ONLINE STATE ---
  String _onlineTiming = 'immediate'; // 'immediate' or 'schedule'
  int _selectedDuration = 15; // 15, 30, 60 minutes
  String _onlineMedium = 'phone'; // 'phone' or 'meet'
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  String _scheduledTimeSlot = '11:30 AM';
  final _userNameController = TextEditingController(text: 'Yajman Devotee');
  final _userPhoneController = TextEditingController(text: '+91 98765 43210');
  String _selectedTopic = 'Marriage & Kundli Dosha';
  final _customTopicController = TextEditingController();

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
    'Others',
  ];

  final List<String> _timeSlots = [
    '09:00 AM',
    '11:00 AM',
    '11:30 AM',
    '02:00 PM',
    '04:30 PM',
    '06:30 PM',
    '08:00 PM',
  ];

  String get _safeScheduledTimeSlot {
    if (_timeSlots.contains(_scheduledTimeSlot)) {
      return _scheduledTimeSlot;
    }
    return _timeSlots.isNotEmpty ? _timeSlots.first : '11:00 AM';
  }

  String get _safeOfflineTimeSlot {
    if (_timeSlots.contains(_offlineTimeSlot)) {
      return _offlineTimeSlot;
    }
    return _timeSlots.isNotEmpty ? _timeSlots.first : '11:00 AM';
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _userPhoneController.dispose();
    _customTopicController.dispose();
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

  Future<void> _submitOnlineConsultation() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final name = _userNameController.text.trim().isNotEmpty
          ? _userNameController.text.trim()
          : 'Devotee';
      final phone = _userPhoneController.text.replaceAll(RegExp(r'\s+'), '').trim().isNotEmpty
          ? _userPhoneController.text.replaceAll(RegExp(r'\s+'), '').trim()
          : '+919876543210';

      final customTopic = _customTopicController.text.trim();
      final effectiveTopic = _selectedTopic == 'Others'
          ? (customTopic.isNotEmpty ? 'Others: $customTopic' : 'Others')
          : _selectedTopic;

      final Map<String, dynamic> body = {
        'type': 'ONLINE',
        'timing': _onlineTiming == 'immediate' ? 'IMMEDIATE' : 'SCHEDULED',
        'medium': _onlineMedium == 'meet' ? 'VIDEO' : 'PHONE',
        'topic': effectiveTopic,
        'durationMinutes': _selectedDuration,
        'devoteeName': name,
        'devoteePhone': phone.length >= 10 ? phone : '+919876543210',
        'requestedDate': _onlineTiming == 'immediate'
            ? DateTime.now().toUtc().toIso8601String()
            : _scheduledDate.toUtc().toIso8601String(),
        'requestedTimeSlot': _onlineTiming == 'immediate' ? 'Immediate' : _safeScheduledTimeSlot,
      };

      final res = await ApiService.createConsultation(body);
      if (mounted) {
        setState(() {
          _persistedConsultation = res;
          _isSubmitting = false;
          _currentView = 3;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_submissionError ?? 'Failed to submit consultation'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Future<void> _submitOfflineConsultation() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final name = _userNameController.text.trim().isNotEmpty
          ? _userNameController.text.trim()
          : 'Devotee';
      final phone = _userPhoneController.text.replaceAll(RegExp(r'\s+'), '').trim().isNotEmpty
          ? _userPhoneController.text.replaceAll(RegExp(r'\s+'), '').trim()
          : '+919876543210';

      final isOffice = _offlinePlaceChoice == 'office';
      final office = _sarvMangalOffices[_selectedOfficeIndex];

      final Map<String, dynamic> body = {
        'type': 'OFFLINE',
        'timing': 'SCHEDULED',
        'medium': 'IN_PERSON',
        'topic': _consultationReasonController.text.trim().isNotEmpty
            ? _consultationReasonController.text.trim()
            : 'Griha Vastu Dosha Remedy',
        'durationMinutes': _offlineDuration,
        'devoteeName': name,
        'devoteePhone': phone.length >= 10 ? phone : '+919876543210',
        'requestedDate': _offlineDate.toUtc().toIso8601String(),
        'requestedTimeSlot': _safeOfflineTimeSlot,
        'venueAddress': isOffice
            ? null
            : '${_addressController.text.trim()}, ${_cityController.text.trim()} - ${_pincodeController.text.trim()}',
        'kendraName': isOffice ? office['name'] : null,
        'notes': _consultationReasonController.text.trim(),
      };

      final res = await ApiService.createConsultation(body);
      if (mounted) {
        setState(() {
          _persistedConsultation = res;
          _isSubmitting = false;
          _currentView = 4;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _submissionError = e.toString().replaceAll('Exception: ', '');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_submissionError ?? 'Failed to submit offline consultation'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
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
    String subtitle = 'SARV MANGAL • सर्व मंगल';

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
          if (_currentView != 0 && _currentView != 3 && _currentView != 4) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(Icons.arrow_back, color: Color(0xFF3D2200), size: 22),
              onPressed: () => setState(() => _currentView = 0),
            ),
            const SizedBox(width: 6),
          ],
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 2,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3D2200),
                      ),
                    ),
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
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.close, color: Color(0xFF8A7060), size: 20),
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
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 2,
                        children: [
                          Text(
                            isHindi ? 'ऑनलाइन परामर्श' : 'Online Consultation',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3D2200),
                            ),
                          ),
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
                const SizedBox(width: 8),
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
                        isHindi ? 'ऑफलाइन परामर्श' : 'Offline Consultation',
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
                const SizedBox(width: 8),
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
                  initialValue: _safeScheduledTimeSlot,
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
          isExpanded: true,
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
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(
                      t,
                      style: GoogleFonts.lato(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedTopic = val);
          },
        ),

        if (_selectedTopic == 'Others') ...[
          const SizedBox(height: 10),
          TextFormField(
            controller: _customTopicController,
            decoration: InputDecoration(
              hintText: isHindi
                  ? 'कृपया अपना विषय बताएं (वैकल्पिक)...'
                  : 'Specify your topic / concern (e.g. Ancestral peace, spiritual guidance)...',
              labelText: isHindi ? 'विशिष्ट विषय' : 'Custom Topic Details',
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
              ),
            ),
            style: GoogleFonts.lato(fontSize: 13),
            maxLines: 2,
            minLines: 1,
          ),
        ],

        const SizedBox(height: 24),

        // Action CTA
        if (_submissionError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _submissionError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitOnlineConsultation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _onlineTiming == 'immediate'
                              ? (isHindi ? 'तत्काल पंडित जी से जुड़ें • ₹${_getPrice(_selectedDuration)}' : 'Connect to Pandit Ji • ₹${_getPrice(_selectedDuration)}')
                              : (isHindi ? 'शेड्यूल कन्फर्म करें • ₹${_getPrice(_selectedDuration)}' : 'Confirm Schedule • ₹${_getPrice(_selectedDuration)}'),
                          style: GoogleFonts.lato(fontSize: 14.5, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
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
                initialValue: _safeOfflineTimeSlot,
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

        // 3. Place Selection: At SARV MANGAL Office vs At Your Place
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
          // LIST OF NEAREST SARV MANGAL OFFICES
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
        if (_submissionError != null) ...[
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _submissionError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitOfflineConsultation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isHindi
                              ? 'ऑफलाइन परामर्श बुक करें • ₹${_getOfflinePrice(_offlineDuration)}'
                              : 'Book Offline Consultation • ₹${_getOfflinePrice(_offlineDuration)}',
                          style: GoogleFonts.lato(fontSize: 14.5, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
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

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Consultation Request Status Card
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
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFE65100), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'CONSULTATION REQUEST SUBMITTED',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE65100),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isHindi
                    ? 'ऑनलाइन परामर्श अनुरोध पंजीकृत'
                    : 'Online Consultation Request Logged',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3D2200),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHindi
                    ? 'स्वचालित वीडियो एवं फ़ोन कॉल ब्रिज वर्तमान में बैकएंड एकीकरण के अधीन है। आपका अनुरोध केंद्रीय व्यवस्थापक को प्राप्त हो गया है। परामर्श समय से पूर्व हमारे प्रतिनिधि आपसे संपर्क करेंगे।'
                    : 'Automated video call and phone routing are currently undergoing server-side bridge integration. Your appointment request has been recorded. Our central desk will contact you via phone prior to the slot.',
                textAlign: TextAlign.center,
                style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF6B5B52), height: 1.35),
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
              if (_persistedConsultation != null) ...[
                _buildDetailRow('Consultation ID', _persistedConsultation!['consultationNumber']?.toString() ?? 'CNS-RECORDED'),
                _buildDetailRow('Status', _persistedConsultation!['status']?.toString() ?? 'REQUESTED'),
              ],
              _buildDetailRow(
                'Topic',
                _selectedTopic == 'Others'
                    ? (_customTopicController.text.trim().isNotEmpty
                        ? 'Others: ${_customTopicController.text.trim()}'
                        : 'Others')
                    : _selectedTopic,
              ),
              _buildDetailRow('Duration', '$_selectedDuration Minutes (₹${_getPrice(_selectedDuration)})'),
              _buildDetailRow(
                'Schedule',
                isImmediate
                    ? 'Immediate (Coordination pending)'
                    : '${_scheduledDate.day}/${_scheduledDate.month}/${_scheduledDate.year} at $_scheduledTimeSlot',
              ),
              _buildDetailRow(
                'Medium',
                isMeet ? '📹 Google Meet (Video Call)' : '📞 Direct Phone Call (Audio)',
              ),
              _buildDetailRow('Devotee Name', _userNameController.text),
              _buildDetailRow('Contact Phone', _userPhoneController.text),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Central Helpdesk Card
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
                'SARV MANGAL Central Coordination Helpline',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3D2200)),
              ),
              const SizedBox(height: 6),
              Text(
                'Phone: +91 734 2551234 • Email: desk@sarvmangal.org',
                style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF6B5B52)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isHindi ? 'पूर्ण एवं बंद करें' : 'Done & Close',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
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
          isHindi ? 'ऑफलाइन परामर्श अनुरोध दर्ज!' : 'Offline Consultation Request Registered!',
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
              ? 'आपका अनुरोध दर्ज कर लिया गया है। व्यवस्थापक द्वारा आचार्य उपलब्धता की पुष्टि हेतु संपर्क किया जाएगा।'
              : 'Your request has been registered. Temple administration will verify Acharya schedule and confirm your appointment.',
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
              if (_persistedConsultation != null) ...[
                _buildDetailRow('Consultation ID', _persistedConsultation!['consultationNumber']?.toString() ?? 'CNS-RECORDED'),
                _buildDetailRow('Request Status', _persistedConsultation!['status']?.toString() ?? 'REQUESTED'),
              ] else ...[
                _buildDetailRow('Request Status', 'Pending Desk Confirmation'),
              ],
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
              _buildDetailRow('Acharya Allotment', 'Coordinated by Kendra Desk'),
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
