import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user_data.dart';
import '../services/language_service.dart';
import '../services/api_service.dart';

class HandmadeKundliOrderModal extends StatefulWidget {
  const HandmadeKundliOrderModal({super.key});

  @override
  State<HandmadeKundliOrderModal> createState() => _HandmadeKundliOrderModalState();
}

class _HandmadeKundliOrderModalState extends State<HandmadeKundliOrderModal> {
  int _step = 0; // 0 = form filling, 1 = review & submit, 2 = confirmed order details

  // Persistence State
  bool _isSubmitting = false;
  String? _submissionError;
  Map<String, dynamic>? _persistedOrder;

  // Form Fields
  final _nameController = TextEditingController(text: UserData.name.isNotEmpty ? UserData.name : 'Rahul Sharma');
  final _phoneController = TextEditingController(text: UserData.phone.isNotEmpty ? UserData.phone : '+91 9876543210');
  final _dobController = TextEditingController(text: UserData.dob.isNotEmpty ? UserData.dob : '24/05/1995');
  final _tobController = TextEditingController(text: UserData.tob.isNotEmpty ? UserData.tob : '09:30 AM');
  final _pobController = TextEditingController(text: UserData.pob.isNotEmpty ? UserData.pob : 'Varanasi, Uttar Pradesh');
  final _gotraController = TextEditingController(text: UserData.gotra.isNotEmpty ? UserData.gotra : 'Kashyap');
  final _addressController = TextEditingController(text: 'House 42, Anand Nagar, Ring Road, Varanasi - 221005');
  final _customConcernController = TextEditingController();

  String _kundliType = 'Patrika'; // 'Patrika' or 'Online Kundli'
  String _gender = 'Male';
  String _birthAccuracy = 'accurate'; // 'accurate' or 'approximate'
  String _language = 'Hindi';

