import "dotenv/config";
import fs from "fs";
import path from "path";
import pool from "../config/db.js";

async function applyMigration0017() {
  console.log("==================================================");
  console.log("SARV MANGAL — Executing Migration 0017 (App UI Configs)");
  console.log("==================================================");

  let client;
  try {
    client = await pool.connect();
    const migrationSqlPath = path.resolve(process.cwd(), "drizzle", "0017_create_app_ui_configs.sql");
    const migrationSql = fs.readFileSync(migrationSqlPath, "utf-8");

    console.log("Executing drizzle/0017_create_app_ui_configs.sql...");
    await client.query("BEGIN;");
    await client.query(migrationSql);
    await client.query("COMMIT;");
    console.log("✓ Migration 0017 applied successfully.");

    // Verification
    const tablesRes = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' AND table_name = 'app_ui_configs';
    `);
    console.log("Verified Tables in DB:", tablesRes.rows.map(r => r.table_name));

    const countRes = await client.query(`SELECT count(*) as count, status, version FROM app_ui_configs GROUP BY status, version;`);
    console.log("Config rows in DB:", countRes.rows);

  } catch (err: any) {
    if (client) {
      await client.query("ROLLBACK;");
    }
    console.warn("Migration 0017 note (DB might be offline/unreachable in local mock test):", err.message);
  } finally {
    if (client) {
      client.release();
    }
    await pool.end();
  }
}

applyMigration0017();
