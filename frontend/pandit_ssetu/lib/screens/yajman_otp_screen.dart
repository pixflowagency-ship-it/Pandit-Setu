import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../user_data.dart';

class YajmanOtpScreen extends StatefulWidget {
  const YajmanOtpScreen({super.key});

  @override
  State<YajmanOtpScreen> createState() => _YajmanOtpScreenState();
}

class _YajmanOtpScreenState extends State<YajmanOtpScreen> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  Timer? _timer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(6, (index) => TextEditingController());
    _focusNodes = List.generate(6, (index) => FocusNode());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          _timer?.cancel();
        }
      });
    });
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;

    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();

    try {

      final res = await ApiService.sendOtp(UserData.phone);
      final mockOtp = res['data']?['mockOtp'];
      if (mockOtp != null) {
        debugPrint('\n==============================================');
        debugPrint('  🔑 RESENT DEV MODE OTP CODE: $mockOtp');
        debugPrint('==============================================\n');
      }

      _startTimer();

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mockOtp != null
                  ? 'OTP Resent! (Dev Code: $mockOtp)'
                  : 'OTP has been resent successfully!',
              style: GoogleFonts.lato(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFFE8920A),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {

      debugPrint('Resend OTP failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to resend OTP: $e',
              style: GoogleFonts.lato(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleVerify() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter the full 6-digit OTP code.',
            style: GoogleFonts.lato(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {

      final response = await ApiService.verifyOtp(UserData.phone, otp, UserData.name);
      final Map<String, dynamic> user = (response != null && response['data'] != null && response['data']['user'] != null) ? Map<String, dynamic>.from(response['data']['user']) : {};
      UserData.save(
        name: user['name'] ?? user['fullName'] ?? '',
        phone: user['phone'] ?? '',
        email: user['email'] ?? '',
        dob: user['dob'] ?? '',
        tob: user['tob'] ?? '',
        pob: user['pob'] ?? '',
        gotra: user['gotra'] ?? '',
        zodiac: user['zodiac'] ?? '',
        city: user['city'] ?? '',
      );

      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Phone Verified Successfully!',
                  style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.go('/home');
      }
    } catch (e) {

      debugPrint('OTP verification failed: $e');
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'OTP verification failed: $e',
              style: GoogleFonts.lato(),
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [

          Image.asset('assets/images/role_select_bg.png', fit: BoxFit.cover),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 12),

                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new),
                                    color: const Color(0xFF8A7060),
                                    iconSize: 20,
                                    onPressed: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/yajman-register');
                                      }
                                    },
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8920A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.self_improvement,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Pandit Setu',
                                      style: GoogleFonts.lato(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF2D1A00),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 36),

                            Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFE8920A,
                                      ).withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFE8920A,
                                          ).withValues(alpha: 0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFFE8920A),
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),

                            Text(
                              'Verify Your Number',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D1A00),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'Enter the 6-digit OTP code sent to your registered mobile number.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.lato(
                                  fontSize: 14,
                                  color: const Color(0xFF8A7060),
                                  fontWeight: FontWeight.w400,
                                  height: 1.4,
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'ENTER OTP CODE',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.lato(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(6, (index) {
                                      return SizedBox(
                                        width: 42,
                                        height: 52,
                                        child: KeyboardListener(
                                          focusNode:
                                              FocusNode(),
                                          onKeyEvent: (event) {
                                            if (event is KeyDownEvent &&
                                                event.logicalKey ==
                                                    LogicalKeyboardKey
                                                        .backspace &&
                                                _controllers[index]
                                                    .text
                                                    .isEmpty &&
                                                index > 0) {
                                              _focusNodes[index - 1]
                                                  .requestFocus();
                                              _controllers[index - 1].clear();
                                            }
                                          },
                                          child: TextField(
                                            controller: _controllers[index],
                                            focusNode: _focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                              LengthLimitingTextInputFormatter(
                                                1,
                                              ),
                                            ],
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.lato(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2D1A00),
                                            ),
                                            decoration: InputDecoration(
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF5F0EA,
                                              ),
                                              contentPadding: EdgeInsets.zero,
                                              counterText: '',
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFE8920A),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                            onChanged: (value) {
                                              if (value.isNotEmpty) {
                                                if (index < 5) {
                                                  _focusNodes[index + 1]
                                                      .requestFocus();
                                                } else {
                                                  _focusNodes[index].unfocus();
                                                }
                                              }
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                                  const SizedBox(height: 24),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (!_canResend) ...[
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: Color(0xFF8A7060),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Resend code in ${_secondsRemaining}s',
                                          style: GoogleFonts.lato(
                                            fontSize: 13,
                                            color: const Color(0xFF8A7060),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ] else ...[
                                        Text(
                                          "Didn't receive the code? ",
                                          style: GoogleFonts.lato(
                                            fontSize: 13,
                                            color: const Color(0xFF8A7060),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: _handleResend,
                                          child: Text(
                                            'Resend OTP',
                                            style: GoogleFonts.lato(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFFE8920A),
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 24),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE8920A),
                                            Color(0xFFC87000),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFFE8920A,
                                            ).withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextButton(
                                        onPressed: _isVerifying
                                            ? null
                                            : _handleVerify,
                                        child: _isVerifying
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: Colors.white,
                                                      strokeWidth: 2.5,
                                                    ),
                                              )
                                            : Text(
                                                'Verify & Proceed',
                                                style: GoogleFonts.lato(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
