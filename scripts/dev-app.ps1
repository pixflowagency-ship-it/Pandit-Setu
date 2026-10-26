# ==============================================================================
# SARV MANGAL - Unified Flutter + Backend Development Runner
# ==============================================================================
param(
    [ValidateSet("emulator", "lan", "phone", "usb", "web", "windows")]
    [string]$Mode = "emulator",

    [string]$LanIp = "",
    [string]$Device = "",
    [int]$Port = 5000,
    [int]$Timeout = 30
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$FlutterDir = Join-Path $RepoRoot "frontend\pandit_ssetu"

# Load shared automation functions
. (Join-Path $ScriptDir "common.ps1")

Write-Header "SARV MANGAL - Unified App Development Startup"

$backendProcess = $null
$startedBackend = $false

try {
    # --------------------------------------------------------------------------
    # 1. Check or Start Backend
    # --------------------------------------------------------------------------
    if (Test-BackendLive -Port $Port) {
        Write-Success "Backend is already online and healthy at http://localhost:$Port"
    } else {
        Write-Info "Backend not detected on port $Port. Launching server in background..."
        
        $backendProcess = Start-BackendProcess -RepoRoot $RepoRoot -Port $Port
        $startedBackend = $true

        $ready = Wait-BackendReady -Port $Port -TimeoutSeconds $Timeout
        if (-not $ready) {
            Write-Err "Backend failed to report healthy readiness within $Timeout seconds."
            $errLog = Join-Path $RepoRoot "storage\logs\backend-dev.stderr.log"
            if (Test-Path $errLog) {
                Write-Host "`n--- Recent Backend Error Output ---" -ForegroundColor Red
                Get-Content $errLog -Tail 15
                Write-Host "-----------------------------------`n" -ForegroundColor Red
            }
            throw "Aborting startup because backend is offline."
        }
        Write-Success "Backend started successfully (PID: $($backendProcess.Id))."
    }

    # --------------------------------------------------------------------------
    # 2. Determine Flutter API Base URL based on Target Mode
    # --------------------------------------------------------------------------
    $targetApiUrl = ""
    switch ($Mode) {
        "emulator" {
            $targetApiUrl = "http://10.0.2.2:$Port/api/v1"
            Write-Info "Target Mode : Android Studio Emulator"
            Write-Info "API URL     : $targetApiUrl"
        }
        { $_ -in "lan", "phone" } {
            if (-not $LanIp) {
                $LanIp = Get-HostLanIp
            }
            $targetApiUrl = "http://$($LanIp):$Port/api/v1"
            Write-Info "Target Mode : Physical Android Phone over Wi-Fi"
            Write-Info "Host LAN IP : $LanIp"
            Write-Info "API URL     : $targetApiUrl"
            Write-Warn "Note: Ensure your phone is connected to the same Wi-Fi network."
            Write-Warn "Windows Firewall must permit inbound traffic on TCP port $Port."
        }
        "usb" {
            Write-Info "Target Mode : Physical Android Phone via USB (adb reverse)"
            try {
                adb.exe reverse tcp:$Port tcp:$Port 2>$null
                Write-Success "Mapped phone port $Port -> PC port $Port via adb reverse"
            } catch {
                Write-Warn "adb reverse command not found or device not attached; proceeding with localhost."
            }
            $targetApiUrl = "http://localhost:$Port/api/v1"
            Write-Info "API URL     : $targetApiUrl"
        }
        "web" {
            $targetApiUrl = "http://localhost:$Port/api/v1"
            Write-Info "Target Mode : Flutter Web (Chrome)"
            Write-Info "API URL     : $targetApiUrl"
            if (-not $Device) { $Device = "chrome" }
        }
        "windows" {
            $targetApiUrl = "http://localhost:$Port/api/v1"
            Write-Info "Target Mode : Flutter Windows Desktop App"
            Write-Info "API URL     : $targetApiUrl"
            if (-not $Device) { $Device = "windows" }
        }
    }

    # --------------------------------------------------------------------------
    # 3. Launch Flutter Application
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Info "Launching Flutter Application from $FlutterDir..."
    Write-Host "========================================================================" -ForegroundColor DarkCyan
    
    Push-Location $FlutterDir
    try {
        $flutterArgs = @("run", "--dart-define=API_BASE_URL=$targetApiUrl")
        if ($Device) {
            $flutterArgs += @("-d", $Device)
        }

        # Run Flutter in foreground so hot reload (r/R) and debugger input work interactively
        & flutter.bat @flutterArgs
    } finally {
        Pop-Location
    }

} catch {
    Write-Err "Startup failure: $_"
    exit 1
} finally {
    # --------------------------------------------------------------------------
    # 4. Clean Process Termination (Only what this script started)
    # --------------------------------------------------------------------------
    if ($startedBackend -and $backendProcess) {
        Write-Host ""
        Write-Info "Terminating background backend process (PID: $($backendProcess.Id))..."
        Stop-ProcessTree -ProcessId $backendProcess.Id
        Write-Success "Backend stopped cleanly."
    } elseif (-not $startedBackend) {
        Write-Host ""
        Write-Info "Leaving pre-existing backend process running as requested."
    }
}
