import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../widgets/incoming_pooja_request_modal.dart';

class PanditDashboardScreen extends StatefulWidget {
  const PanditDashboardScreen({super.key});

  @override
  State<PanditDashboardScreen> createState() => _PanditDashboardScreenState();
}

class _PanditDashboardScreenState extends State<PanditDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isOnline = false;
  bool _isTogglingDuty = false;
  bool _hasIncomingRequest = false;
  final Set<String> _dismissedBookingIds = {};
  Map<String, dynamic>? _incomingRequestPayload;
  socket_io.Socket? _socket;
  Timer? _telemetryTimer;

  // Duty Execution Flow States: none, confirmed, heading_to_venue, arrived, pooja_in_progress, completed
  String _dutyState = 'none';
  String? _activeBookingId;
  Map<String, dynamic>? _activeBooking;
  bool _isUpdatingStatus = false;

  // Dakshina Collection & Booking Closure state (Phase P2-B Task 6)
  String _selectedDakshinaMethod = 'CASH';
  bool _isCollectingDakshina = false;
  String? _activeDakshinaOrderId;
  Map<String, dynamic>? _dakshinaCollectionRecord;
  late Razorpay _dakshinaRazorpay;

  // Earnings state
  double _todayEarnings = 5250.0;
  int _completedTodayCount = 3;
  final double _onlineHours = 5.2;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _verifyAccess();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation =
        Tween<double>(begin: 1.0, end: 1.18).animate(_pulseController);

    _dakshinaRazorpay = Razorpay();
    _dakshinaRazorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleDakshinaPaymentSuccess);
    _dakshinaRazorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleDakshinaPaymentError);
    _dakshinaRazorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleDakshinaExternalWallet);
  }

  Future<void> _verifyAccess() async {
    try {
      final status = await ApiService.getPanditOnboardingStatus();
      final isApproved = status['verificationStatus'] == 'APPROVED' && status['canAccessDashboard'] == true;
      if (!isApproved && mounted) {
        context.go('/pandit-onboarding');
        return;
      }

      await _loadAuthoritativeDashboard();
    } catch (_) {
      if (mounted) {
        context.go('/pandit-onboarding');
      }
    }
  }

  Future<void> _loadAuthoritativeDashboard() async {
    try {
      final dashboard = await ApiService.getPanditDashboard();
      if (!mounted) return;

      setState(() {
        _isOnline = dashboard['isAvailable'] == true;
        if (dashboard['totalEarnings'] != null) {
          _todayEarnings = double.tryParse(dashboard['totalEarnings'].toString()) ?? _todayEarnings;
        }
        if (dashboard['todayCount'] != null) {
          _completedTodayCount = int.tryParse(dashboard['todayCount'].toString()) ?? _completedTodayCount;
        }
      });

      if (_isOnline) {
        _connectSocket();
        _startContinuousTelemetry();
      } else {
        _disconnectSocket();
        _stopContinuousTelemetry();
      }

      await _fetchActiveDuty();
    } catch (e) {
      debugPrint('Failed to load authoritative dashboard state: $e');
    }
  }

  Future<void> _fetchActiveDuty() async {
    try {
      final myBookings = await ApiService.getUserBookings();
      if (!mounted) return;
      final active = myBookings.firstWhere(
        (b) => ['CONFIRMED', 'HEADING_TO_VENUE', 'ARRIVED', 'PUJA_STARTED'].contains(b['status']),
        orElse: () => <String, dynamic>{},
      );
      if (active.isNotEmpty) {
        final activeId = active['id']?.toString();
        Map<String, dynamic>? dakshina;
        if (activeId != null) {
          try {
            final dRes = await ApiService.getDakshinaStatus(activeId);
            if (dRes['isPaid'] == true) {
              dakshina = dRes['collection'];
            }
          } catch (_) {}
        }
        setState(() {
          _activeBookingId = activeId;
          _activeBooking = active;
          _dakshinaCollectionRecord = dakshina;
          final s = active['status'] as String;
          if (s == 'CONFIRMED') {
            _dutyState = 'confirmed';
          } else if (s == 'HEADING_TO_VENUE') {
            _dutyState = 'heading_to_venue';
          } else if (s == 'ARRIVED') {
            _dutyState = 'arrived';
          } else if (s == 'PUJA_STARTED') {
            _dutyState = 'pooja_in_progress';
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching active duty on restore: $e');
    }
  }

  Future<void> _connectSocket() async {
    if (_socket != null && _socket!.connected) return;

    try {
      final token = await ApiService.getToken();
      if (token == null || token.isEmpty) return;

      final socketUrl = ApiConfig.socketUrl;

      _socket?.dispose();
      _socket = socket_io.io(
        socketUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.on('booking:new-request', (data) {
        if (!mounted || !_isOnline || _dutyState != 'none') return;
        if (data is Map) {
          _handleIncomingRealRequest(Map<String, dynamic>.from(data));
        }
      });

      _socket!.on('dakshina:collected', (data) {
        if (!mounted || data is! Map) return;
        final eventBookingId = data['bookingId']?.toString();
        if (_activeBookingId == eventBookingId) {
          setState(() {
            _dakshinaCollectionRecord = Map<String, dynamic>.from(data);
          });
        }
      });

      _socket!.on('booking:status-change', (data) {
        if (!mounted || data is! Map) return;
        final changedBookingId = data['bookingId']?.toString();
        final newStatus = data['status']?.toString();
        if (_activeBookingId == changedBookingId && newStatus != null) {
          setState(() {
            if (newStatus == 'CONFIRMED') {
              _dutyState = 'confirmed';
            } else if (newStatus == 'HEADING_TO_VENUE') {
              _dutyState = 'heading_to_venue';
            } else if (newStatus == 'ARRIVED') {
              _dutyState = 'arrived';
            } else if (newStatus == 'PUJA_STARTED') {
              _dutyState = 'pooja_in_progress';
            } else if (newStatus == 'COMPLETED') {
              _dutyState = 'completed';
            } else if (newStatus == 'CANCELLED') {
              _dutyState = 'none';
              _activeBookingId = null;
              _activeBooking = null;
            }
          });
        }
      });
    } catch (e) {
      debugPrint('Error establishing realtime socket connection: $e');
    }
  }

  void _disconnectSocket() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    } catch (e) {
      debugPrint('Error disconnecting socket: $e');
    }
  }

  /// Obtains genuine device GPS coordinates without fabricating any location
  Future<Position?> _determinePosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5),
        ),
      );
    } catch (e) {
      debugPrint('Location acquisition error: $e');
      return null;
    }
  }

  void _startContinuousTelemetry() {
    _stopContinuousTelemetry();
    if (!_isOnline) return;

    // Send immediate ping
    _sendTelemetryPing();

    // 25-second periodic telemetry loop while online
    _telemetryTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (mounted && _isOnline) {
        _sendTelemetryPing();
      } else {
        _stopContinuousTelemetry();
      }
    });
  }

  void _stopContinuousTelemetry() {
    _telemetryTimer?.cancel();
    _telemetryTimer = null;
  }

  Future<void> _sendTelemetryPing() async {
    if (!mounted || !_isOnline) return;
    try {
      final pos = await _determinePosition();
      if (pos == null || !mounted || !_isOnline) return;

      await ApiService.sendPanditTelemetry(
        lat: pos.latitude,
        lng: pos.longitude,
        accuracy: pos.accuracy,
        heading: pos.heading,
        speed: pos.speed,
      );
    } catch (e) {
      debugPrint('Pandit GPS telemetry transmission error: $e');
    }
  }

  @override
  void dispose() {
    _stopContinuousTelemetry();
    _pulseController.dispose();
    _disconnectSocket();
    _dakshinaRazorpay.clear();
    super.dispose();
  }

  Future<void> _toggleOnlineState() async {
    if (_isTogglingDuty) return;

    setState(() {
      _isTogglingDuty = true;
    });

    final targetState = !_isOnline;
    double? lat;
    double? lng;
    String locationNotice = '';

    if (targetState) {
      final pos = await _determinePosition();
      if (pos != null) {
        lat = pos.latitude;
        lng = pos.longitude;
        locationNotice = ' (with live GPS)';
      } else {
        locationNotice = ' (using saved location)';
      }
    }

    try {
      final updated = await ApiService.updateDutyStatus(
        targetState,
        lat: lat,
        lng: lng,
      );

      if (!mounted) return;

      setState(() {
        _isOnline = updated['isAvailable'] == true;
        if (!_isOnline) {
          _hasIncomingRequest = false;
          _incomingRequestPayload = null;
          _disconnectSocket();
          _stopContinuousTelemetry();
        } else {
          _connectSocket();
          _startContinuousTelemetry();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isOnline
                ? '🟢 You are now ONLINE$locationNotice & ready for Pooja requests!'
                : '🔴 You are OFFLINE. Duty paused.',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: _isOnline ? const Color(0xFF27AE60) : const Color(0xFF7F8C8D),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Duty status update failed: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingDuty = false;
        });
      }
    }
  }

  void _handleIncomingRealRequest(Map<String, dynamic> requestData) {
    final bookingId = requestData['bookingId']?.toString();
    if (bookingId == null || bookingId.isEmpty) {
      debugPrint('Ignored incoming booking request with missing bookingId');
      return;
    }

    if (_dismissedBookingIds.contains(bookingId)) {
      return;
    }

    if (_hasIncomingRequest && _incomingRequestPayload?['bookingId'] == bookingId) {
      return;
    }

    final expiresAtStr = requestData['expiresAt']?.toString();
    if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
      final expiry = DateTime.tryParse(expiresAtStr);
      if (expiry != null && expiry.isBefore(DateTime.now())) {
        debugPrint('Ignored already expired booking request: $bookingId');
        _dismissedBookingIds.add(bookingId);
        return;
      }
    }

    setState(() {
      _incomingRequestPayload = requestData;
      _hasIncomingRequest = true;
    });
  }

  Future<void> _handleAcceptBooking(String bookingId) async {
    try {
      final acceptedBooking = await ApiService.acceptBooking(bookingId);
      if (!mounted) return;

      _dismissedBookingIds.add(bookingId);
      setState(() {
        _hasIncomingRequest = false;
        _incomingRequestPayload = null;
        _activeBookingId = bookingId;
        _activeBooking = acceptedBooking;
        _dutyState = 'confirmed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 Booking Accepted! Ready to start journey.',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _dismissedBookingIds.add(bookingId);
      setState(() {
        _hasIncomingRequest = false;
        _incomingRequestPayload = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Could not accept: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> _handleDeclineBooking(String bookingId, {String? reason}) async {
    try {
      await ApiService.declineBooking(bookingId, reason: reason ?? 'OTHER');
      if (!mounted) return;

      _dismissedBookingIds.add(bookingId);
      setState(() {
        _hasIncomingRequest = false;
        _incomingRequestPayload = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Request declined.',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF7F8C8D),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();

      // If booking is already taken or not found, it is no longer actionable -> dismiss cleanly
      if (cleanMsg.contains('BOOKING_ALREADY_TAKEN') || cleanMsg.contains('BOOKING_NOT_FOUND')) {
        _dismissedBookingIds.add(bookingId);
        setState(() {
          _hasIncomingRequest = false;
          _incomingRequestPayload = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request is no longer active.',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF7F8C8D),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Network or authorization error: DO NOT falsely report persistence!
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Could not decline: $cleanMsg',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFE74C3C),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
        rethrow;
      }
    }
  }

  void _handleDismissBooking(String? bookingId) {
    if (bookingId != null && bookingId.isNotEmpty) {
      _dismissedBookingIds.add(bookingId);
    }
    if (mounted) {
      setState(() {
        _hasIncomingRequest = false;
        _incomingRequestPayload = null;
      });
    }
  }

  Future<void> _startJourney() async {
    if (_activeBookingId == null || _isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      final updated = await ApiService.updateBookingStatus(
        bookingId: _activeBookingId!,
        expectedStatus: 'CONFIRMED',
        newStatus: 'HEADING_TO_VENUE',
      );
      if (!mounted) return;
      setState(() {
        _activeBooking = updated;
        _dutyState = 'heading_to_venue';
        _isUpdatingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🚗 Journey started! En route to Yajman venue.',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Could not start journey: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markArrived() async {
    if (_activeBookingId == null || _isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      final updated = await ApiService.updateBookingStatus(
        bookingId: _activeBookingId!,
        expectedStatus: 'HEADING_TO_VENUE',
        newStatus: 'ARRIVED',
      );
      if (!mounted) return;
      setState(() {
        _activeBooking = updated;
        _dutyState = 'arrived';
        _isUpdatingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 Marked arrival at Yajman venue.',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Could not mark arrival: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _startSankalpa() async {
    if (_activeBookingId == null || _isUpdatingStatus) return;
    setState(() => _isUpdatingStatus = true);
    try {
      final updated = await ApiService.updateBookingStatus(
        bookingId: _activeBookingId!,
        expectedStatus: 'ARRIVED',
        newStatus: 'PUJA_STARTED',
      );
      if (!mounted) return;
      setState(() {
        _activeBooking = updated;
        _dutyState = 'pooja_in_progress';
        _isUpdatingStatus = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🕉️ Puja and Sankalpa commenced.',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUpdatingStatus = false);
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Could not start puja: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCollectCashDakshina() async {
    if (_activeBookingId == null || _isCollectingDakshina) return;
    setState(() => _isCollectingDakshina = true);
    try {
      final res = await ApiService.collectCashDakshina(
        bookingId: _activeBookingId!,
        completeBooking: true,
      );
      if (!mounted) return;
      final amount = double.tryParse(res['dakshina']?['amount']?.toString() ?? '2500') ?? 2500.0;
      setState(() {
        _isCollectingDakshina = false;
        _dutyState = 'completed';
        _dakshinaCollectionRecord = res['dakshina'];
        if (res['booking'] != null) {
          _activeBooking = res['booking'];
        }
        _todayEarnings += amount;
        _completedTodayCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ Cash Dakshina of ₹${amount.toStringAsFixed(0)} confirmed & Pooja completed!',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCollectingDakshina = false);
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Cash Dakshina error: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleInitiateOnlineDakshina() async {
    if (_activeBookingId == null || _isCollectingDakshina) return;
    setState(() => _isCollectingDakshina = true);
    try {
      final res = await ApiService.createDakshinaOrder(bookingId: _activeBookingId!);
      final order = res['order'];
      final orderId = order?['id']?.toString();
      final amount = order?['amount'];

      if (orderId == null || amount == null) {
        throw Exception('Server failed to initialize online Dakshina order');
      }

      _activeDakshinaOrderId = orderId;

      final razorpayKey = const String.fromEnvironment(
        'RAZORPAY_KEY_ID',
        defaultValue: 'rzp_test_placeholder',
      );

      final yajmanName = _activeBooking?['yajman']?['fullName'] ??
          _activeBooking?['yajmanName'] ??
          'Yajman';
      final yajmanPhone = _activeBooking?['yajman']?['phone'] ?? '+91 9876543210';

      final options = {
        'key': razorpayKey,
        'amount': amount,
        'name': 'SARV MANGAL',
        'description': 'Sacred Ritual Dakshina',
        'order_id': orderId,
        'timeout': 180,
        'prefill': {
          'contact': yajmanPhone,
          'name': yajmanName,
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      _dakshinaRazorpay.open(options);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCollectingDakshina = false);
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Online Dakshina initialization failed: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleDakshinaPaymentSuccess(PaymentSuccessResponse response) async {
    if (_activeBookingId == null || _activeDakshinaOrderId == null) return;
    try {
      final res = await ApiService.verifyDakshinaPayment(
        bookingId: _activeBookingId!,
        orderId: _activeDakshinaOrderId!,
        paymentId: response.paymentId ?? '',
        signature: response.signature ?? '',
        completeBooking: true,
      );
      if (!mounted) return;
      final amount = double.tryParse(res['dakshina']?['amount']?.toString() ?? '2500') ?? 2500.0;
      setState(() {
        _isCollectingDakshina = false;
        _dutyState = 'completed';
        _dakshinaCollectionRecord = res['dakshina'];
        if (res['booking'] != null) {
          _activeBooking = res['booking'];
        }
        _todayEarnings += amount;
        _completedTodayCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ Online Dakshina verified & Pooja completed successfully!',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCollectingDakshina = false);
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '❌ Dakshina verification error: $cleanMsg',
            style: GoogleFonts.lato(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleDakshinaPaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isCollectingDakshina = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '❌ Dakshina payment cancelled or failed. You may retry or collect in Cash.',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDakshinaExternalWallet(ExternalWalletResponse response) {
    debugPrint('External wallet selected for Dakshina: ${response.walletName}');
  }


  void _finishDutyAndReset() {
    setState(() {
      _dutyState = 'none';
      _activeBookingId = null;
      _activeBooking = null;
      _dakshinaCollectionRecord = null;
      _activeDakshinaOrderId = null;
      _isUpdatingStatus = false;
      _isCollectingDakshina = false;
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
                        if (_selectedNavIndex == 1) ...[
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Allotted Poojas',
                                style: GoogleFonts.lato(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3D2200),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildUpcomingBookings(),
                              const SizedBox(height: 16),
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
                                        color: const Color(0xFFE8F8F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '24 OCT',
                                            style: GoogleFonts.lato(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF27AE60),
                                            ),
                                          ),
                                          Text(
                                            '11:00 AM',
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
                                            'Satyanarayan Katha',
                                            style: GoogleFonts.lato(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF3D2200),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Yajman: Priya Singh • Indirapuram',
                                            style: GoogleFonts.lato(
                                              fontSize: 12,
                                              color: const Color(0xFF8C7355),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹2,100',
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
                          ),
                        ] else if (_selectedNavIndex == 2) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Column(
                              children: [
                                const Icon(Icons.support_agent, size: 64, color: Color(0xFFF18C16)),
                                const SizedBox(height: 16),
                                Text('Pandit Support',
                                    style: GoogleFonts.lato(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200))),
                                const SizedBox(height: 8),
                                Text('Call us at 1800-PANDIT-SETU',
                                    style: GoogleFonts.lato(fontSize: 16, color: const Color(0xFF8C7355))),
                              ],
                            ),
                          ),
                        ] else if (_selectedNavIndex == 3) ...[
                          const SizedBox(height: 16),
                          Column(
                            children: [
                              const CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150'),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Acharya Shastri Ji',
                                style: GoogleFonts.lato(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3D2200),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '+91 9876543210',
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  color: const Color(0xFF8C7355),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildPerformanceBadges(),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () => context.go('/role-select'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  foregroundColor: Colors.red[700],
                                  elevation: 0,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('Logout', style: GoogleFonts.lato(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ] else if (_dutyState == 'none') ...[
                          // Demand Radar Card
                          _buildDemandRadarCard(),

                          const SizedBox(height: 16),

                          // Earnings Dashboard Overview
                          _buildEarningsDashboard(),

                          const SizedBox(height: 16),

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

            // Incoming Pooja Request Modal (Real-Time Socket.IO)
            if (_hasIncomingRequest && _incomingRequestPayload != null)
              IncomingPoojaRequestModal(
                requestPayload: _incomingRequestPayload!,
                onAccept: _handleAcceptBooking,
                onDecline: _handleDeclineBooking,
                onDismiss: () => _handleDismissBooking(
                  _incomingRequestPayload?['bookingId']?.toString(),
                ),
              ),
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
        },
      },
      {
        'icon': Icons.headset_mic_outlined,
        'activeIcon': Icons.headset_mic,
        'label': 'Help',
        'action': () {
          setState(() => _selectedNavIndex = 2);
        },
      },
      {
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
        'action': () {
          setState(() => _selectedNavIndex = 3);
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
          if (_isTogglingDuty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
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
  // Active Duty Navigation & Execution Flow
  // ----------------------------------------------------
  Widget _buildActiveDutyFlowView() {
    if (_dutyState == 'confirmed') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF27AE60), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE8F8F0),
                      child: Icon(Icons.check_circle, color: Color(0xFF27AE60)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Confirmed & Assigned',
                            style: GoogleFonts.lato(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3D2200),
                            ),
                          ),
                          Text(
                            _activeBooking?['pooja']?['title'] ?? _activeBooking?['poojaName'] ?? 'Vedic Pooja Ritual',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              color: const Color(0xFF8C7355),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFE8DCCB), height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person, color: Color(0xFFF18C16), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeBooking?['yajman']?['fullName'] ?? _activeBooking?['yajmanName'] ?? 'Devotee / Yajman',
                        style: GoogleFonts.lato(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF3D2200)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFFF18C16), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _activeBooking?['venueAddress'] ?? 'Devotee Residence Venue',
                        style: GoogleFonts.lato(fontSize: 13, color: const Color(0xFF6B5B52)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isUpdatingStatus ? null : _startJourney,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: _isUpdatingStatus
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.navigation),
                      const SizedBox(width: 8),
                      Text(
                        'START JOURNEY TO VENUE',
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
                          'En Route to Venue',
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
                        _activeBooking?['yajman']?['fullName'] ?? _activeBooking?['yajmanName'] ?? 'Devotee / Yajman',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3D2200),
                        ),
                      ),
                      Text(
                        _activeBooking?['venueAddress'] ?? 'Devotee Residence Venue',
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
            onPressed: _isUpdatingStatus ? null : _markArrived,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isUpdatingStatus
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
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
            onPressed: _isUpdatingStatus ? null : _startSankalpa,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF18C16),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: _isUpdatingStatus
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Row(
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
      final expectedAmountStr = _activeBooking?['totalAmount']?.toString() ?? '2500';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3D2200), Color(0xFF5C3300)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.self_improvement, color: Color(0xFFF18C16), size: 40),
                const SizedBox(height: 8),
                Text(
                  '${_activeBooking?['pooja']?['title'] ?? _activeBooking?['poojaName'] ?? 'Vedic Pooja'} In Progress',
                  style: GoogleFonts.lato(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ritual Chanting & Sankalpa Active',
                  style: GoogleFonts.lato(
                    fontSize: 13,
                    color: const Color(0xFFF18C16),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Dedicated Dakshina Collection & Booking Closure Panel
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF18C16), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF18C16).withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                        const Icon(Icons.currency_rupee, color: Color(0xFFF18C16), size: 22),
                        const SizedBox(width: 6),
                        Text(
                          'Dakshina Collection',
                          style: GoogleFonts.lato(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3D2200),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹$expectedAmountStr',
                      style: GoogleFonts.lato(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF27AE60),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Collect sacred Dakshina from Yajman to conclude ritual and close booking.',
                  style: GoogleFonts.lato(fontSize: 12, color: const Color(0xFF8C7355)),
                ),
                const SizedBox(height: 14),

                // Method Selector: Cash vs Online
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _isCollectingDakshina
                            ? null
                            : () => setState(() => _selectedDakshinaMethod = 'CASH'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedDakshinaMethod == 'CASH'
                                ? const Color(0xFFFFF3E0)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDakshinaMethod == 'CASH'
                                  ? const Color(0xFFF18C16)
                                  : Colors.grey[300]!,
                              width: _selectedDakshinaMethod == 'CASH' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: _selectedDakshinaMethod == 'CASH'
                                    ? const Color(0xFFF18C16)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cash in Hand',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedDakshinaMethod == 'CASH'
                                      ? const Color(0xFF3D2200)
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _isCollectingDakshina
                            ? null
                            : () => setState(() => _selectedDakshinaMethod = 'ONLINE'),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedDakshinaMethod == 'ONLINE'
                                ? const Color(0xFFFFF3E0)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedDakshinaMethod == 'ONLINE'
                                  ? const Color(0xFFF18C16)
                                  : Colors.grey[300]!,
                              width: _selectedDakshinaMethod == 'ONLINE' ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                color: _selectedDakshinaMethod == 'ONLINE'
                                    ? const Color(0xFFF18C16)
                                    : Colors.grey[600],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Online / UPI',
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedDakshinaMethod == 'ONLINE'
                                      ? const Color(0xFF3D2200)
                                      : Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Button based on chosen payment method
          if (_selectedDakshinaMethod == 'CASH')
            ElevatedButton(
              onPressed: _isCollectingDakshina ? null : _handleCollectCashDakshina,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: _isCollectingDakshina
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        Text(
                          'CONFIRM CASH RECEIVED (₹$expectedAmountStr)',
                          style: GoogleFonts.lato(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            )
          else
            ElevatedButton(
              onPressed: _isCollectingDakshina ? null : _handleInitiateOnlineDakshina,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: _isCollectingDakshina
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.flash_on),
                        const SizedBox(width: 8),
                        Text(
                          'COLLECT ONLINE VIA RAZORPAY (₹$expectedAmountStr)',
                          style: GoogleFonts.lato(
                            fontSize: 14,
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
      final finalDakshina = _dakshinaCollectionRecord?['amount']?.toString() ??
          _activeBooking?['totalAmount']?.toString() ??
          '2500';
      final paymentMethodStr = _dakshinaCollectionRecord?['paymentMethod'] == 'CASH'
          ? 'Cash in Hand'
          : 'Online (Razorpay)';

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
                  '₹$finalDakshina Dakshina confirmed via $paymentMethodStr and credited to your Pandit Wallet.',
                  textAlign: TextAlign.center,
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

