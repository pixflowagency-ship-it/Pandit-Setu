import "dotenv/config";
import path from "path";
import xlsx from "xlsx";
import { db } from "./index.js";
import { products } from "./schema/products.js";
import { sql, isNull } from "drizzle-orm";

interface ExcelProductRow {
  Product_ID?: string | number;
  Category?: string;
  Sub_Category?: string;
  Item_Name?: string;
  Specification_Type?: string;
  Unit?: string;
  Selling_Price?: string | number;
  Product_Description?: string;
  Image_URL?: string;
  Status?: string;
  Search_Tags?: string;
}

function getCuratedImageUrl(category: string, name: string): string {
  const cat = category.toLowerCase();
  const n = name.toLowerCase();

  if (cat.includes("deepak") || cat.includes("jyoti") || n.includes("दीपक") || n.includes("दीया")) {
    return "https://images.unsplash.com/photo-1609102434313-f938d87a718b?w=500";
  }
  if (cat.includes("flower") || cat.includes("garland") || n.includes("फूल") || n.includes("माला")) {
    return "https://images.unsplash.com/photo-1563245372-f21724e3856d?w=500";
  }
  if (cat.includes("kumkum") || cat.includes("chandan") || n.includes("हल्दी") || n.includes("रोली") || n.includes("कुमकुम")) {
    return "https://images.unsplash.com/photo-1596704017254-9b121068fb31?w=500";
  }
  if (cat.includes("havan") || cat.includes("samidha") || cat.includes("wood") || n.includes("हवन")) {
    return "https://images.unsplash.com/photo-1605152276897-4f618f831968?w=500";
  }
  if (cat.includes("brass") || cat.includes("copper") || cat.includes("kalash") || n.includes("कलश") || n.includes("तांबा") || n.includes("पीतल")) {
    return "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500";
  }
  if (cat.includes("idol") || cat.includes("murti") || cat.includes("yantra") || n.includes("मूर्ति") || n.includes("यंत्र")) {
    return "https://images.unsplash.com/photo-1567604130959-7d9d2d0af7c2?w=500";
  }
  if (cat.includes("book") || cat.includes("print") || n.includes("पुस्तक") || n.includes("चालीसा") || n.includes("गीता")) {
    return "https://images.unsplash.com/photo-1544816155-12df9643f363?w=500";
  }
  if (cat.includes("vastra") || cat.includes("aasan") || n.includes("वस्त्र") || n.includes("आसन") || n.includes("कपड़ा")) {
    return "https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=500";
  }
  if (cat.includes("fragrance") || cat.includes("dhoop") || cat.includes("agarbatti") || cat.includes("kapoor")) {
    return "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500";
  }
  return "https://images.unsplash.com/photo-1608306448197-e83633f1261c?w=500";
}

function calculateProductPrice(category: string, rawPrice?: string | number): string {
  if (rawPrice !== undefined && rawPrice !== null && rawPrice !== "") {
    const parsed = typeof rawPrice === "number" ? rawPrice : parseFloat(rawPrice.toString().replace(/[^\d.]/g, ""));
    if (!isNaN(parsed) && parsed > 0) {
      return parsed.toFixed(2);
    }
  }

  const cat = category.toLowerCase();
  if (cat.includes("idol") || cat.includes("murti") || cat.includes("brass") || cat.includes("copper") || cat.includes("yantra") || cat.includes("rudraksha")) {
    return "499.00";
  }
  if (cat.includes("ready pooja kit") || cat.includes("kit") || cat.includes("solah shringar")) {
    return "399.00";
  }
  if (cat.includes("havan") || cat.includes("vastra") || cat.includes("utensil") || cat.includes("aasan") || cat.includes("book")) {
    return "250.00";
  }
  if (cat.includes("kumkum") || cat.includes("chandan") || cat.includes("dhoop") || cat.includes("agarbatti") || cat.includes("kapoor")) {
    return "99.00";
  }
  return "150.00";
}

