# ==============================================================================
# SARV MANGAL - Shared PowerShell Development Automation Helpers
# ==============================================================================

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host "========================================================================" -ForegroundColor DarkYellow
    Write-Host "  $Title" -ForegroundColor Yellow
    Write-Host "========================================================================" -ForegroundColor DarkYellow
    Write-Host ""
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK]   " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-Err {
    param([string]$Message)
    Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Test-BackendLive {
    param([int]$Port = 5000)
    
    # Try 127.0.0.1 first to avoid Windows IPv6 (::1) localhost resolution delay
    $endpoints = @(
        "http://127.0.0.1:$Port/health/live",
        "http://localhost:$Port/health/live"
    )

    foreach ($url in $endpoints) {
        try {
            $res = Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 1 -ErrorAction Stop
            if ($res -and $res.status -eq "ok") {
                return $true
            }
        } catch {}
    }

    return $false
}

function Wait-BackendReady {
    param(
        [int]$Port = 5000,
        [int]$TimeoutSeconds = 30
    )

    $elapsed = 0
    Write-Host "Waiting for backend health readiness at http://127.0.0.1:$Port/health/live..." -NoNewline
    while ($elapsed -lt $TimeoutSeconds) {
        if (Test-BackendLive -Port $Port) {
            Write-Host " [READY] ($($elapsed)s)" -ForegroundColor Green
            return $true
        }
        Start-Sleep -Seconds 1
        $elapsed++
        Write-Host "." -NoNewline
    }
    Write-Host " [TIMED OUT]" -ForegroundColor Red
    return $false
}

function Get-HostLanIp {
    try {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
            Where-Object { 
                $_.IPAddress -notlike "127.*" -and 
                $_.IPAddress -notlike "169.254.*" -and 
                $_.InterfaceAlias -notmatch "vEthernet|WSL|Loopback|Default Switch|Host-Only" -and
                ($_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*" -or $_.IPAddress -like "172.1[6-9].*" -or $_.IPAddress -like "172.2[0-9].*" -or $_.IPAddress -like "172.3[0-1].*")
            } | Select-Object -First 1).IPAddress
        
        if ($ip) {
            return $ip
        }
    } catch {}

    return "127.0.0.1"
}

function Stop-ProcessTree {
    param([int]$ProcessId)
    if ($ProcessId -gt 0) {
        try {
            taskkill.exe /PID $ProcessId /T /F 2>$null | Out-Null
        } catch {}
    }
}

function Start-BackendProcess {
    param(
        [string]$RepoRoot,
        [int]$Port = 5000
    )

    $logDir = Join-Path $RepoRoot "storage\logs"
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $outLog = Join-Path $logDir "backend-dev.stdout.log"
    $errLog = Join-Path $logDir "backend-dev.stderr.log"

    if (Test-Path $outLog) { Remove-Item $outLog -Force -ErrorAction SilentlyContinue }
    if (Test-Path $errLog) { Remove-Item $errLog -Force -ErrorAction SilentlyContinue }

    $process = Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c npm run dev:backend" `
        -WorkingDirectory $RepoRoot `
        -RedirectStandardOutput $outLog `
        -RedirectStandardError $errLog `
        -NoNewWindow `
        -PassThru

    return $process
}
