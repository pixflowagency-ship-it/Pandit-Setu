# SARV MANGAL (सर्व मंगल) — Unified Local Development & Startup Guide

**Official Brand:** SARV MANGAL (सर्व मंगल)  
**Repository:** `https://github.com/pixflowagency-ship-it/Pandit-Setu`  
**Operating Environment:** Windows (PowerShell 5.1 / PowerShell 7+)

---

## 1. Overview & Architecture

The SARV MANGAL development ecosystem consists of three major tiers:
1. **Core API Server & WebSocket Hub:** Node.js, Express, TypeScript, Socket.IO (`http://localhost:5000`)
2. **Mobile Client:** Flutter Cross-Platform Application (`frontend/pandit_ssetu/`)
3. **Admin Web Portal:** Dedicated Vite SPA (`admin-portal/`, `http://localhost:5173`)
4. **Database:** PostgreSQL (Neon Cloud / Local) with Drizzle ORM

The unified development tooling automatically ensures that starting the mobile application launches or connects to an active, healthy backend, while allowing the Admin Portal to run independently without starting duplicate servers.

---

## 2. Quick Command Reference

Run these commands from the **repository root**:

| Command | Action | Description |
| :--- | :--- | :--- |
| **`npm run dev:app`** | **Flutter App + Backend** | Checks backend health, starts backend if offline, and launches the Flutter app with the correct API URL. |
| **`npm run dev:admin`** | **Admin Portal (Independent)** | Launches Vite Admin Portal on port 5173. Connects to existing backend; warns if backend is offline without starting duplicates. |
| **`npm run dev:all`** | **Full Stack (App + Admin + Backend)** | Starts backend (if offline), launches Admin Portal in background, and runs Flutter in foreground. |
| **`npm run dev:backend`** | **Backend Only** | Starts the Node.js/Express API with auto-reloading (`tsx watch --env-file=.env`). Equivalent to `npm run dev`. |

---

## 3. Flutter App Startup Modes

The startup script [`scripts/dev-app.ps1`](file:///c:/Users/krmta/OneDrive/Desktop/pndtbcknd/scripts/dev-app.ps1) supports multiple device targeting modes via PowerShell:

### A. Android Studio Emulator (Default)
When developing on an Android Virtual Device (AVD), the emulator communicates with your computer via loopback IP `10.0.2.2`.
```powershell
# Default mode (uses http://10.0.2.2:5000/api/v1)
npm run dev:app

# Or explicit PowerShell invocation:
.\scripts\dev-app.ps1 -Mode emulator
```

### B. Physical Android Phone (Over Wi-Fi / Local Network)
When testing on a real physical Android phone connected to the same Wi-Fi router as your PC:
```powershell
.\scripts\dev-app.ps1 -Mode lan
```
- **Auto-Detection:** The script automatically detects your PC's active Wi-Fi LAN IP (e.g. `192.168.0.100`) and passes `--dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:5000/api/v1`.
- **Manual LAN IP Override:**
  ```powershell
  .\scripts\dev-app.ps1 -Mode lan -LanIp 192.168.0.105
  ```
- **Windows Firewall Requirement:** Your PC's Windows Defender Firewall must allow inbound traffic on port 5000. To enable this in an administrator PowerShell prompt:
  ```powershell
  New-NetFirewallRule -DisplayName "SARV MANGAL Dev Backend (Port 5000)" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow
  ```
- **Verification on Phone:** Before launching the app, open Chrome on your phone and browse to `http://<YOUR_LAN_IP>:5000/health/live`. You should see `{"status":"ok"}`.

### C. Physical Android Phone (Over USB Cable with ADB)
If your phone is plugged in via USB with USB Debugging enabled:
```powershell
.\scripts\dev-app.ps1 -Mode usb
```
This automatically runs `adb reverse tcp:5000 tcp:5000`, mapping the phone's internal port 5000 directly to your PC's port 5000 over the USB cable without needing Wi-Fi or firewall modifications.

### D. Web or Windows Desktop
```powershell
# Flutter Web (Google Chrome)
.\scripts\dev-app.ps1 -Mode web

# Flutter Windows Native Desktop
.\scripts\dev-app.ps1 -Mode windows
```

---

## 4. Admin Portal Independent Startup

The Admin Portal can be started at any time without triggering a duplicate backend instance:

```bash
# From repository root:
npm run dev:admin

# Or from admin-portal directory:
cd admin-portal
npm run dev
```

- If the backend is already online on port 5000, the script connects to it immediately.
- If the backend is not running, the script displays a clear warning and informs you that API calls will fail until the backend is started.
- To automatically start the backend alongside the Admin Portal, pass the `-StartBackend` switch:
  ```powershell
  .\scripts\dev-admin.ps1 -StartBackend
  ```

---

## 5. Process Lifecycle & Safe Cleanup

### Automatic Cleanup Behavior
- When you press **Ctrl + C** to terminate an `npm run dev:app` or `dev:all` session:
  - If the script **started the backend**, it terminates only the backend process tree (PID) that it spawned.
  - If the backend was **already running before the script started**, the script leaves it running untouched so your existing development workflow is not interrupted.
  - Unrelated Node.js, database, or editor processes are never touched.

### Troubleshooting Common Issues

#### 1. Port 5000 Conflict ("EADDRINUSE")
If a previous backend process was unexpectedly orphaned and is holding port 5000:
```powershell
# Find the PID listening on port 5000:
netstat -ano | findstr 5000

# Terminate only that specific process by PID:
taskkill /PID <PID> /F
```

#### 2. Backend Health Verification
To manually test if the backend server and database are healthy:
```bash
# Fast liveness probe
curl http://localhost:5000/health/live

# Full readiness probe (includes Neon DB latency check)
curl http://localhost:5000/health/ready
```

#### 3. Inspecting Background Backend Logs
When started in background mode by `dev-app.ps1`, the backend writes standard logs to:
- `storage/logs/backend-dev.stdout.log`
- `storage/logs/backend-dev.stderr.log`

---

## 6. Testing & Quality Verification

Before committing changes, verify all tiers with the project's automated test suites:

```bash
# 1. Backend typecheck & unit tests (329 tests)
npm run typecheck
npm test

# 2. Admin Portal production build
npm run build --prefix admin-portal

# 3. Flutter static analysis & widget tests (126 tests)
cd frontend/pandit_ssetu
flutter analyze
flutter test
```
