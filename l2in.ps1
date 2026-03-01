#Requires -Version 5.1

$ErrorActionPreference = "Stop"

$script:VERSION = "6.2"
$script:HOME_DIR = $env:USERPROFILE
$script:BASE_DIR = Join-Path $HOME_DIR ".local2internet"
$script:CONFIG_DIR = Join-Path $BASE_DIR "config"
$script:LOG_DIR = Join-Path $BASE_DIR "logs"
$script:BIN_DIR = Join-Path $BASE_DIR "bin"
$script:TOOLS_DIR = Join-Path $BASE_DIR "tools"
$script:CONFIG_FILE = Join-Path $CONFIG_DIR "config.json"
$script:RuntimeProcesses = @{}

function Write-Info([string]$msg) { Write-Host "[+] $msg" -ForegroundColor Cyan }
function Write-Ok([string]$msg) { Write-Host "[OK] $msg" -ForegroundColor Green }
function Write-WarnMsg([string]$msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err([string]$msg) { Write-Host "[ERR] $msg" -ForegroundColor Red }

function Ensure-Directories {
    foreach ($dir in @($BASE_DIR, $CONFIG_DIR, $LOG_DIR, $BIN_DIR, $TOOLS_DIR)) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
    }
}

function ConvertTo-Hashtable($obj) {
    if ($null -eq $obj) { return $null }

    if ($obj -is [System.Collections.IDictionary]) {
        $result = @{}
        foreach ($key in $obj.Keys) {
            $result[$key] = ConvertTo-Hashtable $obj[$key]
        }
        return $result
    }

    if ($obj -is [System.Collections.IEnumerable] -and -not ($obj -is [string])) {
        $list = @()
        foreach ($item in $obj) {
            $list += ,(ConvertTo-Hashtable $item)
        }
        return $list
    }

    if ($obj -is [pscustomobject]) {
        $result = @{}
        foreach ($prop in $obj.PSObject.Properties) {
            $result[$prop.Name] = ConvertTo-Hashtable $prop.Value
        }
        return $result
    }

    return $obj
}

function Get-CommandPath([string]$name) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    return $null
}

function Get-AppConfig {
    if (-not (Test-Path $CONFIG_FILE)) { return @{} }
    try {
        $raw = Get-Content $CONFIG_FILE -Raw
        $cfg = ConvertTo-Hashtable (ConvertFrom-Json $raw)
        if ($null -eq $cfg) { return @{} }
        return $cfg
    } catch {
        return @{}
    }
}

function Save-AppConfig([hashtable]$config) {
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $CONFIG_FILE -Encoding UTF8
}

function Get-ToolPath([string]$toolName) {
    $cmdPath = Get-CommandPath $toolName
    if ($cmdPath) { return $cmdPath }

    foreach ($candidate in @(
        (Join-Path $BIN_DIR ("$toolName.exe")),
        (Join-Path $TOOLS_DIR ("$toolName.exe")),
        (Join-Path $BIN_DIR $toolName),
        (Join-Path $TOOLS_DIR $toolName)
    )) {
        if (Test-Path $candidate) { return $candidate }
    }

    return $null
}

