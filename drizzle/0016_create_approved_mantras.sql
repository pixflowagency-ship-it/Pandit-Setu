ALTER TABLE "pandits" ALTER COLUMN "verification_method" SET DEFAULT 'MANTRA_VIDEO';
UPDATE "pandits" SET "verification_method" = 'MANTRA_VIDEO' WHERE "verification_method" = 'VIDEO_CALL';

CREATE TABLE IF NOT EXISTS "approved_mantras" (
  "id" VARCHAR(64) PRIMARY KEY,
  "title" VARCHAR(255) NOT NULL,
  "sanskrit_text" TEXT NOT NULL,
  "transliteration" TEXT,
  "meaning" TEXT,
  "pronunciation_guidance" TEXT,
  "min_duration_seconds" INTEGER NOT NULL DEFAULT 10,
  "max_duration_seconds" INTEGER NOT NULL DEFAULT 120,
  "is_active" BOOLEAN NOT NULL DEFAULT true,
  "display_order" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
  "updated_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS "idx_approved_mantras_active" ON "approved_mantras"("is_active", "display_order");

INSERT INTO "approved_mantras" ("id", "title", "sanskrit_text", "transliteration", "meaning", "pronunciation_guidance", "min_duration_seconds", "max_duration_seconds", "is_active", "display_order")
VALUES
(
  'GAYATRI_MANTRA',
  'Gayatri Mahamantra (गायत्री महामंत्र)',
  'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्॥',
  'Om Bhur Bhuvah Swah, Tat-Savitur Varenyam, Bhargo Devasya Dheemahi, Dhiyo Yo Nah Prachodayat.',
  'We meditate on the supreme divine radiance of Savita (the Sun). May that divine light illuminate and inspire our intellect toward righteousness.',
  'Recite with sacred Vedic rhythm and clear Sandhi separation. Avoid hasty pronunciation.',
  12,
  120,
  true,
  1
),
(
  'MAHAMRITYUNJAYA_MANTRA',
  'Mahamrityunjaya Mantra (महामृत्युंजय मंत्र)',
  'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम्। उर्वारुकमिव बन्धनान्मृग्योर्मुक्षीय मामृतात्॥',
  'Om Tryambakam Yajaamahe Sugandhim Pushti-Vardhanam, Urvaarukamiva Bandhanaan Mrityor Muksheeya Maamritaat.',
  'We adore the Three-Eyed Lord Shiva, the fragrant nourisher of all life. Just as a ripe fruit is released from its vine, may we be liberated from the bondage of mortality.',
  'Clearly enunciate compound consonants in ''Tryambakam'' and ''Bandhanaat''.',
  12,
  120,
  true,
  2
),
(
  'SHANTI_MANTRA',
  'Vedic Shanti Path (वैदिक शांति पाठ)',
  'ॐ द्यौः शान्तिरन्तरिक्षं शान्तिः पृथिवी शान्तिरापः शान्तिरोषधयः शान्तिः। वनस्पतयः शान्तिर्विश्वेदेवाः शान्तिर्ब्रह्म शान्तिः सर्वं शान्तिः शान्तिरेव शान्तिः सा मा शान्तिरेधि॥ ॐ शान्तिः शान्तिः शान्तिः॥',
  'Om Dyauh Shantir-Antariksham Shantih, Prithivi Shantir-Aapah Shantir-Oshadhayah Shantih, Vanaspatayah Shantir-Vishvedevaah Shantir-Brahma Shantih, Sarvam Shantih Shantireva Shantih Saa Maa Shantiredhi. Om Shantih Shantih Shantih.',
  'May peace prevail in the heavens, in the sky, on earth, in water, in herbs and vegetation, and in all cosmic forces. May universal peace fill our hearts.',
  'Recite in an even, tranquil tempo maintaining balance across all Pada phrases.',
  15,
  180,
  true,
  3
),
(
  'GANESH_INVOCATION',
  'Shri Ganesh Vandana (श्री गणेश वंदना)',
  'वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ। निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा॥',
  'Vakratunda Mahaakaaya Suryakoti Samaprabha, Nirvighnam Kuru Me Deva Sarva-Kaaryeshu Sarvadaa.',
  'O Lord Ganesha of curved trunk and magnificent form, shining with the effulgence of ten million suns, please dispel all obstacles from our sacred work always.',
  'Resonant, devotional cadence with respectful elongation of the final vowels.',
  10,
  90,
  true,
  4
),
(
  'GURU_VANDANA',
  'Guru Vandana & Mangalacharan (गुरु वंदना)',
  'गुरुर्ब्रह्मा गुरुर्विष्णुः गुरुर्देवो महेश्वरः। गुरुः साक्षात् परं ब्रह्म तस्मै श्रीगुरवे नमः॥',
  'Gurur Brahmaa Gurur Vishnuh Gurur Devo Maheshwarah, Guruh Saakshaat Param Brahma Tasmai Shri Gurave Namah.',
  'The Guru is Brahma, the Guru is Vishnu, the Guru is Shiva. The Guru is indeed the living embodiment of Supreme Reality. Salutations to the revered Guru.',
  'Pure Sanskrit tone emphasizing the reverence of the Guru-Shishya tradition.',
  10,
  90,
  true,
  5
)
ON CONFLICT ("id") DO NOTHING;
