import 'package:flutter/material.dart';

class AppUiThemeConfig {
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;

  const AppUiThemeConfig({
    this.primaryColor = const Color(0xFFE65100),
    this.accentColor = const Color(0xFFD97706),
    this.backgroundColor = const Color(0xFFFFF8EE),
    this.surfaceColor = const Color(0xFFFFFFFF),
  });

  factory AppUiThemeConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const AppUiThemeConfig();

    Color parseColor(dynamic hexStr, Color fallback) {
      if (hexStr is! String) return fallback;
      try {
        final clean = hexStr.replaceAll('#', '').trim();
        if (clean.length == 6) {
          return Color(int.parse('FF$clean', radix: 16));
        } else if (clean.length == 8) {
          return Color(int.parse(clean, radix: 16));
        }
      } catch (_) {}
      return fallback;
    }

    return AppUiThemeConfig(
      primaryColor: parseColor(json['primaryColor'], const Color(0xFFE65100)),
      accentColor: parseColor(json['accentColor'], const Color(0xFFD97706)),
      backgroundColor: parseColor(json['backgroundColor'], const Color(0xFFFFF8EE)),
      surfaceColor: parseColor(json['surfaceColor'], const Color(0xFFFFFFFF)),
    );
  }

  Map<String, dynamic> toJson() => {
        'primaryColor': '#${primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'accentColor': '#${accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'backgroundColor': '#${backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        'surfaceColor': '#${surfaceColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
      };

}

class AppSectionConfig {
  final String id;
  final bool enabled;
  final int order;
  final String title;
  final String titleHi;
  final String? subtitle;
  final String? subtitleHi;

  const AppSectionConfig({
    required this.id,
    this.enabled = true,
    this.order = 1,
    required this.title,
    required this.titleHi,
    this.subtitle,
    this.subtitleHi,
  });

  factory AppSectionConfig.fromJson(Map<String, dynamic> json) {
    return AppSectionConfig(
      id: json['id']?.toString() ?? 'unknown',
      enabled: json['enabled'] != false,
      order: (json['order'] is num) ? (json['order'] as num).toInt() : 1,
      title: json['title']?.toString() ?? '',
      titleHi: json['titleHi']?.toString() ?? json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString(),
      subtitleHi: json['subtitleHi']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'enabled': enabled,
        'order': order,
        'title': title,
        'titleHi': titleHi,
        if (subtitle != null) 'subtitle': subtitle,
        if (subtitleHi != null) 'subtitleHi': subtitleHi,
      };
}

class AppHeroSlide {
  final String id;
  final String title;
  final String titleHi;
  final String subtitle;
  final String subtitleHi;
  final String tag;
  final String tagHi;
  final String imageUrl;
  final String actionType;
  final String actionTarget;
  final String? slug;

  const AppHeroSlide({
    required this.id,
    required this.title,
    required this.titleHi,
    this.subtitle = '',
    this.subtitleHi = '',
    this.tag = '',
    this.tagHi = '',
    required this.imageUrl,
    this.actionType = 'POOJA',
    required this.actionTarget,
    this.slug,
  });

  factory AppHeroSlide.fromJson(Map<String, dynamic> json) {
    return AppHeroSlide(
      id: json['id']?.toString() ?? 'slide-1',
      title: json['title']?.toString() ?? 'Vedic Pooja',
      titleHi: json['titleHi']?.toString() ?? json['title']?.toString() ?? 'वैदिक पूजा',
      subtitle: json['subtitle']?.toString() ?? '',
      subtitleHi: json['subtitleHi']?.toString() ?? '',
      tag: json['tag']?.toString() ?? '',
      tagHi: json['tagHi']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ??
          'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900',
      actionType: json['actionType']?.toString() ?? 'POOJA',
      actionTarget: json['actionTarget']?.toString() ?? '',
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleHi': titleHi,
        'subtitle': subtitle,
        'subtitleHi': subtitleHi,
        'tag': tag,
        'tagHi': tagHi,
        'imageUrl': imageUrl,
        'actionType': actionType,
        'actionTarget': actionTarget,
        if (slug != null) 'slug': slug,
      };
}

class AppServiceGridItem {
  final String id;
  final String title;
  final String titleHi;
  final String subtitle;
  final String subtitleHi;
  final String? badge;
  final String? badgeHi;
  final String icon;
  final String target;
  final bool enabled;
  final int order;

