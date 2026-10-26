import "dotenv/config";
import pool from "../config/db.js";
import { hashPassword, verifyPassword } from "../utils/password.js";

async function provisionAdmin() {
  const adminEmail = process.env.ADMIN_INITIAL_EMAIL?.trim().toLowerCase();
  const adminPassword = process.env.ADMIN_INITIAL_PASSWORD;
  const adminPhone = process.env.ADMIN_INITIAL_PHONE || "+919999900000";
  const adminName = process.env.ADMIN_INITIAL_NAME || "SARV MANGAL Admin Desk";
  const forceReset = process.env.FORCE_ADMIN_PASSWORD_RESET === "true";

  console.log("==================================================");
  console.log("SARV MANGAL — Admin Account Provisioning");
  console.log("==================================================");

  if (!adminEmail || !adminPassword) {
    console.error("❌ ERROR: Both ADMIN_INITIAL_EMAIL and ADMIN_INITIAL_PASSWORD are required environment variables.");
    console.error("Usage: ADMIN_INITIAL_EMAIL=admin@sarvmangal.app ADMIN_INITIAL_PASSWORD=<secret> npx tsx src/db/provision_admin.ts");
    process.exitCode = 1;
    return;
  }

  if (adminPassword.length < 12) {
    console.error("❌ ERROR: Administrative password must be at least 12 characters long.");
    process.exitCode = 1;
    return;
  }

  try {
    // 1. Ensure DB columns exist
    await pool.query(`
      ALTER TABLE users ADD COLUMN IF NOT EXISTS password_hash VARCHAR(255);
      ALTER TABLE users ADD COLUMN IF NOT EXISTS password_salt VARCHAR(64);
    `);
    console.log("✓ users table schema validated (password_hash, password_salt columns present)");

    // 2. Check if user already exists
    const existing = await pool.query(
      "SELECT id, role, email, password_hash FROM users WHERE email = $1 OR phone = $2",
      [adminEmail, adminPhone]
    );

    if (existing.rows.length > 0) {
      const user = existing.rows[0];
      if (user.password_hash && !forceReset) {
        console.log(`✓ Admin account exists (${adminEmail}, ID: ${user.id}).`);
        console.log("✓ Existing credentials preserved. (Set FORCE_ADMIN_PASSWORD_RESET=true to overwrite)");
        return;
      }

      // Hash the new password securely using scrypt
      const { hash, salt } = hashPassword(adminPassword);
      if (!verifyPassword(adminPassword, hash, salt)) {
        throw new Error("Password verification self-test failed");
      }

      await pool.query(
        `UPDATE users 
         SET full_name = $1, email = $2, role = 'ADMIN', password_hash = $3, password_salt = $4, updated_at = NOW() 
         WHERE id = $5`,
        [adminName, adminEmail, hash, salt, user.id]
      );
      console.log(`✓ Updated existing account to ADMIN role with new credentials (ID: ${user.id})`);
    } else {
      const { hash, salt } = hashPassword(adminPassword);
      if (!verifyPassword(adminPassword, hash, salt)) {
        throw new Error("Password verification self-test failed");
      }

      const insertRes = await pool.query(
        `INSERT INTO users (full_name, phone, email, role, password_hash, password_salt, created_at, updated_at) 
         VALUES ($1, $2, $3, 'ADMIN', $4, $5, NOW(), NOW()) 
         RETURNING id`,
        [adminName, adminPhone, adminEmail, hash, salt]
      );
      console.log(`✓ Provisioned new ADMIN user: ${adminEmail} (ID: ${insertRes.rows[0].id})`);
    }

    console.log("✓ Admin account provisioned safely.");
    console.log("✓ Credentials hashed with scrypt + 16-byte cryptographically secure salt.");
  } catch (error: any) {
    console.error("Provisioning failed:", error.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
}

provisionAdmin();
