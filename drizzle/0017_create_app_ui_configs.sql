-- Migration 0017: Create app_ui_configs table and seed initial published version
DO $$ BEGIN
    CREATE TYPE "app_config_status" AS ENUM ('DRAFT', 'PUBLISHED', 'ARCHIVED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

CREATE TABLE IF NOT EXISTS "app_ui_configs" (
    "id" uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    "version" integer NOT NULL,
    "status" "app_config_status" DEFAULT 'DRAFT' NOT NULL,
    "config" jsonb NOT NULL,
    "published_by" uuid REFERENCES "users"("id") ON DELETE SET NULL,
    "published_at" timestamp with time zone,
    "change_summary" text,
    "created_at" timestamp with time zone DEFAULT now() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT now() NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_app_ui_configs_status" ON "app_ui_configs" ("status");
CREATE INDEX IF NOT EXISTS "idx_app_ui_configs_version" ON "app_ui_configs" ("version");

-- Seed initial published configuration (Version 1) if not already exists
INSERT INTO "app_ui_configs" (
    "version",
    "status",
    "change_summary",
    "published_at",
    "config"
)
SELECT
    1,
    'PUBLISHED',
    'Initial default SARV MANGAL home layout and branding configuration',
    now(),
    '{
        "schemaVersion": 1,
        "theme": {
            "primaryColor": "#E65100",
            "accentColor": "#D97706",
            "backgroundColor": "#FFF8EE",
            "surfaceColor": "#FFFFFF"
        },
        "sections": [
            { "id": "hero_slideshow", "enabled": true, "order": 1, "title": "Banners", "titleHi": "बैनर" },
            { "id": "six_box_grid", "enabled": true, "order": 2, "title": "Our Sacred Services", "titleHi": "हमारी पवित्र सेवाएं" },
            { "id": "life_problems", "enabled": true, "order": 3, "title": "Problems in Life?", "titleHi": "जीवन में समस्याएं?" },
            { "id": "upcoming_booking", "enabled": true, "order": 4, "title": "Your Next Pooja", "titleHi": "आपकी आगामी पूजा" },
            { "id": "category_menu", "enabled": true, "order": 5, "title": "Explore by Category", "titleHi": "श्रेणी अनुसार खोजें" },
            { "id": "panchang", "enabled": true, "order": 6, "title": "Daily Vedic Panchang", "titleHi": "दैनिक पंचांग" },
            { "id": "rarest_items", "enabled": true, "order": 7, "title": "Sacred Rarest Samagri", "titleHi": "दुर्लभ पूजन सामग्री" },
            { "id": "trending_rituals", "enabled": true, "order": 8, "title": "Trending Rituals", "titleHi": "लोकप्रिय अनुष्ठान" },
            { "id": "blog", "enabled": true, "order": 9, "title": "Vedic Wisdom & Insights", "titleHi": "वैदिक ज्ञान" },
            { "id": "trust_badges", "enabled": true, "order": 10, "title": "Why SARV MANGAL", "titleHi": "सर्व मंगल क्यों" }
        ],
        "heroSlides": [
            {
                "id": "slide-1",
                "title": "Grand Navratri & Durga Puja 2026",
                "titleHi": "भव्य शारदीय नवरात्रि एवं दुर्गा पूजा 2026",
                "subtitle": "Book Authentic Vedic Chandi Path & Havan by Certified Acharyas",
                "subtitleHi": "प्रमाणित आचार्यों द्वारा प्रामाणिक वैदिक चंडी पाठ एवं हवन",
                "tag": "FESTIVAL SPECIAL",
                "tagHi": "उत्सव विशेष",
                "imageUrl": "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=900",
                "actionType": "POOJA",
                "actionTarget": "67e77a47-8ffb-403a-bc64-c948ab5e2abc",
                "slug": "navratri-pooja"
            },
            {
                "id": "slide-2",
                "title": "Shri Satyanarayan Vrat Katha",
                "titleHi": "श्री सत्यनारायण व्रत कथा",
                "subtitle": "Invite Infinite Health, Peace & Family Harmony",
                "subtitleHi": "अनंत सुख, शांति एवं पारिवारिक समृद्धि का वास कराएं",
                "tag": "MOST POPULAR",
                "tagHi": "सर्वाधिक लोकप्रिय",
                "imageUrl": "https://images.unsplash.com/photo-1605152276897-4f618f831968?w=900",
                "actionType": "POOJA",
                "actionTarget": "92086a65-41a9-4545-9588-6f35c8bb8b6b",
                "slug": "satyanarayan-katha"
            },
            {
                "id": "slide-3",
                "title": "Griha Pravesh & Vastu Shanti",
                "titleHi": "गृह प्रवेश एवं वास्तु शांति",
                "subtitle": "Purify Your New Residence with Vedic Mantras & Havan",
                "subtitleHi": "वैदिक मंत्रोच्चार एवं हवन द्वारा अपने नए आवास को शुद्ध करें",
                "tag": "HOUSEWARMING",
                "tagHi": "गृह प्रवेश",
                "imageUrl": "https://images.unsplash.com/photo-1621252179027-94459d278660?w=900",
                "actionType": "POOJA",
                "actionTarget": "9ae802b2-95f9-4461-af5a-e7c32d6fb1af",
                "slug": "griha-pravesh-pooja"
            },
            {
                "id": "slide-4",
                "title": "Mahamrityunjaya Healing Havan",
                "titleHi": "महामृत्युंजय महा अनुष्ठान",
                "subtitle": "Conquer Illness & Invoke Divine Life Energy of Bhagwan Shiva",
                "subtitleHi": "रोग-निवारण एवं भगवान शिव की दिव्य प्राण-ऊर्जा प्राप्त करें",
                "tag": "SACRED FIRE RITUAL",
                "tagHi": "पवित्र अग्नि अनुष्ठान",
                "imageUrl": "https://images.unsplash.com/photo-1604882737079-7dc3df3e09ac?w=900",
                "actionType": "POOJA",
                "actionTarget": "9484cd34-05de-4b00-9621-b190d075be33",
                "slug": "mahamrityunjaya-jaap"
            }
        ],
        "serviceGrid": [
            { "id": "pooja", "enabled": true, "order": 1, "title": "Vedic Poojas", "titleHi": "वैदिक पूजा", "subtitle": "Book Acharya", "subtitleHi": "आचार्य बुक करें", "badge": "POPULAR", "badgeHi": "लोकप्रिय", "icon": "auto_awesome", "target": "/pooja-flow" },
            { "id": "kundli", "enabled": true, "order": 2, "title": "Handmade Kundli", "titleHi": "हस्तनिर्मित कुंडली", "subtitle": "By Astrologers", "subtitleHi": "ज्योतिषियों द्वारा", "badge": "CUSTOM", "badgeHi": "विशेष", "icon": "menu_book", "target": "/kundli-flow" },
            { "id": "consultation", "enabled": true, "order": 3, "title": "Consultation", "titleHi": "ज्योतिष परामर्श", "subtitle": "Call / Video", "subtitleHi": "कॉल / वीडियो", "badge": "LIVE", "badgeHi": "लाइव", "icon": "phone_in_talk", "target": "/consultation-flow" },
            { "id": "samagri", "enabled": true, "order": 4, "title": "Poojan Samagri", "titleHi": "पूजन सामग्री", "subtitle": "Pure & Vedic", "subtitleHi": "शुद्ध व वैदिक", "badge": "DELIVERY", "badgeHi": "डिलीवरी", "icon": "local_florist", "target": "/shop" },
            { "id": "temples", "enabled": true, "order": 5, "title": "Nearest Temple", "titleHi": "निकटतम मंदिर", "subtitle": "Darshan & Nav", "subtitleHi": "दर्शन व मार्ग", "badge": "MAP", "badgeHi": "मानचित्र", "icon": "temple_hindu", "target": "/nearest-temple" },
            { "id": "tracking", "enabled": true, "order": 6, "title": "Live Tracking", "titleHi": "लाइव ट्रैकिंग", "subtitle": "Pandit Location", "subtitleHi": "पंडित जी की लोकेशन", "badge": "GPS", "badgeHi": "जीपीएस", "icon": "explore", "target": "/live-tracking" }
        ],
        "lifeProblemsBanner": {
            "enabled": true,
            "title": "Problems in Life?",
            "titleHi": "जीवन में कोई समस्या है?",
            "subtitle": "Talk to Expert Astrologers & Get Vedic Remedies",
            "subtitleHi": "विशेषज्ञ ज्योतिषियों से बात करें और वैदिक समाधान पाएं",
            "buttonText": "Consult Now",
            "buttonTextHi": "परामर्श लें",
            "target": "/consultation-flow"
        }
    }'::jsonb
WHERE NOT EXISTS (
    SELECT 1 FROM "app_ui_configs" WHERE "status" = 'PUBLISHED'
);
