import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'user_data.dart'; // your global UserData class

// ── Same color palette as profile_screen.dart ────────────────────────
class _C {
  static const parchmentBg = Color(0xFFFDFAF3);
  static const warmCream   = Color(0xFFFAF2DC);
  static const richAmber   = Color(0xFF51381B);
  static const mediumAmber = Color(0xFF8D6A42);
  static const saffronGold = Color(0xFFE48F00);
  static const softSaffron = Color(0xFFFFF2D5);
  static const accentLine  = Color(0xFFEFE5CD);
}

class UserProfileDetailScreen extends StatefulWidget {
  const UserProfileDetailScreen({super.key});

  @override
  State<UserProfileDetailScreen> createState() =>
      _UserProfileDetailScreenState();
}

class _UserProfileDetailScreenState extends State<UserProfileDetailScreen> {
  // Edit mode buffers — pulled fresh from UserData each time edit opens
  bool _isEditing = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _tobCtrl;
  late TextEditingController _pobCtrl;
  late TextEditingController _gotraCtrl;
  late TextEditingController _zodiacCtrl;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameCtrl   = TextEditingController(text: UserData.name);
    _phoneCtrl  = TextEditingController(text: UserData.phone);
    _emailCtrl  = TextEditingController(text: UserData.email);
    _dobCtrl    = TextEditingController(text: UserData.dob);
    _tobCtrl    = TextEditingController(text: UserData.tob);
    _pobCtrl    = TextEditingController(text: UserData.pob);
    _gotraCtrl  = TextEditingController(text: UserData.gotra);
    _zodiacCtrl = TextEditingController(text: UserData.zodiac);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _tobCtrl.dispose();
    _pobCtrl.dispose();
    _gotraCtrl.dispose();
    _zodiacCtrl.dispose();
    super.dispose();
  }

  void _saveChanges() {
    UserData.save(
      name:   _nameCtrl.text.trim(),
      phone:  _phoneCtrl.text.trim(),
      email:  _emailCtrl.text.trim(),
      dob:    _dobCtrl.text.trim(),
      tob:    _tobCtrl.text.trim(),
      pob:    _pobCtrl.text.trim(),
      gotra:  _gotraCtrl.text.trim(),
      zodiac: _zodiacCtrl.text.trim(),
    );
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Profile updated successfully 🙏',
          style: GoogleFonts.lato(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: _C.saffronGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build initials avatar ────────────────────────────────────────
  String get _initials {
    final name = UserData.name;
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.parchmentBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildTopBar(context),
                _buildVedicDivider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 16),
                    child: Column(
                      children: [
                        _buildAvatarSection(),
                        const SizedBox(height: 20),
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        if (_isEditing) _buildEditForm(),
                        if (!_isEditing) _buildMenuItems(context),
                        const SizedBox(height: 16),
                        if (!_isEditing) _buildLogoutButton(context),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Back arrow
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _C.softSaffron,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _C.saffronGold.withValues(alpha: 0.5), width: 1),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: _C.richAmber, size: 18),
            ),
          ),
          const Spacer(),
          Text(
            'User Profile',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: _C.richAmber,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          // Settings / Edit icon
          GestureDetector(
            onTap: () {
              _initControllers(); // refresh from latest UserData
              setState(() => _isEditing = !_isEditing);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isEditing ? _C.saffronGold : _C.softSaffron,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _C.saffronGold.withValues(alpha: 0.5), width: 1),
              ),
              child: Icon(
                _isEditing ? Icons.close : Icons.settings_outlined,
                color: _isEditing ? Colors.white : _C.saffronGold,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vedic Ornamental Divider ─────────────────────────────────────
  Widget _buildVedicDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, _C.accentLine],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: _C.saffronGold, shape: BoxShape.circle),
          ),
        ),
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _C.saffronGold, width: 1)),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _C.saffronGold, width: 1)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
                color: _C.saffronGold, shape: BoxShape.circle),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.accentLine, Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Avatar Section ───────────────────────────────────────────────
  Widget _buildAvatarSection() {
    return Column(
      children: [
        const SizedBox(height: 10),
        // Mandala / sun-ray ring behind avatar
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer warm circle
            Container(
              width: 148,
              height: 148,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _C.saffronGold.withValues(alpha: 0.15),
                    _C.softSaffron.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                    color: _C.saffronGold.withValues(alpha: 0.25), width: 1.5),
              ),
            ),
            // Inner avatar circle
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF18C16), Color(0xFFE5A93B)],
                ),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: _C.saffronGold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _initials,
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 40,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Name
        Text(
          UserData.name,
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: _C.richAmber,
          ),
        ),
        const SizedBox(height: 6),
        // Phone
        Text(
          UserData.phone,
          style: GoogleFonts.lato(
            fontSize: 15,
            color: _C.mediumAmber,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        // Email
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email_outlined,
                color: Color(0xFF819B4C), size: 15),
            const SizedBox(width: 6),
            Text(
              UserData.email,
              style: GoogleFonts.lato(
                  fontSize: 13, color: _C.mediumAmber),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Location
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on,
                color: Color(0xFFE65100), size: 15),
            const SizedBox(width: 4),
            Text(
              UserData.pob,
              style: GoogleFonts.lato(
                  fontSize: 13, color: _C.mediumAmber),
            ),
          ],
        ),
      ],
    );
  }

  // ── Info Pills (Gotra + Zodiac) ──────────────────────────────────
  Widget _buildInfoSection() {
    if (UserData.gotra.isEmpty && UserData.zodiac.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (UserData.gotra.isNotEmpty)
          _infoPill(Icons.account_tree_outlined, 'Gotra', UserData.gotra),
        if (UserData.gotra.isNotEmpty && UserData.zodiac.isNotEmpty)
          const SizedBox(width: 12),
        if (UserData.zodiac.isNotEmpty)
          _infoPill(Icons.auto_awesome_outlined, 'Zodiac', UserData.zodiac),
      ],
    );
  }

  Widget _infoPill(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _C.warmCream,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _C.accentLine, width: 1),
        boxShadow: [
          BoxShadow(
            color: _C.richAmber.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _C.saffronGold, size: 15),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.lato(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      color: _C.mediumAmber)),
              Text(value,
                  style: GoogleFonts.lato(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: _C.richAmber)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Menu Items (Edit Profile, My Bookings, Payments, Notifications) ─
  Widget _buildMenuItems(BuildContext context) {
    final items = [
      {
        'icon': Icons.edit_outlined,
        'label': 'Edit Profile',
        'sub': 'Update your devotee information',
        'onTap': () {
          _initControllers();
          setState(() => _isEditing = true);
        },
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'My Bookings',
        'sub': 'View upcoming & past rituals',
        'onTap': () => context.go('/profile'),
      },
      {
        'icon': Icons.lock_outline,
        'label': 'Payments',
        'sub': 'Transaction history & wallet',
        'onTap': () {},
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'sub': 'Manage your alerts',
        'onTap': () {},
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: _C.warmCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.accentLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _C.richAmber.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item['onTap'] as VoidCallback,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(22) : Radius.zero,
                  bottom: isLast
                      ? const Radius.circular(22)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _C.softSaffron,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _C.saffronGold.withValues(alpha: 0.5),
                              width: 0.8),
                        ),
                        child: Icon(item['icon'] as IconData,
                            color: _C.saffronGold, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['label'] as String,
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _C.richAmber,
                                )),
                            Text(item['sub'] as String,
                                style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: _C.mediumAmber)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: _C.mediumAmber, size: 22),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Divider(
                    height: 1,
                    color: _C.accentLine,
                    indent: 16,
                    endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  // ── Logout Button ────────────────────────────────────────────────
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFCF3A00), Color(0xFFFF9100)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFCF3A00).withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            // Clear user data on logout
            UserData.clear();
            context.go('/role-select');
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.power_settings_new,
                  color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                'Logout',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Edit Form ────────────────────────────────────────────────────
  Widget _buildEditForm() {
    return Container(
      decoration: BoxDecoration(
        color: _C.warmCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.accentLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: _C.richAmber.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit, color: _C.saffronGold, size: 18),
              const SizedBox(width: 8),
              Text(
                'EDIT PROFILE',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  color: _C.saffronGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _field('Full Name', _nameCtrl, Icons.person_outline),
          const SizedBox(height: 12),
          _field('Phone Number', _phoneCtrl, Icons.phone_outlined,
                keyboard: TextInputType.phone, readOnly: true),
          const SizedBox(height: 12),
          _field('Email Address', _emailCtrl, Icons.email_outlined,
              keyboard: TextInputType.emailAddress),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field('Gotra', _gotraCtrl,
                    Icons.account_tree_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field('Zodiac', _zodiacCtrl,
                    Icons.auto_awesome_outlined),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _field('Date of Birth (DD-MM-YYYY)', _dobCtrl,
              Icons.cake_outlined,
              keyboard: TextInputType.number),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _field(
                    'Time of Birth', _tobCtrl, Icons.schedule_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _field(
                    'Place of Birth', _pobCtrl, Icons.place_outlined),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Save Button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: _C.saffronGold,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.saffronGold.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _saveChanges,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      readOnly: readOnly,
      style: GoogleFonts.lato(fontSize: 14, color: _C.richAmber),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.lato(fontSize: 12, color: _C.mediumAmber),
        prefixIcon: Icon(icon, color: _C.saffronGold, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.accentLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.accentLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: _C.saffronGold, width: 1.5),
        ),
      ),
    );
  }
}