  const AppServiceGridItem({
    required this.id,
    required this.title,
    required this.titleHi,
    this.subtitle = '',
    this.subtitleHi = '',
    this.badge,
    this.badgeHi,
    required this.icon,
    required this.target,
    this.enabled = true,
    this.order = 1,
  });

  factory AppServiceGridItem.fromJson(Map<String, dynamic> json) {
    return AppServiceGridItem(
      id: json['id']?.toString() ?? 'service',
      title: json['title']?.toString() ?? '',
      titleHi: json['titleHi']?.toString() ?? json['title']?.toString() ?? '',
      subtitle: json['subtitle']?.toString() ?? '',
      subtitleHi: json['subtitleHi']?.toString() ?? '',
      badge: json['badge']?.toString(),
      badgeHi: json['badgeHi']?.toString(),
      icon: json['icon']?.toString() ?? 'auto_awesome',
      target: json['target']?.toString() ?? '/home',
      enabled: json['enabled'] != false,
      order: (json['order'] is num) ? (json['order'] as num).toInt() : 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleHi': titleHi,
        'subtitle': subtitle,
        'subtitleHi': subtitleHi,
        if (badge != null) 'badge': badge,
        if (badgeHi != null) 'badgeHi': badgeHi,
        'icon': icon,
        'target': target,
        'enabled': enabled,
        'order': order,
      };
}

class AppLifeProblemsBanner {
  final bool enabled;
  final String title;
  final String titleHi;
  final String subtitle;
  final String subtitleHi;
  final String buttonText;
  final String buttonTextHi;
  final String target;

  const AppLifeProblemsBanner({
    this.enabled = true,
    required this.title,
    required this.titleHi,
    this.subtitle = '',
    this.subtitleHi = '',
    required this.buttonText,
    required this.buttonTextHi,
    this.target = '/consultation-flow',
  });

  factory AppLifeProblemsBanner.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AppLifeProblemsBanner(
        enabled: true,
        title: 'Problems in Life?',
        titleHi: 'जीवन में कोई समस्या है?',
        subtitle: 'Talk to Expert Astrologers & Get Vedic Remedies',
        subtitleHi: 'विशेषज्ञ ज्योतिषियों से बात करें और वैदिक समाधान पाएं',
        buttonText: 'Consult Now',
        buttonTextHi: 'परामर्श लें',
        target: '/consultation-flow',
      );
    }

    return AppLifeProblemsBanner(
      enabled: json['enabled'] != false,
      title: json['title']?.toString() ?? 'Problems in Life?',
      titleHi: json['titleHi']?.toString() ?? 'जीवन में कोई समस्या है?',
      subtitle: json['subtitle']?.toString() ?? '',
      subtitleHi: json['subtitleHi']?.toString() ?? '',
      buttonText: json['buttonText']?.toString() ?? 'Consult Now',
      buttonTextHi: json['buttonTextHi']?.toString() ?? 'परामर्श लें',
      target: json['target']?.toString() ?? '/consultation-flow',
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'title': title,
        'titleHi': titleHi,
        'subtitle': subtitle,
        'subtitleHi': subtitleHi,
        'buttonText': buttonText,
        'buttonTextHi': buttonTextHi,
        'target': target,
      };
}

class AppUiConfig {
  final int schemaVersion;
  final AppUiThemeConfig theme;
  final List<AppSectionConfig> sections;
  final List<AppHeroSlide> heroSlides;
  final List<AppServiceGridItem> serviceGrid;
  final AppLifeProblemsBanner lifeProblemsBanner;

  const AppUiConfig({
    this.schemaVersion = 1,
    this.theme = const AppUiThemeConfig(),
    this.sections = defaultSections,
    this.heroSlides = defaultHeroSlides,
    this.serviceGrid = defaultServiceGrid,
    this.lifeProblemsBanner = const AppLifeProblemsBanner(
      title: 'Problems in Life?',
      titleHi: 'जीवन में कोई समस्या है?',
      buttonText: 'Consult Now',
      buttonTextHi: 'परामर्श लें',
    ),
  });