  // Consultation concern categories reused
  final List<String> _concernCategories = [
    'Marriage & Kundli Dosha',
    'Career, Job & Business Growth',
    'Health, Family Peace & Prosperity',
    'Griha Vastu Dosha Remedy',
    'Child Education & Higher Studies',
    'Navagraha & Rahu-Ketu Shanti',
    'Others',
  ];
  String _selectedConcernCategory = 'Marriage & Kundli Dosha';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _pobController.dispose();
    _gotraController.dispose();
    _addressController.dispose();
    _customConcernController.dispose();
    super.dispose();
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
          // Drag bar
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Row(
              children: [
                if (_step == 1)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF3D2200)),
                    onPressed: () => setState(() => _step = 0),
                  ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE65100).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_graph, color: Color(0xFFE65100), size: 22),
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
                              isHindi ? 'हस्तनिर्मित कुंडली विवरण' : 'Handmade Kundali Details',
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
                              color: const Color(0xFFB45309),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'TRADITIONAL',
                              style: TextStyle(
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
                        'SARV MANGAL • सर्व मंगल',
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
          ),

          const Divider(height: 1, color: Color(0xFFEADBCA)),

          // Body steps
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildStepView(isHindi),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitKundliOrder() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _submissionError = null;
    });

    try {
      final name = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Rahul Sharma';
      final phone = _phoneController.text.replaceAll(RegExp(r'\s+'), '').trim().isNotEmpty
          ? _phoneController.text.replaceAll(RegExp(r'\s+'), '').trim()
          : '+919876543210';
      final dob = _dobController.text.trim().isNotEmpty ? _dobController.text.trim() : '1995-05-24';
      final tob = _tobController.text.trim().isNotEmpty ? _tobController.text.trim() : '09:30 AM';
      final pob = _pobController.text.trim().isNotEmpty ? _pobController.text.trim() : 'Varanasi, UP';
      final address = _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : 'House 42, Anand Nagar, Varanasi - 221005';

      final customNotes = _selectedConcernCategory == 'Others'
          ? _customConcernController.text.trim()
          : null;

      final Map<String, dynamic> body = {
        'devoteeName': name,
        'devoteePhone': phone.length >= 10 ? phone : '+919876543210',
        'gender': _gender,
        'dob': dob,
        'tob': tob,
        'pob': pob,
        'birthAccuracy': _birthAccuracy,
        'gotra': _gotraController.text.trim().isNotEmpty ? _gotraController.text.trim() : null,
        'language': _language,
        'deliveryAddress': address,
        'kundliType': _kundliType,
        'concernCategory': _selectedConcernCategory,
        'specialNotes': customNotes != null && customNotes.isNotEmpty ? customNotes : null,
      };

      final res = await ApiService.createKundliOrder(body);
      if (mounted) {
        setState(() {
          _persistedOrder = res;
          _isSubmitting = false;
          _step = 2;
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
            content: Text(_submissionError ?? 'Failed to submit Kundli order'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  Widget _buildStepView(bool isHindi) {
    switch (_step) {
      case 0:
        return _buildFormStep(isHindi);
      case 1:
        return _buildReviewStep(isHindi);
      case 2:
        return _buildConfirmationStep(isHindi);
      default:
        return _buildFormStep(isHindi);
    }
  }

  // --- STEP 0: FORM FILLING WITH ACCURACY SELECTOR ---
  Widget _buildFormStep(bool isHindi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Select Your Kundli Type
        Text(
          isHindi ? 'कुंडली का प्रकार चुनें' : 'Select Your Kundli Type',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _kundliType = 'Patrika'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kundliType == 'Patrika' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _kundliType == 'Patrika' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _kundliType == 'Patrika' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Patrika',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _kundliType == 'Patrika' ? const Color(0xFFE65100) : const Color(0xFF3D2200),
                            ),
                          ),
                          Icon(
                            _kundliType == 'Patrika' ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 18,
                            color: _kundliType == 'Patrika' ? const Color(0xFFE65100) : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(32 Page Kundli)',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A7060),
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
                onTap: () => setState(() => _kundliType = 'Online Kundli'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: _kundliType == 'Online Kundli' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _kundliType == 'Online Kundli' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _kundliType == 'Online Kundli' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Online Kundli',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _kundliType == 'Online Kundli' ? const Color(0xFFE65100) : const Color(0xFF3D2200),
                            ),
                          ),
                          Icon(
                            _kundliType == 'Online Kundli' ? Icons.radio_button_checked : Icons.radio_button_off,
                            size: 18,
                            color: _kundliType == 'Online Kundli' ? const Color(0xFFE65100) : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHindi ? '(डिजिटल प्रारूप)' : '(Digital PDF Chart)',
                        style: GoogleFonts.lato(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A7060),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        // Personal Details
        Text(
          isHindi ? '1. व्यक्तिगत जानकारी' : '1. Personal Details',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        _buildTextField('Full Name (जातक का पूरा नाम)', _nameController, icon: Icons.person),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Phone (फ़ोन नंबर)', _phoneController, icon: Icons.phone),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender (लिंग)',
                  labelStyle: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g, style: GoogleFonts.lato(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _gender = val);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Birth Details (DOB, TOB, POB)
        Text(
          isHindi ? '2. जन्म विवरण (Birth Details)' : '2. Exact Birth Details',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField('Date of Birth (DD/MM/YYYY)', _dobController, icon: Icons.calendar_today),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField('Time of Birth (HH:MM AM/PM)', _tobController, icon: Icons.access_time),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildTextField('Place of Birth (जन्म स्थान - City, State)', _pobController, icon: Icons.location_city),

        const SizedBox(height: 20),

        // CRITICAL REQUIREMENT: BIRTH TIME ACCURACY (Accurate vs Approximate)
        Text(
          isHindi ? '3. जन्म समय की सटीकता (Birthtime Accuracy)*' : '3. Birth Time Accuracy*',
          style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _birthAccuracy = 'accurate'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _birthAccuracy == 'accurate' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _birthAccuracy == 'accurate' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _birthAccuracy == 'accurate' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _birthAccuracy == 'accurate' ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: _birthAccuracy == 'accurate' ? const Color(0xFFE65100) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'सटीक (Accurate)' : 'Accurate',
                              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3D2200)),
                            ),
                            Text(
                              isHindi ? 'प्रमाणपत्र या घड़ी अनुसार' : 'Hospital or Watch Verified',
                              style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF8A7060)),
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
                onTap: () => setState(() => _birthAccuracy = 'approximate'),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _birthAccuracy == 'approximate' ? const Color(0xFFFFF3E0) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _birthAccuracy == 'approximate' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                      width: _birthAccuracy == 'approximate' ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _birthAccuracy == 'approximate' ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: _birthAccuracy == 'approximate' ? const Color(0xFFE65100) : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'अनुमानित (Approximate)' : 'Approximate',
                              style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFF3D2200)),
                            ),
                            Text(
                              isHindi ? 'सुबह/शाम का अनुमान' : 'Estimated Time Bracket',
                              style: GoogleFonts.lato(fontSize: 10, color: const Color(0xFF8A7060)),
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

        const SizedBox(height: 20),

        // Gotra & Language
        Row(
          children: [
            Expanded(
              child: _buildTextField('Gotra (गोत्र - यदि ज्ञात हो)', _gotraController, icon: Icons.family_restroom),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _language,
                decoration: InputDecoration(
                  labelText: 'Kundali Script',
                  labelStyle: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                ),
                items: ['Hindi', 'Sanskrit', 'English', 'Gujarati', 'Marathi']
                    .map((lang) => DropdownMenuItem(value: lang, child: Text(lang, style: GoogleFonts.lato(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _language = val);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        _buildTextField('Delivery Address (डाक पता जहां जन्मपत्री भेजी जाएगी)', _addressController, icon: Icons.home),
        const SizedBox(height: 12),

        // Select Your Concern
        Text(
          isHindi ? 'अपनी समस्या / विषय चुनें' : 'Select Your Concern',
          style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: _selectedConcernCategory,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            prefixIcon: const Icon(Icons.help_outline, size: 18, color: Color(0xFFE65100)),
          ),
          items: _concernCategories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, style: GoogleFonts.lato(fontSize: 13), overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedConcernCategory = val;
              });
            }
          },
        ),

        if (_selectedConcernCategory == 'Others') ...[
          const SizedBox(height: 10),
          _buildTextField(
            'Describe Your Specific Concern (विस्तार से लिखें) *',
            _customConcernController,
            icon: Icons.edit_note,
          ),
        ],

        const SizedBox(height: 24),

        // Continue to Booking Charge Payment
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedConcernCategory == 'Others' && _customConcernController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isHindi ? 'कृपया अपनी समस्या का विवरण लिखें' : 'Please describe your specific concern before proceeding.',
                      style: GoogleFonts.lato(color: Colors.white),
                    ),
                    backgroundColor: Colors.red.shade800,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              setState(() => _step = 1);
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
                  isHindi ? 'आगे बढ़ें • विवरण समीक्षा' : 'Proceed to Review Details',
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

  // --- STEP 1: REVIEW & SERVICE STATUS NOTICE ---
  Widget _buildReviewStep(bool isHindi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isHindi ? 'जन्म विवरण समीक्षा' : 'Review Birth Details',
          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'कृपया दर्ज किए गए विवरण की समीक्षा करें। प्रामाणिक हस्तलिखित जन्मपत्री वैदिक नियमों के अनुसार तैयार की जाती है।'
              : 'Please verify the details below. Authentic handwritten Janam Patri manuscripts are prepared according to Vedic rules.',
          style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B5B52)),
        ),

        const SizedBox(height: 18),

        // Summary of Birth Data
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
              Text(
                isHindi ? 'दर्ज विवरण सारांश' : 'Entered Birth Profile',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFE65100)),
              ),
              const SizedBox(height: 10),
              _buildMiniRow('Devotee Name', _nameController.text),
              _buildMiniRow('Phone Number', _phoneController.text),
              _buildMiniRow('Date & Time', '${_dobController.text} at ${_tobController.text}'),
              _buildMiniRow('Accuracy', _birthAccuracy == 'accurate' ? 'Accurate (सटीक)' : 'Approximate (अनुमानित)'),
              _buildMiniRow('Place of Birth', _pobController.text),
              _buildMiniRow('Script & Gotra', '$_language • ${_gotraController.text}'),
              _buildMiniRow('Delivery Address', _addressController.text),
              _buildMiniRow('Kundli Type', _kundliType == 'Patrika' ? 'Patrika (32 Page Kundli)' : 'Online Kundli'),
              _buildMiniRow('Concern Area', _selectedConcernCategory),
              if (_selectedConcernCategory == 'Others' && _customConcernController.text.trim().isNotEmpty)
                _buildMiniRow('Specific Concern', _customConcernController.text.trim()),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Service Notice Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'ऑनलाइन चेकआउट सेवा सूचना' : 'Online Ordering Unavailable',
                      style: GoogleFonts.lato(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi
                          ? 'हस्तलिखित जन्मपत्री हेतु स्वचालित भुगतान गेटवे एवं वरिष्ठ ज्योतिषाचार्य आवंटन प्रणाली वर्तमान में बैकएंड एकीकरण के अधीन है। ऑनलाइन चेकआउट अभी उपलब्ध नहीं है। व्यक्तिगत हस्तलिखित जन्मपत्री तैयार करवाने हेतु कृपया सारव मंगल मंदिर डेस्क से संपर्क करें।'
                          : 'Automated payment processing and senior astrologer allotment for physical handwritten Janam Patri are currently undergoing backend integration. Online orders are not accepted at this time. Please visit or contact the SARV MANGAL central temple desk for manual preparation.',
                      style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF78350F), height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Action Buttons
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
          height: 48,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitKundliOrder,
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
                : Text(
                    isHindi ? 'जन्मपत्री अनुरोध प्रस्तुत करें • ₹1,501' : 'Submit Kundli Request • ₹1,501',
                    style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 10),

        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton(
            onPressed: () => setState(() => _step = 0),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFE65100)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(
              isHindi ? 'विवरण संशोधित करें' : 'Edit Birth Details',
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
            ),
          ),
        ),

        const SizedBox(height: 8),

        SizedBox(
          width: double.infinity,
          height: 44,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              isHindi ? 'बंद करें (Close)' : 'Close',
              style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B5B52)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep(bool isHindi) {
    final orderNum = _persistedOrder?['orderNumber']?.toString() ?? 'KND-RECORDED';
    final status = _persistedOrder?['status']?.toString() ?? 'REQUESTED';
    final amount = _persistedOrder?['amount']?.toString() ?? '1501.00';

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
          isHindi ? 'हस्तनिर्मित जन्मपत्री अनुरोध पंजीकृत!' : 'Handmade Kundli Request Registered!',
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
              ? 'आपका अनुरोध डेटाबेस में सुरक्षित दर्ज हो चुका है। वरिष्ठ ज्योतिषाचार्यों द्वारा जन्म विवरण की समीक्षा की जाएगी।'
              : 'Your request is recorded in the SARV MANGAL database. Senior Vedic Acharyas will review the birth chart calculations.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B5B52)),
        ),
        const SizedBox(height: 20),

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
              _buildMiniRow('Order Reference', orderNum),
              _buildMiniRow('Status', '$status (Under Astrologer Review)'),
              _buildMiniRow('Devotee Name', _nameController.text),
              _buildMiniRow('Language', _language),
              _buildMiniRow('Amount Due', '₹$amount (Payable after desk approval)'),
              _buildMiniRow('Delivery Address', _addressController.text),
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
              style: GoogleFonts.lato(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.lato(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF8A7060)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF3D2200)),
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
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      ),
    );
  }
}
