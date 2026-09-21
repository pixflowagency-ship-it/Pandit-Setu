import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/pooja_detail_modal.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_side_drawer.dart';

class BookScreen extends StatefulWidget {
  final String initialCategory;
  const BookScreen({super.key, this.initialCategory = 'ghar_jeevan'});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  late String selectedCategory;

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory;
    if (!_categoryRituals.containsKey(selectedCategory)) {
      selectedCategory = 'ghar_jeevan';
    }
  }

  final Map<String, List<PoojaDetail>> _categoryRituals = {
    'ghar_jeevan': [
      const PoojaDetail(
        id: 'griha_pravesh_pooja',
        title: 'Griha Pravesh Pooja',
        category: 'Ghar aur Jeevan se related Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=600&q=80',
        isPopular: true,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 2 Pandit(s)',
        description: 'Auspicious Griha Pravesh Pooja performed strictly according to Vedic Shastras by 2 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '2 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 5100.0,
        samagriPrice: 1275.0,
        originalPrice: 7650.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'vastu_shanti_pooja',
        title: 'Vastu Shanti Pooja',
        category: 'Ghar aur Jeevan se related Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        isPopular: false,
        duration: '1-7 Days',
        durationBreakdown: '30 mins setup • 1-7 Days ritual with 5 To 7 Pandit(s)',
        description: 'Auspicious Vastu Shanti Pooja performed strictly according to Vedic Shastras by 5 To 7 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '5 To 7 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 51000.0,
        samagriPrice: 12750.0,
        originalPrice: 76500.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'satyanarayan_katha',
        title: 'Satyanarayan Katha',
        category: 'Ghar aur Jeevan se related Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
        isPopular: true,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Satyanarayan Katha performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'lakshmi_pooja',
        title: 'Lakshmi Pooja',
        category: 'Ghar aur Jeevan se related Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1617981408346-39acb6da1b64?w=500',
        isPopular: false,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Lakshmi Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 3100.0,
        samagriPrice: 775.0,
        originalPrice: 4650.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'kuber_pooja',
        title: 'Kuber Pooja',
        category: 'Ghar aur Jeevan se related Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
        isPopular: false,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Kuber Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 3100.0,
        samagriPrice: 775.0,
        originalPrice: 4650.0,
        availability: 'Available Daily',
      ),
    ],
    'sanskar': [
      const PoojaDetail(
        id: 'vivah_marriage_pooja',
        title: 'Vivah (Marriage Pooja)',
        category: 'Sanskar (Life Events)',
        imageUrl: 'https://images.unsplash.com/photo-1609102434313-f938d87a718b?w=500',
        isPopular: true,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 2 Pandit(s)',
        description: 'Auspicious Vivah (Marriage Pooja) performed strictly according to Vedic Shastras by 2 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '2 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 21000.0,
        samagriPrice: 5250.0,
        originalPrice: 31500.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'namkaran_sanskar',
        title: 'Namkaran Sanskar',
        category: 'Sanskar (Life Events)',
        imageUrl: 'https://images.unsplash.com/photo-1544717305-2782549b5136?w=500',
        isPopular: false,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Namkaran Sanskar performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 3100.0,
        samagriPrice: 775.0,
        originalPrice: 4650.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'mundan_sanskar',
        title: 'Mundan Sanskar',
        category: 'Sanskar (Life Events)',
        imageUrl: 'https://images.unsplash.com/photo-1583307878879-9a4c4e78b7e5?w=500',
        isPopular: false,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Mundan Sanskar performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'upanayan_janeu_sanskar',
        title: 'Upanayan (Janeu Sanskar)',
        category: 'Sanskar (Life Events)',
        imageUrl: 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
        isPopular: false,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Upanayan (Janeu Sanskar) performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 5100.0,
        samagriPrice: 1275.0,
        originalPrice: 7650.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'annaprashan',
        title: 'Annaprashan',
        category: 'Sanskar (Life Events)',
        imageUrl: 'https://images.unsplash.com/photo-1519689680058-324335c77eba?w=500',
        isPopular: false,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Annaprashan performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
    ],
    'dosh_nivaran': [
      const PoojaDetail(
        id: 'navgraha_shanti_pooja',
        title: 'Navgraha Shanti Pooja',
        category: 'Dosh Nivaran & Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
        isPopular: true,
        duration: '1 day',
        durationBreakdown: '30 mins setup • 1 day ritual with 3 Pandit(s)',
        description: 'Auspicious Navgraha Shanti Pooja performed strictly according to Vedic Shastras by 3 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '3 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 11000.0,
        samagriPrice: 2750.0,
        originalPrice: 16500.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'kaal_sarp_dosh_pooja',
        title: 'Kaal Sarp Dosh Pooja',
        category: 'Dosh Nivaran & Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
        isPopular: false,
        duration: '3 Day',
        durationBreakdown: '30 mins setup • 3 Day ritual with 5 Pandit(s)',
        description: 'Auspicious Kaal Sarp Dosh Pooja performed strictly according to Vedic Shastras by 5 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '5 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 25000.0,
        samagriPrice: 6250.0,
        originalPrice: 37500.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'mangal_dosh_pooja',
        title: 'Mangal Dosh Pooja',
        category: 'Dosh Nivaran & Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 3 Pandit(s)',
        description: 'Auspicious Mangal Dosh Pooja performed strictly according to Vedic Shastras by 3 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '3 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 11000.0,
        samagriPrice: 2750.0,
        originalPrice: 16500.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'mahamrityunjaya_jaap',
        title: 'Mahamrityunjaya Jaap',
        category: 'Dosh Nivaran & Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
        isPopular: false,
        duration: '1 To 7',
        durationBreakdown: '30 mins setup • 1 To 7 ritual with 7 Pandit(s)',
        description: 'Auspicious Mahamrityunjaya Jaap performed strictly according to Vedic Shastras by 7 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '7 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'pitra_dosh_nivaran',
        title: 'Pitra Dosh Nivaran',
        category: 'Dosh Nivaran & Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Pitra Dosh Nivaran performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 5100.0,
        samagriPrice: 1275.0,
        originalPrice: 7650.0,
        availability: 'Available Daily',
      ),
    ],
    'festival': [
      const PoojaDetail(
        id: 'diwali_lakshmi_ganesh_pooja',
        title: 'Diwali Lakshmi Ganesh Pooja',
        category: 'Festival Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1617981408346-39acb6da1b64?w=500',
        isPopular: true,
        duration: '1-3 Hour',
        durationBreakdown: '30 mins setup • 1-3 Hour ritual with 1 Pandit(s)',
        description: 'Auspicious Diwali Lakshmi Ganesh Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 5100.0,
        samagriPrice: 1275.0,
        originalPrice: 7650.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'ganesh_chaturthi_pooja',
        title: 'Ganesh Chaturthi Pooja',
        category: 'Festival Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500',
        isPopular: false,
        duration: '5 Day',
        durationBreakdown: '30 mins setup • 5 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Ganesh Chaturthi Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'navratri_pooja',
        title: 'Navratri Pooja',
        category: 'Festival Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
        isPopular: false,
        duration: '9 Day',
        durationBreakdown: '30 mins setup • 9 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Navratri Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'durga_pooja',
        title: 'Durga Pooja',
        category: 'Festival Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Durga Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 3100.0,
        samagriPrice: 775.0,
        originalPrice: 4650.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'shivratri_pooja',
        title: 'Shivratri Pooja',
        category: 'Festival Special Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Shivratri Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 5100.0,
        samagriPrice: 1275.0,
        originalPrice: 7650.0,
        availability: 'Available Daily',
      ),
    ],
    'business': [
      const PoojaDetail(
        id: 'vishwakarma_pooja',
        title: 'Vishwakarma Pooja',
        category: 'Business Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1621252179027-94459d278660?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Vishwakarma Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 3100.0,
        samagriPrice: 775.0,
        originalPrice: 4650.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'kuber_upasana',
        title: 'Kuber Upasana',
        category: 'Business Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Kuber Upasana performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 5100.0,
        samagriPrice: 1275.0,
        originalPrice: 7650.0,
        availability: 'Available Daily',
      ),
    ],
    'daily': [
      const PoojaDetail(
        id: 'ganesh_pooja',
        title: 'Ganesh Pooja',
        category: 'Daily / Regular Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Ganesh Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'hanuman_pooja',
        title: 'Hanuman Pooja',
        category: 'Daily / Regular Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Hanuman Pooja performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 2100.0,
        samagriPrice: 525.0,
        originalPrice: 3150.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'sundarkand_path',
        title: 'Sundarkand Path',
        category: 'Daily / Regular Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
        isPopular: true,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 5 Pandit(s)',
        description: 'Auspicious Sundarkand Path performed strictly according to Vedic Shastras by 5 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '5 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 15000.0,
        samagriPrice: 3750.0,
        originalPrice: 22500.0,
        availability: 'Available Daily',
      ),
      const PoojaDetail(
        id: 'rudrabhishek',
        title: 'Rudrabhishek',
        category: 'Daily / Regular Pooja',
        imageUrl: 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=500',
        isPopular: false,
        duration: '1 Day',
        durationBreakdown: '30 mins setup • 1 Day ritual with 1 Pandit(s)',
        description: 'Auspicious Rudrabhishek performed strictly according to Vedic Shastras by 1 certified Acharya(s).',
        spiritualSignificance: 'Invokes divine peace, removes negative energy, and brings health, wealth, and prosperity to the family.',
        inclusions: [
          '1 Certified Vedic Acharya(s)',
          'Complete Sacred Havan & Samagri Kit',
          'Kalash Sthapana & Panchamrit setup',
          'Prashad & Blessing Rituals',
        ],
        chantingDetails: [
          'Vedic Suktam & Mantra Recitation',
          '108 Gayatri Mantra Chanting',
          'Aarti & Sankalpa',
        ],
        standardPrice: 3100.0,
        samagriPrice: 775.0,
        originalPrice: 4650.0,
        availability: 'Available Daily',
      ),
    ],
  };

  List<Widget> _buildRitualCards() {
    return (_categoryRituals[selectedCategory] ?? []).map((ritual) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _buildRitualCard(ritual),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EE),
      drawer: const AppSideDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: 12),
                    _buildSelectRitualTitle(),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildCategoryCards(),
                    const SizedBox(height: 14),
                    _buildOrnamentalDivider(),
                    const SizedBox(height: 12),
                    _buildTrendingRitualsHeader(),
                    const SizedBox(height: 10),
                    ..._buildRitualCards(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentPath: '/book'),
    );
  }

  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const Icon(Icons.menu, size: 26, color: Color(0xFF5A4A3A)),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF18C16),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.self_improvement,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Pandit Setu',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => context.push('/notifications'),
            child: const Icon(
              Icons.notifications_outlined,
              size: 26,
              color: Color(0xFFE8920A),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectRitualTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Select Ritual',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3D2200),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9800), Color(0xFFE65100)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'VERIFIED PANDITS',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        Text(
          '100% Vedic Shastra',
          style: GoogleFonts.lato(
            fontSize: 11,
            color: const Color(0xFF7A6251),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 44,
      child: TextField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          hintText: 'Search rituals, pandits, or locations...',
          hintStyle: GoogleFonts.lato(fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Color(0xFFE8920A), size: 20),
          filled: true,
          fillColor: const Color(0xFFFAF0DC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: const BorderSide(color: Color(0xFFE8920A), width: 1),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCards() {
    final categories = [
      {'id': 'ghar_jeevan', 'label': 'Ghar & Jeevan', 'icon': Icons.home_outlined},
      {'id': 'sanskar', 'label': 'Sanskar Rituals', 'icon': Icons.favorite_outline},
      {'id': 'dosh_nivaran', 'label': 'Dosh Nivaran', 'icon': Icons.shield_outlined},
      {'id': 'festival', 'label': 'Festival Special', 'icon': Icons.auto_awesome},
      {'id': 'business', 'label': 'Business & Wealth', 'icon': Icons.storefront},
      {'id': 'daily', 'label': 'Daily & Regular', 'icon': Icons.temple_hindu},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final String id = cat['id'] as String;
          final String label = cat['label'] as String;
          final IconData icon = cat['icon'] as IconData;
          return _buildCategoryCard(icon: icon, label: label, id: id);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required String label,
    required String id,
  }) {
    final bool isActive = selectedCategory == id;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF18C16) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? const Color(0xFFF18C16) : const Color(0xFFE8D5A3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isActive ? 0.12 : 0.03),
              blurRadius: isActive ? 6 : 2,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : const Color(0xFF3D2200),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lato(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : const Color(0xFF3D2200),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrnamentalDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0xFFE8D5A3)],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Icon(Icons.auto_awesome, color: Color(0xFFE8920A), size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE8D5A3), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendingRitualsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Available Rituals',
          style: GoogleFonts.lato(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3D2200),
          ),
        ),
        Text(
          'View All',
          style: GoogleFonts.lato(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFE8920A),
          ),
        ),
      ],
    );
  }

  Widget _buildRitualCard(PoojaDetail detail) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  detail.imageUrl,
                  width: 105,
                  height: 105,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 105,
                    height: 105,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                    ),
                    child: const Icon(
                      Icons.temple_hindu,
                      color: Color(0xFFE8920A),
                      size: 40,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            detail.title,
                            style: GoogleFonts.lato(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3D2200),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (detail.isPopular) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE082),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'POPULAR',
                              style: GoogleFonts.lato(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3D2200),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${detail.duration} • ₹${detail.standardPrice.toInt()}',
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFD97706),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail.description,
                      style: GoogleFonts.lato(
                        fontSize: 12,
                        color: const Color(0xFF8A7060),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: Color(0xFFE8920A),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          detail.availability,
                          style: GoogleFonts.lato(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8A7060),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                showPoojaDetailBottomSheet(context, detail);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF18C16),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'View Details & Book',
                style: GoogleFonts.lato(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
