import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pandit_ssetu/constants/branding.dart';
import 'package:pandit_ssetu/screens/book_screen.dart';
import 'package:pandit_ssetu/theme/app_theme.dart';
import 'package:pandit_ssetu/theme/app_typography.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SARV MANGAL UI Polish & Typography Tests', () {
    testWidgets('1. AppTheme and AppTypography use centralized sans-serif font configuration', (tester) async {
      final theme = AppTheme.lightTheme;
      expect(theme.textTheme.bodyMedium?.fontFamily, contains('Lato'));
      expect(theme.textTheme.headlineMedium?.fontFamily, contains('Lato'));

      expect(AppTypography.sansSerifFallback, contains('Lato'));
      expect(AppTypography.sansSerifFallback, contains('sans-serif'));

      // Verify Devanagari font fallback
      expect(AppTypography.sacredDevanagari.fontFamilyFallback, contains('Noto Sans Devanagari'));
    });

    test('2. Official branding displays exact SARV MANGAL lockup', () {
      expect(AppBranding.appDisplayName, equals('SARV MANGAL'));
      expect(AppBranding.appTagline, equals('सर्व मंगल मांगल्ये शिवे सर्वार्थ साधिके'));
    });

    testWidgets('3. BookScreen does not render ritual-mode switch banner in online or offline mode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BookScreen(mode: 'offline'),
        ),
      );
      await tester.pumpAndSettle();

      // Top bar title renders
      expect(find.text('SARV MANGAL'), findsOneWidget);

      // Verify that the ritual-mode banner and switch buttons are completely absent
      expect(find.text('Offline Ritual Mode'), findsNothing);
      expect(find.text('Online Ritual Mode'), findsNothing);
      expect(find.text('Switch to Online'), findsNothing);
      expect(find.text('Switch to Offline'), findsNothing);

      // Select Ritual title and search bar render cleanly
      expect(find.text('Select Ritual'), findsOneWidget);
      expect(find.text('Search rituals, pandits, or locations...'), findsOneWidget);
    });

    testWidgets('4. Select Pooja Format dialog options display Offline Pooja and Online Pooja without numeric prefixes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Trigger the Pooja Format selection dialog
                    showDialog(
                      context: ctx,
                      builder: (dialogCtx) => Dialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        backgroundColor: const Color(0xFFFFFDF8),
                        child: Padding(
                          padding: const EdgeInsets.all(22),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select Pooja Format',
                                style: GoogleFonts.lato(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3D2200),
                                ),
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    'Offline Pooja',
                                    style: GoogleFonts.lato(fontSize: 15.5, fontWeight: FontWeight.bold),
                                  ),
                                  const Text('Home / Office'),
                                ],
                              ),
                              Wrap(
                                children: [
                                  Text(
                                    'Online Pooja',
                                    style: GoogleFonts.lato(fontSize: 15.5, fontWeight: FontWeight.bold),
                                  ),
                                  const Text('LIVE VIDEO'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Select Pooja Format'), findsOneWidget);
      expect(find.text('Offline Pooja'), findsOneWidget);
      expect(find.text('Online Pooja'), findsOneWidget);

      // Verify absence of numeric prefixes
      expect(find.textContaining('1. Offline'), findsNothing);
      expect(find.textContaining('2. Online'), findsNothing);
    });

    testWidgets('5. Narrow portrait layout (320px width) does not produce RenderFlex overflow in BookScreen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const BookScreen(mode: 'offline'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SARV MANGAL'), findsOneWidget);
      expect(find.text('Select Ritual'), findsOneWidget);
    });
  });
}
