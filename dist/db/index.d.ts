import postgres from "postgres";
import * as schema from "./schema/index.js";
export declare const db: import("drizzle-orm/postgres-js").PostgresJsDatabase<typeof schema> & {
    $client: postgres.Sql<{}>;
};
export * from "./schema/index.js";
//# sourceMappingURL=index.d.ts.map