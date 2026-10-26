import "dotenv/config";
import fs from "fs";
import path from "path";
import pool from "../config/db.js";

async function applyMigration0016() {
  console.log("==================================================");
  console.log("SARV MANGAL — Executing Migration 0016 (Approved Mantras)");
  console.log("==================================================");

  const client = await pool.connect();
  try {
    const migrationSqlPath = path.resolve(process.cwd(), "drizzle", "0016_create_approved_mantras.sql");
    const migrationSql = fs.readFileSync(migrationSqlPath, "utf-8");

    console.log("Executing drizzle/0016_create_approved_mantras.sql...");
    await client.query("BEGIN;");
    await client.query(migrationSql);
    await client.query("COMMIT;");
    console.log("✓ Migration 0016 applied successfully.");

    // Verification
    const tablesRes = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'approved_mantras';
    `);
    console.log("Verified Tables in DB:", tablesRes.rows.map(r => r.table_name));

    const countRes = await client.query(`SELECT count(*) as count FROM approved_mantras;`);
    console.log("Seeded Mantras count in DB:", countRes.rows[0]?.count);

  } catch (err: any) {
    await client.query("ROLLBACK;");
    console.error("Migration 0016 failed:", err.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

applyMigration0016();
