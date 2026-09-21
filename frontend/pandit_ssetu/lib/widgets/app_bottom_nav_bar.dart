import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AppBottomNavBar extends StatelessWidget {
  final String currentPath;

  const AppBottomNavBar({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final navItems = [
      {
        'path': '/home',
        'icon': Icons.home_outlined,
        'activeIcon': Icons.home,
        'label': 'Home',
      },
      {
        'path': '/book',
        'icon': Icons.menu_book_outlined,
        'activeIcon': Icons.menu_book,
        'label': 'Book',
      },
      {
        'path': '/panchang',
        'icon': Icons.calendar_month_outlined,
        'activeIcon': Icons.calendar_month,
        'label': 'Panchang',
      },
      {
        'path': '/shop',
        'icon': Icons.shopping_bag_outlined,
        'activeIcon': Icons.shopping_bag,
        'label': 'Shop',
      },
      {
        'path': '/profile',
        'icon': Icons.person_outline,
        'activeIcon': Icons.person,
        'label': 'Profile',
      },
    ];

    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.only(bottom: 16, top: 4, left: 16, right: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              // Translucent frosted glass dark chocolate background
              color: const Color(0xD92E1906),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: const Color(0x40F18C16), // Translucent saffron glass rim border
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: navItems.map((item) {
                final String itemPath = item['path'] as String;
                final bool isActive = currentPath == itemPath;
                final IconData iconData =
                    (isActive ? item['activeIcon'] : item['icon']) as IconData;
                final String label = item['label'] as String;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (!isActive) {
                        context.go(itemPath);
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          iconData,
                          size: 23,
                          color: isActive
                              ? const Color(0xFFF18C16) // Warm saffron orange active state
                              : const Color(0xFFD4C5B9), // Soft cream/grey inactive state
                        ),
                        const SizedBox(height: 3),
                        Text(
                          label,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFFF18C16)
                                : const Color(0xFFD4C5B9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
