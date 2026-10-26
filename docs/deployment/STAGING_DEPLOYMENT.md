# SARV MANGAL — Staging Deployment & Operational Guide

## 1. Overview & Architecture

SARV MANGAL is an on-demand spiritual services platform providing Vedic Pooja bookings, continuous live GPS telemetry for traveling Pandits, temple discoveries, astrology consultations, and a sacred store.

### System Components:
- **Backend**: Node.js (v20+ ESM), Express, TypeScript, Vitest
- **Database**: PostgreSQL 16+ with **PostGIS** extension (spatial points, gist index)
- **Cache & Realtime Broker**: Redis 7+ (GEO index `pandits:live`, rate-limiting, deduplication, Socket.IO adapter)
- **WebSockets**: Socket.IO with authenticated room-level access (`booking:<id>`, `user:<id>`, `pandit:user:<id>`)
- **Payment Gateway**: Razorpay (Webhook raw-body HMAC SHA-256 signature verification & atomic idempotency)
- **Mobile Client**: Flutter 3.24+ (Dart 3.5+)

---

## 2. Required Runtimes & Infrastructure

| Component | Minimum Version | Recommended | Notes |
| :--- | :--- | :--- | :--- |
| **Node.js** | 20.10.0 LTS | 20.x LTS | Active LTS with ES module support |
| **npm** | 10.x | 10.x | Bundled with Node.js 20 |
| **PostgreSQL** | 15.0+ | 16.2+ / Neon | Must have `postgis` extension enabled |
| **PostGIS** | 3.3+ | 3.4+ / 3.6+ | Required for `ST_DWithin`, `ST_Distance`, and geometry types |
| **Redis** | 6.2+ | 7.2+ | Required for `GEOADD`, `GEORADIUS`, and Redis Adapter |
| **Docker / Compose** | 24.0+ | 26.0+ | Optional for containerized staging deployment |
| **Flutter SDK** | 3.22.0+ | 3.24.0+ | For compiling frontend client |

---

## 3. Environment Variable Inventory & Security Classification

All configurations are read from environment variables. **Never commit actual secret values, credentials, or service account JSON files to version control.**

### Core & Server Configuration
| Variable | Classification | Staging Recommendation | Description |
| :--- | :--- | :--- | :--- |
| `NODE_ENV` | **Required** | `staging` | Runtime environment (`development`, `staging`, `production`) |
| `PORT` | Optional | `5000` | Port for the HTTP and WebSocket server |
| `HOST` | Optional | `0.0.0.0` | Network binding interface |
| `CORS_ORIGIN` | **Required** | `https://staging.sarvmangal.app` | Comma-separated list of allowed origins. **Do not use `*` in staging/production.** |

### Database & Redis Configuration
| Variable | Classification | Example Format | Security & Operational Notes |
| :--- | :--- | :--- | :--- |
| `DATABASE_URL` | **Required** | `postgresql://user:pass@host:5432/dbname?sslmode=require` | PostgreSQL connection string. Must target isolated staging DB, never production. |
| `REDIS_URL` | **Required** | `rediss://default:pass@redis-host:6379` | Redis connection URL. Use `rediss://` protocol for TLS encryption in transit. |

### Authentication & Tokens
| Variable | Classification | Minimum Spec | Description |
| :--- | :--- | :--- | :--- |
| `JWT_SECRET` | **Required** | 256-bit random hex/base64 string | Secret for signing and validating auth tokens |
| `JWT_EXPIRES_IN` | Optional | `7d` | Token validity window for standard users (e.g., `7d`, `24h`) |
| `ADMIN_JWT_EXPIRES_IN` | Optional | `4h` | Short-lived token validity window for administrative sessions |
| `OTP_EXPIRY_SECONDS` | Optional | `300` | Expiration window for phone verification OTPs |
| `ADMIN_INITIAL_EMAIL` | **Required for Provisioning** | Valid email | Email address for initial super-admin account provisioning |
| `ADMIN_INITIAL_PASSWORD` | **Required for Provisioning** | 12+ chars, mixed case, number, symbol | Strong initial password for administrator |
| `FORCE_ADMIN_PASSWORD_RESET` | Optional | `false` | Explicit flag required to reset an existing admin's password |

