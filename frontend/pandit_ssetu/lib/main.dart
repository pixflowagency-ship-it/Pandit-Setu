import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/role_select_screen.dart';
import 'screens/yajman_register_screen.dart';
import 'screens/yajman_login_screen.dart';
import 'screens/yajman_otp_screen.dart';
import 'screens/home_screen.dart';
import 'screens/book_screen.dart';
import 'screens/panchang_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/pooja_booking_flow_screen.dart';
import 'screens/bookings_screen.dart';
import 'widgets/pooja_detail_modal.dart';
import 'user_profile_detail_screen.dart';
import 'screens/kundli_screen.dart';
import 'screens/live_pooja_tracking_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/support_screen.dart';
import 'screens/phool_mala_screen.dart';
import 'screens/nearest_temple_screen.dart';

import 'screens/pandit_login_screen.dart';
import 'screens/pandit_onboarding_screen.dart';
import 'screens/pandit_dashboard_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'theme/app_theme.dart';
import 'constants/branding.dart';
import 'user_data.dart';

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (context, state) => const RoleSelectScreen(),
    ),
    GoRoute(
      path: '/yajman-register',
      builder: (context, state) => const YajmanRegisterScreen(),
    ),
    GoRoute(
      path: '/yajman-otp',
      builder: (context, state) => const YajmanOtpScreen(),
    ),
    GoRoute(
      path: '/yajman-login',
      builder: (context, state) => const YajmanLoginScreen(),
    ),
    GoRoute(
      path: '/pandit-login',
      builder: (context, state) => const PanditLoginScreen(),
    ),
    GoRoute(
      path: '/pandit-onboarding',
      builder: (context, state) => const PanditOnboardingScreen(),
    ),
    GoRoute(
      path: '/pandit-dashboard',
      builder: (context, state) => const PanditDashboardScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/book',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'ghar_jeevan';
        final mode = state.uri.queryParameters['mode'] ?? 'offline';
        return BookScreen(initialCategory: category, mode: mode);
      },
    ),
    GoRoute(
      path: '/book-flow',
      builder: (context, state) {
        PoojaDetail? pooja;
        String mode = state.uri.queryParameters['mode'] ?? 'offline';
        if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          pooja = map['pooja'] as PoojaDetail?;
          if (map.containsKey('mode') && map['mode'] != null) {
            mode = map['mode'].toString();
          }
        } else if (state.extra is PoojaDetail) {
          pooja = state.extra as PoojaDetail;
        }

        pooja ??= const PoojaDetail(
          id: '92086a65-41a9-4545-9588-6f35c8bb8b6b',
          title: 'Satyanarayan Katha',
          category: 'Ghar & Jeevan',
          imageUrl:
              'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
          isPopular: true,
          duration: '1-3 Hour',
          durationBreakdown: '30 mins setup • 2.0 hours main ritual by 1 Pandit',
          description:
              'Shri Satyanarayan Pooja is performed to seek divine blessings of Lord Vishnu for prosperity and health.',
          spiritualSignificance:
              'Reciting Satyanarayan Katha invokes truth and divine consciousness.',
          inclusions: [
            '1 Certified Acharya',
            'Complete Sacred Havan & Samagri Kit'
          ],
          chantingDetails: [
            'Vishnu Sahasranama Stotram',
            '108 Gayatri Mantra'
          ],
          standardPrice: 2100.0,
          samagriPrice: 525.0,
          originalPrice: 3150.0,
        );
        return PoojaBookingFlowScreen(pooja: pooja, bookingMode: mode);
      },
    ),
    GoRoute(
      path: '/bookings',
      builder: (context, state) => const BookingsScreen(),
    ),
    GoRoute(
      path: '/panchang',
      builder: (context, state) => const PanchangScreen(),
    ),
    GoRoute(
      path: '/shop',
      builder: (context, state) => const ShopScreen(),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/profile/detail',
      builder: (context, state) => const UserProfileDetailScreen(),
    ),
    GoRoute(
      path: '/kundli',
      builder: (context, state) => const KundliScreen(),
    ),
    GoRoute(
      path: '/tracking',
      builder: (context, state) => LivePoojaTrackingScreen(
        bookingId: state.uri.queryParameters['bookingId'],
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportScreen(),
    ),
    GoRoute(
      path: '/phool-mala',
      builder: (context, state) => const PhoolMalaScreen(),
    ),
    GoRoute(
      path: '/nearest-temple',
      builder: (context, state) => const NearestTempleScreen(),
    ),
  ],
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserData.loadFromPrefs();
  runApp(const PanditSetuApp());
}

class PanditSetuApp extends StatelessWidget {
  const PanditSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppBranding.appDisplayName,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.lightTheme,
    );
  }
}