  factory AppUiConfig.fromJson(Map<String, dynamic> json) {
    return AppUiConfig(
      schemaVersion: (json['schemaVersion'] is num)
          ? (json['schemaVersion'] as num).toInt()
          : 1,
      theme: AppUiThemeConfig.fromJson(json['theme'] as Map<String, dynamic>?),
      sections: (json['sections'] is List)
          ? (json['sections'] as List)
              .map((s) => AppSectionConfig.fromJson(s as Map<String, dynamic>))
              .toList()
          : defaultSections,
      heroSlides: (json['heroSlides'] is List)
          ? (json['heroSlides'] as List)
              .map((h) => AppHeroSlide.fromJson(h as Map<String, dynamic>))
              .toList()
          : defaultHeroSlides,
      serviceGrid: (json['serviceGrid'] is List)
          ? (json['serviceGrid'] as List)
              .map((g) => AppServiceGridItem.fromJson(g as Map<String, dynamic>))
              .toList()
          : defaultServiceGrid,
      lifeProblemsBanner: AppLifeProblemsBanner.fromJson(
        json['lifeProblemsBanner'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'theme': theme.toJson(),
        'sections': sections.map((s) => s.toJson()).toList(),
        'heroSlides': heroSlides.map((h) => h.toJson()).toList(),
        'serviceGrid': serviceGrid.map((g) => g.toJson()).toList(),
        'lifeProblemsBanner': lifeProblemsBanner.toJson(),
      };

  static const List<AppSectionConfig> defaultSections = [
    AppSectionConfig(id: 'hero_slideshow', enabled: true, order: 1, title: 'Banners', titleHi: 'बैनर'),
    AppSectionConfig(id: 'six_box_grid', enabled: true, order: 2, title: 'Our Sacred Services', titleHi: 'हमारी पवित्र सेवाएं'),
    AppSectionConfig(id: 'life_problems', enabled: true, order: 3, title: 'Problems in Life?', titleHi: 'जीवन में समस्याएं?'),
    AppSectionConfig(id: 'upcoming_booking', enabled: true, order: 4, title: 'Your Next Pooja', titleHi: 'आपकी आगामी पूजा'),
    AppSectionConfig(id: 'category_menu', enabled: true, order: 5, title: 'Explore by Category', titleHi: 'श्रेणी अनुसार खोजें'),
    AppSectionConfig(id: 'panchang', enabled: true, order: 6, title: 'Daily Vedic Panchang', titleHi: 'दैनिक पंचांग'),
    AppSectionConfig(id: 'rarest_items', enabled: true, order: 7, title: 'Sacred Rarest Samagri', titleHi: 'दुर्लभ पूजन सामग्री'),
    AppSectionConfig(id: 'trending_rituals', enabled: true, order: 8, title: 'Trending Rituals', titleHi: 'लोकप्रिय अनुष्ठान'),
    AppSectionConfig(id: 'blog', enabled: true, order: 9, title: 'Vedic Wisdom & Insights', titleHi: 'वैदिक ज्ञान'),
    AppSectionConfig(id: 'trust_badges', enabled: true, order: 10, title: 'Why SARV MANGAL', titleHi: 'सर्व मंगल क्यों'),
  ];

  static const List<AppHeroSlide> defaultHeroSlides = [
    AppHeroSlide(
      id: 'slide-1',
      title: 'Grand Navratri & Durga Puja 2026',
      titleHi: 'भव्य शारदीय नवरात्रि एवं दुर्गा पूजा 2026',
      subtitle: 'Book Authentic Vedic Chandi Path & Havan by Certified Acharyas',
      subtitleHi: 'प्रमाणित आचार्यों द्वारा प्रामाणिक वैदिक चंडी पाठ एवं हवन',
      tag: 'FESTIVAL SPECIAL',
      tagHi: 'उत्सव विशेष',
      imageUrl: 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900',
      actionType: 'POOJA',
      actionTarget: '67e77a47-8ffb-403a-bc64-c948ab5e2abc',
      slug: 'navratri-pooja',
    ),
    AppHeroSlide(
      id: 'slide-2',
      title: 'Shri Satyanarayan Vrat Katha',
      titleHi: 'श्री सत्यनारायण व्रत कथा',
      subtitle: 'Invite Infinite Health, Peace & Family Harmony',
      subtitleHi: 'अनंत सुख, शांति एवं पारिवारिक समृद्धि का वास कराएं',
      tag: 'MOST POPULAR',
      tagHi: 'सर्वाधिक लोकप्रिय',
      imageUrl: 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=900',
      actionType: 'POOJA',
      actionTarget: '92086a65-41a9-4545-9588-6f35c8bb8b6b',
      slug: 'satyanarayan-katha',
    ),
    AppHeroSlide(
      id: 'slide-3',
      title: 'Griha Pravesh & Vastu Shanti',
      titleHi: 'गृह प्रवेश एवं वास्तु शांति',
      subtitle: 'Purify Your New Residence with Vedic Mantras & Havan',
      subtitleHi: 'वैदिक मंत्रोच्चार एवं हवन द्वारा अपने नए आवास को शुद्ध करें',
      tag: 'HOUSEWARMING',
      tagHi: 'गृह प्रवेश',
      imageUrl: 'https://images.unsplash.com/photo-1621252179027-94459d278660?w=900',
      actionType: 'POOJA',
      actionTarget: '9ae802b2-95f9-4461-af5a-e7c32d6fb1af',
      slug: 'griha-pravesh-pooja',
    ),
    AppHeroSlide(
      id: 'slide-4',
      title: 'Mahamrityunjaya Healing Havan',
      titleHi: 'महामृत्युंजय महा अनुष्ठान',
      subtitle: 'Conquer Illness & Invoke Divine Life Energy of Bhagwan Shiva',
      subtitleHi: 'रोग-निवारण एवं भगवान शिव की दिव्य प्राण-ऊर्जा प्राप्त करें',
      tag: 'SACRED FIRE RITUAL',
      tagHi: 'पवित्र अग्नि अनुष्ठान',
      imageUrl: 'https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=900',
      actionType: 'POOJA',
      actionTarget: '9484cd34-05de-4b00-9621-b190d075be33',
      slug: 'mahamrityunjaya-jaap',
    ),
  ];

  static const List<AppServiceGridItem> defaultServiceGrid = [
    AppServiceGridItem(
      id: 'pooja',
      enabled: true,
      order: 1,
      title: 'Vedic Poojas',
      titleHi: 'वैदिक पूजा',
      subtitle: 'Book Acharya',
      subtitleHi: 'आचार्य बुक करें',
      badge: 'POPULAR',
      badgeHi: 'लोकप्रिय',
      icon: 'auto_awesome',
      target: '/pooja-flow',
    ),
    AppServiceGridItem(
      id: 'kundli',
      enabled: true,
      order: 2,
      title: 'Handmade Kundli',
      titleHi: 'हस्तनिर्मित कुंडली',
      subtitle: 'By Astrologers',
      subtitleHi: 'ज्योतिषियों द्वारा',
      badge: 'CUSTOM',
      badgeHi: 'विशेष',
      icon: 'menu_book',
      target: '/kundli-flow',
    ),
    AppServiceGridItem(
      id: 'consultation',
      enabled: true,
      order: 3,
      title: 'Consultation',
      titleHi: 'ज्योतिष परामर्श',
      subtitle: 'Call / Video',
      subtitleHi: 'कॉल / वीडियो',
      badge: 'LIVE',
      badgeHi: 'लाइव',
      icon: 'phone_in_talk',
      target: '/consultation-flow',
    ),
    AppServiceGridItem(
      id: 'samagri',
      enabled: true,
      order: 4,
      title: 'Poojan Samagri',
      titleHi: 'पूजन सामग्री',
      subtitle: 'Pure & Vedic',
      subtitleHi: 'शुद्ध व वैदिक',
      badge: 'DELIVERY',
      badgeHi: 'डिलीवरी',
      icon: 'local_florist',
      target: '/shop',
    ),
    AppServiceGridItem(
      id: 'temples',
      enabled: true,
      order: 5,
      title: 'Nearest Temple',
      titleHi: 'निकटतम मंदिर',
      subtitle: 'Darshan & Nav',
      subtitleHi: 'दर्शन व मार्ग',
      badge: 'MAP',
      badgeHi: 'मानचित्र',
      icon: 'temple_hindu',
      target: '/nearest-temple',
    ),
    AppServiceGridItem(
      id: 'tracking',
      enabled: true,
      order: 6,
      title: 'Live Tracking',
      titleHi: 'लाइव ट्रैकिंग',
      subtitle: 'Pandit Location',
      subtitleHi: 'पंडित जी की लोकेशन',
      badge: 'GPS',
      badgeHi: 'जीपीएस',
      icon: 'explore',
      target: '/live-tracking',
    ),
  ];
}