### External Service Providers (Sandboxes & Test Keys)
| Variable | Classification | Required in Staging? | Purpose / Failure Behavior |
| :--- | :--- | :--- | :--- |
| `RAZORPAY_KEY_ID` | **Required (for payments)** | Yes (Test Mode) | Razorpay Test Key ID (`rzp_test_...`) for initiating sandbox orders |
| `RAZORPAY_KEY_SECRET` | **Required (for payments)** | Yes (Test Mode) | Razorpay Test Secret for server-side HMAC signature verification |
| `RAZORPAY_WEBHOOK_SECRET` | Optional | Recommended | Webhook secret for asynchronous capture verification |
| `FAST2SMS_API_KEY` | Optional | Optional | Dispatches real SMS OTPs. Falls back safely to mock log in dev/test |
| `GOOGLE_PLACES_API_KEY` | Optional | Optional | Queries nearby temples. Falls back to empty list if absent |
| `AGORA_APP_ID` | Optional | Optional | Agora WebRTC App ID for video consultations |
| `AGORA_APP_CERTIFICATE` | Optional | Optional | Agora Primary Certificate for server-side token generation |
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Optional | Optional | Base64-encoded JSON of Firebase service account for push notifications |
| `FIREBASE_SERVICE_ACCOUNT_PATH` | Optional | Optional | Local filepath to service account JSON (alternative to Base64) |

---

## 4. Database Setup & Migration Safety

### 1. Enable PostGIS Extension
Connect to the staging PostgreSQL database as an administrative user and execute:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Verify installation
SELECT version(), postgis_full_version();
```

### 2. Migration Execution Commands
```bash
# Check status and generate migration files from Drizzle schema
npm run db:generate

