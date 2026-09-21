import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_side_drawer.dart';
import '../user_data.dart';
import '../services/api_service.dart';

class _C {
  static const parchmentBg = Color(0xFFFDFAF3);
  static const warmCream = Color(0xFFFAF2DC);
  static const richAmber = Color(0xFF51381B);
  static const mediumAmber = Color(0xFF8D6A42);
  static const saffronGold = Color(0xFFE48F00);
  static const softSaffron = Color(0xFFFFF2D5);
  static const accentLine = Color(0xFFEFE5CD);
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditMode = false;

  late String _name, _phone, _email, _dob, _tob, _pob, _gotra, _zodiac;

  late String _savedName = UserData.name;
  late String _savedPhone = UserData.phone;
  late String _savedEmail = UserData.email;
  late String _savedDob = UserData.dob;
  late String _savedTob = UserData.tob;
  late String _savedPob = UserData.pob;
  late String _savedGotra = UserData.gotra;
  late String _savedZodiac = UserData.zodiac;

  @override
  void initState() {
    super.initState();
    _resetBuffers();
    _loadUserProfile();
  }

  void _resetBuffers() {

    _savedName = UserData.name;
    _savedPhone = UserData.phone;
    _savedEmail = UserData.email;
    _savedDob = UserData.dob;
    _savedTob = UserData.tob;
    _savedPob = UserData.pob;
    _savedGotra = UserData.gotra;
    _savedZodiac = UserData.zodiac;
    _name = _savedName;
    _phone = _savedPhone;
    _email = _savedEmail;
    _dob = _savedDob;
    _tob = _savedTob;
    _pob = _savedPob;
    _gotra = _savedGotra;
    _zodiac = _savedZodiac;
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await ApiService.getProfile();
      final user = response['data']?['user'] ?? response['user'] ?? {};
      UserData.save(
        name: user['name'] ?? user['fullName'] ?? '',
        phone: user['phone'] ?? '',
        email: user['email'] ?? '',
        dob: user['dob'] ?? '',
        tob: user['tob'] ?? '',
        pob: user['pob'] ?? '',
        gotra: user['gotra'] ?? '',
        zodiac: user['zodiac'] ?? '',
        city: user['city'] ?? '',
      );
      setState(() {
        _resetBuffers();
      });
    } catch (e) {
      debugPrint('Failed to load profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.parchmentBg,
      drawer: const AppSideDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context),
                        const SizedBox(height: 4),
                        _buildVedicDivider(),
                        const SizedBox(height: 18),

                        _buildSacredDevoteeCoreCard(context),
                        const SizedBox(height: 16),

                        _buildAstroQuickViewCard(),
                        const SizedBox(height: 16),

                        _buildSavedAddressesCard(),
                        const SizedBox(height: 16),

                        _buildMyBookingsCard(),
                        const SizedBox(height: 16),

                        _buildFavoriteExperts(),
                        const SizedBox(height: 16),

                        _buildAppSettingsAndAccountActions(context),
                        const SizedBox(height: 16),

                        _buildContactSupportBtn(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (_isEditMode) _buildEditDialog(context),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentPath: '/profile'),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                child: const Icon(Icons.menu, color: _C.richAmber, size: 26),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Pandit Setu',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: _C.richAmber,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => setState(() {
            _resetBuffers();
            _isEditMode = true;
          }),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.softSaffron,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _C.saffronGold.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.settings_outlined,
              color: _C.saffronGold,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

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
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _C.saffronGold,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.saffronGold, width: 1),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _C.saffronGold, width: 1),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _C.saffronGold,
              shape: BoxShape.circle,
            ),
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

  Widget _buildSacredDevoteeCoreCard(BuildContext context) {
    final name = UserData.name.isNotEmpty
        ? UserData.name
        : (_savedName.isNotEmpty ? _savedName : 'Sacred Devotee');
    final phone = UserData.phone.isNotEmpty
        ? UserData.phone
        : (_savedPhone.isNotEmpty ? _savedPhone : 'Not provided');
    final email = UserData.email.isNotEmpty
        ? UserData.email
        : (_savedEmail.isNotEmpty ? _savedEmail : 'devotee@panditsetu.com');
    final city = UserData.city.isNotEmpty ? UserData.city : 'Varanasi, UP';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: _C.saffronGold.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF51381B).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.softSaffron,
                  border: Border.all(color: _C.saffronGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _C.saffronGold.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'Y',
                    style: GoogleFonts.lato(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: _C.saffronGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: _C.richAmber,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() {
                            _resetBuffers();
                            _isEditMode = true;
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _C.softSaffron,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _C.saffronGold.withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: _C.saffronGold,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 14,
                          color: _C.mediumAmber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _C.mediumAmber,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.email_outlined,
                          size: 14,
                          color: _C.mediumAmber,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: _C.mediumAmber,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _C.accentLine),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: Colors.green,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VERIFIED DEVOTEE',
                      style: GoogleFonts.lato(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: _C.saffronGold,
                    size: 14,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    city,
                    style: GoogleFonts.lato(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _C.richAmber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAstroQuickViewCard() {
    final gotra = UserData.gotra.isNotEmpty
        ? UserData.gotra
        : (_savedGotra.isNotEmpty ? _savedGotra : 'Kashyap');
    final zodiac = UserData.zodiac.isNotEmpty
        ? UserData.zodiac
        : (_savedZodiac.isNotEmpty ? _savedZodiac : 'Simha (Leo)');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.accentLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF51381B).withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.softSaffron,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: _C.saffronGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Astrological Quick-View',
                    style: GoogleFonts.lato(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: _C.richAmber,
                    ),
                  ),
                  Text(
                    'Personalized Kundli & Panchang Profile',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: _C.mediumAmber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildAstroTagChip(
                  icon: Icons.temple_hindu,
                  label: 'GOTRA',
                  value: gotra,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAstroTagChip(
                  icon: Icons.brightness_5,
                  label: 'ZODIAC',
                  value: zodiac,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAstroTagChip(
                  icon: Icons.nightlight_round,
                  label: 'NAKSHATRA',
                  value: 'Purva Phalguni',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _resetBuffers();
                _isEditMode = true;
              }),
              icon:
                  const Icon(Icons.edit_note, color: _C.saffronGold, size: 20),
              label: Text(
                'Edit Kundli Details',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _C.saffronGold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _C.saffronGold, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: _C.softSaffron.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstroTagChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: _C.warmCream,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _C.accentLine, width: 0.8),
      ),
      child: Column(
        children: [
          Icon(icon, color: _C.saffronGold, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.lato(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: _C.mediumAmber,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _C.richAmber,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSavedAddressesCard() {
    final city = UserData.city.isNotEmpty ? UserData.city : 'Mumbai';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.accentLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF51381B).withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _C.softSaffron,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: _C.saffronGold,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved Locations for Samagri & Pooja',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _C.richAmber,
                      ),
                    ),
                    Text(
                      'Delivery and Pandit visit addresses',
                      style: GoogleFonts.lato(
                        fontSize: 11,
                        color: _C.mediumAmber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _buildAddressTile(
            title: 'Home (Primary)',
            address: 'Flat 402, Shivam Apts, MG Road, $city - 400001',
            icon: Icons.home_outlined,
            isPrimary: true,
          ),
          const SizedBox(height: 8),

          _buildAddressTile(
            title: 'Temple / Event Venue',
            address: 'Plot 12, Sector 14, Near Hanuman Mandir',
            icon: Icons.temple_hindu_outlined,
            isPrimary: false,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () => _showAddAddressDialog(),
              icon: const Icon(
                Icons.add_location_alt_outlined,
                color: _C.saffronGold,
                size: 18,
              ),
              label: Text(
                '+ Add New Location',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _C.saffronGold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _C.saffronGold, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTile({
    required String title,
    required String address,
    required IconData icon,
    required bool isPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.warmCream,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.accentLine),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _C.softSaffron,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _C.saffronGold.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: _C.saffronGold, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _C.richAmber,
                      ),
                    ),
                    if (isPrimary) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _C.saffronGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'DEFAULT',
                          style: GoogleFonts.lato(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: _C.saffronGold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: GoogleFonts.lato(
                    fontSize: 11,
                    color: _C.mediumAmber,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              color: _C.mediumAmber,
              size: 18,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  void _showAddAddressDialog() {
    final addrCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.parchmentBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Add New Location',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: _C.richAmber,
          ),
        ),
        content: TextField(
          controller: addrCtrl,
          decoration: InputDecoration(
            labelText: 'Full Address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Cancel', style: GoogleFonts.lato(color: _C.mediumAmber)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'New address saved!',
                    style: GoogleFonts.lato(color: Colors.white),
                  ),
                  backgroundColor: _C.saffronGold,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _C.saffronGold,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyBookingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: _C.warmCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.accentLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF51381B).withValues(alpha: 0.08),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Bookings',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _C.richAmber,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/book'),
                child: Text(
                  'View History',
                  style: GoogleFonts.lato(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _C.saffronGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=300',
                        width: 95,
                        height: 95,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 95,
                          height: 95,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.all(
                              Radius.circular(14),
                            ),
                          ),
                          child: const Icon(
                            Icons.temple_hindu,
                            color: Color(0xFFE8920A),
                            size: 36,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      _C.saffronGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: _C.saffronGold.withValues(
                                      alpha: 0.5,
                                    ),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'UPCOMING',
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.5,
                                    color: _C.saffronGold,
                                  ),
                                ),
                              ),
                              Text(
                                'Mar 20',
                                style: GoogleFonts.lato(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _C.richAmber,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Satyanarayan Pooja',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _C.richAmber,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pandit Vishwanath Shastri',
                            style: GoogleFonts.lato(
                              fontSize: 12,
                              color: _C.mediumAmber,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                color: _C.saffronGold,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '08:30 AM  –  Home Visit',
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: _C.richAmber,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/book'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEEEEEE),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size(0, 40),
                          elevation: 0,
                        ),
                        child: Text(
                          'View Details',
                          style: GoogleFonts.lato(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3D2200),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFFF18C16), Color(0xFFE5A93B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ElevatedButton(
                          onPressed: () => context.go('/book'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(0, 40),
                          ),
                          child: Text(
                            'Reschedule',
                            style: GoogleFonts.lato(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteExperts() {
    final experts = [
      {'rating': '4.9', 'color': const Color(0xFF2C3E50)},
      {'rating': '5.0', 'color': const Color(0xFFF57F17)},
      {'rating': '4.8', 'color': const Color(0xFF3E2723)},
    ];

    return Container(
      decoration: BoxDecoration(
        color: _C.warmCream,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.accentLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF51381B).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Favorite Experts',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _C.richAmber,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ...experts.map(
                (e) => Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: e['color'] as Color,
                        shape: BoxShape.circle,
                        border: Border.all(color: _C.saffronGold, width: 1.5),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star,
                          color: _C.saffronGold,
                          size: 11,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${e['rating']} ★',
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _C.mediumAmber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _C.saffronGold.withValues(alpha: 0.7),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      color: Colors.white,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: _C.saffronGold,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add',
                    style: GoogleFonts.lato(
                      fontSize: 11,
                      color: _C.mediumAmber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsAndAccountActions(BuildContext context) {
    final items = [
      {
        'icon': Icons.history,
        'label': 'My Bookings History',
        'sub': 'View upcoming & past pooja bookings',
        'onTap': () => context.push('/bookings'),
        'isDestructive': false,
      },
      {
        'icon': Icons.badge_outlined,
        'label': 'My Devotee Profile Details',
        'sub': 'View full devotee record specs',
        'onTap': () => context.go('/profile/detail'),
        'isDestructive': false,
      },
      {
        'icon': Icons.headset_mic_outlined,
        'label': 'Help & Support',
        'sub': 'Contact support team & FAQs',
        'onTap': () => context.push('/support'),
        'isDestructive': false,
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'label': 'Privacy & Terms',
        'sub': 'App usage policy & privacy standards',
        'onTap': () {},
        'isDestructive': false,
      },
      {
        'icon': Icons.logout,
        'label': 'Logout',
        'sub': 'Clear session & sign out of app',
        'onTap': () => _handleLogout(context),
        'isDestructive': true,
      },
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _C.accentLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF51381B).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            child: Text(
              'App Settings & Account Actions',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _C.richAmber,
              ),
            ),
          ),
          const Divider(height: 1, color: _C.accentLine),
          Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isLast = i == items.length - 1;
              final isDestructive = item['isDestructive'] as bool;
              final itemColor =
                  isDestructive ? const Color(0xFFD32F2F) : _C.richAmber;
              final iconColor =
                  isDestructive ? const Color(0xFFD32F2F) : _C.saffronGold;
              final iconBg =
                  isDestructive ? const Color(0xFFFFEBEE) : _C.softSaffron;

              return Column(
                children: [
                  InkWell(
                    onTap: item['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(0) : Radius.zero,
                      bottom: isLast ? const Radius.circular(22) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: iconBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: iconColor.withValues(alpha: 0.3),
                                width: 0.8,
                              ),
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: iconColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['label'] as String,
                                  style: GoogleFonts.lato(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: itemColor,
                                  ),
                                ),
                                Text(
                                  item['sub'] as String,
                                  style: GoogleFonts.lato(
                                    fontSize: 11,
                                    color: isDestructive
                                        ? const Color(0xFFE57373)
                                        : _C.mediumAmber,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: isDestructive
                                ? const Color(0xFFD32F2F)
                                : _C.mediumAmber,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      color: _C.accentLine,
                      indent: 16,
                      endIndent: 16,
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.parchmentBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Confirm Logout',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            color: _C.richAmber,
          ),
        ),
        content: Text(
          'Are you sure you want to log out of your Pandit Setu devotee account?',
          style: GoogleFonts.lato(color: _C.mediumAmber),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.lato(color: _C.mediumAmber),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      UserData.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
      if (context.mounted) {
        context.go('/role-select');
      }
    }
  }

  Widget _buildContactSupportBtn() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: _C.saffronGold,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: _C.saffronGold.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.headset_mic_outlined,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            'Contact Support',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditDialog(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          decoration: BoxDecoration(
            color: _C.parchmentBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _C.saffronGold, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: _C.saffronGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Sacred Devotee Core',
                      style: GoogleFonts.lato(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: _C.richAmber,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _isEditMode = false),
                      icon: const Icon(Icons.close, color: _C.richAmber),
                    ),
                  ],
                ),
              ),
              const Divider(color: _C.accentLine, height: 1),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DEVOTEE RECORD FORM',
                        style: GoogleFonts.lato(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 1.0,
                          color: _C.saffronGold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _editField(
                        'Full Name',
                        _name,
                        Icons.person_outline,
                        (v) => setState(() => _name = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _editField(
                              'Gotra',
                              _gotra,
                              Icons.location_on_outlined,
                              (v) => setState(() => _gotra = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _editField(
                              'Zodiac',
                              _zodiac,
                              Icons.auto_awesome_outlined,
                              (v) => setState(() => _zodiac = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _editField(
                        'Date of Birth (DD-MM-YYYY)',
                        _dob,
                        Icons.cake_outlined,
                        (v) => setState(() => _dob = v),
                        keyboard: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _editField(
                              'Time of Birth',
                              _tob,
                              Icons.schedule_outlined,
                              (v) => setState(() => _tob = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: _editField(
                              'Place of Birth',
                              _pob,
                              Icons.place_outlined,
                              (v) => setState(() => _pob = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _editField(
                        'Phone Number',
                        _phone,
                        Icons.phone_outlined,
                        (v) => setState(() => _phone = v),
                        keyboard: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      _editField(
                        'Email Address',
                        _email,
                        Icons.email_outlined,
                        (v) => setState(() => _email = v),
                        keyboard: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _savedName = _name;
                              _savedPhone = _phone;
                              _savedEmail = _email;
                              _savedDob = _dob;
                              _savedTob = _tob;
                              _savedPob = _pob;
                              _savedGotra = _gotra;
                              _savedZodiac = _zodiac;
                              _isEditMode = false;
                            });
                            UserData.save(
                              name: _name,
                              phone: _phone,
                              email: _email,
                              dob: _dob,
                              tob: _tob,
                              pob: _pob,
                              gotra: _gotra,
                              zodiac: _zodiac,
                            );
                          },
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            'Apply Devotee Record Changes',
                            style: GoogleFonts.lato(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _C.saffronGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    String value,
    IconData icon,
    ValueChanged<String> onChanged, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      keyboardType: keyboard,
      style: GoogleFonts.lato(fontSize: 14, color: _C.richAmber),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.lato(fontSize: 13, color: _C.mediumAmber),
        prefixIcon: Icon(icon, color: _C.saffronGold, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 12,
        ),
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
          borderSide: const BorderSide(color: _C.saffronGold, width: 1.5),
        ),
      ),
    );
  }
}
