import 'dotenv/config';
import path from 'path';
import xlsx from 'xlsx';
import { eq } from 'drizzle-orm';
import { db } from './index.js';
import { poojas } from './schema/poojas.js';
import { samagriItems } from './schema/samagri.js';

const EXCEL_PATH = path.resolve(process.cwd(), 'Pooja List.xlsx');

function cleanPrice(raw: unknown): string {
  if (typeof raw === 'number') return raw.toFixed(2);
  if (!raw) return '0.00';
  const cleaned = String(raw).replace(/[^0-9.]/g, '');
  const num = parseFloat(cleaned);
  return isNaN(num) ? '0.00' : num.toFixed(2);
}

function parseDurationMinutes(raw: unknown): number {
  if (!raw) return 180;
  const s = String(raw).toLowerCase().trim();
  if (s.includes('1-3 hour') || s.includes('1-3 hr')) return 180;
  if (s.includes('1-7') || s.includes('1 to 7')) return 360;
  if (s.includes('9 day')) return 540;
  if (s.includes('5 day')) return 300;
  if (s.includes('3 day')) return 300;
  if (s.includes('1 day')) return 240;
  return 180;
}

function generateSlug(title: string): string {
  return title
    .toLowerCase()
    .replace(/[()]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

// Curated authentic Vedic imagery for verified rituals
const POOJA_IMAGES: Record<string, string> = {
  'griha-pravesh-pooja': 'https://images.unsplash.com/photo-1621252179027-94459d278660?w=500',
  'vastu-shanti-pooja': 'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=500',
  'satyanarayan-katha': 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500',
  'lakshmi-pooja': 'https://images.unsplash.com/photo-1617981408346-39acb6da1b64?w=500',
  'kuber-pooja': 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
  'vivah-marriage-pooja': 'https://images.unsplash.com/photo-1609102434313-f938d87a718b?w=500',
  'namkaran-sanskar': 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500',
  'mundan-sanskar': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
  'upanayan-janeu-sanskar': 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
  'annaprashan': 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500',
  'navgraha-shanti-pooja': 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=500',
  'kaal-sarp-dosh-pooja': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=500',
  'mangal-dosh-pooja': 'https://images.unsplash.com/photo-1519817650390-64a93db51149?w=500',
  'mahamrityunjaya-jaap': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500',
  'pitra-dosh-nivaran': 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=500',
  'diwali-lakshmi-ganesh-pooja': 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=500',
  'ganesh-chaturthi-pooja': 'https://images.unsplash.com/photo-1567591414240-e144a9b83b3e?w=500',
  'navratri-pooja': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=500',
  'durga-pooja': 'https://images.unsplash.com/photo-1601050690597-df0568f70950?w=500',
  'shivratri-pooja': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500',
  'vishwakarma-pooja': 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=500',
  'kuber-upasana': 'https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500',
  'ganesh-pooja': 'https://images.unsplash.com/photo-1567591414240-e144a9b83b3e?w=500',
  'hanuman-pooja': 'https://images.unsplash.com/photo-1582510003544-4d00b7f74220?w=500',
  'sundarkand-path': 'https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=500',
  'rudrabhishek': 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500',
};

export async function importPoojaExcel() {
  console.log(`\n======================================================`);
  console.log(`📖 Loading Excel workbook: ${EXCEL_PATH}`);
  console.log(`======================================================`);

  const workbook = xlsx.readFile(EXCEL_PATH);

  // -------------------------------------------------------------------------
  // 1. IMPORT SHEET: "List OF Pooja" -> PostgreSQL table "poojas"
  // -------------------------------------------------------------------------
  const poojaSheet = workbook.Sheets['List OF Pooja'];
  if (!poojaSheet) {
    throw new Error('Sheet "List OF Pooja" not found in Excel workbook!');
  }

  const poojaRows: unknown[][] = xlsx.utils.sheet_to_json(poojaSheet, { header: 1 });
  let currentCategory = 'General Vedic Pooja';
  let importedPoojasCount = 0;
  let updatedPoojasCount = 0;

  console.log(`\n--- Importing Pujas (Sheet: "List OF Pooja") ---`);

  for (let i = 2; i < poojaRows.length; i++) {
    const row = poojaRows[i];
    if (!row || row.length === 0) continue;

    const rawCategory = row[0];
    const rawTitle = row[1];
    const rawDuration = row[2];
    const rawPandits = row[3];
    const rawRate = row[4];

    if (!rawTitle || String(rawTitle).trim() === '') continue;

    if (rawCategory && String(rawCategory).trim() !== '') {
      currentCategory = String(rawCategory).trim();
    }

    const title = String(rawTitle).trim();
    const duration = rawDuration ? String(rawDuration).trim() : '1-3 Hour';
    const requiredPandits = rawPandits != null ? String(rawPandits).trim() : '1';
    const basePrice = cleanPrice(rawRate);
    const durationMinutes = parseDurationMinutes(duration);
    const slug = generateSlug(title);
    const imageUrl = POOJA_IMAGES[slug] || 'https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500';
    const description = `Authentic ${title} ritual performed by ${requiredPandits} experienced Vedic Pandit(s). Duration: ${duration}. Category: ${currentCategory}.`;

    // Idempotent upsert by slug
    const existingPooja = await db.query.poojas.findFirst({
      where: eq(poojas.slug, slug),
    });

    if (existingPooja) {
      await db
        .update(poojas)
        .set({
          title,
          category: currentCategory,
          duration,
          requiredPandits,
          basePrice,
          durationMinutes,
          description,
          imageUrl: existingPooja.imageUrl || imageUrl,
          isActive: true,
          updatedAt: new Date(),
        })
        .where(eq(poojas.id, existingPooja.id));
      updatedPoojasCount++;
    } else {
      await db.insert(poojas).values({
        title,
        slug,
        category: currentCategory,
        duration,
        requiredPandits,
        basePrice,
        samagriPrice: '0.00',
        durationMinutes,
        description,
        imageUrl,
        isActive: true,
      });
      importedPoojasCount++;
    }
  }

  console.log(`✅ Pujas sync complete: ${importedPoojasCount} inserted, ${updatedPoojasCount} updated.`);

  // -------------------------------------------------------------------------
  // 2. IMPORT SHEET: "List OF Items" -> PostgreSQL table "samagri_items"
  // -------------------------------------------------------------------------
  const itemSheet = workbook.Sheets['List OF Items'];
  let importedItemsCount = 0;
  let updatedItemsCount = 0;

  if (itemSheet) {
    console.log(`\n--- Importing Ritual Items (Sheet: "List OF Items") ---`);
    const rawItems: Record<string, unknown>[] = xlsx.utils.sheet_to_json(itemSheet);

    for (const r of rawItems) {
      const sNo = parseInt(String(r['S.No.'])) || 0;
      const category = String(r['Category'] || 'General').trim();
      const name = String(r['Item Name'] || '').trim();
      const nameEnglish = String(r['Name In English'] || '').trim();
      const quantity = parseFloat(String(r['Quantity'])) || 1;
      const unit = String(r['Unit'] || 'pcs').trim();
      const requiredAvailable = String(r['Required/Available'] || 'Required').trim();
      const remarks = String(r['Remarks'] || '').trim();

      if (!name) continue;

      // Idempotent upsert by sNo (or name + category)
      const existingItem = await db.query.samagriItems.findFirst({
        where: eq(samagriItems.sNo, sNo),
      });

      if (existingItem) {
        await db
          .update(samagriItems)
          .set({
            name,
            nameEnglish: nameEnglish || existingItem.nameEnglish,
            category,
            quantity: String(quantity),
            unit,
            requiredAvailable,
            remarks,
            isActive: true,
          })
          .where(eq(samagriItems.id, existingItem.id));
        updatedItemsCount++;
      } else {
        await db.insert(samagriItems).values({
          sNo,
          category,
          name,
          nameEnglish,
          quantity: String(quantity),
          unit,
          requiredAvailable,
          remarks,
          price: '0.00',
          stockQuantity: 100,
          isActive: true,
        });
        importedItemsCount++;
      }
    }

    console.log(`✅ Samagri items sync complete: ${importedItemsCount} inserted, ${updatedItemsCount} updated.`);
  }

  // -------------------------------------------------------------------------
  // 3. INSPECT SHEET: "Pandit Ji List "
  // -------------------------------------------------------------------------
  const panditSheet = workbook.Sheets['Pandit Ji List '];
  if (panditSheet) {
    const pRows = xlsx.utils.sheet_to_json(panditSheet);
    console.log(`\n--- Inspected Sheet: "Pandit Ji List " ---`);
    console.log(`Rows found: ${pRows.length} (Empty / placeholder sheet).`);
  }

  console.log(`\n======================================================`);
  console.log(`🎉 ALL EXCEL DATA IMPORTED & SYNCHRONIZED SUCCESSFULLY`);
  console.log(`======================================================\n`);
}

// Execute if run directly from CLI
if (process.argv[1]?.endsWith('import_pooja_excel.ts') || process.argv[1]?.endsWith('import_pooja_excel.js')) {
  importPoojaExcel()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('❌ Import failed with error:', err);
      process.exit(1);
    });
}
