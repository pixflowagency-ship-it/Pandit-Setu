import { Pool, type QueryResult, type QueryResultRow } from "pg";
import { env } from "./env.js";
import { logger } from "../utils/logger.js";

const pool = new Pool({
  connectionString: env.databaseUrl,
});

export async function query<T extends QueryResultRow = QueryResultRow>(
  text: string,
  params?: unknown[],
): Promise<QueryResult<T>> {
  const start = Date.now();
  try {
    const result = await pool.query<T>(text, params);
    const duration = Date.now() - start;
    if (env.nodeEnv === "development") {
      logger.debug({ duration }, "Executed query");
    }
    return result;
  } catch (error) {
    logger.error({ err: error }, "Database query error");
    throw error;
  }
}

export async function testDbConnection(): Promise<void> {
  try {
    const result = await query("SELECT NOW()");
    logger.info({ now: result.rows[0] }, "Database connection successful");
  } catch (error) {
    logger.fatal({ err: error }, "Database connection failed");
    process.exit(1);
  }
}

export default pool;
