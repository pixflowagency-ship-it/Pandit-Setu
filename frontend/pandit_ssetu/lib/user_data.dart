// lib/user_data.dart
// Global in-memory store — persists for the app session.
// Call UserData.save() after register, read fields anywhere.

class UserData {
  static String name   = '';
  static String phone  = '';
  static String email  = '';
  static String dob    = '';
  static String tob    = '';
  static String pob    = '';
  static String gotra  = '';
  static String zodiac = '';
  static String city   = '';

  /// Call this right after the register form is submitted.
  static void save({
    required String name,
    required String phone,
    String email  = '',
    String dob    = '',
    String tob    = '',
    String pob    = '',
    String gotra  = '',
    String zodiac = '',
    String city   = '',
  }) {
    UserData.name   = name;
    UserData.phone  = phone;
    UserData.email  = email;
    UserData.dob    = dob;
    UserData.tob    = tob;
    UserData.pob    = pob;
    UserData.gotra  = gotra;
    UserData.zodiac = zodiac;
    UserData.city   = city;
  }

  /// Call on logout — wipes all stored data.
  static void clear() {
    name = phone = email = dob = tob = pob = gotra = zodiac = city = '';
  }

  static bool get hasData => name.isNotEmpty || phone.isNotEmpty;
}
