import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pandit_ssetu/user_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserData and Profile Persistence Tests (BUG-001)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      UserData.clear();
    });

    test('UserData saves and persists to in-memory state', () {
      UserData.save(
        name: 'Aacharya Sharma',
        phone: '9876543210',
        email: 'sharma@vedic.org',
        dob: '01/01/1985',
        tob: '06:00 AM',
        pob: 'Varanasi',
        gotra: 'Kashyap',
        zodiac: 'Aries',
        city: 'Kashi',
      );

      expect(UserData.name, 'Aacharya Sharma');
      expect(UserData.phone, '9876543210');
      expect(UserData.email, 'sharma@vedic.org');
      expect(UserData.gotra, 'Kashyap');
      expect(UserData.city, 'Kashi');
      expect(UserData.hasData, isTrue);
    });

    test('UserData restores correctly from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'user_name': 'Pandit Ji',
        'user_phone': '9123456780',
        'user_email': 'pandit@setu.com',
        'user_gotra': 'Bharadwaj',
        'user_city': 'Ayodhya',
      });

      await UserData.loadFromPrefs();

      expect(UserData.name, 'Pandit Ji');
      expect(UserData.phone, '9123456780');
      expect(UserData.email, 'pandit@setu.com');
      expect(UserData.gotra, 'Bharadwaj');
      expect(UserData.city, 'Ayodhya');
    });

    test('Profile response parsing does not wipe existing valid fields when keys are empty', () {
      // Step 1: Pre-populate existing user data
      UserData.save(
        name: 'Original Devotee',
        phone: '+91 9999999999',
        email: 'devotee@temple.com',
        gotra: 'Vashistha',
      );

      // Step 2: Simulate backend returning partial object without gotra or email
      final backendResponse = <String, dynamic>{
        'success': true,
        'data': {
          'fullName': 'Updated Devotee Name',
          'phone': '+91 9999999999',
          'email': null,
          'gotra': '',
        },
      };

      final data = backendResponse['data'] as Map<String, dynamic>;
      final fetchedName = (data['name'] ?? data['fullName'])?.toString();
      final fetchedPhone = data['phone']?.toString();
      final fetchedEmail = data['email']?.toString();
      final fetchedGotra = data['gotra']?.toString();

      // Applying safe merge pattern
      UserData.save(
        name: (fetchedName != null && fetchedName.trim().isNotEmpty) ? fetchedName : UserData.name,
        phone: (fetchedPhone != null && fetchedPhone.trim().isNotEmpty) ? fetchedPhone : UserData.phone,
        email: (fetchedEmail != null && fetchedEmail.trim().isNotEmpty) ? fetchedEmail : UserData.email,
        gotra: (fetchedGotra != null && fetchedGotra.trim().isNotEmpty) ? fetchedGotra : UserData.gotra,
      );

      // Name should be updated
      expect(UserData.name, 'Updated Devotee Name');
      // Phone should remain
      expect(UserData.phone, '+91 9999999999');
      // Email and Gotra must NOT be wiped with empty string
      expect(UserData.email, 'devotee@temple.com');
      expect(UserData.gotra, 'Vashistha');
    });

    test('UserData clear removes all fields and clears prefs', () async {
      UserData.save(
        name: 'Test Devotee',
        phone: '1234567890',
      );
      expect(UserData.hasData, isTrue);

      await UserData.clear();
      expect(UserData.name, isEmpty);
      expect(UserData.phone, isEmpty);
      expect(UserData.hasData, isFalse);
    });
  });
}
