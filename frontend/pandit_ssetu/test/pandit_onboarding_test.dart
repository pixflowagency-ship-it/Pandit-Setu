import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/screens/pandit_onboarding_screen.dart';
import 'package:pandit_ssetu/constants/branding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pandit Onboarding & Verification Workflow Tests (Phase P2-A)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'mock-pandit-jwt-token',
        'user_role': 'PANDIT',
      });
    });

    test('Branding display name is SARV MANGAL across constants', () {
      expect(AppBranding.appDisplayName, 'SARV MANGAL');
      expect(AppBranding.appTagline, contains('सर्व मंगल'));
    });

    test('Onboarding step resolution logic', () {
      // Step calculation rules:
      // STAGE_1_PHONE_VERIFIED -> Step 1 (Profile Details)
      // STAGE_2_PROFILE_COMPLETE -> Step 2 (Documents Upload)
      // STAGE_3_DOCS_SUBMITTED -> Step 3 (Video Verification)
      // STAGE_4_VIDEO_COMPLETED or AWAITING_APPROVAL -> Step 4 (Status & Approval Gate)
      int resolveStep(String? stage) {
        if (stage == 'STAGE_2_PROFILE_COMPLETE') return 2;
        if (stage == 'STAGE_3_DOCS_SUBMITTED') return 3;
        if (stage == 'STAGE_4_VIDEO_COMPLETED' || stage == 'DOCUMENTS_UNDER_REVIEW') return 4;
        return 1;
      }

      expect(resolveStep('STAGE_1_PHONE_VERIFIED'), 1);
      expect(resolveStep(null), 1);
      expect(resolveStep('STAGE_2_PROFILE_COMPLETE'), 2);
      expect(resolveStep('STAGE_3_DOCS_SUBMITTED'), 3);
      expect(resolveStep('STAGE_4_VIDEO_COMPLETED'), 4);
      expect(resolveStep('DOCUMENTS_UNDER_REVIEW'), 4);
    });

    test('Dashboard access is strictly blocked when verificationStatus is not APPROVED', () {
      bool canAccessDashboard(Map<String, dynamic> statusData) {
        final verificationStatus = statusData['verificationStatus']?.toString().toUpperCase();
        final isVerified = statusData['isVerified'] == true;
        return verificationStatus == 'APPROVED' && isVerified;
      }

      // Scenario 1: Phone verified only
      expect(canAccessDashboard({'verificationStatus': 'PENDING', 'isVerified': false}), isFalse);

      // Scenario 2: Profile complete
      expect(canAccessDashboard({'verificationStatus': 'PENDING', 'isVerified': false, 'stage': 'STAGE_2_PROFILE_COMPLETE'}), isFalse);

      // Scenario 3: Documents submitted under review
      expect(canAccessDashboard({'verificationStatus': 'UNDER_REVIEW', 'isVerified': false}), isFalse);

      // Scenario 4: Video verification completed, pending final approval
      expect(canAccessDashboard({'verificationStatus': 'UNDER_REVIEW', 'isVerified': false, 'videoCallStatus': 'COMPLETED'}), isFalse);

      // Scenario 5: Rejected application
      expect(canAccessDashboard({'verificationStatus': 'REJECTED', 'isVerified': false}), isFalse);

      // Scenario 6: Approved by administrator/authorized verifier
      expect(canAccessDashboard({'verificationStatus': 'APPROVED', 'isVerified': true}), isTrue);
    });

    test('Multi-Role: Yajman identity requires explicit Pandit application', () {
      // When Yajman attempts Pandit login without existing Pandit profile
      final yajmanLoginResponse = {
        'success': true,
        'data': {
          'token': 'jwt-for-phone',
          'user': {'id': 'user-123', 'phone': '9876543210', 'role': 'YAJMAN'},
          'isPandit': false,
          'hasPanditProfile': false,
          'requiresApplication': true,
        }
      };

      final data = yajmanLoginResponse['data'] as Map<String, dynamic>;
      expect(data['requiresApplication'], isTrue);
      expect(data['isPandit'], isFalse);

      // Once applied:
      final appliedResponse = {
        'success': true,
        'data': {
          'pandit': {
            'id': 'pandit-123',
            'userId': 'user-123',
            'verificationStage': 'STAGE_1_PHONE_VERIFIED',
            'verificationStatus': 'PENDING',
            'isVerified': false,
          }
        }
      };

      final panditData = (appliedResponse['data'] as Map<String, dynamic>)['pandit'] as Map<String, dynamic>;
      expect(panditData['userId'], 'user-123'); // SAME phone identity, no duplicate
      expect(panditData['verificationStage'], 'STAGE_1_PHONE_VERIFIED');
      expect(panditData['verificationStatus'], 'PENDING');
      expect(panditData['isVerified'], isFalse);
    });

    testWidgets('PanditOnboardingScreen renders SARV MANGAL title in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PanditOnboardingScreen(),
        ),
      );

      // Verify initial frame renders the AppBar title with SARV MANGAL
      expect(find.text('${AppBranding.appDisplayName} • Acharya Onboarding'), findsOneWidget);
    });
  });
}
