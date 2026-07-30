
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
  }

  static void clear() {
    name = phone = email = dob = tob = pob = gotra = zodiac = city = '';
  }

  static bool get hasData => name.isNotEmpty || phone.isNotEmpty;
}
