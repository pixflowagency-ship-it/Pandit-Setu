import dotenv from "dotenv";
dotenv.config();
import app from "./app.js";
import { env } from "./config/env.js";
import { testDbConnection } from "./config/db.js";
async function startServer() {
    await testDbConnection();
    app.listen(env.port, () => {
        console.log(`Poojapaath API running on http://localhost:${env.port}`);
    });
}
startServer();
//# sourceMappingURL=server.js.map