function Test-PortAvailable([int]$port) {
    try {
        $listener = New-Object System.Net.Sockets.TcpListener([System.Net.IPAddress]::Loopback, $port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

function Wait-LocalServer([int]$port, [int]$maxAttempts = 20) {
    for ($i = 0; $i -lt $maxAttempts; $i++) {
        try {
            $resp = Invoke-WebRequest -Uri ("http://127.0.0.1:{0}" -f $port) -Method Get -TimeoutSec 2
            if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 500) { return $true }
        } catch {
            $null = $_
        }
        Start-Sleep -Milliseconds 700
    }
    return $false
}

function Start-ManagedProcess([string]$name, [string]$filePath, [string[]]$arguments, [string]$stdoutFile, [string]$workingDirectory) {
    if (Test-Path $stdoutFile) { Remove-Item $stdoutFile -Force -ErrorAction SilentlyContinue }
    $stderrFile = "$stdoutFile.err"
    if (Test-Path $stderrFile) { Remove-Item $stderrFile -Force -ErrorAction SilentlyContinue }

    $proc = Start-Process -FilePath $filePath -ArgumentList $arguments -WorkingDirectory $workingDirectory -RedirectStandardOutput $stdoutFile -RedirectStandardError $stderrFile -WindowStyle Hidden -PassThru
    $script:RuntimeProcesses[$name] = $proc
    return $proc
}

function Stop-AllProcesses {
    foreach ($entry in $script:RuntimeProcesses.GetEnumerator()) {
        try {
            if ($entry.Value -and -not $entry.Value.HasExited) {
                Stop-Process -Id $entry.Value.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {}
    }
    $script:RuntimeProcesses = @{}
}

function Get-FirstRegexMatchFromFile([string]$filePath, [string]$pattern) {
    if (-not (Test-Path $filePath)) { return $null }
    $content = Get-Content $filePath -Raw -ErrorAction SilentlyContinue
    if (-not $content) { return $null }
    $m = [regex]::Match($content, $pattern)
    if ($m.Success) { return $m.Value }
    return $null
}

function Get-FirstRegexMatchFromLogs([string]$baseLogFile, [string]$pattern) {
    $stdoutMatch = Get-FirstRegexMatchFromFile $baseLogFile $pattern
    if ($stdoutMatch) { return $stdoutMatch }

    $stderrMatch = Get-FirstRegexMatchFromFile ("{0}.err" -f $baseLogFile) $pattern
    if ($stderrMatch) { return $stderrMatch }

    return $null
}

function Start-NgrokTunnel([int]$port, [hashtable]$config) {
    $ngrok = Get-ToolPath "ngrok"
    if (-not $ngrok) {
        Write-WarnMsg "Ngrok not found. Install with: choco install ngrok -y"
        return $null
    }

    if ($config.ContainsKey("ngrok_token") -and $config["ngrok_token"]) {
        try {
            & $ngrok "config" "add-authtoken" $config["ngrok_token"] | Out-Null
        } catch {
            Write-WarnMsg "Ngrok token apply failed; tunnel may be limited."
        }
    }

    $logFile = Join-Path $LOG_DIR "ngrok.log"
    Start-ManagedProcess -name "ngrok" -filePath $ngrok -arguments @("http", ("127.0.0.1:{0}" -f $port), "--log=stdout", "--log-level=info") -stdoutFile $logFile -workingDirectory $HOME_DIR | Out-Null
    Start-Sleep -Seconds 3

    for ($i = 0; $i -lt 20; $i++) {
        try {
            $api = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -Method Get -TimeoutSec 2
            if ($api.tunnels) {
                $httpsTunnel = $api.tunnels | Where-Object { $_.public_url -like "https://*" } | Select-Object -First 1
                if ($httpsTunnel -and $httpsTunnel.public_url) { return $httpsTunnel.public_url }
            }
        } catch {}

        $logUrl = Get-FirstRegexMatchFromLogs $logFile "https://[a-zA-Z0-9.-]*ngrok(-free)?\.(app|dev|io)"
        if ($logUrl -and $logUrl -notmatch "dashboard\.ngrok\.com") { return $logUrl }

        Start-Sleep -Seconds 1
    }

    return $null
}

function Start-CloudflareTunnel([int]$port) {
    $cloudflared = Get-ToolPath "cloudflared"
    if (-not $cloudflared) {
        Write-WarnMsg "Cloudflared not found. Install with: winget install Cloudflare.cloudflared or equivalent."
        return $null
    }

    $logFile = Join-Path $LOG_DIR "cloudflared.log"
    Start-ManagedProcess -name "cloudflared" -filePath $cloudflared -arguments @("tunnel", "--url", ("http://127.0.0.1:{0}" -f $port)) -stdoutFile $logFile -workingDirectory $HOME_DIR | Out-Null
    Start-Sleep -Seconds 4

    for ($i = 0; $i -lt 25; $i++) {
        $url = Get-FirstRegexMatchFromLogs $logFile "https://[-a-zA-Z0-9]*\.trycloudflare\.com"
        if ($url) { return $url }
        Start-Sleep -Seconds 1
    }
    return $null
}

function Start-LoclxTunnel([int]$port, [hashtable]$config) {
    $loclx = Get-ToolPath "loclx"
    if (-not $loclx) {
        Write-WarnMsg ("Loclx not found. Re-run installer or put loclx.exe in {0}" -f $TOOLS_DIR)
        return $null
    }

    $args = @("tunnel", "http", "--to", ("127.0.0.1:{0}" -f $port))
    if ($config.ContainsKey("loclx_token") -and $config["loclx_token"]) {
        # Token argument has been deprecated in loclx CLI
        # Users must run 'loclx account login' interactively for token features.
    }

    $logFile = Join-Path $LOG_DIR "loclx.log"
    Start-ManagedProcess -name "loclx" -filePath $loclx -arguments $args -stdoutFile $logFile -workingDirectory $HOME_DIR | Out-Null
    Start-Sleep -Seconds 4

    for ($i = 0; $i -lt 25; $i++) {
        $url = Get-FirstRegexMatchFromLogs $logFile "https://[a-zA-Z0-9.-]*\.loclx\.io"
        if ($url) { return $url }
        Start-Sleep -Seconds 1
    }

    return $null
}

function Start-LocalServer([string]$directory, [string]$mode, [int]$port) {
    $serverCmd = $null
    $serverArgs = @()

    switch ($mode) {
        "python" {
            $serverCmd = Get-CommandPath "python"
            $serverArgs = @("-m", "http.server", ("{0}" -f $port), "--bind", "127.0.0.1")
        }
        "php" {
            $serverCmd = Get-CommandPath "php"
            $serverArgs = @("-S", ("127.0.0.1:{0}" -f $port))
        }
        "node" {
            $serverCmd = Get-CommandPath "http-server"
            $serverArgs = @("-p", ("{0}" -f $port), "-a", "127.0.0.1")
        }
    }

    if (-not $serverCmd) {
        Write-Err ("Selected server runtime is not installed ({0})." -f $mode)
        return $false
    }

    $logFile = Join-Path $LOG_DIR "server.log"
    Start-ManagedProcess -name "server" -filePath $serverCmd -arguments $serverArgs -stdoutFile $logFile -workingDirectory $directory | Out-Null

    if (-not (Wait-LocalServer -port $port)) {
        Write-Err ("Local server failed to start on port {0}" -f $port)
        return $false
    }

    Write-Ok ("Local server ready: http://127.0.0.1:{0}" -f $port)
    return $true
}

function Show-ApiKeyMenu {
    $config = Get-AppConfig

    while ($true) {
        Clear-Host
        Write-Host ("Local2Internet v{0} - API Key Management`n" -f $VERSION) -ForegroundColor Cyan

        $ngrokStatus = if ($config.ContainsKey("ngrok_token") -and $config["ngrok_token"]) { "Configured" } else { "Not Set" }
        $loclxStatus = if ($config.ContainsKey("loclx_token") -and $config["loclx_token"]) { "Configured" } else { "Not Set" }

        Write-Host ("1) Set Ngrok token ({0})" -f $ngrokStatus)
        Write-Host ("2) Set Loclx token ({0})" -f $loclxStatus)
        Write-Host "3) Remove Ngrok token"
        Write-Host "4) Remove Loclx token"
        Write-Host "0) Back"

        $choice = Read-Host "`nChoice"
        switch ($choice) {
            "1" {
                $token = Read-Host "Enter Ngrok authtoken"
                if ($token) {
                    $config["ngrok_token"] = $token.Trim()
                    Save-AppConfig $config
                    Write-Ok "Ngrok token saved"
                }
                Start-Sleep -Seconds 1
            }
            "2" {
                $token = Read-Host "Enter Loclx token"
                if ($token) {
                    $config["loclx_token"] = $token.Trim()
                    Save-AppConfig $config
                    Write-Ok "Loclx token saved"
                }
                Start-Sleep -Seconds 1
            }
            "3" {
                $null = $config.Remove("ngrok_token")
                Save-AppConfig $config
                Write-Ok "Ngrok token removed"
                Start-Sleep -Seconds 1
            }
            "4" {
                $null = $config.Remove("loclx_token")
                Save-AppConfig $config
                Write-Ok "Loclx token removed"
                Start-Sleep -Seconds 1
            }
            "0" { return }
            default {
                Write-WarnMsg "Invalid choice"
                Start-Sleep -Milliseconds 700
            }
        }
    }
}

function Start-HostingFlow {
    $config = Get-AppConfig

    Clear-Host
    Write-Host ("Local2Internet v{0} - Start Server and Tunnels`n" -f $VERSION) -ForegroundColor Cyan

    $directoryInput = Read-Host "Directory to host (default .)"
    if (-not $directoryInput) { $directoryInput = "." }
    $resolved = Resolve-Path -Path $directoryInput -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Err "Directory not found"
        Start-Sleep -Seconds 1
        return
    }
    $directory = $resolved.Path

    Write-Host "`nServer mode: 1) Python  2) PHP  3) Node"
    $modeChoice = Read-Host "Choose mode (default 1)"
    if (-not $modeChoice) { $modeChoice = "1" }
    $mode = switch ($modeChoice) {
        "2" { "php" }
        "3" { "node" }
        default { "python" }
    }

    $defaultPort = if ($config.ContainsKey("last_port")) { [int]$config["last_port"] } else { 8888 }
    $portInput = Read-Host ("Port (default {0})" -f $defaultPort)
    $port = if ($portInput) { [int]$portInput } else { $defaultPort }

    if ($port -le 0 -or $port -gt 65535) {
        Write-Err "Invalid port"
        Start-Sleep -Seconds 1
        return
    }

    if (-not (Test-PortAvailable -port $port)) {
        Write-Err ("Port {0} is already in use" -f $port)
        Start-Sleep -Seconds 1
        return
    }

    $config["last_port"] = $port
    Save-AppConfig $config

    if (-not (Start-LocalServer -directory $directory -mode $mode -port $port)) {
        Stop-AllProcesses
        Start-Sleep -Seconds 2
        return
    }

    Write-Info "Starting Ngrok"
    $ngrokUrl = Start-NgrokTunnel -port $port -config $config
    if ($ngrokUrl) { Write-Ok ("Ngrok URL: {0}" -f $ngrokUrl) } else { Write-WarnMsg ("Ngrok failed. Check {0}\ngrok.log" -f $LOG_DIR) }

    Write-Info "Starting Cloudflare"
    $cloudflareUrl = Start-CloudflareTunnel -port $port
    if ($cloudflareUrl) { Write-Ok ("Cloudflare URL: {0}" -f $cloudflareUrl) } else { Write-WarnMsg ("Cloudflare failed. Check {0}\cloudflared.log" -f $LOG_DIR) }

    Write-Info "Starting Loclx"
    $loclxUrl = Start-LoclxTunnel -port $port -config $config
    if ($loclxUrl) { Write-Ok ("Loclx URL: {0}" -f $loclxUrl) } else { Write-WarnMsg ("Loclx failed. Check {0}\loclx.log" -f $LOG_DIR) }

    Write-Host "`nPress ENTER to stop server and tunnels"
    $null = Read-Host
    Stop-AllProcesses
}

function Show-Status {
    $config = Get-AppConfig

    Clear-Host
    Write-Host ("Local2Internet v{0} - System Status`n" -f $VERSION) -ForegroundColor Cyan

    $ngrok = Get-ToolPath "ngrok"
    $loclx = Get-ToolPath "loclx"

    Write-Host ("Ngrok binary: {0}" -f $(if ($ngrok) { "Found" } else { "Missing" }))
    Write-Host ("Loclx binary: {0}" -f $(if ($loclx) { "Found" } else { "Missing" }))
    Write-Host ("Ngrok token: {0}" -f $(if ($config.ContainsKey("ngrok_token") -and $config["ngrok_token"]) { "Configured" } else { "Not Set" }))
    Write-Host ("Loclx token: {0}" -f $(if ($config.ContainsKey("loclx_token") -and $config["loclx_token"]) { "Configured" } else { "Not Set" }))

    Write-Host ("`nLog directory: {0}" -f $LOG_DIR)
    Write-Host ("Config file: {0}" -f $CONFIG_FILE)

    $null = Read-Host "`nPress ENTER to continue"
}

function Show-MainMenu {
    while ($true) {
        Clear-Host
        Write-Host ("Local2Internet v{0}`n" -f $VERSION) -ForegroundColor Cyan
        Write-Host "1) Start Server and Tunnels"
        Write-Host "2) API Key Management"
        Write-Host "3) System Status"
        Write-Host "0) Exit"

        $choice = Read-Host "`nChoice"
        switch ($choice) {
            "1" { Start-HostingFlow }
            "2" { Show-ApiKeyMenu }
            "3" { Show-Status }
            "0" {
                Stop-AllProcesses
                Write-Ok "Goodbye"
                return
            }
            default {
                Write-WarnMsg "Invalid choice"
                Start-Sleep -Milliseconds 700
            }
        }
    }
}

try {
    Ensure-Directories
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action { Stop-AllProcesses }
    Show-MainMenu
} catch {
    Write-Err $_.Exception.Message
    Stop-AllProcesses
    exit 1
}
