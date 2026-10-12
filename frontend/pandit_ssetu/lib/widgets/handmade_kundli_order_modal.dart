import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../user_data.dart';
import '../services/language_service.dart';

class HandmadeKundliOrderModal extends StatefulWidget {
  const HandmadeKundliOrderModal({super.key});

  @override
  State<HandmadeKundliOrderModal> createState() => _HandmadeKundliOrderModalState();
}

class _HandmadeKundliOrderModalState extends State<HandmadeKundliOrderModal> {
  int _step = 0; // 0 = form filling, 1 = payment of booking charge, 2 = admin allotment confirmed

  // Form Fields
  final _nameController = TextEditingController(text: UserData.name.isNotEmpty ? UserData.name : 'Rahul Sharma');
  final _phoneController = TextEditingController(text: UserData.phone.isNotEmpty ? UserData.phone : '+91 9876543210');
  final _dobController = TextEditingController(text: UserData.dob.isNotEmpty ? UserData.dob : '24/05/1995');
  final _tobController = TextEditingController(text: UserData.tob.isNotEmpty ? UserData.tob : '09:30 AM');
  final _pobController = TextEditingController(text: UserData.pob.isNotEmpty ? UserData.pob : 'Varanasi, Uttar Pradesh');
  final _gotraController = TextEditingController(text: UserData.gotra.isNotEmpty ? UserData.gotra : 'Kashyap');
  final _addressController = TextEditingController(text: 'House 42, Anand Nagar, Ring Road, Varanasi - 221005');
  final _specialNotesController = TextEditingController(text: 'Focus on career growth, business hurdles, and favorable marriage timing.');

  String _gender = 'Male';
  String _birthAccuracy = 'accurate'; // 'accurate' or 'approximate'
  String _language = 'Hindi';
  String _paymentOption = 'token'; // 'token' (₹251) or 'full' (₹1,501)
  String _paymentMethod = 'upi';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _tobController.dispose();
    _pobController.dispose();
    _gotraController.dispose();
    _addressController.dispose();
    _specialNotesController.dispose();
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
                              _step == 2
                                  ? (isHindi ? 'पंडित आवंटन पुष्टि' : 'Pandit Allotment Confirmed')
                                  : (isHindi ? 'हस्तनिर्मित कुंडली आर्डर' : 'Order Handmade Kundali'),
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
                        'SARV MANGALS • सर्व मंगल',
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

  Widget _buildStepView(bool isHindi) {
    switch (_step) {
      case 0:
        return _buildFormStep(isHindi);
      case 1:
        return _buildPaymentStep(isHindi);
      case 2:
        return _buildAllotmentConfirmedStep(isHindi);
      default:
        return _buildFormStep(isHindi);
    }
  }

