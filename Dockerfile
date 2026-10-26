# ==============================================================================
# SARV MANGAL Backend — Production & Staging Multi-Stage Dockerfile
# ==============================================================================

# Stage 1: Build TypeScript application
FROM node:20-alpine AS builder

WORKDIR /app

# Install build dependencies
COPY package*.json ./
RUN npm ci

# Copy TypeScript source and configurations
COPY tsconfig.json ./
COPY src/ ./src/

# Compile TypeScript to dist/
RUN npm run build

# Stage 2: Production / Staging runtime
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=staging
ENV PORT=5000
ENV HOST=0.0.0.0

# Install production dependencies only
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled JavaScript from builder stage
COPY --from=builder /app/dist ./dist
COPY drizzle/ ./drizzle/
COPY drizzle.config.ts ./

# Create non-root system user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup && \
    mkdir -p /app/storage/documents && chown -R appuser:appgroup /app

USER appuser

EXPOSE 5000

# Native Node.js HTTP liveness healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "fetch('http://localhost:5000/health/live').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["node", "dist/server.js"]
