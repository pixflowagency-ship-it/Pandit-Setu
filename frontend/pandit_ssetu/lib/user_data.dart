import 'package:shared_preferences/shared_preferences.dart';

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

    _persistToPrefs();
  }

  static Future<void> _persistToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
      await prefs.setString('user_phone', phone);
      await prefs.setString('user_email', email);
      await prefs.setString('user_dob', dob);
      await prefs.setString('user_tob', tob);
      await prefs.setString('user_pob', pob);
      await prefs.setString('user_gotra', gotra);
      await prefs.setString('user_zodiac', zodiac);
      await prefs.setString('user_city', city);
    } catch (_) {}
  }

  static Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      name   = prefs.getString('user_name') ?? name;
      phone  = prefs.getString('user_phone') ?? phone;
      email  = prefs.getString('user_email') ?? email;
      dob    = prefs.getString('user_dob') ?? dob;
      tob    = prefs.getString('user_tob') ?? tob;
      pob    = prefs.getString('user_pob') ?? pob;
      gotra  = prefs.getString('user_gotra') ?? gotra;
      zodiac = prefs.getString('user_zodiac') ?? zodiac;
      city   = prefs.getString('user_city') ?? city;
    } catch (_) {}
  }

  static Future<void> clear() async {
    name = phone = email = dob = tob = pob = gotra = zodiac = city = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_phone');
      await prefs.remove('user_email');
      await prefs.remove('user_dob');
      await prefs.remove('user_tob');
      await prefs.remove('user_pob');
      await prefs.remove('user_gotra');
      await prefs.remove('user_zodiac');
      await prefs.remove('user_city');
    } catch (_) {}
  }

  static bool get hasData => name.isNotEmpty || phone.isNotEmpty;
}
