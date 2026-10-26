# ==============================================================================
# SARV MANGAL - Independent Admin Portal Development Runner
# ==============================================================================
param(
    [int]$Port = 5000,
    [switch]$StartBackend = $false
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$AdminDir = Join-Path $RepoRoot "admin-portal"

# Load shared automation functions
. (Join-Path $ScriptDir "common.ps1")

Write-Header "SARV MANGAL - Admin Portal Development Startup"

$backendProcess = $null
$startedBackend = $false

try {
    # --------------------------------------------------------------------------
    # 1. Check Backend Availability
    # --------------------------------------------------------------------------
    if (Test-BackendLive -Port $Port) {
        Write-Success "Connected to active SARV MANGAL Backend at http://localhost:$Port"
    } else {
        if ($StartBackend) {
            Write-Info "Backend not detected on port $Port. Auto-launching backend in background..."
            $backendProcess = Start-BackendProcess -RepoRoot $RepoRoot -Port $Port
            $startedBackend = $true

            $ready = Wait-BackendReady -Port $Port -TimeoutSeconds 30
            if (-not $ready) {
                Write-Err "Backend failed to report healthy readiness."
                throw "Backend startup timed out."
            }
            Write-Success "Backend started successfully (PID: $($backendProcess.Id))."
        } else {
            Write-Warn "Backend is NOT currently detected at http://localhost:$Port."
            Write-Warn "The Admin Portal UI will load, but administrative API requests will fail."
            Write-Info "Tip: You can start the backend via 'npm run dev:backend' in another console, or pass '-StartBackend'."
        }
    }

    # --------------------------------------------------------------------------
    # 2. Launch Vite Admin Portal Development Server
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Info "Starting Vite Development Server in $AdminDir..."
    Write-Info "Admin Portal URL: http://localhost:5173"
    Write-Host "========================================================================" -ForegroundColor DarkCyan

    Push-Location $AdminDir
    try {
        & npm.cmd run dev
    } finally {
        Pop-Location
    }

} catch {
    Write-Err "Admin Portal startup failure: $_"
    exit 1
} finally {
    # Clean up backend ONLY if this script started it
    if ($startedBackend -and $backendProcess) {
        Write-Host ""
        Write-Info "Terminating background backend process (PID: $($backendProcess.Id))..."
        Stop-ProcessTree -ProcessId $backendProcess.Id
        Write-Success "Backend stopped cleanly."
    }
}
