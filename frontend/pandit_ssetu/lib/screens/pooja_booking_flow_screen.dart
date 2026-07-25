import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/pooja_detail_modal.dart';
import '../services/api_service.dart';
import '../user_data.dart';

class PoojaBookingFlowScreen extends StatefulWidget {
  final PoojaDetail pooja;

  const PoojaBookingFlowScreen({super.key, required this.pooja});

  @override
  State<PoojaBookingFlowScreen> createState() => _PoojaBookingFlowScreenState();
}

class _PoojaBookingFlowScreenState extends State<PoojaBookingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1: Location & Date
  final _streetController =
      TextEditingController(text: 'Flat 402, Lotus Heights');
  final _cityController = TextEditingController(text: 'Mumbai');
  final _pincodeController = TextEditingController(text: '400001');
  final _landmarkController = TextEditingController(text: 'Near City Park');
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:30 AM';

  final List<String> _timeSlots = [
    '07:00 AM',
    '09:30 AM',
    '12:00 PM',
    '04:00 PM',
    '06:30 PM',
  ];

  // Step 2: Samagri Add-on
  bool _includeSamagriKit = true;
  final List<String> _samagriItems = [
    'Pure Desi Cow Ghee (500g)',
    'Bhimseni Camphor & Pure Sandalwood Paste',
    'Fresh Lotus Flowers & Bilva Leaves',
    'Sacred Havan Samagri & 108 Herbs',
    'Copper Kalash, Coconut & Sacred Thread (Mauli)',
    'Turmeric, Kumkum & Aksata Grains',
  ];

  // Step 3: Pandit Allocation
  String _allocationMode = 'auto'; // 'auto' or 'manual'
  List<Map<String, dynamic>> _nearbyPandits = [];
  Map<String, dynamic>? _selectedPandit;
  bool _isLoadingPandits = false;

  // Step 4: Payment
  String _selectedPaymentMethod = 'upi'; // 'upi', 'card', 'pay_later'
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPandits();
  }

  Future<void> _loadPandits() async {
    setState(() => _isLoadingPandits = true);
    final pandits = await ApiService.getNearbyPandits();
    if (mounted) {
      setState(() {
        _nearbyPandits = pandits;
        if (pandits.isNotEmpty) {
          _selectedPandit = pandits.first;
        }
        _isLoadingPandits = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  double get _samagriCost =>
      _includeSamagriKit ? widget.pooja.samagriPrice : 0.0;
  double get _convenienceFee => 99.0;
  double get _totalPrice =>
      widget.pooja.standardPrice + _samagriCost + _convenienceFee;

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleConfirmAndPay() async {
    setState(() => _isSubmitting = true);

    final bookingData = {
      'poojaId': widget.pooja.id,
      'poojaTitle': widget.pooja.title,
      'address':
          '${_streetController.text}, ${_cityController.text} - ${_pincodeController.text}',
      'date':
          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
      'timeSlot': _selectedTimeSlot,
      'samagriIncluded': _includeSamagriKit,
      'allocationMode': _allocationMode,
      'panditName': _allocationMode == 'auto'
          ? 'Auto-Allocated Acharya'
          : (_selectedPandit?['name'] ?? 'Assigned Pandit'),
      'paymentMethod': _selectedPaymentMethod.toUpperCase(),
      'totalAmount': _totalPrice.toInt(),
      'userName': UserData.name.isNotEmpty ? UserData.name : 'Yajman',
      'userPhone': UserData.phone.isNotEmpty ? UserData.phone : '+91 9876543210',
    };

    final response = await ApiService.createBooking(bookingData);

    if (mounted) {
      setState(() => _isSubmitting = false);
      _showSuccessDialog(response['data']?['id'] ?? 'PS-BK-9901');
    }
  }

  void _showSuccessDialog(String bookingId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFFFAF6EE),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFD97706),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Booking Confirmed!',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ritual for ${widget.pooja.title} has been successfully booked.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(
                fontSize: 13,
                color: const Color(0xFF6B5B52),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFD97706).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Booking ID: $bookingId',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD97706),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go('/bookings');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'View My Bookings',
                  style: GoogleFonts.lato(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6EE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F2937)),
          onPressed: () {
            if (_currentStep > 0) {
              _prevStep();
            } else {
              context.pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Book Ritual',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            Text(
              widget.pooja.title,
              style: GoogleFonts.lato(
                fontSize: 12,
                color: const Color(0xFFD97706),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Progress Stepper
            _buildStepperHeader(),

            // Step Content PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1LocationAndDate(),
                  _buildStep2SamagriToggle(),
                  _buildStep3PanditAllocation(),
                  _buildStep4OrderReviewAndPayment(),
                ],
              ),
            ),

            // Bottom Sticky Price Summary & Actions
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  // Top Stepper Header Widget
  Widget _buildStepperHeader() {
    final steps = ['Address', 'Samagri', 'Pandit', 'Payment'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(steps.length, (index) {
          final isCompleted = _currentStep > index;
          final isCurrent = _currentStep == index;

          return Expanded(
            child: Row(
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isCompleted || isCurrent
                            ? const Color(0xFFD97706)
                            : const Color(0xFFE5E7EB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : Text(
                                '${index + 1}',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCurrent
                                      ? Colors.white
                                      : const Color(0xFF6B7280),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[index],
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent
                            ? const Color(0xFFD97706)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
                if (index < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
                      color: isCompleted
                          ? const Color(0xFFD97706)
                          : const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ----------------------------------------------------
  // STEP 1: Location & Date Selection
  // ----------------------------------------------------
  Widget _buildStep1LocationAndDate() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Address Card
        Container(
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
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Pooja Location Address',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildInputField('Street Address / House No.', _streetController),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _buildInputField('City', _cityController)),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _buildInputField('Postal Code', _pincodeController)),
                ],
              ),
              const SizedBox(height: 10),
              _buildInputField('Landmark (Optional)', _landmarkController),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Date & Time Card
        Container(
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
                children: [
                  const Icon(Icons.calendar_today,
                      color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Select Ritual Date & Time',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Date Picker Selector
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: Color(0xFFD97706),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF6EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.event,
                              color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: GoogleFonts.lato(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Change Date >',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Text(
                'Available Muhurat Time Slots',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 10),

              // Time Slot Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final isSelected = _selectedTimeSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedTimeSlot = slot);
                      }
                    },
                    selectedColor: const Color(0xFFD97706),
                    backgroundColor: const Color(0xFFFAF6EE),
                    labelStyle: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1F2937),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFFD97706)
                            : const Color(0xFFE5E7EB),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: GoogleFonts.lato(fontSize: 14, color: const Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B7280)),
        filled: true,
        fillColor: const Color(0xFFFAF6EE),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD97706)),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // STEP 2: Samagri Add-on Toggle
  // ----------------------------------------------------
  Widget _buildStep2SamagriToggle() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Main Toggle Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _includeSamagriKit
                  ? const Color(0xFFD97706)
                  : const Color(0xFFE5E7EB),
              width: _includeSamagriKit ? 2 : 1,
            ),
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
                  Row(
                    children: [
                      const Icon(Icons.shopping_bag,
                          color: Color(0xFFD97706), size: 22),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pure Vedic Samagri Kit',
                            style: GoogleFonts.lato(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '+₹${widget.pooja.samagriPrice.toInt()}',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // ignore: deprecated_member_use
                  Switch(
                    value: _includeSamagriKit,
                    // ignore: deprecated_member_use
                    activeColor: const Color(0xFFD97706),
                    onChanged: (val) {
                      setState(() => _includeSamagriKit = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'When enabled, Pandit Ji brings 100% pure, lab-tested, organic samagri kit directly to your doorstep. You don\'t need to purchase anything.',
                style: GoogleFonts.lato(
                  fontSize: 12.5,
                  height: 1.45,
                  color: const Color(0xFF6B5B52),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Kit Contents Checklist
        Container(
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
              Text(
                'Items Included in Kit:',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              ..._samagriItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          _includeSamagriKit
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: _includeSamagriKit
                              ? const Color(0xFFD97706)
                              : Colors.grey,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: _includeSamagriKit
                                  ? const Color(0xFF1F2937)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // STEP 3: Pandit Allocation Method
  // ----------------------------------------------------
  Widget _buildStep3PanditAllocation() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Select Pandit Allocation Method',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),

        // Auto Option
        GestureDetector(
          onTap: () => setState(() => _allocationMode = 'auto'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _allocationMode == 'auto'
                    ? const Color(0xFFD97706)
                    : const Color(0xFFE5E7EB),
                width: _allocationMode == 'auto' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // ignore: deprecated_member_use
                Radio<String>(
                  value: 'auto',
                  // ignore: deprecated_member_use
                  groupValue: _allocationMode,
                  activeColor: const Color(0xFFD97706),
                  // ignore: deprecated_member_use
                  onChanged: (val) =>
                      setState(() => _allocationMode = val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Automatic Allocation',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'RECOMMENDED',
                              style: GoogleFonts.lato(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'System automatically pairs highest-rated nearby Acharya based on your location.',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF6B5B52),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Manual Option
        GestureDetector(
          onTap: () => setState(() => _allocationMode = 'manual'),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _allocationMode == 'manual'
                    ? const Color(0xFFD97706)
                    : const Color(0xFFE5E7EB),
                width: _allocationMode == 'manual' ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // ignore: deprecated_member_use
                Radio<String>(
                  value: 'manual',
                  // ignore: deprecated_member_use
                  groupValue: _allocationMode,
                  activeColor: const Color(0xFFD97706),
                  // ignore: deprecated_member_use
                  onChanged: (val) =>
                      setState(() => _allocationMode = val!),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Pandit Manually',
                        style: GoogleFonts.lato(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Browse verified profiles, ratings, and languages to choose your preferred Acharya.',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF6B5B52),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expanded Pandit Selection List
        if (_allocationMode == 'manual') ...[
          const SizedBox(height: 18),
          Text(
            'Nearby Available Pandits:',
            style: GoogleFonts.lato(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 10),

          if (_isLoadingPandits)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: Color(0xFFD97706)),
              ),
            )
          else
            ..._nearbyPandits.map((pandit) {
              final isSelected = _selectedPandit?['id'] == pandit['id'];
              return GestureDetector(
                onTap: () => setState(() => _selectedPandit = pandit),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFD97706)
                          : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.network(
                          pandit['photoUrl'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(

                            width: 50,
                            height: 50,
                            color: const Color(0xFFFFF3E0),
                            child: const Icon(Icons.person,
                                color: Color(0xFFD97706)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pandit['name'],
                              style: GoogleFonts.lato(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${pandit['experience']} • ${pandit['rating']}',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: const Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              pandit['languages'],
                              style: GoogleFonts.lato(
                                fontSize: 11.5,
                                color: const Color(0xFF6B5B52),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle,
                            color: Color(0xFFD97706), size: 22),
                    ],
                  ),
                ),
              );
            }),
        ],
      ],
    );
  }

  // ----------------------------------------------------
  // STEP 4: Order Review & Payment Gateway
  // ----------------------------------------------------
  Widget _buildStep4OrderReviewAndPayment() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary Card
        Container(
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
              Text(
                'Booking Summary',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              _summaryRow('Selected Pooja', widget.pooja.title),
              _summaryRow('Date & Time',
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at $_selectedTimeSlot'),
              _summaryRow('Location',
                  '${_streetController.text}, ${_cityController.text}'),
              _summaryRow('Pandit Choice',
                  _allocationMode == 'auto' ? 'Auto Allocation' : (_selectedPandit?['name'] ?? 'Selected Acharya')),
              _summaryRow('Vedic Samagri Kit',
                  _includeSamagriKit ? 'Included (+₹${widget.pooja.samagriPrice.toInt()})' : 'Not Included'),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Price Breakdown Card
        Container(
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
              Text(
                'Price Breakdown',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              _priceRow('Pooja Dakshina Fee', '₹${widget.pooja.standardPrice.toInt()}'),
              if (_includeSamagriKit)
                _priceRow('Samagri Kit Fee', '₹${widget.pooja.samagriPrice.toInt()}'),
              _priceRow('Service & Support Fee', '₹${_convenienceFee.toInt()}'),
              const Divider(color: Color(0xFFE5E7EB), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Payable',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  Text(
                    '₹${_totalPrice.toInt()}',
                    style: GoogleFonts.lato(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Payment Options Card
        Container(
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
              Text(
                'Select Payment Method',
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              _paymentOptionTile(
                  'upi', 'UPI (Google Pay / PhonePe / Paytm)', Icons.account_balance_wallet),
              _paymentOptionTile('card', 'Credit / Debit Card', Icons.credit_card),
              _paymentOptionTile(
                  'pay_later', 'Pay After Pooja (Cash / UPI)', Icons.handshake),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.lato(
                  fontSize: 12.5, color: const Color(0xFF6B5B52))),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.lato(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.lato(
                  fontSize: 13, color: const Color(0xFF6B5B52))),
          Text(amount,
              style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937))),
        ],
      ),
    );
  }

  Widget _paymentOptionTile(String value, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : const Color(0xFFFAF6EE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD97706)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected
                    ? const Color(0xFFD97706)
                    : const Color(0xFF6B5B52),
                size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            // ignore: deprecated_member_use
            Radio<String>(
              value: value,
              // ignore: deprecated_member_use
              groupValue: _selectedPaymentMethod,
              activeColor: const Color(0xFFD97706),
              // ignore: deprecated_member_use
              onChanged: (val) =>
                  setState(() => _selectedPaymentMethod = val!),
            ),
          ],
        ),
      ),
    );
  }

  // Dynamic Sticky Bottom Bar
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.lato(
                  fontSize: 11,
                  color: const Color(0xFF6B5B52),
                ),
              ),
              Text(
                '₹${_totalPrice.toInt()}',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFD97706),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        if (_currentStep < 3) {
                          _nextStep();
                        } else {
                          _handleConfirmAndPay();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep < 3
                                ? 'Next Step'
                                : 'Confirm & Pay ₹${_totalPrice.toInt()}',
                            style: GoogleFonts.lato(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
