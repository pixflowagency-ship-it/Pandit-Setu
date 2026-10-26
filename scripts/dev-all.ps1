# ==============================================================================
# SARV MANGAL - Full Stack Development Runner (Backend + Admin + App)
# ==============================================================================
param(
    [ValidateSet("emulator", "lan", "phone", "usb", "web", "windows")]
    [string]$Mode = "emulator",

    [string]$LanIp = "",
    [string]$Device = "",
    [int]$Port = 5000,
    [int]$AdminPort = 5173,
    [int]$Timeout = 30
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$FlutterDir = Join-Path $RepoRoot "frontend\pandit_ssetu"
$AdminDir = Join-Path $RepoRoot "admin-portal"

# Load shared automation functions
. (Join-Path $ScriptDir "common.ps1")

Write-Header "SARV MANGAL - Full Stack Development Environment"

$backendProcess = $null
$adminProcess = $null
$startedBackend = $false

try {
    # --------------------------------------------------------------------------
    # 1. Start Backend if not already running
    # --------------------------------------------------------------------------
    if (Test-BackendLive -Port $Port) {
        Write-Success "Backend is already online and healthy at http://localhost:$Port"
    } else {
        Write-Info "Backend not detected on port $Port. Launching server in background..."
        $backendProcess = Start-BackendProcess -RepoRoot $RepoRoot -Port $Port
        $startedBackend = $true

        $ready = Wait-BackendReady -Port $Port -TimeoutSeconds $Timeout
        if (-not $ready) {
            Write-Err "Backend failed to report healthy readiness."
            throw "Aborting full-stack startup because backend is offline."
        }
        Write-Success "Backend started successfully (PID: $($backendProcess.Id))."
    }

    # --------------------------------------------------------------------------
    # 2. Start Admin Portal in background
    # --------------------------------------------------------------------------
    Write-Info "Launching Admin Portal Vite Server in background..."
    $psiAdmin = New-Object System.Diagnostics.ProcessStartInfo
    $psiAdmin.FileName = "cmd.exe"
    $psiAdmin.Arguments = "/c npm run dev"
    $psiAdmin.WorkingDirectory = $AdminDir
    $psiAdmin.UseShellExecute = $false
    $psiAdmin.CreateNoWindow = $true

    $adminProcess = New-Object System.Diagnostics.Process
    $adminProcess.StartInfo = $psiAdmin
    $adminProcess.Start() | Out-Null
    Write-Success "Admin Portal online at http://localhost:$AdminPort (PID: $($adminProcess.Id))."

    # --------------------------------------------------------------------------
    # 3. Determine API URL for Flutter
    # --------------------------------------------------------------------------
    if (-not $Device -and $Mode -eq "emulator") {
        $hasAndroid = $false
        try {
            $adbDevices = (adb.exe devices 2>$null) | Where-Object { $_ -match "\bdevice\b" -and $_ -notmatch "List of devices" }
            if ($adbDevices) {
                $hasAndroid = $true
            }
        } catch {}

        if (-not $hasAndroid) {
            Write-Info "No running Android emulator detected. Auto-selecting Chrome Web browser..."
            $Mode = "web"
            $Device = "chrome"
        }
    }

    $targetApiUrl = ""
    switch ($Mode) {
        "emulator" {
            $targetApiUrl = "http://10.0.2.2:$Port/api/v1"
            Write-Info "Target Mode : Android Studio Emulator (API: $targetApiUrl)"
        }
        { $_ -in "lan", "phone" } {
            if (-not $LanIp) {
                $LanIp = Get-HostLanIp
            }
            $targetApiUrl = "http://$($LanIp):$Port/api/v1"
            Write-Info "Target Mode : Physical Phone via Wi-Fi LAN (API: $targetApiUrl)"
        }
        "usb" {
            try {
                adb.exe reverse tcp:$Port tcp:$Port 2>$null
            } catch {}
            $targetApiUrl = "http://localhost:$Port/api/v1"
            Write-Info "Target Mode : Physical Phone via USB adb reverse (API: $targetApiUrl)"
        }
        "web" {
            $targetApiUrl = "http://localhost:$Port/api/v1"
            Write-Info "Target Mode : Flutter Web (Chrome)"
            if (-not $Device) { $Device = "chrome" }
        }
        "windows" {
            $targetApiUrl = "http://localhost:$Port/api/v1"
            Write-Info "Target Mode : Flutter Windows Desktop App"
            if (-not $Device) { $Device = "windows" }
        }
    }

    # --------------------------------------------------------------------------
    # 4. Launch Flutter in foreground
    # --------------------------------------------------------------------------
    Write-Host ""
    Write-Info "Launching Flutter Application in foreground..."
    Write-Host "========================================================================" -ForegroundColor DarkCyan

    Push-Location $FlutterDir
    try {
        $flutterArgs = @("run", "--dart-define=API_BASE_URL=$targetApiUrl")
        if ($Device) {
            $flutterArgs += @("-d", $Device)
        }
        & flutter.bat @flutterArgs
    } finally {
        Pop-Location
    }

} catch {
    Write-Err "Full-stack startup failure: $_"
    exit 1
} finally {
    Write-Host ""
    # Clean up Admin Portal
    if ($adminProcess) {
        Write-Info "Terminating background Admin Portal process (PID: $($adminProcess.Id))..."
        Stop-ProcessTree -ProcessId $adminProcess.Id
        Write-Success "Admin Portal stopped."
    }

    # Clean up Backend ONLY if started by this script
    if ($startedBackend -and $backendProcess) {
        Write-Info "Terminating background Backend process (PID: $($backendProcess.Id))..."
        Stop-ProcessTree -ProcessId $backendProcess.Id
        Write-Success "Backend stopped."
    }
}
