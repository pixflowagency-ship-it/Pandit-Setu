# SARV MANGAL — Setup & Developer Environment Guide

**Official Brand:** SARV MANGAL (सर्व मंगल)  
**Repository:** https://github.com/pixflowagency-ship-it/Pandit-Setu  

---

## 1. Prerequisites

- **Node.js**: v20+ LTS (with npm)
- **TypeScript**: v5.8+
- **Flutter SDK**: 3.24+ (with Dart 3.5+)
- **PostgreSQL**: 16+ (with PostGIS extension enabled)
- **Redis**: 7.0+ (optional; local in-memory fallback included for development)
- **Docker & Docker Compose**: Optional for containerized orchestration

---

## 2. Backend Setup

1. **Navigate to the repository root**:
   ```bash
   cd pndtbcknd
   ```
2. **Install dependencies**:
   ```bash
   npm install
   ```
3. **Configure environment variables**:
   ```bash
   cp .env.example .env
   # Edit .env with your local PostgreSQL and Redis credentials
   ```
4. **Database Migration & Seeding**:
   ```bash
   npm run db:push
   npm run seed
   npm run import:poojas
   npm run import:products
   ```
5. **Start Development Server**:
   ```bash
   npm run dev
   ```
   Server will listen at `http://localhost:5000`.

---

## 3. Dedicated Admin Web Portal Setup

1. **Navigate to `admin-portal/`**:
   ```bash
   cd admin-portal
   ```
2. **Install dependencies**:
   ```bash
   npm install
   ```
3. **Configure environment**:
   ```bash
   cp .env.example .env
   ```
4. **Start Vite Development Server**:
   ```bash
   npm run dev
   ```
   Admin portal will be available at `http://localhost:3000` (or `http://localhost:5173`).
5. **Production Build**:
   ```bash
   npm run build
   ```

---

## 4. Flutter Mobile Client Setup

1. **Navigate to `frontend/pandit_ssetu/`**:
   ```bash
   cd frontend/pandit_ssetu
   ```
2. **Resolve packages**:
   ```bash
   flutter pub get
   ```
3. **Run Static Analysis**:
   ```bash
   flutter analyze
   ```
4. **Run Widget Tests**:
   ```bash
   flutter test
   ```
5. **Launch Application**:
   ```bash
   flutter run
   ```

---

## 5. Docker Orchestration

To run the complete stack (Backend, Admin Portal, PostGIS, Redis) via Docker Compose:

```bash
docker compose up --build -d
```