# Apply pending SQL migrations safely to the target database
npm run db:migrate
```

> [!CAUTION]
> **Migration Safety Rules:**
> 1. Never run `npm run db:push --force` on staging or production databases.
> 2. Always verify the database hostname in `$DATABASE_URL` before running migration commands.
> 3. Verify that `__drizzle_migrations` tracks all 14 historical migrations (`0000_init.sql` through `0013_consultations_and_kundli_orders.sql`).

### 3. Administrative User Provisioning & Credential Security
To provision the initial administrator account without hardcoding credentials:
```bash
ADMIN_INITIAL_EMAIL="admin@yourdomain.com" \
ADMIN_INITIAL_PASSWORD="YourStrongUniquePassword#2026" \
npm run db:provision-admin
```

> [!IMPORTANT]
> **Admin Security Policy:**
> - `npm run db:provision-admin` will **never** silently overwrite an existing admin password unless `FORCE_ADMIN_PASSWORD_RESET=true` is explicitly provided.
> - Password hashes are generated using scrypt with random 16-byte salts.
> - Never print passwords or hashes to terminal output or deployment logs.
> - Administrative sessions expire automatically after 4 hours (`ADMIN_JWT_EXPIRES_IN=4h`).
> - Administrators can invalidate their session via `POST /api/v1/admin/auth/logout`.

---

## 5. Deployment Options & Execution Procedures

### Option A: Containerized Staging Deployment (Docker & Compose)

1. **Verify or inject staging environment:**
   Create a secure `.env.staging` file on the staging host (do not commit to Git).
2. **Build and launch containers:**
   ```bash
   docker compose -f docker-compose.staging.yml up -d --build
   ```
3. **Verify running containers and health status:**
   ```bash
   docker compose -f docker-compose.staging.yml ps
   docker compose -f docker-compose.staging.yml logs -f backend
   ```

### Option B: Bare-Metal / Cloud VM (PM2 / Systemd)

1. **Clean install & build:**
   ```bash
   npm ci
   npm run typecheck
   npm run build
   ```
2. **Launch with PM2 process manager:**
   ```bash
   NODE_ENV=staging pm2 start dist/server.js --name "sarvmangal-backend" --instances 2 --max-memory-restart 500M
   ```

---

## 6. Observability, Health Probes & Tracing

### 1. Liveness Probe (`GET /health/live`)
- **Purpose**: Kubernetes, Docker, or Load Balancer container liveness check.
- **Expected Status**: `200 OK`
- **Sample Response**:
  ```json
  {
    "status": "ok",
    "timestamp": "2026-10-20T00:00:00.000Z",
    "uptimeSeconds": 312
  }
  ```

### 2. Readiness Probe (`GET /health/ready`)
- **Purpose**: Verifies that database connectivity (`SELECT 1`), Redis connection (`PING`), and external providers are properly initialized before routing traffic.
- **Expected Status**: `200 OK` (or `503 Service Unavailable` if database is down)
- **Sample Response**:
  ```json
  {
    "status": "ok",
    "timestamp": "2026-10-20T00:00:00.000Z",
    "uptimeSeconds": 312,
    "checks": {
      "database": { "status": "up", "latencyMs": 4 },
      "redis": { "status": "up", "latencyMs": 2 },
      "providers": {
        "razorpay": { "configured": true, "details": "Key ID present" },
        "fast2sms": { "configured": false, "details": "Missing key (using development mock)" },
        "firebase": { "configured": false, "details": "Missing service account (push notifications disabled)" },
        "googlePlaces": { "configured": false, "details": "Missing key (temple discovery mock)" },
        "agora": { "configured": false, "details": "Missing credentials" }
      }
    }
  }
  ```

### 3. Request Correlation (`x-request-id`)
Every incoming request receives an `x-request-id` header (either passed by an upstream proxy or generated as a UUIDv4). All structured logs correlate to this ID.

---

## 7. Graceful Teardown & Safe Shutdown

The application intercepts `SIGTERM` and `SIGINT` signals to guarantee no in-flight requests are severed:
1. Stops accepting incoming HTTP/WebSocket connections.
2. Closes Socket.IO server and disconnects active socket connections cleanly.
3. Closes Redis connection (`closeRedis`).
4. Closes PostgreSQL client pool (`pool.end`).
5. Imposes a 10-second hard timeout before emergency exit to prevent lingering hung processes.

---

## 8. Backup, Restore Drills & Rollback Procedures

### Database Backup
Run automated snapshots or logical dumps:
```bash
pg_dump -Fc -v -d "$DATABASE_URL" -f "sarvmangal_staging_$(date +%Y%m%d_%H%M%S).dump"
```

### Safe Restore Procedure (Restore Drills)
> [!WARNING]
> **NEVER use `pg_restore --clean --if-exists` against an active staging or production database.**
> Always perform restore drills against a newly created, disposable database to verify dump integrity and prevent accidental data loss.

1. **Create a disposable drill database:**
   ```bash
   createdb sarvmangal_restore_drill
   ```
2. **Execute restore into the drill target:**
   ```bash
   pg_restore -v -d "postgresql://user:pass@host:5432/sarvmangal_restore_drill" "sarvmangal_staging_<timestamp>.dump"
   ```
3. **Verify table count, PostGIS geometry indexes, and row counts:**
   ```sql
   SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';
   SELECT count(*) FROM users;
   SELECT count(*) FROM bookings;
   ```
4. **Tear down disposable database after drill:**
   ```bash
   dropdb sarvmangal_restore_drill
   ```

### Application Rollback
If a deployment fails:
1. Roll back the Git commit or container image tag to the previously stable release:
   ```bash
   git checkout <last-stable-tag>
   npm ci
   npm run build
   pm2 restart sarvmangal-backend
   ```
2. If schema changes are backward-compatible, keep the database schema forward. If schema changes broke backward compatibility, restore from the verified pre-deployment snapshot.

---

## 9. Staging Smoke Test Checklist

Execute these verifications after deploying to staging:

- [ ] `GET /health/live` returns HTTP 200 with valid uptime.
- [ ] `GET /health/ready` returns HTTP 200 with database `up` and latency < 50ms.
- [ ] Database tables and PostGIS spatial indexes verified (`idx_pandits_location_gist`).
- [ ] Redis responds to ping with latency < 10ms.
- [ ] Request correlation header `x-request-id` returned in HTTP responses.
- [ ] Devotee OTP request (`POST /api/v1/auth/send-otp`) functions.
- [ ] Devotee login (`POST /api/v1/auth/verify-otp`) issues valid JWT token.
- [ ] Pandit duty toggle (`PATCH /api/v1/pandits/duty-status`) updates Postgres and Redis GEO `pandits:live`.
- [ ] Pandit continuous telemetry (`POST /api/v1/pandits/me/telemetry`) records location and rejects updates when off duty.
- [ ] Stale location (> 10 minutes) correctly excludes Pandit from live in-person dispatch.
- [ ] Devotee tracking screen displays live GPS vs last known location badges accurately.
- [ ] Graceful shutdown verified (`kill -SIGTERM <pid>` completes cleanly without unhandled rejection).
