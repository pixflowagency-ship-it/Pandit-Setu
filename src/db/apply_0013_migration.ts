import fs from "fs";
import path from "path";
import pool from "../config/db.js";

async function applyMigration() {
  console.log("==================================================");
  console.log("SARV MANGAL — Executing Migration 0013 & Spatial Index");
  console.log("==================================================");

  const client = await pool.connect();
  try {
    const migrationSqlPath = path.resolve(process.cwd(), "drizzle", "0013_consultations_and_kundli_orders.sql");
    const migrationSql = fs.readFileSync(migrationSqlPath, "utf-8");

    console.log("Executing drizzle/0013_consultations_and_kundli_orders.sql...");
    await client.query("BEGIN;");
    await client.query(migrationSql);
    
    console.log("Creating spatial GIST index on pandits.location...");
    await client.query(`CREATE INDEX IF NOT EXISTS "idx_pandits_location_gist" ON "pandits" USING GIST ("location");`);
    
    await client.query("COMMIT;");
    console.log("✓ Migration and spatial index applied successfully.");

    // Verification
    const tablesRes = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name IN ('consultations', 'kundli_orders');
    `);
    console.log("Verified Tables in DB:", tablesRes.rows.map(r => r.table_name));

    const indexRes = await client.query(`
      SELECT indexname, indexdef 
      FROM pg_indexes 
      WHERE tablename = 'pandits' AND indexname = 'idx_pandits_location_gist';
    `);
    console.log("Verified Spatial Index:", indexRes.rows[0]?.indexname || "NOT FOUND");

  } catch (err: any) {
    await client.query("ROLLBACK;");
    console.error("Migration failed:", err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

applyMigration();
