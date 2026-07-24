import 'dotenv/config';
import { sql } from 'drizzle-orm';
import { db } from './index.js';
async function fixUsersTable() {
    console.log('Syncing missing columns to users table...');
    await db.execute(sql `
    ALTER TABLE "users"
      ADD COLUMN IF NOT EXISTS "dob" varchar(50),
      ADD COLUMN IF NOT EXISTS "tob" varchar(50),
      ADD COLUMN IF NOT EXISTS "pob" varchar(255),
      ADD COLUMN IF NOT EXISTS "gotra" varchar(100),
      ADD COLUMN IF NOT EXISTS "zodiac" varchar(50),
      ADD COLUMN IF NOT EXISTS "city" varchar(100),
      ADD COLUMN IF NOT EXISTS "email" varchar(255);
  `);
    console.log('✅ Users table updated successfully!');
    process.exit(0);
}
fixUsersTable().catch((err) => {
    console.error('Migration failed:', err);
    process.exit(1);
});
//# sourceMappingURL=fix_users_table.js.map