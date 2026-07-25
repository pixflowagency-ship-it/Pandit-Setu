import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../user_data.dart';
import '../services/api_service.dart';

class YajmanRegisterScreen extends StatefulWidget {
  const YajmanRegisterScreen({super.key});

  @override
  State<YajmanRegisterScreen> createState() => _YajmanRegisterScreenState();
}

class _YajmanRegisterScreenState extends State<YajmanRegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _handleContinue() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your full name',
            style: GoogleFonts.lato(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter a valid 10-digit phone number',
            style: GoogleFonts.lato(),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Call send OTP API
      await ApiService.sendOtp(phone);

      // Save registration info to UserData
      UserData.save(
        name: name,
        phone: phone,
        email: email,
      );

      if (mounted) {
        // Navigate to OTP Screen
        context.go('/yajman-otp');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send OTP. Please try again.',
              style: GoogleFonts.lato(),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ─── BACKGROUND IMAGE ───────────────────────────────
          Image.asset(
            'assets/images/role_select_bg.png',
            fit: BoxFit.cover,
          ),

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

                            // ─── TOP HEADER (Logo and Close) ─────────────────
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFE8920A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.self_improvement,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
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
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: IconButton(
                                    icon: const Icon(Icons.close),
                                    color: const Color(0xFF8A7060),
                                    iconSize: 22,
                                    onPressed: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/role-select');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // ─── SPARKLING HERO BADGE ────────────────────────
                            Center(
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8920A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFF1A1A1A),
                                  size: 26,
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ─── HERO TEXT ───────────────────────────────────
                            Text(
                              'Begin Your Journey',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF2D1A00),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Connect with authentic spiritual wisdom.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.lato(
                                fontSize: 14,
                                color: const Color(0xFF4A3728),
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ─── FORM CARD ───────────────────────────────────
                            Container(
                              margin: const EdgeInsets.only(bottom: 32),
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
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // FIELD 1 — FULL NAME
                                  Text(
                                    'FULL NAME',
                                    style: GoogleFonts.lato(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _nameController,
                                    textCapitalization: TextCapitalization.words,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF5F0EA),
                                      hintText: 'E.g. Arjun Sharma',
                                      hintStyle: GoogleFonts.lato(
                                        color: const Color(0xFFE8920A).withValues(alpha: 0.35),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      color: const Color(0xFF2D1A00),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // FIELD 2 — PHONE NUMBER
                                  Text(
                                    'PHONE NUMBER',
                                    style: GoogleFonts.lato(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF1A1A1A),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      // Country code pill
                                      Container(
                                        height: 48,
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.symmetric(horizontal: 18),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F0EA),
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          '+91',
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF1A1A1A),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Phone number textfield
                                      Expanded(
                                        child: TextField(
                                          controller: _phoneController,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.digitsOnly,
                                            LengthLimitingTextInputFormatter(10),
                                          ],
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: const Color(0xFFF5F0EA),
                                            hintText: '98765 43210',
                                            hintStyle: GoogleFonts.lato(
                                              color: const Color(0xFFE8920A).withValues(alpha: 0.35),
                                            ),
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 14,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(30),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          style: GoogleFonts.lato(
                                            fontSize: 16,
                                            color: const Color(0xFF2D1A00),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Small info text
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 14,
                                        color: Color(0xFF8A7060),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'A 6-digit OTP will be sent for verification',
                                        style: GoogleFonts.lato(
                                          fontSize: 11,
                                          color: const Color(0xFF8A7060),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // FIELD 3 — EMAIL ADDRESS
                                  RichText(
                                    text: TextSpan(
                                      style: GoogleFonts.lato(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1A1A),
                                        letterSpacing: 1.5,
                                      ),
                                      children: const [
                                        TextSpan(text: 'EMAIL ADDRESS '),
                                        TextSpan(
                                          text: '(optional)',
                                          style: TextStyle(
                                            color: Color(0xFFE8920A),
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: const Color(0xFFF5F0EA),
                                      hintText: 'name@example.com',
                                      hintStyle: GoogleFonts.lato(
                                        color: const Color(0xFFE8920A).withValues(alpha: 0.35),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 14,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(30),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    style: GoogleFonts.lato(
                                      fontSize: 16,
                                      color: const Color(0xFF2D1A00),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  // CONTINUE BUTTON
                                  SizedBox(
                                    width: double.infinity,
                                    height: 54,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFE8920A), Color(0xFFC87000)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE8920A).withValues(alpha: 0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: TextButton(
                                        onPressed: _isLoading ? null : _handleContinue,
                                        child: _isLoading
                                            ? const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : Text(
                                                'Continue',
                                                style: GoogleFonts.lato(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // ─── DIVIDER ───────────────────────────────
                                  const Divider(
                                    color: Color(0xFFE0D5C5),
                                    thickness: 0.8,
                                  ),

                                  const SizedBox(height: 16),

                                  // ─── BOTTOM TEXT ───────────────────────────
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: GoogleFonts.lato(
                                          fontSize: 13,
                                          color: const Color(0xFF8A7060),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          context.go('/yajman-login');
                                        },
                                        child: Text(
                                          'Log In',
                                          style: GoogleFonts.lato(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFFE8920A),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
