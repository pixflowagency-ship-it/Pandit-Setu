import dotenv from "dotenv";
dotenv.config();

import pool from "../config/db.js";

async function verifyDatabase() {
  console.log("==================================================");
  console.log("SARV MANGAL — Live Database Verification");
  console.log("==================================================");

  try {
    // 1. PostGIS Version
    const postgisRes = await pool.query("SELECT version(), postgis_full_version();");
    console.log("PostgreSQL Version:", postgisRes.rows[0].version.split(" on ")[0]);
    console.log("PostGIS Version:", postgisRes.rows[0].postgis_full_version.split(" ")[0]);

    // 2. Tables
    const tablesRes = await pool.query(
      "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name;"
    );
    const tables = tablesRes.rows.map((r) => r.table_name);
    console.log("\nTables Present in DB (" + tables.length + "):");
    console.log(tables.join(", "));

    // 3. PostGIS Geometry Column & Index Check
    const geomRes = await pool.query(`
      SELECT f_table_name, f_geometry_column, coord_dimension, srid, type 
      FROM geometry_columns;
    `);
    console.log("\nPostGIS Geometry Columns:");
    console.log(geomRes.rows);

    const indexRes = await pool.query(`
      SELECT indexname, indexdef 
      FROM pg_indexes 
      WHERE tablename = 'pandits' AND indexname = 'idx_pandits_location_gist';
    `);
    console.log("\nSpatial GIST Index on Pandits Location:");
    console.log(indexRes.rows.length > 0 ? "PRESENT (" + indexRes.rows[0].indexname + ")" : "MISSING");

    // 4. Migration History
    const migCheck = await pool.query(`
      SELECT to_regclass('public.__drizzle_migrations') as exists;
    `);
    if (migCheck.rows[0].exists) {
      const migHistory = await pool.query("SELECT id, hash, created_at FROM __drizzle_migrations ORDER BY id;");
      console.log("\nDrizzle Applied Migrations (" + migHistory.rows.length + "):");
      console.log(migHistory.rows);
    } else {
      console.log("\n__drizzle_migrations table: NOT PRESENT (Drizzle push used or initial setup)");
    }

    // 5. Core Catalog Counts
    for (const table of ["poojas", "samagri", "products", "users", "pandits", "bookings", "consultations", "kundli_orders"]) {
      if (tables.includes(table)) {
        const countRes = await pool.query(`SELECT count(*) FROM "${table}";`);
        console.log(`Count in ${table}:`, countRes.rows[0].count);
      } else {
        console.log(`Table ${table}: NOT YET CREATED IN DB`);
      }
    }
  } catch (err: any) {
    console.error("Verification error:", err.message);
  } finally {
    await pool.end();
  }
}

verifyDatabase();
