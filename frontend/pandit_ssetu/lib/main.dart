import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/role_select_screen.dart';
import 'screens/yajman_register_screen.dart';
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
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Yajman Login — Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/pandit-login',
      builder: (context, state) => const Scaffold(
        body: Center(child: Text('Pandit Login — Coming Soon')),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/book',
      builder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'wedding';
        return BookScreen(initialCategory: category);
      },
    ),
    GoRoute(
      path: '/book-flow',
      builder: (context, state) {
        final pooja = state.extra as PoojaDetail? ??
            const PoojaDetail(
              id: 'satyanarayan',
              title: 'Satyanarayan Pooja',
              category: 'Wedding Rituals',
              imageUrl:
                  'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
              isPopular: true,
              duration: '2.5 Hours',
              durationBreakdown: '30 mins setup • 2.0 hours main ritual',
              description:
                  'Shri Satyanarayan Pooja is performed to seek divine blessings of Lord Vishnu for prosperity and health.',
              spiritualSignificance:
                  'Reciting Satyanarayan Katha invokes truth and divine consciousness.',
              inclusions: [
                '2 Certified Acharyas',
                'Complete Sacred Havan & Samagri Kit'
              ],
              chantingDetails: [
                'Vishnu Sahasranama Stotram',
                '108 Gayatri Mantra'
              ],
              standardPrice: 2100.0,
              samagriPrice: 1100.0,
              originalPrice: 4000.0,
            );
        return PoojaBookingFlowScreen(pooja: pooja);
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
      builder: (context, state) => const LivePoojaTrackingScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/support',
      builder: (context, state) => const SupportScreen(),
    ),
  ],
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PanditSetuApp());
}

class PanditSetuApp extends StatelessWidget {
  const PanditSetuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pandit Setu',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFFC0392B),
        useMaterial3: true,
      ),
    );
  }
}
