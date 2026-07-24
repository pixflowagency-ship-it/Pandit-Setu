import { Pool } from "pg";
import { env } from "./env.js";
const pool = new Pool({
    connectionString: env.databaseUrl,
});
export async function query(text, params) {
    const start = Date.now();
    try {
        const result = await pool.query(text, params);
        const duration = Date.now() - start;
        if (env.nodeEnv === "development") {
            console.log(`Executed query in ${duration}ms`);
        }
        return result;
    }
    catch (error) {
        console.error("Database query error:", error);
        throw error;
    }
}
export async function testDbConnection() {
    try {
        const result = await query("SELECT NOW()");
        console.log("✅ Database connection successful:", result.rows[0]);
    }
    catch (error) {
        console.error("❌ Database connection failed:", error);
        process.exit(1);
    }
}
export default pool;
//# sourceMappingURL=db.js.map