import { Client } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const client = new Client({
  connectionString: process.env.DATABASE_URL,
});

(async () => {
  try {
    await client.connect();
    await client.query(`ALTER TABLE "poojas" ADD COLUMN IF NOT EXISTS "updated_at" timestamptz NOT NULL DEFAULT now();`);
    console.log('updated_at column added (or already existed)');
  } catch (err) {
    console.error('Error adding updated_at column', err);
  } finally {
    await client.end();
  }
})();
