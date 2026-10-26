import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../utils/booking_date_time_helper.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  /// Helper to get stored JWT Bearer token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// Sends 6-digit OTP to user's mobile number
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();
    final response = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': cleanPhone}),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else {
      final errorMsg = data['error']?['message'] ?? 'Failed to send OTP (${response.statusCode})';
      debugPrint('Failed to send OTP: ${response.statusCode} ${response.body}');
      throw Exception(errorMsg);
    }
  }

  /// Verifies OTP, signs JWT and stores session in SharedPreferences
  static Future<Map<String, dynamic>?> verifyOtp(
    String phone,
    String otp,
    String name, {
    String? role,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '').trim();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': cleanPhone,
          'otp': otp.trim(),
          if (name.trim().isNotEmpty) 'name': name.trim(),
          if (role != null && role.isNotEmpty) 'role': role,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        if (data['data']?['token'] != null) {
          await prefs.setString('token', data['data']['token']);
        }
        if (data['data']?['user'] != null) {
          await prefs.setString('user', jsonEncode(data['data']['user']));
        }
        return data;
      } else {
        final errorMsg = data['error']?['message'] ?? 'Invalid OTP';
        debugPrint('verifyOtp error: $errorMsg');
        return null;
      }
    } catch (e) {
      debugPrint('Error in verifyOtp: $e');
      return null;
    }
  }

  /// Fetches profile of currently logged-in user from backend
  static Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    final response = await http.get(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    } else {
      final body = jsonDecode(response.body);
      final msg = body['error']?['message'] ?? 'Failed to fetch profile (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Updates profile attributes on the backend database
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> updateData) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }
    final response = await http.put(
      Uri.parse('$baseUrl/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updateData),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to update profile (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches live catalog of pujas from the database
  static Future<List<Map<String, dynamic>>> getPoojas({int page = 1, int limit = 50}) async {
    final safeLimit = (limit > 50) ? 50 : (limit < 1 ? 1 : limit);
    final requestUrl = '$baseUrl/poojas?page=$page&limit=$safeLimit';
    debugPrint('ApiService.getPoojas() requesting URL: $requestUrl');

    final response = await http.get(
      Uri.parse(requestUrl),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['data']?['items'] ?? data['data'] ?? [];
      return List<Map<String, dynamic>>.from(items);
    } else {
      throw Exception('Failed to fetch poojas catalog (${response.statusCode})');
    }
  }

  /// Fetches live catalog of store products from the PostgreSQL database
  static Future<List<Map<String, dynamic>>> getProducts({
    int page = 1,
    int limit = 50,
    String? category,
    String? search,
  }) async {
    String url = '$baseUrl/products?page=$page&limit=$limit';
    if (category != null && category.isNotEmpty && category != 'All') {
      url += '&category=${Uri.encodeComponent(category)}';
    }
    if (search != null && search.trim().isNotEmpty) {
      url += '&search=${Uri.encodeComponent(search.trim())}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final items = data['data']?['items'] ?? data['data'] ?? [];
      return List<Map<String, dynamic>>.from(items);
    } else {
      throw Exception('Failed to fetch store products (${response.statusCode})');
    }
  }

  /// Fetches a single product by ID (UUID or Product_ID)
  static Future<Map<String, dynamic>?> getProductById(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/$id'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['data'] as Map<String, dynamic>?;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to fetch product details (${response.statusCode})');
    }
  }

  /// Queries nearby pandits using genuine device PostGIS geospatial coordinates
  static Future<List<Map<String, dynamic>>> getNearbyPandits({
    double? lat,
    double? lng,
    double radiusKm = 25,
  }) async {
    if (lat == null || lng == null) {
      debugPrint('getNearbyPandits requires genuine device coordinates; skipping call.');
      return [];
    }

    final token = await getToken();
    final uri = Uri.parse(
      '$baseUrl/pandits/nearby?lat=${lat.toStringAsFixed(6)}&lng=${lng.toStringAsFixed(6)}&radiusKm=${radiusKm.toInt()}',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data']?['pandits'] ?? data['data'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      } else {
        debugPrint('Nearby pandits API error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error in getNearbyPandits: $e');
      return [];
    }
  }

  /// Queries nearby verified ancient temples and gurukuls via Google Places / Redis cache
  static Future<List<Map<String, dynamic>>> getNearbyTemples({
    required double lat,
    required double lng,
    double radiusKm = 10,
  }) async {
    final token = await getToken();
    final uri = Uri.parse(
      '$baseUrl/temples/nearby?lat=${lat.toStringAsFixed(6)}&lng=${lng.toStringAsFixed(6)}&radiusKm=${radiusKm.toInt()}',
    );

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data'] is List ? data['data'] : (data['data']?['temples'] ?? []);
        return List<Map<String, dynamic>>.from(list);
      } else {
        debugPrint('Nearby temples API error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Network error in getNearbyTemples: $e');
      return [];
    }
  }

  /// Initiates a genuine Phool Mala recurring subscription with Razorpay
  static Future<Map<String, dynamic>> createSubscription(String planId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Please sign in to subscribe to floral delivery services.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/subscriptions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'planId': planId}),
    );

    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
      return data['data'] ?? {};
    } else {
      final errorMsg = data['error']?['message'] ?? 'Subscription creation failed (${response.statusCode})';
      throw Exception(errorMsg);
    }
  }

  /// Creates a real booking in the PostgreSQL database with strict schema validation
  static Future<Map<String, dynamic>> createBooking(Map<String, dynamic> rawBookingData) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Please sign in to confirm your booking.');
    }

    final bool isOnline = rawBookingData['mode'] == 'ONLINE' ||
        rawBookingData['bookingType']?.toString().toUpperCase() == 'ONLINE' ||
        rawBookingData['bookingMode']?.toString().toLowerCase() == 'online';

    // Strictly validate and resolve ISO8601 booking datetime string
    final String bookingTimeStr = BookingDateTimeHelper.resolveBookingTime(rawBookingData);

    // Prepare strictly validated payload
    final Map<String, dynamic> payload = {
      'poojaId': rawBookingData['poojaId'],
      'bookingTime': bookingTimeStr,
      'mode': isOnline ? 'ONLINE' : 'IN_PERSON',
    };

    if (rawBookingData['customNotes'] != null && rawBookingData['customNotes'].toString().isNotEmpty) {
      payload['customNotes'] = rawBookingData['customNotes'].toString();
    }

    if (!isOnline) {
      payload['venueAddress'] = (rawBookingData['venueAddress'] ?? rawBookingData['address'] ?? 'Devotee Residence')
          .toString()
          .trim();
      if ((payload['venueAddress'] as String).length < 5) {
        payload['venueAddress'] = '${payload['venueAddress']}, City Center';
      }
      payload['lat'] = (rawBookingData['lat'] is num) ? (rawBookingData['lat'] as num).toDouble() : 28.6139;
      payload['lng'] = (rawBookingData['lng'] is num) ? (rawBookingData['lng'] as num).toDouble() : 77.2090;
      payload['samagriIncluded'] = rawBookingData['samagriIncluded'] == true;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      final errorMsg = data['error']?['message'] ?? 'Failed to create booking (${response.statusCode})';
      debugPrint('Booking creation failed: ${response.statusCode} - $errorMsg');
      throw Exception(errorMsg);
    }
  }

  /// Retrieves user's genuine bookings from the database
  static Future<List<Map<String, dynamic>>> getUserBookings({int limit = 20}) async {
    final token = await getToken();
    if (token == null) {
      return [];
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bookings?limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data['data']?['items'] ?? data['data']?['bookings'] ?? data['data'] ?? [];
        return List<Map<String, dynamic>>.from(list);
      } else {
        debugPrint('getUserBookings error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching user bookings: $e');
      return [];
    }
  }

  /// Creates a Razorpay order on the backend for a verified booking
  static Future<Map<String, dynamic>> createPaymentOrder(String bookingId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to initialize payment.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/create-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'bookingId': bookingId}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      final order = data['data']?['order'];
      if (order == null) {
        throw Exception('Invalid order response from server');
      }
      return Map<String, dynamic>.from(order);
    } else {
      final errorMsg = data['error']?['message'] ?? 'Failed to create payment order (${response.statusCode})';
      throw Exception(errorMsg);
    }
  }

  /// Verifies a Razorpay payment signature on the backend
  static Future<Map<String, dynamic>> verifyPaymentSignature({
    required String orderId,
    required String paymentId,
    required String signature,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to verify payment.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/payments/verify-signature'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
      }),
    ).timeout(const Duration(seconds: 12));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final booking = data['data']?['booking'];
      if (booking == null) {
        throw Exception('Payment verification response missing booking data');
      }
      return Map<String, dynamic>.from(booking);
    } else {
      final errorMsg = data['error']?['message'] ?? 'Payment signature verification failed (${response.statusCode})';
      throw Exception(errorMsg);
    }
  }

  /// Applies for Pandit role using existing phone identity
  static Future<Map<String, dynamic>> applyForPandit() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to apply for Pandit role.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/apply'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final newToken = data['data']?['token'];
      if (newToken != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', newToken);
      }
      return Map<String, dynamic>.from(data['data']);
    } else {
      final msg = data['error']?['message'] ?? 'Failed to apply for Pandit role (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches authoritative Pandit onboarding and verification status
  static Future<Map<String, dynamic>> getPanditOnboardingStatus() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/pandits/me/onboarding-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch onboarding status (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Updates Pandit profile information during onboarding
  static Future<Map<String, dynamic>> updatePanditOnboardingProfile(Map<String, dynamic> profileData) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/pandits/me/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(profileData),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    } else {
      final msg = data['error']?['message'] ?? 'Failed to update profile (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Uploads a private verification document with base64 payload
  static Future<Map<String, dynamic>> uploadPanditDocument({
    required String docType,
    required String fileName,
    required String mimeType,
    required String fileDataBase64,
    String? docNumber,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to upload document.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/me/documents'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'docType': docType,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileDataBase64': fileDataBase64,
        if (docNumber != null && docNumber.isNotEmpty) 'docNumber': docNumber,
      }),
    ).timeout(const Duration(seconds: 25));

    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    } else {
      final msg = data['error']?['message'] ?? 'Failed to upload document (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Deletes an unapproved document to allow replacement
  static Future<void> deletePanditDocument(String docId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/pandits/me/documents/$docId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['success'] != true) {
      final msg = data['error']?['message'] ?? 'Failed to delete document';
      throw Exception(msg);
    }
  }

  /// Submits uploaded documents for administrative review
  static Future<Map<String, dynamic>> submitPanditDocumentsForReview() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/me/submit-for-review'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    } else {
      final msg = data['error']?['message'] ?? 'Failed to submit documents (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Schedules a video verification appointment slot
  static Future<Map<String, dynamic>> schedulePanditVideoVerification(Map<String, dynamic> appointmentData) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/me/video-verification/schedule'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(appointmentData),
    ).timeout(const Duration(seconds: 12));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']);
    } else {
      final msg = data['error']?['message'] ?? 'Failed to schedule video verification (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches approved Sanskrit/Vedic mantra prompts for recording verification
  static Future<List<Map<String, dynamic>>> getApprovedMantras() async {
    final response = await http.get(
      Uri.parse('$baseUrl/pandits/mantras'),
      headers: {
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final list = data['data']?['mantras'] as List? ?? [];
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch approved mantras (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Sets the Pandit's preferred verification method ('VIDEO_CALL' or 'MANTRA_RECORDING')
  static Future<Map<String, dynamic>> setPanditVerificationMethod(String method) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/pandits/me/verification-method'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'method': method}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to update verification method (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Uploads a genuine audio recording of a Vedic mantra recitation for admin review
  static Future<Map<String, dynamic>> uploadPanditMantraRecording({
    required String mantraId,
    required String mantraTitle,
    required String fileName,
    required String mimeType,
    required String fileDataBase64,
    int? durationSeconds,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/me/mantra-recordings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'mantraId': mantraId,
        'mantraTitle': mantraTitle,
        'fileName': fileName,
        'mimeType': mimeType,
        'fileDataBase64': fileDataBase64,
        if (durationSeconds != null && durationSeconds > 0) 'durationSeconds': durationSeconds,
      }),
    ).timeout(const Duration(seconds: 35));

    final data = jsonDecode(response.body);
    if ((response.statusCode == 200 || response.statusCode == 201) && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']?['recording'] ?? data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to upload mantra recording (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches history of submitted mantra recordings for the current Pandit
  static Future<List<Map<String, dynamic>>> getPanditMantraRecordings() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/pandits/me/mantra-recordings'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final list = data['data']?['recordings'] as List? ?? [];
      return list.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    } else {
      final msg = data['error']?['message'] ?? 'Failed to load mantra recordings (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches real Pandit Dashboard metrics (strictly checks server-side approval)
  static Future<Map<String, dynamic>> getPanditDashboard() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to view dashboard.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/pandits/dashboard'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']?['dashboard'] ?? data['data'] ?? {});
    } else if (response.statusCode == 403) {
      throw Exception('PANDIT_NOT_APPROVED: Verification pending.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch dashboard metrics (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Updates Pandit duty status (online/offline) with optional GPS coordinates
  static Future<Map<String, dynamic>> updateDutyStatus(
    bool isAvailable, {
    double? lat,
    double? lng,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to update duty status.');
    }

    final Map<String, dynamic> body = {
      'isAvailable': isAvailable,
    };
    if (lat != null && lng != null) {
      body['lat'] = lat;
      body['lng'] = lng;
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/pandits/duty-status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']?['pandit'] ?? data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to update duty status (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Accepts a pending booking by an approved Pandit
  static Future<Map<String, dynamic>> acceptBooking(String bookingId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to accept booking.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/accept-booking'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'bookingId': bookingId}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']?['booking'] ?? data['data'] ?? {});
    } else if (response.statusCode == 409) {
      throw Exception('BOOKING_ALREADY_TAKEN: This booking has already been accepted by another Pandit.');
    } else if (response.statusCode == 403) {
      throw Exception('PANDIT_NOT_APPROVED: Your Pandit profile must be approved before accepting bookings.');
    } else if (response.statusCode == 404) {
      throw Exception('BOOKING_NOT_FOUND: The requested booking does not exist.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to accept booking (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Persistently declines a booking request by an approved Pandit
  static Future<Map<String, dynamic>> declineBooking(
    String bookingId, {
    String? reason,
    String? notes,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to decline booking.');
    }

    final payload = <String, dynamic>{
      'bookingId': bookingId,
      'reason': reason ?? 'OTHER',
    };
    if (notes != null && notes.isNotEmpty) {
      payload['notes'] = notes;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/decline-booking'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']?['decline'] ?? data['data'] ?? {});
    } else if (response.statusCode == 409) {
      throw Exception('BOOKING_ALREADY_TAKEN: This booking has already been accepted or is no longer available.');
    } else if (response.statusCode == 403) {
      throw Exception('PANDIT_NOT_APPROVED: Your Pandit profile must be approved before declining bookings.');
    } else if (response.statusCode == 404) {
      throw Exception('BOOKING_NOT_FOUND: The requested booking does not exist.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to decline booking (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Updates the lifecycle status of a booking (assigned Pandit only)
  static Future<Map<String, dynamic>> updateBookingStatus({
    required String bookingId,
    required String expectedStatus,
    required String newStatus,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to update booking status.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/bookings/$bookingId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'expectedStatus': expectedStatus,
        'newStatus': newStatus,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']?['booking'] ?? data['data'] ?? {});
    } else if (response.statusCode == 409) {
      throw Exception('STATUS_CONFLICT: ${data['error']?['message'] ?? 'Booking status mismatch or concurrent update.'}');
    } else if (response.statusCode == 403) {
      throw Exception('FORBIDDEN: ${data['error']?['message'] ?? 'You are not authorized to update this booking status.'}');
    } else if (response.statusCode == 404) {
      throw Exception('BOOKING_NOT_FOUND: The requested booking does not exist.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to update booking status (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Retrieves an authoritative single booking by ID
  static Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 8));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data']?['booking'] ?? data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch booking details (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Confirms Cash Dakshina collection and optionally closes/completes the booking
  static Future<Map<String, dynamic>> collectCashDakshina({
    required String bookingId,
    double? amount,
    String? notes,
    bool completeBooking = true,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to record Dakshina.');
    }

    final payload = <String, dynamic>{
      'completeBooking': completeBooking,
    };
    if (amount != null) payload['amount'] = amount;
    if (notes != null) payload['notes'] = notes;

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/dakshina/cash'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Cash Dakshina confirmation failed (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Creates a Razorpay order for online Dakshina payment
  static Future<Map<String, dynamic>> createDakshinaOrder({
    required String bookingId,
    double? amount,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to create Dakshina order.');
    }

    final payload = <String, dynamic>{};
    if (amount != null) payload['amount'] = amount;

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/dakshina/create-order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to initialize Dakshina order (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Verifies Razorpay payment signature for online Dakshina and optionally completes booking
  static Future<Map<String, dynamic>> verifyDakshinaPayment({
    required String bookingId,
    required String orderId,
    required String paymentId,
    required String signature,
    bool completeBooking = true,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to verify Dakshina payment.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/$bookingId/dakshina/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'orderId': orderId,
        'paymentId': paymentId,
        'signature': signature,
        'completeBooking': completeBooking,
      }),
    ).timeout(const Duration(seconds: 12));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Dakshina verification failed (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches Dakshina payment status for a booking
  static Future<Map<String, dynamic>> getDakshinaStatus(String bookingId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/$bookingId/dakshina'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 8));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch Dakshina status (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Places a new product order on the backend with server-authoritative pricing
  static Future<Map<String, dynamic>> createProductOrder({
    required List<Map<String, dynamic>> items,
    required Map<String, dynamic> shippingAddress,
    String? notes,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to place an order.');
    }

    final payload = {
      'items': items,
      'shippingAddress': shippingAddress,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/product-orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to create order (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Creates a Razorpay order for product order payment
  static Future<Map<String, dynamic>> createProductOrderPayment(String orderId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required for payment initialization.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/product-orders/$orderId/payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to create payment order (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Verifies Razorpay payment signature on backend for a product order
  static Future<Map<String, dynamic>> verifyProductOrderPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required for payment verification.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/product-orders/$orderId/verify-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Payment verification failed (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches paginated list of product orders placed by authenticated user
  static Future<Map<String, dynamic>> getMyProductOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    String url = '$baseUrl/product-orders?page=$page&limit=$limit';
    if (status != null && status.isNotEmpty) {
      url += '&status=${Uri.encodeComponent(status)}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch orders (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches single product order details by ID
  static Future<Map<String, dynamic>> getProductOrderById(String orderId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/product-orders/$orderId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch order details (${response.statusCode})';
      throw Exception(msg);
    }
  }

  // ==========================================
  // PHASE P2-C: ADMIN DASHBOARD API METHODS
  // ==========================================

  /// Fetches operational dashboard metrics from the backend
  static Future<Map<String, dynamic>> getAdminStats() async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required for administrative dashboard.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else if (response.statusCode == 403) {
      throw Exception('FORBIDDEN: Administrative privileges required.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch admin stats (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches list of Pandit KYC onboarding applications
  static Future<Map<String, dynamic>> getAdminPandits({
    String status = 'ALL',
    int page = 1,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/pandits?status=$status&page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else if (response.statusCode == 403) {
      throw Exception('FORBIDDEN: Administrative privileges required.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch pandits list (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches detailed Pandit application with verified/pending documents
  static Future<Map<String, dynamic>> getAdminPanditDetail(String panditId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/pandits/$panditId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch pandit details (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Approves a Pandit's application
  static Future<Map<String, dynamic>> adminApprovePandit(String panditId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/pandits/$panditId/approval'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': 'APPROVED'}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to approve application (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Rejects a Pandit's application with a mandatory reason
  static Future<Map<String, dynamic>> adminRejectPandit(String panditId, String reason) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    if (reason.trim().isEmpty) {
      throw Exception('A rejection reason is required.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/pandits/$panditId/approval'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': 'REJECTED',
        'rejectionReason': reason.trim(),
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to reject application (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Verifies or rejects an individual verification document
  static Future<Map<String, dynamic>> adminVerifyDocument(
    String documentId,
    String status, {
    String? rejectionReason,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final Map<String, dynamic> body = {'status': status};
    if (status == 'REJECTED' && rejectionReason != null && rejectionReason.isNotEmpty) {
      body['rejectionReason'] = rejectionReason.trim();
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/documents/$documentId/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to verify document (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches real subscription records for administrative oversight
  static Future<Map<String, dynamic>> getAdminSubscriptions({
    String status = 'ALL',
    int page = 1,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/subscriptions?status=$status&page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else if (response.statusCode == 403) {
      throw Exception('FORBIDDEN: Administrative privileges required.');
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch subscriptions (${response.statusCode})';
      throw Exception(msg);
    }
  }

  // ==========================================
  // SARV MANGAL Phase P3: Consultation APIs
  // ==========================================

  /// Submits a persistent Vedic consultation request
  static Future<Map<String, dynamic>> createConsultation(Map<String, dynamic> body) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required. Please log in first.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/consultations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to create consultation (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Lists authenticated user's consultations
  static Future<Map<String, dynamic>> getMyConsultations({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/consultations?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch consultations (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Gets single consultation detail with permission verification
  static Future<Map<String, dynamic>> getConsultationById(String id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/consultations/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch consultation details (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Devotee cancels a consultation request
  static Future<Map<String, dynamic>> cancelConsultation(String id, String cancellationReason) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/consultations/$id/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'cancellationReason': cancellationReason.trim()}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to cancel consultation (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Creates Razorpay order for consultation fee
  static Future<Map<String, dynamic>> createConsultationPaymentOrder(String id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/consultations/$id/payment/order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to initiate payment (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Verifies Razorpay signature on server
  static Future<Map<String, dynamic>> verifyConsultationPayment(
    String id, {
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/consultations/$id/payment/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Payment verification failed (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Admin lists consultation queue
  static Future<Map<String, dynamic>> adminGetConsultations({
    String status = 'ALL',
    int page = 1,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/consultations?status=$status&page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch consultation desk queue (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Admin schedules consultation
  static Future<Map<String, dynamic>> adminScheduleConsultation(
    String id, {
    required String scheduledDateTime,
    String? meetingLink,
    String? notes,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/consultations/$id/schedule'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'scheduledDateTime': scheduledDateTime,
        if (meetingLink != null && meetingLink.isNotEmpty) 'meetingLink': meetingLink,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to schedule consultation (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Alias for adminGetConsultations
  static Future<Map<String, dynamic>> getAdminConsultations({
    String? status,
    int page = 1,
    int limit = 50,
  }) =>
      adminGetConsultations(
        status: status ?? 'ALL',
        page: page,
        limit: limit,
      );

  /// Admin assigns verified Pandit to consultation
  static Future<Map<String, dynamic>> adminAssignPanditToConsultation(
    String id, {
    required String panditId,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/consultations/$id/assignment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'panditId': panditId}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to assign Pandit (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Admin updates consultation status
  static Future<Map<String, dynamic>> adminUpdateConsultationStatus(
    String id, {
    required String status,
    String? reason,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/consultations/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to update consultation status (${response.statusCode})';
      throw Exception(msg);
    }
  }

  // ==========================================
  // SARV MANGAL Phase P3: Handmade Kundli APIs
  // ==========================================

  /// Submits a persistent handmade Kundli request
  static Future<Map<String, dynamic>> createKundliOrder(Map<String, dynamic> body) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required. Please log in first.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/kundli-orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to submit Kundli order (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Lists authenticated user's Kundli orders
  static Future<Map<String, dynamic>> getMyKundliOrders({
    int page = 1,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/kundli-orders?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch Kundli orders (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Gets single Kundli order detail with permission verification
  static Future<Map<String, dynamic>> getKundliOrderById(String id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/kundli-orders/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch Kundli details (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Devotee cancels a Kundli order
  static Future<Map<String, dynamic>> cancelKundliOrder(String id, String cancellationReason) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/kundli-orders/$id/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'cancellationReason': cancellationReason.trim()}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to cancel Kundli order (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Creates Razorpay order for Kundli fee
  static Future<Map<String, dynamic>> createKundliPaymentOrder(String id) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/kundli-orders/$id/payment/order'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to initiate Kundli payment (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Verifies Kundli payment
  static Future<Map<String, dynamic>> verifyKundliPayment(
    String id, {
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/kundli-orders/$id/payment/verify'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Kundli payment verification failed (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Admin lists Kundli orders
  static Future<Map<String, dynamic>> adminGetKundliOrders({
    String status = 'ALL',
    int page = 1,
    int limit = 20,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/admin/kundli-orders?status=$status&page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to fetch Kundli orders queue (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Alias for adminGetKundliOrders
  static Future<Map<String, dynamic>> getAdminKundliOrders({
    String? status,
    int page = 1,
    int limit = 50,
  }) =>
      adminGetKundliOrders(
        status: status ?? 'ALL',
        page: page,
        limit: limit,
      );

  /// Admin decision on Kundli order
  static Future<Map<String, dynamic>> adminDecisionKundliOrder(
    String id, {
    required String decision,
    String? reason,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/kundli-orders/$id/decision'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'decision': decision,
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to record Kundli review decision (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Admin assigns Pandit/astrologer to Kundli order
  static Future<Map<String, dynamic>> adminAssignPanditToKundli(
    String id, {
    required String panditId,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/kundli-orders/$id/assignment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'panditId': panditId}),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to assign Pandit to Kundli (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Admin updates Kundli preparation or dispatch status
  static Future<Map<String, dynamic>> adminUpdateKundliStatus(
    String id, {
    required String status,
    String? dispatchTrackingNumber,
    String? trackingNumber,
    String? courierPartner,
    String? notes,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final tracking = dispatchTrackingNumber ?? trackingNumber;

    final response = await http.patch(
      Uri.parse('$baseUrl/admin/kundli-orders/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'status': status,
        if (tracking != null && tracking.isNotEmpty)
          'dispatchTrackingNumber': tracking,
        if (courierPartner != null && courierPartner.isNotEmpty)
          'courierPartner': courierPartner,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      }),
    ).timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to update Kundli status (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Dispatches continuous GPS telemetry for on-duty, approved Pandit
  static Future<Map<String, dynamic>> sendPanditTelemetry({
    required double lat,
    required double lng,
    double? accuracy,
    double? heading,
    double? speed,
    DateTime? timestamp,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required to send telemetry.');
    }

    final payload = <String, dynamic>{
      'lat': lat,
      'lng': lng,
      if (accuracy != null && accuracy > 0) 'accuracy': accuracy,
      if (heading != null && heading >= 0) 'heading': heading,
      if (speed != null && speed >= 0) 'speed': speed,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/pandits/me/telemetry'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 8));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      return Map<String, dynamic>.from(data['data'] ?? {});
    } else {
      final msg = data['error']?['message'] ?? 'Failed to record telemetry (${response.statusCode})';
      throw Exception(msg);
    }
  }

  /// Fetches live or last-known tracking location of assigned Pandit for a booking
  static Future<Map<String, dynamic>?> getBookingTrackingLocation(String bookingId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Authentication required.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/tracking/$bookingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 8));

    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['success'] == true) {
      final loc = data['data']?['location'];
      if (loc != null && loc is Map) {
        return Map<String, dynamic>.from(loc);
      }
      return null;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      final msg = data['error']?['message'] ?? 'Failed to get location (${response.statusCode})';
      throw Exception(msg);
    }
  }
}