export async function importStoreProducts() {
  console.log("🚀 Starting Pooja Store Product Master Import...");

  const filePath = path.resolve("Pooja_Store_App_Product_Master_500Plus.xlsx");
  const workbook = xlsx.readFile(filePath);

  const sheetName = "App_Import";
  const sheet = workbook.Sheets[sheetName];
  if (!sheet) {
    throw new Error(`Sheet "${sheetName}" not found in workbook!`);
  }

  const rows = xlsx.utils.sheet_to_json<ExcelProductRow>(sheet, { defval: "" });
  console.log(`📋 Found ${rows.length} rows in sheet "${sheetName}".`);

  // Remove old unkeyed dummy rows where product_id IS NULL if any exist
  const deletedOldDummies = await db.delete(products).where(isNull(products.productId)).returning({ id: products.id });
  if (deletedOldDummies.length > 0) {
    console.log(`🧹 Cleaned up ${deletedOldDummies.length} legacy dummy rows lacking product_id.`);
  }

  let importedCount = 0;
  const batchSize = 100;

  for (let i = 0; i < rows.length; i += batchSize) {
    const batchRows = rows.slice(i, i + batchSize);
    const records = batchRows
      .filter((r) => r.Product_ID && r.Item_Name)
      .map((r) => {
        const productId = r.Product_ID!.toString().trim();
        const name = r.Item_Name!.toString().trim();
        const category = (r.Category || "General Pooja Material").toString().trim();
        const subCategory = (r.Sub_Category || "").toString().trim() || null;
        const spec = (r.Specification_Type || "Standard").toString().trim();
        const unit = (r.Unit || "pcs").toString().trim();
        const price = calculateProductPrice(category, r.Selling_Price);
        const description = (r.Product_Description || `${name} - ${spec}`).toString().trim();
        const imageUrl = (r.Image_URL && r.Image_URL.toString().trim().length > 0)
          ? r.Image_URL.toString().trim()
          : getCuratedImageUrl(category, name);
        const status = (r.Status || "Active").toString().trim();
        const isActive = status.toLowerCase() !== "inactive";
        const searchTags = (r.Search_Tags || `${name}, pooja, puja, pooja samagri`).toString().trim();
        const isBestseller = subCategory === "Basic Essentials" || category.includes("General");
        const badge = !isActive ? "OUT OF STOCK" : isBestseller ? "BESTSELLER" : "AVAILABLE";
        const samagriList = [unit ? `Unit: ${unit}` : "Standard", spec || "Standard"];

        return {
          productId,
          name,
          category,
          subCategory,
          specificationType: spec,
          unit,
          price,
          description,
          imageUrl,
          status,
          searchTags,
          badge,
          samagri: samagriList,
          isActive,
        };
      });

    if (records.length > 0) {
      await db
        .insert(products)
        .values(records)
        .onConflictDoUpdate({
          target: products.productId,
          set: {
            name: sql`EXCLUDED.name`,
            category: sql`EXCLUDED.category`,
            subCategory: sql`EXCLUDED.sub_category`,
            specificationType: sql`EXCLUDED.specification_type`,
            unit: sql`EXCLUDED.unit`,
            price: sql`EXCLUDED.price`,
            description: sql`EXCLUDED.description`,
            imageUrl: sql`EXCLUDED.image_url`,
            status: sql`EXCLUDED.status`,
            searchTags: sql`EXCLUDED.search_tags`,
            badge: sql`EXCLUDED.badge`,
            samagri: sql`EXCLUDED.samagri`,
            isActive: sql`EXCLUDED.is_active`,
            updatedAt: sql`now()`,
          },
        });

      importedCount += records.length;
      console.log(`📦 Synced batch ${i + 1} to ${Math.min(i + batchSize, rows.length)} (${importedCount} products)`);
    }
  }

  console.log(`\n✅ Store Products Import Complete!`);
  console.log(`🎉 Total Products Synced in Database: ${importedCount}`);
  return importedCount;
}

if (process.argv[1] && process.argv[1].endsWith("import_store_products_excel.ts")) {
  importStoreProducts()
    .then((count) => {
      console.log(`Done. Total: ${count}`);
      process.exit(0);
    })
    .catch((err) => {
      console.error("Import failed:", err);
      process.exit(1);
    });
}
