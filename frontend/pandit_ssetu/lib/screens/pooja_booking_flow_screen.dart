import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../widgets/pooja_detail_modal.dart';
import '../services/api_service.dart';
import '../user_data.dart';
import '../utils/booking_date_time_helper.dart';
import 'package:geolocator/geolocator.dart';

class PoojaBookingFlowScreen extends StatefulWidget {
  final PoojaDetail pooja;
  final String bookingMode; // 'offline' or 'online'

  const PoojaBookingFlowScreen({
    super.key,
    required this.pooja,
    this.bookingMode = 'offline',
  });

  @override
  State<PoojaBookingFlowScreen> createState() => _PoojaBookingFlowScreenState();
}

class _PoojaBookingFlowScreenState extends State<PoojaBookingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final _streetController =
      TextEditingController(text: 'Flat 402, Lotus Heights');
  final _cityController = TextEditingController(text: 'Mumbai');
  final _pincodeController = TextEditingController(text: '400001');
  final _landmarkController = TextEditingController(text: 'Near City Park');

  // Online Fields
  final _onlineNameController =
      TextEditingController(text: UserData.name.isNotEmpty ? UserData.name : 'Rahul Sharma');
  final _onlineGotraController =
      TextEditingController(text: UserData.gotra.isNotEmpty ? UserData.gotra : 'Kashyap');
  final _onlinePhoneController =
      TextEditingController(text: UserData.phone.isNotEmpty ? UserData.phone : '+91 9876543210');
  String _onlinePlatform = 'Google Meet';
  String _selectedKitType = 'standard';

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = '09:30 AM';

  final List<String> _timeSlots = [
    '07:00 AM',
    '09:30 AM',
    '12:00 PM',
    '04:00 PM',
    '06:30 PM',
  ];

  bool _includeSamagriKit = true;

  bool get isOnlinePooja {
    final cat = widget.pooja.category.toLowerCase();
    final title = widget.pooja.title.toLowerCase();
    final id = widget.pooja.id.toLowerCase();
    return cat.contains('online') || title.contains('online') || id.contains('online');
  }

  bool get isOnlineMode =>
      widget.bookingMode.toLowerCase() == 'online' || isOnlinePooja;

  final List<String> _samagriItems = [
    'Pure Desi Cow Ghee (500g)',
    'Bhimseni Camphor & Pure Sandalwood Paste',
    'Fresh Lotus Flowers & Bilva Leaves',
    'Sacred Havan Samagri & 108 Herbs',
    'Copper Kalash, Coconut & Sacred Thread (Mauli)',
    'Turmeric, Kumkum & Aksata Grains',
  ];

  String _allocationMode = 'auto';
  List<Map<String, dynamic>> _nearbyPandits = [];
  Map<String, dynamic>? _selectedPandit;
  bool _isLoadingPandits = false;

  String _selectedPaymentMethod = 'upi';
  bool _isSubmitting = false;

  late Razorpay _razorpay;
  String? _activeBookingId;
  String? _activeOrderId;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadPandits();
  }

  Future<void> _loadPandits() async {
    setState(() => _isLoadingPandits = true);
    try {
      double? lat;
      double? lng;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          );
          lat = position.latitude;
          lng = position.longitude;
        }
      }

      final pandits = await ApiService.getNearbyPandits(lat: lat, lng: lng);
      if (mounted) {
        setState(() {
          _nearbyPandits = pandits;
          if (pandits.isNotEmpty) {
            _selectedPandit = pandits.first;
          }
          _isLoadingPandits = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading nearby pandits: $e');
      if (mounted) {
        setState(() => _isLoadingPandits = false);
      }
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _pageController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _landmarkController.dispose();
    _onlineNameController.dispose();
    _onlineGotraController.dispose();
    _onlinePhoneController.dispose();
    super.dispose();
  }

  double get _samagriCost {
    if (isOnlineMode) {
      return _selectedKitType == 'premium' ? 1050.0 : widget.pooja.samagriPrice;
    }
    if (!_includeSamagriKit || _selectedKitType == 'none') {
      return 0.0;
    }
    return _selectedKitType == 'premium' ? 1050.0 : widget.pooja.samagriPrice;
  }

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
    if (_isSubmitting) return;

    if (_selectedTimeSlot.trim().isEmpty) {
      _showErrorSnackBar('Please select a valid ritual time slot.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final bookingTimeIso = BookingDateTimeHelper.formatToIsoUtc(
        date: _selectedDate,
        timeSlot: _selectedTimeSlot,
      );

      final bookingData = {
        'poojaId': widget.pooja.id,
        'poojaTitle': widget.pooja.title,
        'bookingTime': bookingTimeIso,
        'address':
            '${_streetController.text}, ${_cityController.text} - ${_pincodeController.text}',
        'venueAddress':
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
        'mode': widget.bookingMode.toUpperCase(),
      };

      // 1. Create booking record on backend
      final response = await ApiService.createBooking(bookingData);
      final bookingId = response['data']?['booking']?['id'] ??
          response['data']?['id'];

      if (bookingId == null) {
        throw Exception('Server did not return a valid booking ID');
      }

      _activeBookingId = bookingId;

      // 2. Handle Payment Method
      if (_selectedPaymentMethod == 'pay_later') {
        // Devotee chose to offer Dakshina in Cash/UPI after the ritual completion
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog(bookingId, isCashPayLater: true);
        }
        return;
      }

      // 3. Initiate Razorpay Checkout for Advance Online Payment
      try {
        final order = await ApiService.createPaymentOrder(bookingId);
        final orderId = order['id']?.toString();
        final amount = order['amount'];

        if (orderId == null || amount == null) {
          throw Exception('Server failed to initialize payment order');
        }

        _activeOrderId = orderId;

        final razorpayKey = const String.fromEnvironment(
          'RAZORPAY_KEY_ID',
          defaultValue: 'rzp_test_placeholder',
        );

        final options = {
          'key': razorpayKey,
          'amount': amount,
          'name': 'SARV MANGAL Pooja',
          'description': widget.pooja.title,
          'order_id': orderId,
          'timeout': 180,
          'prefill': {
            'contact': UserData.phone.isNotEmpty ? UserData.phone : '+91 9876543210',
            'name': UserData.name.isNotEmpty ? UserData.name : 'Yajman',
          },
          'external': {
            'wallets': ['paytm']
          }
        };

        _razorpay.open(options);
      } catch (e) {
        // The booking IS genuinely persisted in PostgreSQL with PENDING status!
        debugPrint('Online payment gateway note: $e');
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog(bookingId, isPendingOnlinePayment: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // IMPORTANT: A client callback is NOT authoritative proof of payment!
    // We MUST verify signature on backend before showing confirmation.
    try {
      if (mounted) setState(() => _isSubmitting = true);

      final verifiedBooking = await ApiService.verifyPaymentSignature(
        orderId: response.orderId ?? _activeOrderId ?? '',
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        final paymentStatus = verifiedBooking['paymentStatus']?.toString().toUpperCase();
        final bookingStatus = verifiedBooking['status']?.toString().toUpperCase();

        if (paymentStatus == 'PAID' || bookingStatus == 'CONFIRMED') {
          _showSuccessDialog(_activeBookingId ?? 'PS-BK-CONFIRMED');
        } else {
          _showErrorSnackBar('Payment pending verification. Please check your bookings.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorSnackBar(
          'Payment verification failed: ${e.toString().replaceAll('Exception: ', '')}. Contact support with Payment ID: ${response.paymentId}',
        );
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
      final msg = isCancelled
          ? 'Payment cancelled. Your booking remains pending.'
          : 'Payment failed (${response.code}): ${response.message ?? 'Transaction could not be completed'}.';
      _showErrorSnackBar(msg);
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected external wallet: ${response.walletName}. Please complete payment in wallet app.',
            style: GoogleFonts.lato(color: Colors.white),
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.lato(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessDialog(String bookingId, {bool isCashPayLater = false, bool isPendingOnlinePayment = false}) {
    final String title = (isCashPayLater || isPendingOnlinePayment)
        ? 'Booking Request Recorded!'
        : 'Booking Confirmed!';
    final String subtitle = isCashPayLater
        ? 'Your ritual for ${widget.pooja.title} is recorded. You can offer Dakshina in cash or UPI directly to the Pandit after the ritual.'
        : (isPendingOnlinePayment
            ? 'Your ritual for ${widget.pooja.title} is recorded in the SARV MANGAL database. You can complete payment later from My Bookings or pay after the ritual.'
            : 'Your ritual for ${widget.pooja.title} has been successfully booked.');

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
              title,
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
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

            _buildStepperHeader(),

            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1LocationAndDate(),
                  _buildStep3PanditAllocation(),
                  _buildStep2SamagriToggle(),
                  _buildStep4OrderReviewAndPayment(),
                ],
              ),
            ),

            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    final steps = ['Details', 'Pandit', 'Items', 'Payment'];

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

  Widget _buildStep1LocationAndDate() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

        if (isOnlineMode)
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
                    const Icon(Icons.videocam, color: Color(0xFFE65100), size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Live E-Pooja & Sankalp Details',
                      style: GoogleFonts.lato(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildInputField('Devotee Name for Sankalp (संकल्प जातक)', _onlineNameController),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _buildInputField('Gotra (गोत्र)', _onlineGotraController)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildInputField('WhatsApp / Video Link Phone', _onlinePhoneController)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Preferred Video Platform:',
                  style: GoogleFonts.lato(fontSize: 12.5, fontWeight: FontWeight.bold, color: const Color(0xFF5A4A3A)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Google Meet', 'Zoom', 'WhatsApp Video'].map((plat) {
                    final isSel = _onlinePlatform == plat;
                    return ChoiceChip(
                      label: Text(plat),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setState(() => _onlinePlatform = plat);
                      },
                      selectedColor: const Color(0xFFE65100),
                      labelStyle: GoogleFonts.lato(
                        color: isSel ? Colors.white : const Color(0xFF1F2937),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          )
        else
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

  void _showSelectPoojaKitModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Container(
            padding: const EdgeInsets.all(22),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF6EE),
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4C2AA),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE65100).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.inventory_2, color: Color(0xFFE65100), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select the Pooja Kit',
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3D2200),
                            ),
                          ),
                          Text(
                            isOnlineMode
                                ? 'Consecrated Sacred Kit for Live E-Pooja'
                                : 'Choose sacred samagri kit for your ritual',
                            style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8A7060)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Option 1: Standard Vedic Kit
                GestureDetector(
                  onTap: () {
                    setModalState(() => _selectedKitType = 'standard');
                    setState(() {
                      _selectedKitType = 'standard';
                      _includeSamagriKit = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedKitType == 'standard' ? const Color(0xFFFFF3E0) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedKitType == 'standard' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                        width: _selectedKitType == 'standard' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedKitType == 'standard' ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Standard Vedic Pooja Kit',
                                    style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE65100),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'POPULAR',
                                      style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Complete Sacred Hawan herbs, Desi Ghee, Mauli, Kumkum & Akshat grains.',
                                style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFF6B5B52)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${widget.pooja.samagriPrice.toInt()}',
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFFE65100)),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Option 2: Premium Sanctum Gold Kit
                GestureDetector(
                  onTap: () {
                    setModalState(() => _selectedKitType = 'premium');
                    setState(() {
                      _selectedKitType = 'premium';
                      _includeSamagriKit = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedKitType == 'premium' ? const Color(0xFFFFF3E0) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedKitType == 'premium' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                        width: _selectedKitType == 'premium' ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedKitType == 'premium' ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: const Color(0xFFE65100),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premium Gold Vedic Kit',
                                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Adds Pure Silver Coin, Kashi Gangajal, Panchamrit, Lotus flowers & Purnahuti vastram.',
                                style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFF6B5B52)),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹1,050',
                          style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFFE65100)),
                        ),
                      ],
                    ),
                  ),
                ),

                if (!isOnlineMode) ...[
                  const SizedBox(height: 12),
                  // Option 3: Arrange Own Samagri
                  GestureDetector(
                    onTap: () {
                      setModalState(() => _selectedKitType = 'none');
                      setState(() {
                        _selectedKitType = 'none';
                        _includeSamagriKit = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedKitType == 'none' ? const Color(0xFFFFF3E0) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedKitType == 'none' ? const Color(0xFFE65100) : const Color(0xFFE5E7EB),
                          width: _selectedKitType == 'none' ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedKitType == 'none' ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: const Color(0xFFE65100),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Arrange My Own Items',
                                  style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  'I will prepare all sacred items before Pandit Ji arrives.',
                                  style: GoogleFonts.lato(fontSize: 11.5, color: const Color(0xFF6B5B52)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹0',
                            style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      _nextStep();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE65100),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Confirm Kit & Proceed to Payment',
                      style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStep2SamagriToggle() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (isOnlineMode)
          // ONLINE POOJA: User is NOT allowed to select items
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lock, color: Color(0xFF2E7D32), size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Online E-Pooja: Sacred Samagri Included',
                        style: GoogleFonts.lato(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'All sacred havan samagri, desi cow ghee, herbs, kalash, and offerings are consecrated and provided directly at the Vedic altar by the Acharya. Devotees are not allowed or required to select/unselect items.',
                        style: GoogleFonts.lato(
                          fontSize: 12,
                          color: const Color(0xFF2E7D32),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          // OFFLINE POOJA: User CAN select items whether to include or not
          GestureDetector(
            onTap: () {
              setState(() {
                _includeSamagriKit = !_includeSamagriKit;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _includeSamagriKit
                      ? const Color(0xFFE65100)
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
                          Icon(
                            _includeSamagriKit
                                ? Icons.shopping_bag
                                : Icons.shopping_bag_outlined,
                            color: _includeSamagriKit
                                ? const Color(0xFFE65100)
                                : Colors.grey,
                            size: 22,
                          ),
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
                                _includeSamagriKit
                                    ? '+₹${widget.pooja.samagriPrice.toInt()}'
                                    : 'Excluded (Bring Own Samagri)',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _includeSamagriKit
                                      ? const Color(0xFFE65100)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Switch(
                        value: _includeSamagriKit,
                        activeTrackColor: const Color(0xFFE65100),
                        activeThumbColor: Colors.white,
                        onChanged: (val) {
                          setState(() {
                            _includeSamagriKit = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _includeSamagriKit
                        ? 'Pandit Ji brings 100% pure, lab-tested, organic Samagri kit directly to your doorstep so you don\'t need to purchase anything.'
                        : 'You have chosen to arrange Samagri yourself. Please prepare all required sacred items before Pandit Ji arrives.',
                    style: GoogleFonts.lato(
                      fontSize: 12.5,
                      height: 1.45,
                      color: const Color(0xFF6B5B52),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // List of items in the Kit
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Items Included in Kit:',
                    style: GoogleFonts.lato(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  if (isOnlineMode)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LOCKED FOR ONLINE',
                        style: GoogleFonts.lato(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ..._samagriItems.map((item) {
                final bool isChecked = isOnlineMode || _includeSamagriKit;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(
                        isOnlineMode
                            ? Icons.verified
                            : (isChecked ? Icons.check_box : Icons.check_box_outline_blank),
                        color: isOnlineMode
                            ? const Color(0xFF2E7D32)
                            : (isChecked ? const Color(0xFFE65100) : Colors.grey),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            color: isChecked ? const Color(0xFF1F2937) : Colors.grey,
                            fontWeight: isOnlineMode ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

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

                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(left: 6, right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _allocationMode == 'auto' ? const Color(0xFFD97706) : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: _allocationMode == 'auto'
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        )
                      : null,
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

                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(left: 6, right: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _allocationMode == 'manual' ? const Color(0xFFD97706) : Colors.grey.shade400,
                      width: 2,
                    ),
                  ),
                  child: _allocationMode == 'manual'
                      ? Center(
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        )
                      : null,
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
          else if (_nearbyPandits.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFD97706)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No specific pandits nearby right now. Select "Auto Allocate" above to automatically match a verified Vedic Pandit.',
                      style: GoogleFonts.lato(fontSize: 12.5, color: const Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            )
          else
            ..._nearbyPandits.map((pandit) {
              final isSelected = _selectedPandit?['id'] == pandit['id'];
              final photoUrl = pandit['photoUrl']?.toString() ??
                  'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150';
              final name = pandit['name']?.toString() ?? 'Vedic Acharya';
              final experience = pandit['experience']?.toString() ?? 'Vedic Scholar';
              final rating = pandit['rating']?.toString() ?? '4.9 ★';
              final languages = pandit['languages']?.toString() ?? 'Sanskrit, Hindi';

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
                          photoUrl,
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
                              name,
                              style: GoogleFonts.lato(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$experience • $rating',
                              style: GoogleFonts.lato(
                                fontSize: 12,
                                color: const Color(0xFFD97706),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              languages,
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

  Widget _buildStep4OrderReviewAndPayment() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [

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

            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(left: 6, right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFD97706) : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

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
                        if (_currentStep == 2) {
                          _showSelectPoojaKitModal();
                        } else if (_currentStep < 3) {
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
