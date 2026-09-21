import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NeumorphicButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;

  const NeumorphicButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.gradient = const LinearGradient(
      colors: [Color(0xFFF18C16), Color(0xFFD97706)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.backgroundColor,
    this.textColor = Colors.white,
    this.height = 48,
    this.width,
    this.borderRadius = 25,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: widget.height,
        width: widget.width,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? const Color(0xFFF18C16),
          gradient: widget.backgroundColor == null ? widget.gradient : null,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: const Offset(1, 1),
                    blurRadius: 3,
                  ),
                ]
              : [
                  // Light highlight top-left
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.45),
                    offset: const Offset(-3, -3),
                    blurRadius: 8,
                  ),
                  // Dark shadow bottom-right
                  BoxShadow(
                    color: const Color(0xFF3D2200).withValues(alpha: 0.35),
                    offset: const Offset(4, 5),
                    blurRadius: 10,
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: widget.textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              widget.text,
              style: GoogleFonts.lato(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
