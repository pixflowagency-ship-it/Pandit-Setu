import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/branding.dart';
import '../utils/booking_date_time_helper.dart';

/// Production-ready Incoming Pooja Request Modal for Pandits.
///
/// Displays real-time request details received via Socket.IO `booking:new-request`,
/// featuring an authoritative countdown timer, sanitized locality display
/// protecting Yajman privacy, and robust accept/decline action handlers.
class IncomingPoojaRequestModal extends StatefulWidget {
  final Map<String, dynamic> requestPayload;
  final Future<void> Function(String bookingId) onAccept;
  final dynamic onDecline;
  final VoidCallback onDismiss;

  const IncomingPoojaRequestModal({
    super.key,
    required this.requestPayload,
    required this.onAccept,
    required this.onDecline,
    required this.onDismiss,
  });

  @override
  State<IncomingPoojaRequestModal> createState() => _IncomingPoojaRequestModalState();
}

class _IncomingPoojaRequestModalState extends State<IncomingPoojaRequestModal> {
  late int _remainingSeconds;
  Timer? _countdownTimer;
  bool _isSubmitting = false;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _calculateRemainingSeconds();
    if (_remainingSeconds <= 0) {
      _isExpired = true;
    } else {
      _startCountdown();
    }
  }

  int _calculateRemainingSeconds() {
    final expiresAtStr = widget.requestPayload['expiresAt']?.toString();
    if (expiresAtStr != null && expiresAtStr.isNotEmpty) {
      final expiry = DateTime.tryParse(expiresAtStr);
      if (expiry != null) {
        final diff = expiry.difference(DateTime.now()).inSeconds;
        return diff.clamp(0, 60);
      }
    }
    return 60;
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _isExpired = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _sanitizeLocality(String? address) {
    if (address == null || address.trim().isEmpty) {
      return 'Location shared with Pandit';
    }
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.length > 1 &&
        RegExp(r'^(flat|house|plot|room|apt|h\.no|#|\d+)', caseSensitive: false)
            .hasMatch(parts[0])) {
      return parts.sublist(1).join(', ');
    }
    return address;
  }

  Future<void> _handleAccept() async {
    if (_isSubmitting || _isExpired) return;

    final bookingId = widget.requestPayload['bookingId']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onAccept(bookingId);
    } catch (_) {
      // Error feedback is handled by onAccept handler via SnackBar
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleDecline() async {
    if (_isSubmitting || _isExpired) return;

    final bookingId = widget.requestPayload['bookingId']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    // Show reason selection dialog
    final selectedReason = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => _buildDeclineReasonDialog(dialogCtx),
    );

    // If cancelled by tapping outside or cancel button
    if (selectedReason == null) return;

    await _executeDecline(bookingId, selectedReason);
  }

  Future<void> _executeDecline(String bookingId, String reason) async {
    if (_isSubmitting || _isExpired) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.onDecline is Future<void> Function(String, {String? reason})) {
        await (widget.onDecline as Future<void> Function(String, {String? reason}))(
          bookingId,
          reason: reason,
        );
      } else if (widget.onDecline is Future<void> Function(String)) {
        await (widget.onDecline as Future<void> Function(String))(bookingId);
      } else if (widget.onDecline is VoidCallback) {
        (widget.onDecline as VoidCallback)();
      } else if (widget.onDecline is Function) {
        try {
          final res = (widget.onDecline as dynamic)(bookingId, reason: reason);
          if (res is Future) await res;
        } catch (_) {
          final res = (widget.onDecline as dynamic)();
          if (res is Future) await res;
        }
      }
    } catch (_) {
      // Error feedback is handled by onDecline handler via SnackBar
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildDeclineReasonDialog(BuildContext dialogCtx) {
    String currentSelection = 'OTHER';
    return StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.cancel_outlined, color: Color(0xFFE74C3C), size: 24),
              const SizedBox(width: 8),
              Text(
                'Decline Request',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Please select a reason (optional):',
                  style: GoogleFonts.lato(fontSize: 13, color: Colors.grey[700]),
                ),
                const SizedBox(height: 12),
                ...[
                  {'label': 'Too Far / Travel Distance', 'value': 'TOO_FAR'},
                  {'label': 'Currently Busy', 'value': 'BUSY'},
                  {'label': 'Schedule Conflict', 'value': 'SCHEDULE_CONFLICT'},
                  {'label': 'Other / Personal Reason', 'value': 'OTHER'},
                ].map((opt) {
                  final isSelected = currentSelection == opt['value'];
                  return InkWell(
                    key: Key('decline_reason_${opt['value']}'),
                    onTap: () {
                      setDialogState(() {
                        currentSelection = opt['value']!;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? const Color(0xFFE74C3C) : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt['label']!,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.black87 : Colors.grey[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(null),
              child: Text(
                'CANCEL',
                style: GoogleFonts.lato(color: Colors.grey[600], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogCtx).pop(currentSelection),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'CONFIRM DECLINE',
                style: GoogleFonts.lato(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.requestPayload;
    final poojaName = payload['poojaName']?.toString() ?? 'Sacred Pooja Ritual';
    final totalAmount = payload['totalAmount']?.toString() ?? '0';
    final mode = (payload['mode']?.toString().toUpperCase() == 'ONLINE') ? 'ONLINE' : 'IN_PERSON';
    final samagriIncluded = payload['samagriIncluded'] == true;
    final distanceKm = payload['approximateDistanceKm'] != null
        ? double.tryParse(payload['approximateDistanceKm'].toString())
        : null;
    final formattedTime = BookingDateTimeHelper.formatForDisplay(payload['bookingTime']?.toString());
    final locality = _sanitizeLocality(payload['venueAddress']?.toString());

    final isUrgent = _remainingSeconds <= 10 && !_isExpired;
    final timerColor = _isExpired
        ? const Color(0xFF7F8C8D)
        : (isUrgent ? const Color(0xFFE74C3C) : const Color(0xFFF18C16));

    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Tag & Official Branding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFE0B2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wb_sunny, color: Color(0xFFF18C16), size: 14),
                            const SizedBox(width: 5),
                            Text(
                              AppBranding.appDisplayName,
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFF18C16),
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: mode == 'ONLINE'
                              ? const Color(0xFFE8EAF6)
                              : const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          mode == 'ONLINE' ? 'VIRTUAL RITUAL' : 'IN-PERSON',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: mode == 'ONLINE'
                                ? const Color(0xFF3F51B5)
                                : const Color(0xFF27AE60),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF8C7355), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onDismiss,
                    tooltip: 'Close',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Title and Countdown Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          poojaName,
                          style: GoogleFonts.lato(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF3D2200),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 15, color: Color(0xFF8C7355)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formattedTime,
                                style: GoogleFonts.lato(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF8C7355),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Countdown Radial Display
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: CircularProgressIndicator(
                          value: _isExpired ? 0.0 : (_remainingSeconds / 60.0),
                          backgroundColor: const Color(0xFFF0EBE1),
                          color: timerColor,
                          strokeWidth: 4.5,
                        ),
                      ),
                      Text(
                        _isExpired ? '0s' : '${_remainingSeconds}s',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Dakshina & Samagri Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EE),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFFE0B2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ESTIMATED DAKSHINA',
                          style: GoogleFonts.lato(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF8C7355),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹$totalAmount',
                          style: GoogleFonts.lato(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF27AE60),
                          ),
                        ),
                      ],
                    ),
                    if (samagriIncluded)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F8F0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFB8E6CE)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 14, color: Color(0xFF27AE60)),
                            const SizedBox(width: 4),
                            Text(
                              'Samagri Kit Included',
                              style: GoogleFonts.lato(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF27AE60),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Location & Distance Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE8DCCB)),
                ),
                child: Row(
                  children: [
                    Icon(
                      mode == 'ONLINE' ? Icons.videocam : Icons.location_on,
                      color: const Color(0xFFF18C16),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mode == 'ONLINE' ? 'Virtual Devotee Session' : locality,
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3D2200),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            mode == 'ONLINE'
                                ? 'Secure live audio-video ritual room'
                                : (distanceKm != null
                                    ? '$distanceKm km away • En route service'
                                    : 'Nearby location verified'),
                            style: GoogleFonts.lato(
                              fontSize: 11,
                              color: const Color(0xFF8C7355),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Expired Notice vs Action Buttons
              if (_isExpired) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFEEBA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Request Expired • This pooja request is no longer available.',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF856404),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: widget.onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7F8C8D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'DISMISS',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _handleDecline,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _isSubmitting ? Colors.grey : const Color(0xFFE74C3C),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'DECLINE',
                          style: GoogleFonts.lato(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isSubmitting ? Colors.grey : const Color(0xFFE74C3C),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF27AE60).withValues(alpha: 0.6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, size: 19),
                                  const SizedBox(width: 8),
                                  Text(
                                    'ACCEPT BOOKING',
                                    style: GoogleFonts.lato(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