  // --- STEP 0: FORM FILLING WITH ACCURACY SELECTOR ---
  Widget _buildFormStep(bool isHindi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Intro Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF3E7D3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.menu_book, color: Color(0xFFE65100), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isHindi
                      ? '32 पृष्ठों की प्रामाणिक हस्तलिखित जन्मपत्री। कृपया सटीक जन्म विवरण दर्ज करें।'
                      : '32-Page traditional hand-drawn Janam Patri by senior Kashi astrologers. Please provide birth details.',
                  style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF5A4A3A)),
                ),
              ),
            ],
          ),
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
        _buildTextField('Specific Questions / Concerns for Jyotish Acharya', _specialNotesController, icon: Icons.help_outline),

        const SizedBox(height: 24),

        // Continue to Booking Charge Payment
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
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
                  isHindi ? 'आगे बढ़ें • बुकिंग शुल्क भुगतान' : 'Proceed to Booking Charge Payment',
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

  // --- STEP 1: BOOKING CHARGE PAYMENT ---
  Widget _buildPaymentStep(bool isHindi) {
    final int amount = _paymentOption == 'token' ? 251 : 1501;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          isHindi ? 'बुकिंग शुल्क का भुगतान करें' : 'Pay Booking Charge',
          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'आर्डर डेटा व्यवस्थापक को भेजा जाएगा और वरिष्ठ पंडित जी को हस्तलेखन के लिए सौंपा जाएगा।'
              : 'Your birth data will be sent to the admin, and a senior Acharya will be allotted.',
          style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B5B52)),
        ),

        const SizedBox(height: 20),

        // Payment Option Selector (Token ₹251 vs Full ₹1,501)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEADBCA)),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _paymentOption = 'token'),
                child: Row(
                  children: [
                    Icon(
                      _paymentOption == 'token' ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pay Booking Token Charge (₹251)',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            'Reserve Senior Pandit allotment. Balance ₹1,250 payable on delivery.',
                            style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹251',
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFE65100)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24),
              GestureDetector(
                onTap: () => setState(() => _paymentOption = 'full'),
                child: Row(
                  children: [
                    Icon(
                      _paymentOption == 'full' ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pay Full Janam Patri Fee (₹1,501)',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          Text(
                            'Includes 32-page handwritten book, wooden box packaging & free postal courier.',
                            style: GoogleFonts.lato(fontSize: 11, color: const Color(0xFF8A7060)),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹1,501',
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFFE65100)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Summary of Birth Data sent to Admin
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
                'Summary Sent to Admin Panel',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 13, color: const Color(0xFFE65100)),
              ),
              const SizedBox(height: 8),
              _buildMiniRow('Devotee Name', _nameController.text),
              _buildMiniRow('Date & Time', '${_dobController.text} at ${_tobController.text}'),
              _buildMiniRow('Accuracy', _birthAccuracy == 'accurate' ? 'Accurate (सटीक)' : 'Approximate (अनुमानित)'),
              _buildMiniRow('Place of Birth', _pobController.text),
              _buildMiniRow('Script & Gotra', '$_language • ${_gotraController.text}'),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Payment Method Selector
        Text(
          isHindi ? 'भुगतान विधि चुनें' : 'Select Payment Method',
          style: GoogleFonts.lato(fontSize: 13.5, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildPayMethodTile('upi', 'UPI / GPay', Icons.account_balance_wallet),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPayMethodTile('card', 'Cards', Icons.credit_card),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPayMethodTile('netbanking', 'Net Banking', Icons.account_balance),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Pay & Submit Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    await Future.delayed(const Duration(milliseconds: 900));
                    if (mounted) {
                      setState(() {
                        _isSubmitting = false;
                        _step = 2; // Jump to Pandit Allotment Confirmed step!
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE65100),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(
                    isHindi ? '₹$amount भुगतान करें एवं आर्डर भेजें' : 'Pay ₹$amount & Send to Admin',
                    style: GoogleFonts.lato(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayMethodTile(String id, String label, IconData icon) {
    final isSel = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSel ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSel ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
            width: isSel ? 1.8 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSel ? const Color(0xFFE65100) : const Color(0xFF8A7060), size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSel ? const Color(0xFFE65100) : const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- STEP 2: ADMIN PANDIT ALLOTMENT CONFIRMED ---
  Widget _buildAllotmentConfirmedStep(bool isHindi) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 42),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          isHindi ? 'हस्तनिर्मित कुंडली आर्डर स्वीकृत!' : 'Handmade Kundali Order Placed!',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
        ),
        const SizedBox(height: 6),
        Text(
          isHindi
              ? 'जन्म विवरण व्यवस्थापक को प्राप्त हो गया है एवं वरिष्ठ पंडित जी आवंटित कर दिए गए हैं।'
              : 'User birth data received by admin. Senior Vedic Pandit has been alloted.',
          textAlign: TextAlign.center,
          style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B5B52)),
        ),

        const SizedBox(height: 20),

        // ALLOTTED PANDIT CARD
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE65100).withValues(alpha: 0.3)),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'PANDIT ALLOTTED BY ADMIN',
                      style: GoogleFonts.lato(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  Text(
                    'Order #SMG-HK-8842',
                    style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFE65100)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE65100), width: 1.8),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/pandit_2.jpeg',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: const Color(0xFFFFF3E0),
                          child: const Icon(Icons.person, color: Color(0xFFE65100), size: 30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pt. Rameshwar Sharma Shastri',
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF3D2200)),
                        ),
                        Text(
                          'Senior Jyotish Ratna • Sampurnanand Sanskrit University',
                          style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFF8A7060)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Status: Preparing Handwritten Janam Patri Manuscript',
                          style: GoogleFonts.lato(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF2E7D32)),
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

        // Order Timeline Summary
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
              _buildMiniRow('Devotee Name', _nameController.text),
              _buildMiniRow('Birth Accuracy', _birthAccuracy == 'accurate' ? 'Accurate (सटीक)' : 'Approximate (अनुमानित)'),
              _buildMiniRow('Booking Paid', '₹${_paymentOption == 'token' ? 251 : 1501}'),
              _buildMiniRow('Delivery Address', _addressController.text),
              _buildMiniRow('Expected Dispatch', 'Within 5-7 business days via Speed Post'),
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
