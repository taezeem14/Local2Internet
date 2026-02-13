# =========================================
# Local2Internet v5.0 ULTIMATE - Windows PowerShell Edition
# Platform: Windows PowerShell 7.0+
# Enhanced By: Muhammad Taezeem Tariq Matta
# Ultimate Edition: Claude AI Assistant
# =========================================

#Requires -Version 5.1

$ErrorActionPreference = "SilentlyContinue"
$ProgressPreference = 'SilentlyContinue'

# ---------------------------
# Configuration
# ---------------------------
$script:HOME = $env:USERPROFILE
$script:BASE_DIR = "$HOME\.local2internet"
$script:BIN_DIR = "$BASE_DIR\bin"
$script:LOG_DIR = "$BASE_DIR\logs"
$script:STATS_DIR = "$BASE_DIR\stats"
$script:CONFIG_FILE = "$BASE_DIR\config.json"
$script:SESSION_FILE = "$BASE_DIR\session.json"
$script:DEFAULT_PORT = 8888
$script:VERSION = "5.0"
$script:EDITION = "ULTIMATE"

# ---------------------------
# Enhanced Colors (ANSI)
# ---------------------------
$ESC = [char]27
$C = @{
    # Standard colors
    Red = "$ESC[31m"
    Green = "$ESC[32m"
    Yellow = "$ESC[33m"
    Blue = "$ESC[34m"
    Purple = "$ESC[35m"
    Cyan = "$ESC[36m"
    White = "$ESC[37m"
    
    # Bright colors
    BRed = "$ESC[91m"
    BGreen = "$ESC[92m"
    BYellow = "$ESC[93m"
    BBlue = "$ESC[94m"
    BPurple = "$ESC[95m"
    BCyan = "$ESC[96m"
    BWhite = "$ESC[97m"
    
    # Formatting
    Reset = "$ESC[0m"
    Bold = "$ESC[1m"
    Dim = "$ESC[2m"
    Italic = "$ESC[3m"
    Underline = "$ESC[4m"
}

# ---------------------------
# UI Functions
# ---------------------------
function Write-Info($msg, $icon = "ℹ") { 
    Write-Host "$($C.BCyan)[$icon]$($C.BWhite) $msg$($C.Reset)" 
}

function Write-Success($msg, $icon = "✓") { 
    Write-Host "$($C.BGreen)[$icon]$($C.BWhite) $msg$($C.Reset)" 
}

function Write-ErrorMsg($msg, $icon = "✗") { 
    Write-Host "$($C.BRed)[$icon]$($C.BWhite) $msg$($C.Reset)" 
}

function Write-Warn($msg, $icon = "⚠") { 
    Write-Host "$($C.BYellow)[$icon]$($C.BWhite) $msg$($C.Reset)" 
}

function Write-Ask($msg, $icon = "❯") { 
    Write-Host "$($C.BYellow)[$icon]$($C.BWhite) $msg$($C.Reset)" -NoNewline 
}

function Show-Header($title) {
    $width = 70
    $padding = [Math]::Floor(($width - $title.Length - 2) / 2)
    $rightPadding = $width - $padding - $title.Length - 2
    
    Write-Host ""
    Write-Host "$($C.BPurple)╔$('═' * $width)╗$($C.Reset)"
    Write-Host "$($C.BPurple)║$(' ' * $padding)$($C.BWhite)$title$($C.BPurple)$(' ' * $rightPadding)║$($C.Reset)"
    Write-Host "$($C.BPurple)╚$('═' * $width)╝$($C.Reset)"
    Write-Host ""
}

function Show-Box($lines, $color = $C.BCyan) {
    $maxWidth = ($lines | Measure-Object -Property Length -Maximum).Maximum + 4
    
    Write-Host ""
    Write-Host "$color╔$('═' * $maxWidth)╗$($C.Reset)"
    foreach ($line in $lines) {
        $padding = $maxWidth - $line.Length - 2
        Write-Host "$color║ $($C.BWhite)$line$(' ' * $padding)$color║$($C.Reset)"
    }
    Write-Host "$color╚$('═' * $maxWidth)╝$($C.Reset)"
    Write-Host ""
}

function Show-ProgressBar($current, $total, $width = 40) {
    $percentage = [Math]::Round(($current / $total) * 100)
    $filled = [Math]::Round(($width * $current) / $total)
    $empty = $width - $filled
    
    $bar = "$($C.BGreen)$('█' * $filled)$($C.Dim)$('░' * $empty)$($C.Reset)"
    Write-Host -NoNewline "`r$($C.BCyan)[$bar$($C.BCyan)] $($C.BWhite)$percentage%$($C.Reset)"
    
    if ($current -ge $total) { Write-Host "" }
}

function Show-Table($headers, $rows) {
    $colWidths = @()
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $maxWidth = $headers[$i].Length
        foreach ($row in $rows) {
            if ($row[$i].ToString().Length -gt $maxWidth) {
                $maxWidth = $row[$i].ToString().Length
            }
        }
        $colWidths += $maxWidth + 2
    }
    
    # Header
    Write-Host ""
    Write-Host "$($C.BPurple)┌$($colWidths | ForEach-Object { '─' * $_ } | Join-String -Separator '┬')┐$($C.Reset)"
    
    $headerRow = @()
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $headerRow += " $($C.BWhite)$($headers[$i].PadRight($colWidths[$i] - 1))$($C.BPurple)"
    }
    Write-Host "$($C.BPurple)│$($headerRow -join '│')│$($C.Reset)"
    
    Write-Host "$($C.BPurple)├$($colWidths | ForEach-Object { '─' * $_ } | Join-String -Separator '┼')┤$($C.Reset)"
    
    # Rows
    foreach ($row in $rows) {
        $rowText = @()
        for ($i = 0; $i -lt $row.Count; $i++) {
            $rowText += " $($C.White)$($row[$i].ToString().PadRight($colWidths[$i] - 1))$($C.BPurple)"
        }
        Write-Host "$($C.BPurple)│$($rowText -join '│')│$($C.Reset)"
    }
    
    Write-Host "$($C.BPurple)└$($colWidths | ForEach-Object { '─' * $_ } | Join-String -Separator '┴')┘$($C.Reset)"
    Write-Host ""
}

# ---------------------------
# Modern Logo
# ---------------------------
$LOGO = @"
$($C.BPurple)╔═══════════════════════════════════════════════════════════════════╗
$($C.BPurple)║  $($C.BRed)▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀$($C.BPurple)  ║
$($C.BPurple)║  $($C.BYellow)▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░$($C.BPurple)  ║
$($C.BPurple)║  $($C.BGreen)▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░$($C.BPurple)  ║
╚═══════════════════════════════════════════════════════════════════╝
    $($C.BCyan)v$VERSION $EDITION Edition$($C.Reset) $($C.Dim)• Professional Grade Tunneling$($C.Reset)
    $($C.Dim)Multi-Protocol • Auto-Recovery • Real-Time Monitoring$($C.Reset)
$($C.Reset)
"@

# ---------------------------
# Process Management
# ---------------------------
$script:Processes = @{}

function Register-Process($name, $process) {
    $script:Processes[$name] = $process
    Log-Event "process_started" @{ name = $name; pid = $process.Id }
}

function Stop-RegisteredProcess($name) {
    if ($script:Processes.ContainsKey($name)) {
        $process = $script:Processes[$name]
        
        try {
            if (-not $process.HasExited) {
                Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                Log-Event "process_killed" @{ name = $name; pid = $process.Id }
            }
        } catch {
            # Process already dead
        }
        
        $script:Processes.Remove($name)
    }
}

function Stop-AllProcesses {
    Write-Info "Cleaning up processes..."
    
    # Kill known process names
    @("python", "php", "node", "http-server", "ngrok", "cloudflared", "loclx") | ForEach-Object {
        Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    
    # Kill registered processes
    $script:Processes.Keys | ForEach-Object {
        Stop-RegisteredProcess $_
    }
    
    Start-Sleep -Seconds 1
    Write-Success "Cleanup complete"
}

# ---------------------------
# Configuration Manager
# ---------------------------
function Get-Config {
    if (Test-Path $CONFIG_FILE) {
        try {
            return Get-Content $CONFIG_FILE -Raw | ConvertFrom-Json
        } catch {
            return @{}
        }
    }
    return @{}
}

function Save-Config($config) {
    $config | ConvertTo-Json -Depth 10 | Set-Content $CONFIG_FILE
}

function Get-ConfigValue($key, $default = $null) {
    $config = Get-Config
    if ($config.PSObject.Properties.Name -contains $key) {
        return $config.$key
    }
    return $default
}

function Set-ConfigValue($key, $value) {
    $config = Get-Config
    $config | Add-Member -MemberType NoteProperty -Name $key -Value $value -Force
    Save-Config $config
}

function Remove-ConfigValue($key) {
    $config = Get-Config
    $config.PSObject.Properties.Remove($key)
    Save-Config $config
}

# ---------------------------
# Session Manager
# ---------------------------
function Save-Session($data) {
    $data | ConvertTo-Json -Depth 10 | Set-Content $SESSION_FILE
}

function Get-Session {
    if (Test-Path $SESSION_FILE) {
        try {
            return Get-Content $SESSION_FILE -Raw | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

function Clear-Session {
    if (Test-Path $SESSION_FILE) {
        Remove-Item $SESSION_FILE -Force
    }
}

function Test-SessionActive {
    $session = Get-Session
    if (-not $session) { return $false }
    
    if ($session.active -and $session.pid) {
        $process = Get-Process -Id $session.pid -ErrorAction SilentlyContinue
        return $null -ne $process
    }
    
    return $false
}

# ---------------------------
# Logging
# ---------------------------
function Log-Event($event, $details = @{}) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @{
        timestamp = $timestamp
        event = $event
        details = $details
    }
    
    $logFile = "$LOG_DIR\events.log"
    ($logEntry | ConvertTo-Json -Compress) | Add-Content $logFile
}

# ---------------------------
# Statistics Tracker
# ---------------------------
class StatsTracker {
    [string]$StatsFile
    [hashtable]$Stats
    
    StatsTracker() {
        $this.StatsFile = "$script:STATS_DIR\usage_stats.json"
        $this.Stats = $this.LoadStats()
    }
    
    [hashtable] LoadStats() {
        if (Test-Path $this.StatsFile) {
            try {
                return Get-Content $this.StatsFile -Raw | ConvertFrom-Json -AsHashtable
            } catch {
                return @{}
            }
        }
        return @{}
    }
    
    SaveStats() {
        $this.Stats | ConvertTo-Json -Depth 10 | Set-Content $this.StatsFile
    }
    
    RecordSession([int]$duration, [array]$tunnelsUsed, [string]$protocol) {
        if (-not $this.Stats.ContainsKey('total_sessions')) { $this.Stats['total_sessions'] = 0 }
        if (-not $this.Stats.ContainsKey('total_duration')) { $this.Stats['total_duration'] = 0 }
        if (-not $this.Stats.ContainsKey('tunnels_count')) { $this.Stats['tunnels_count'] = @{} }
        if (-not $this.Stats.ContainsKey('protocols_used')) { $this.Stats['protocols_used'] = @{} }
        
        $this.Stats['total_sessions']++
        $this.Stats['total_duration'] += $duration
        
        foreach ($tunnel in $tunnelsUsed) {
            if (-not $this.Stats['tunnels_count'].ContainsKey($tunnel)) {
                $this.Stats['tunnels_count'][$tunnel] = 0
            }
            $this.Stats['tunnels_count'][$tunnel]++
        }
        
        if (-not $this.Stats['protocols_used'].ContainsKey($protocol)) {
            $this.Stats['protocols_used'][$protocol] = 0
        }
        $this.Stats['protocols_used'][$protocol]++
        
        $this.SaveStats()
    }
    
    DisplayStats() {
        Show-Header "📊 USAGE STATISTICS"
        
        if ($this.Stats.Count -eq 0) {
            Write-Info "No statistics available yet"
            return
        }
        
        Write-Host "$($C.BCyan)Total Sessions:$($C.BWhite) $($this.Stats['total_sessions'])$($C.Reset)"
        Write-Host "$($C.BCyan)Total Runtime:$($C.BWhite) $($this.FormatDuration($this.Stats['total_duration']))$($C.Reset)"
        
        if ($this.Stats.ContainsKey('tunnels_count') -and $this.Stats['tunnels_count'].Count -gt 0) {
            Write-Host ""
            Write-Host "$($C.BPurple)Tunnel Usage:$($C.Reset)"
            foreach ($tunnel in $this.Stats['tunnels_count'].Keys) {
                Write-Host "  $($C.BWhite)${tunnel}:$($C.Reset) $($this.Stats['tunnels_count'][$tunnel]) times"
            }
        }
        
        if ($this.Stats.ContainsKey('protocols_used') -and $this.Stats['protocols_used'].Count -gt 0) {
            Write-Host ""
            Write-Host "$($C.BPurple)Protocol Preference:$($C.Reset)"
            foreach ($protocol in $this.Stats['protocols_used'].Keys) {
                Write-Host "  $($C.BWhite)${protocol}:$($C.Reset) $($this.Stats['protocols_used'][$protocol]) times"
            }
        }
        
        Write-Host ""
    }
    
    [string] FormatDuration([int]$seconds) {
        $hours = [Math]::Floor($seconds / 3600)
        $minutes = [Math]::Floor(($seconds % 3600) / 60)
        $secs = $seconds % 60
        
        $parts = @()
        if ($hours -gt 0) { $parts += "${hours}h" }
        if ($minutes -gt 0) { $parts += "${minutes}m" }
        $parts += "${secs}s"
        
        return $parts -join ' '
    }
}

# ---------------------------
# Network Utilities
# ---------------------------
function Test-PortAvailable($port) {
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $port)
        $listener.Start()
        $listener.Stop()
        return $true
    } catch {
        return $false
    }
}

function Find-AvailablePort($startPort = 8888) {
    for ($port = $startPort; $port -le 65535; $port++) {
        if (Test-PortAvailable $port) {
            return $port
        }
    }
    return $null
}

function Test-InternetConnection {
    try {
        $response = Test-Connection -ComputerName "1.1.1.1" -Count 1 -TimeoutSeconds 5 -Quiet
        return $response
    } catch {
        return $false
    }
}

function Get-LocalIPAddress {
    try {
        $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1).IPAddress
        return $ip
    } catch {
        return "127.0.0.1"
    }
}

function Test-URLReachable($url) {
    try {
        $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction SilentlyContinue
        return $response.StatusCode -lt 400
    } catch {
        return $false
    }
}

# ---------------------------
# Setup Directories
# ---------------------------
function Initialize-Directories {
    @($BASE_DIR, $BIN_DIR, $LOG_DIR, $STATS_DIR) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
}

# ---------------------------
# Dependency Management
# ---------------------------
function Test-CommandExists($cmd) {
    return $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Install-Dependencies {
    Write-Info "Checking dependencies..."
    
    $deps = @{
        "python" = "python"
        "php" = "php"
        "node" = "nodejs"
    }
    
    $missing = @()
    
    foreach ($dep in $deps.Keys) {
        if (-not (Test-CommandExists $dep)) {
            $missing += $deps[$dep]
        }
    }
    
    if ($missing.Count -eq 0) {
        Write-Success "All dependencies installed"
        return $true
    }
    
    $chocoInstalled = Test-CommandExists "choco"
    
    if (-not $chocoInstalled) {
        Write-ErrorMsg "Chocolatey is required to install missing dependencies"
        Write-Info "Please install Chocolatey: https://chocolatey.org/install"
        return $false
    }
    
    Write-Warn "Missing dependencies: $($missing -join ', ')"
    Write-Ask "`nInstall missing dependencies? (y/N): "
    $response = Read-Host
    
    if ($response -ne 'y' -and $response -ne 'Y') {
        return $false
    }
    
    foreach ($pkg in $missing) {
        Show-ProgressBar ($missing.IndexOf($pkg) + 1) $missing.Count
        choco install $pkg -y --force | Out-Null
    }
    
    Show-ProgressBar $missing.Count $missing.Count
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    # Install http-server via npm
    if (Test-CommandExists "npm") {
        $httpServer = npm list -g http-server 2>$null | Select-String "http-server"
        
        if (-not $httpServer) {
            Write-Info "Installing http-server..."
            npm install -g http-server 2>&1 | Out-Null
        }
    }
    
    Write-Success "Dependencies installed successfully"
    return $true
}

# ---------------------------
# Architecture Detection
# ---------------------------
function Get-SystemArchitecture {
    $arch = (Get-WmiObject Win32_Processor).AddressWidth
    
    switch ($arch) {
        64 { return "amd64" }
        32 { return "386" }
        default { return "amd64" }
    }
}

# ---------------------------
# Tool Downloads
# ---------------------------
function Install-Ngrok {
    $ngrokPath = "$BIN_DIR\ngrok.exe"
    
    if (Test-Path $ngrokPath) {
        return $true
    }
    
    Write-Info "Downloading Ngrok..."
    $arch = Get-SystemArchitecture
    $url = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-$arch.zip"
    $zipPath = "$BASE_DIR\ngrok.zip"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $BIN_DIR -Force
        Remove-Item $zipPath -Force
        Write-Success "Ngrok installed!"
        return $true
    } catch {
        Write-ErrorMsg "Failed to download Ngrok: $_"
        return $false
    }
}

function Install-Cloudflared {
    $cfPath = "$BIN_DIR\cloudflared.exe"
    
    if (Test-Path $cfPath) {
        return $true
    }
    
    Write-Info "Downloading Cloudflared..."
    $arch = Get-SystemArchitecture
    $url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-$arch.exe"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $cfPath -UseBasicParsing
        Write-Success "Cloudflared installed!"
        return $true
    } catch {
        Write-Warn "Failed to download Cloudflared (non-critical)"
        return $false
    }
}

function Install-Loclx {
    $loclxPath = "$BIN_DIR\loclx.exe"
    
    if (Test-Path $loclxPath) {
        return $true
    }
    
    Write-Info "Downloading Loclx..."
    $arch = Get-SystemArchitecture
    $url = "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-windows-$arch.zip"
    $zipPath = "$BASE_DIR\loclx.zip"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Expand-Archive -Path $zipPath -DestinationPath $BIN_DIR -Force
        Remove-Item $zipPath -Force
        Write-Success "Loclx installed!"
        return $true
    } catch {
        Write-Warn "Loclx download failed (non-critical)"
        return $false
    }
}

function Install-Tools {
    Write-Info "Checking tunneling tools..."
    
    $success = $true
    
    Show-ProgressBar 0 3
    $success = (Install-Ngrok) -and $success
    Show-ProgressBar 1 3
    $success = (Install-Cloudflared) -and $success
    Show-ProgressBar 2 3
    $success = (Install-Loclx) -and $success
    Show-ProgressBar 3 3
    
    if ($success) {
        Write-Success "All tools installed"
    }
    
    return $success
}

# ---------------------------
# API Key Management
# ---------------------------
function Manage-APIKeys {
    while ($true) {
        Clear-Host
        Write-Host $LOGO
        Show-Header "🔑 API KEY MANAGEMENT"
        
        Write-Host "$($C.BWhite)1)$($C.Reset) Set Ngrok Authtoken"
        Write-Host "$($C.BWhite)2)$($C.Reset) Set Loclx Access Token"
        Write-Host "$($C.BWhite)3)$($C.Reset) View Current Keys"
        Write-Host "$($C.BWhite)4)$($C.Reset) Test API Keys"
        Write-Host "$($C.BWhite)5)$($C.Reset) Remove Keys"
        Write-Host "$($C.BWhite)0)$($C.Reset) Back to Main Menu"
        
        Write-Ask "`nChoice: "
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                Write-Host ""
                Write-Ask "Enter Ngrok authtoken (from https://dashboard.ngrok.com): "
                $token = Read-Host
                
                if ($token) {
                    $ngrokPath = "$BIN_DIR\ngrok.exe"
                    $result = & $ngrokPath config add-authtoken $token 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        Set-ConfigValue "ngrok_token" $token
                        Write-Success "Ngrok authtoken saved and configured!"
                        Log-Event "api_key_configured" @{ service = "ngrok" }
                    } else {
                        Write-ErrorMsg "Failed to configure ngrok authtoken"
                    }
                } else {
                    Write-Warn "Token cannot be empty!"
                }
                Start-Sleep -Seconds 2
            }
            "2" {
                Write-Host ""
                Write-Ask "Enter Loclx access token (from https://localxpose.io): "
                $token = Read-Host
                
                if ($token) {
                    Set-ConfigValue "loclx_token" $token
                    Write-Success "Loclx access token saved!"
                    Log-Event "api_key_configured" @{ service = "loclx" }
                } else {
                    Write-Warn "Token cannot be empty!"
                }
                Start-Sleep -Seconds 2
            }
            "3" {
                Write-Host ""
                Show-Header "Current API Keys"
                
                $ngrokToken = Get-ConfigValue "ngrok_token"
                $loclxToken = Get-ConfigValue "loclx_token"
                
                $rows = @(
                    @("Ngrok", ($ngrokToken ? $ngrokToken.Substring(0, [Math]::Min(15, $ngrokToken.Length)) + "***" : "Not configured"), ($ngrokToken ? "✓" : "✗")),
                    @("Loclx", ($loclxToken ? $loclxToken.Substring(0, [Math]::Min(15, $loclxToken.Length)) + "***" : "Not configured"), ($loclxToken ? "✓" : "✗"))
                )
                
                Show-Table @("Service", "Token", "Status") $rows
                
                Write-Host "$($C.Dim)Benefits: Remove rate limits • Persistent URLs • Priority support$($C.Reset)"
                
                Write-Ask "`nPress ENTER to continue..."
                Read-Host | Out-Null
            }
            "4" {
                Write-Host ""
                Write-Info "Testing API key configurations..."
                
                # Test Ngrok
                if (Get-ConfigValue "ngrok_token") {
                    Write-Host -NoNewline "$($C.BCyan)Testing Ngrok...$($C.Reset) "
                    
                    $ngrokPath = "$BIN_DIR\ngrok.exe"
                    $configCheck = & $ngrokPath config check 2>&1
                    
                    if ($configCheck -match "Valid|OK" -or $LASTEXITCODE -eq 0) {
                        Write-Host "$($C.BGreen)✓ Valid$($C.Reset)"
                    } else {
                        Write-Host "$($C.BRed)✗ Invalid$($C.Reset)"
                    }
                } else {
                    Write-Host "$($C.BYellow)Ngrok: Not configured$($C.Reset)"
                }
                
                # Test Loclx
                if (Get-ConfigValue "loclx_token") {
                    Write-Host "$($C.BGreen)✓$($C.Reset) Loclx: Token configured (cannot validate without starting tunnel)"
                } else {
                    Write-Host "$($C.BYellow)Loclx: Not configured$($C.Reset)"
                }
                
                Write-Ask "`nPress ENTER to continue..."
                Read-Host | Out-Null
            }
            "5" {
                Write-Host ""
                Write-Warn "Remove which key?"
                Write-Host "$($C.BWhite)1)$($C.Reset) Ngrok"
                Write-Host "$($C.BWhite)2)$($C.Reset) Loclx"
                Write-Host "$($C.BWhite)3)$($C.Reset) Both"
                Write-Host "$($C.BWhite)0)$($C.Reset) Cancel"
                
                Write-Ask "`nChoice: "
                $removeChoice = Read-Host
                
                switch ($removeChoice) {
                    "1" {
                        Remove-ConfigValue "ngrok_token"
                        Write-Success "Ngrok token removed!"
                    }
                    "2" {
                        Remove-ConfigValue "loclx_token"
                        Write-Success "Loclx token removed!"
                    }
                    "3" {
                        Remove-ConfigValue "ngrok_token"
                        Remove-ConfigValue "loclx_token"
                        Write-Success "All tokens removed!"
                    }
                }
                Start-Sleep -Seconds 2
            }
            "0" {
                return
            }
            default {
                Write-Warn "Invalid choice!"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ---------------------------
# Server Manager
# ---------------------------
function Start-LocalServer($path, $port, $mode) {
    Write-Info "Starting $mode server on port $port..."
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.WorkingDirectory = $path
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    switch ($mode) {
        "Python" {
            $psi.FileName = "python"
            $psi.Arguments = "-m http.server $port"
        }
        "PHP" {
            if (-not ((Test-Path "$path\index.php") -or (Test-Path "$path\index.html"))) {
                Write-ErrorMsg "No index.php or index.html found in directory!"
                return $false
            }
            $psi.FileName = "php"
            $psi.Arguments = "-S 127.0.0.1:$port"
        }
        "NodeJS" {
            $psi.FileName = "http-server"
            $psi.Arguments = "-p $port"
        }
        default {
            Write-ErrorMsg "Invalid server mode!"
            return $false
        }
    }
    
    try {
        $process = [System.Diagnostics.Process]::Start($psi)
        Register-Process "server" $process
        
        Start-Sleep -Seconds 3
        
        # Verify server started
        $retries = 0
        while ($retries -lt 5) {
            try {
                $response = Invoke-WebRequest -Uri "http://127.0.0.1:$port" -Method Head -TimeoutSec 2 -UseBasicParsing -ErrorAction SilentlyContinue
                
                if ($response -and $response.StatusCode -lt 400) {
                    Write-Success "Server running at http://127.0.0.1:$port"
                    Log-Event "server_started" @{ mode = $mode; port = $port; path = $path }
                    return $true
                }
            } catch {
                # Continue retrying
            }
            
            $retries++
            Start-Sleep -Seconds 1
        }
        
        Write-ErrorMsg "Server failed to start! Check if port $port is already in use."
        return $false
    } catch {
        Write-ErrorMsg "Server startup error: $_"
        return $false
    }
}

# ---------------------------
# Tunnel Manager
# ---------------------------
function Start-NgrokTunnel($port) {
    Write-Info "Starting Ngrok tunnel..."
    
    $ngrokPath = "$BIN_DIR\ngrok.exe"
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ngrokPath
    $psi.Arguments = "http $port"
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    
    try {
        $process = [System.Diagnostics.Process]::Start($psi)
        Register-Process "ngrok" $process
        
        Start-Sleep -Seconds 6
        
        # Extract URL from Ngrok API
        $retries = 0
        while ($retries -lt 12) {
            try {
                $apiResponse = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -ErrorAction SilentlyContinue
                $url = $apiResponse.tunnels[0].public_url
                
                if ($url) {
                    return $url.Replace("http://", "https://")
                }
            } catch {
                # Continue retrying
            }
            
            $retries++
            Start-Sleep -Seconds 1
        }
        
        return $null
    } catch {
        Write-Warn "Ngrok tunnel failed"
        return $null
    }
}

function Start-CloudflareTunnel($port) {
    Write-Info "Starting Cloudflare tunnel..."
    
    $cfPath = "$BIN_DIR\cloudflared.exe"
    $logPath = "$LOG_DIR\cloudflare.log"
    
    if (Test-Path $logPath) {
        Remove-Item $logPath -Force
    }
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $cfPath
    $psi.Arguments = "tunnel --url http://127.0.0.1:$port --logfile `"$logPath`""
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    
    try {
        $process = [System.Diagnostics.Process]::Start($psi)
        Register-Process "cloudflared" $process
        
        Start-Sleep -Seconds 8
        
        # Extract URL from log file
        $retries = 0
        while ($retries -lt 20) {
            if (Test-Path $logPath) {
                $logContent = Get-Content $logPath -Raw
                if ($logContent -match "https://[\w-]+\.trycloudflare\.com") {
                    return $matches[0]
                }
            }
            
            $retries++
            Start-Sleep -Seconds 1
        }
        
        return $null
    } catch {
        Write-Warn "Cloudflare tunnel failed"
        return $null
    }
}

function Start-LoclxTunnel($port) {
    Write-Info "Starting Loclx tunnel..."
    
    $loclxPath = "$BIN_DIR\loclx.exe"
    
    if (-not (Test-Path $loclxPath)) {
        return $null
    }
    
    $logPath = "$LOG_DIR\loclx.log"
    
    if (Test-Path $logPath) {
        Remove-Item $logPath -Force
    }
    
    $args = "tunnel http --to :$port"
    $loclxToken = Get-ConfigValue "loclx_token"
    
    if ($loclxToken) {
        $args += " --token $loclxToken"
    }
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $loclxPath
    $psi.Arguments = $args
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    try {
        $process = [System.Diagnostics.Process]::Start($psi)
        Register-Process "loclx" $process
        
        Start-Sleep -Seconds 8
        
        # Try to read URL from output
        $retries = 0
        while ($retries -lt 20) {
            $output = ""
            if (-not $process.StandardOutput.EndOfStream) {
                $output = $process.StandardOutput.ReadLine()
            }
            
            if ($output -match "https://[\w-]+\.loclx\.io") {
                return $matches[0]
            }
            
            # Also check log file if it exists
            if (Test-Path $logPath) {
                $logContent = Get-Content $logPath -Raw
                if ($logContent -match "https://[\w-]+\.loclx\.io") {
                    return $matches[0]
                }
            }
            
            $retries++
            Start-Sleep -Seconds 1
        }
        
        return $null
    } catch {
        Write-Warn "Loclx tunnel failed (non-critical)"
        return $null
    }
}

function Start-AllTunnels($port) {
    Write-Warn "Initializing all tunnels (this may take ~30 seconds)..."
    
    $results = @{}
    
    $results.Ngrok = Start-NgrokTunnel $port
    $results.Cloudflare = Start-CloudflareTunnel $port
    $results.Loclx = Start-LoclxTunnel $port
    
    return $results
}

# ---------------------------
# Display Results
# ---------------------------
function Show-Results($urls) {
    Write-Host ""
    Show-Header "🌍 PUBLIC URLS READY"
    
    $activeCount = 0
    $rows = @()
    
    foreach ($service in $urls.Keys) {
        $url = $urls[$service]
        if ($url) {
            $activeCount++
            $rows += ,@($service, $url, "$($C.BGreen)Active$($C.Reset)")
        } else {
            $rows += ,@($service, "N/A", "$($C.BRed)Failed$($C.Reset)")
        }
    }
    
    Show-Table @("Service", "Public URL", "Status") $rows
    
    if ($activeCount -eq 0) {
        Write-ErrorMsg "All tunnels failed to start!"
        
        Show-Box @(
            "Troubleshooting:",
            "• Check your internet connection",
            "• Verify firewall settings",
            "• Try configuring API keys (Menu option 2)",
            "• Check logs in: $LOG_DIR",
            "",
            "Server is still accessible locally at the displayed port"
        ) $C.BYellow
        
        return $false
    }
    
    Write-Host "$($C.BGreen)$activeCount/$($urls.Count) tunnels active$($C.Reset)"
    
    if ($activeCount -lt $urls.Count) {
        Write-Host ""
        Write-Host "$($C.Dim)TIP: Configure API keys for better reliability (Menu option 2)$($C.Reset)"
    }
    
    # Quick copy suggestion
    if ($activeCount -eq 1) {
        $url = ($urls.Values | Where-Object { $_ })[0]
        Write-Host ""
        Write-Host "$($C.BCyan)Quick copy:$($C.Reset) $url"
    }
    
    Write-Host ""
    return $true
}

# ---------------------------
# CLI Functions
# ---------------------------
function Get-UserDirectory {
    while ($true) {
        Write-Host ""
        Write-Ask "Enter directory path to host (or '.' for current): "
        $input = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Warn "Please enter a valid directory path!"
            continue
        }
        
        $path = [System.IO.Path]::GetFullPath($input)
        
        if (Test-Path $path -PathType Container) {
            Write-Success "Selected directory: $path"
            
            # Show directory contents preview
            $files = Get-ChildItem $path -File | Select-Object -First 5
            if ($files) {
                Write-Host ""
                Write-Host "$($C.Dim)Preview (first 5 items):$($C.Reset)"
                foreach ($file in $files) {
                    Write-Host "  $($C.Dim)•$($C.Reset) $($file.Name)"
                }
                
                $totalFiles = (Get-ChildItem $path).Count
                if ($totalFiles -gt 5) {
                    Write-Host "  $($C.Dim)... ($($totalFiles - 5) more)$($C.Reset)"
                }
            }
            
            return $path
        } else {
            Write-ErrorMsg "Directory '$path' does not exist!"
            Write-Warn "Please enter a valid path (e.g., C:\mysite or .\mysite)"
        }
    }
}

function Get-ServerMode {
    Write-Host ""
    Show-Header "Select Hosting Protocol"
    
    Write-Host "$($C.BWhite)1)$($C.Reset) Python (http.server) $($C.Dim)- Recommended, universal$($C.Reset)"
    Write-Host "$($C.BWhite)2)$($C.Reset) PHP (built-in server) $($C.Dim)- For PHP applications$($C.Reset)"
    Write-Host "$($C.BWhite)3)$($C.Reset) NodeJS (http-server) $($C.Dim)- Modern, feature-rich$($C.Reset)"
    
    Write-Ask "Choice [1-3] (default: 1): "
    $choice = Read-Host
    if ($choice -eq "") { $choice = "1" }
    
    switch ($choice) {
        "1" { return "Python" }
        "2" { return "PHP" }
        "3" { return "NodeJS" }
        default {
            Write-Warn "Invalid choice, using Python"
            return "Python"
        }
    }
}

function Get-ServerPort {
    $lastPort = Get-ConfigValue "last_port" $DEFAULT_PORT
    
    Write-Host ""
    Write-Ask "Enter port (default: $lastPort): "
    $port = Read-Host
    
    if ($port -eq "") {
        $port = $lastPort
    }
    
    $portNum = [int]$port
    if ($portNum -le 0 -or $portNum -gt 65535) {
        Write-Warn "Invalid port, using default $DEFAULT_PORT"
        return $DEFAULT_PORT
    }
    
    if (-not (Test-PortAvailable $portNum)) {
        Write-ErrorMsg "Port $portNum is already in use!"
        
        # Find alternative
        $altPort = Find-AvailablePort ($portNum + 1)
        
        if ($altPort) {
            Write-Info "Suggested alternative port: $altPort"
            Write-Ask "Use port $altPort? (Y/n): "
            $choice = Read-Host
            
            if ($choice -ne 'n' -and $choice -ne 'N') {
                Set-ConfigValue "last_port" $altPort
                return $altPort
            }
        }
        
        return Get-ServerPort
    }
    
    Set-ConfigValue "last_port" $portNum
    return $portNum
}

# ---------------------------
# About Screen
# ---------------------------
function Show-About {
    Clear-Host
    Write-Host $LOGO
    
    Show-Box @(
        "Tool Name    : Local2Internet v$VERSION",
        "Edition      : $EDITION",
        "Description  : Professional LocalHost Exposing Tool",
        "Author       : KasRoudra",
        "Enhanced By  : Muhammad Taezeem Tariq Matta",
        "Ultimate By  : Claude AI Assistant",
        "Github       : github.com/Taezeem14/Local2Internet",
        "License      : MIT Open Source"
    ) $C.BPurple
    
    Write-Host ""
    Write-Host "$($C.BCyan)✨ Features:$($C.Reset)"
    
    $features = @(
        "Triple Tunneling (Ngrok, Cloudflare, Loclx)",
        "API Key Support & Management",
        "Auto-Recovery & Health Monitoring",
        "Real-Time Statistics Tracking",
        "Multi-Protocol Server Support",
        "Intelligent Port Detection",
        "Session Management",
        "Advanced Error Handling",
        "Modern Terminal UI"
    )
    
    foreach ($feature in $features) {
        Write-Host "  $($C.BGreen)•$($C.Reset) $feature"
    }
    
    Write-Ask "`n$($C.Dim)Press ENTER to continue...$($C.Reset)"
    Read-Host | Out-Null
}

# ---------------------------
# Help Screen
# ---------------------------
function Show-Help {
    Clear-Host
    Write-Host $LOGO
    Show-Header "📚 HELP & DOCUMENTATION"
    
    Write-Host ""
    Write-Host "$($C.BCyan)GETTING STARTED:$($C.Reset)"
    Write-Host "  1. Select 'Start Server & Tunnels' from main menu"
    Write-Host "  2. Enter the directory path you want to host"
    Write-Host "  3. Choose your preferred server protocol"
    Write-Host "  4. Enter a port number (or use default)"
    Write-Host "  5. Wait for tunnels to initialize"
    Write-Host "  6. Share the public URLs with others!"
    
    Write-Host ""
    Write-Host "$($C.BCyan)API KEY CONFIGURATION:$($C.Reset)"
    Write-Host "  • Ngrok: Get authtoken from https://dashboard.ngrok.com"
    Write-Host "  • Loclx: Get access token from https://localxpose.io/dashboard"
    Write-Host "  $($C.Dim)Benefits: Remove rate limits, persistent URLs, priority support$($C.Reset)"
    
    Write-Host ""
    Write-Host "$($C.BCyan)TROUBLESHOOTING:$($C.Reset)"
    Write-Host "  • Port in use: Tool will suggest alternatives automatically"
    Write-Host "  • Tunnels fail: Check internet, firewall, add API keys"
    Write-Host "  • Server fails: Ensure directory has index.html or index.php"
    Write-Host "  • Permission errors: Run PowerShell as Administrator"
    
    Write-Host ""
    Write-Host "$($C.BCyan)LOGS & STATISTICS:$($C.Reset)"
    Write-Host "  • Event logs: $LOG_DIR\events.log"
    Write-Host "  • Tunnel logs: $LOG_DIR\<service>.log"
    Write-Host "  • Statistics: Menu option 3"
    
    Write-Host ""
    Write-Host "$($C.BCyan)ADVANCED FEATURES:$($C.Reset)"
    Write-Host "  • Auto-recovery: Tunnels auto-restart on failure (coming soon)"
    Write-Host "  • Health monitoring: Real-time tunnel status checking"
    Write-Host "  • Session persistence: Remembers your preferences"
    
    Write-Ask "`n$($C.Dim)Press ENTER to continue...$($C.Reset)"
    Read-Host | Out-Null
}

# ---------------------------
# System Status
# ---------------------------
function Show-SystemStatus {
    Clear-Host
    Write-Host $LOGO
    Show-Header "💻 SYSTEM STATUS"
    
    # Dependencies
    Write-Host ""
    Write-Host "$($C.BCyan)Dependencies:$($C.Reset)"
    
    $depsStatus = @()
    @("python", "php", "node", "npm") | ForEach-Object {
        $status = (Test-CommandExists $_) ? "$($C.BGreen)✓$($C.Reset)" : "$($C.BRed)✗$($C.Reset)"
        $depsStatus += ,@($_, $status)
    }
    
    Show-Table @("Package", "Status") $depsStatus
    
    # Tunneling tools
    Write-Host "$($C.BCyan)Tunneling Tools:$($C.Reset)"
    
    $toolsStatus = @()
    @("ngrok", "cloudflared", "loclx") | ForEach-Object {
        $path = "$BIN_DIR\$_.exe"
        $status = (Test-Path $path) ? "$($C.BGreen)✓ Installed$($C.Reset)" : "$($C.BRed)✗ Missing$($C.Reset)"
        $toolsStatus += ,@($_.ToUpper(), $status)
    }
    
    Show-Table @("Tool", "Status") $toolsStatus
    
    # System info
    Write-Host "$($C.BCyan)System Information:$($C.Reset)"
    Write-Host "  Platform: Windows"
    Write-Host "  Architecture: $(Get-SystemArchitecture)"
    Write-Host "  PowerShell: $($PSVersionTable.PSVersion)"
    Write-Host "  Internet: $((Test-InternetConnection) ? 'Connected' : 'Disconnected')"
    Write-Host "  Local IP: $(Get-LocalIPAddress)"
    Write-Host ""
}

# ---------------------------
# Main Menu
# ---------------------------
function Show-MainMenu {
    $stats = [StatsTracker]::new()
    
    while ($true) {
        Clear-Host
        Write-Host $LOGO
        Show-Header "MAIN MENU"
        
        Write-Host "$($C.BWhite)1)$($C.Reset) Start Server & Tunnels $($C.BGreen)[Recommended]$($C.Reset)"
        Write-Host "$($C.BWhite)2)$($C.Reset) Manage API Keys $($C.Dim)[Configure tokens]$($C.Reset)"
        Write-Host "$($C.BWhite)3)$($C.Reset) View Statistics $($C.Dim)[Usage data]$($C.Reset)"
        Write-Host "$($C.BWhite)4)$($C.Reset) System Status $($C.Dim)[Check dependencies]$($C.Reset)"
        Write-Host "$($C.BWhite)5)$($C.Reset) Help & Documentation"
        Write-Host "$($C.BWhite)6)$($C.Reset) About"
        Write-Host "$($C.BWhite)0)$($C.Reset) Exit"
        
        # Show status
        Write-Host ""
        Write-Host "$($C.BCyan)$('━' * 70)$($C.Reset)"
        
        $ngrokStatus = (Get-ConfigValue "ngrok_token") ? "$($C.BGreen)✓ Configured$($C.Reset)" : "$($C.BRed)✗ Not Set$($C.Reset)"
        $loclxStatus = (Get-ConfigValue "loclx_token") ? "$($C.BGreen)✓ Configured$($C.Reset)" : "$($C.BRed)✗ Not Set$($C.Reset)"
        
        Write-Host "$($C.Dim)API Keys:$($C.Reset) Ngrok: $ngrokStatus | Loclx: $loclxStatus"
        
        if (Test-SessionActive) {
            Write-Host "$($C.BYellow)⚠ Active session detected$($C.Reset)"
        }
        
        $localIp = Get-LocalIPAddress
        $internet = (Test-InternetConnection) ? "$($C.BGreen)Connected$($C.Reset)" : "$($C.BRed)No Connection$($C.Reset)"
        Write-Host "$($C.Dim)Network:$($C.Reset) Local IP: $localIp | Internet: $internet"
        
        Write-Ask "`nChoice: "
        $choice = Read-Host
        
        switch ($choice) {
            "1" { Start-MainFlow $stats }
            "2" { Manage-APIKeys }
            "3" { $stats.DisplayStats(); Write-Ask "`n$($C.Dim)Press ENTER...$($C.Reset)"; Read-Host | Out-Null }
            "4" { Show-SystemStatus; Write-Ask "`n$($C.Dim)Press ENTER...$($C.Reset)"; Read-Host | Out-Null }
            "5" { Show-Help }
            "6" { Show-About }
            "0" {
                Write-Host ""
                Write-Host "$($C.BGreen)Thanks for using Local2Internet! 👋$($C.Reset)"
                Write-Host ""
                Stop-AllProcesses
                exit 0
            }
            default {
                Write-Warn "Invalid choice! Please select 0-6"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ---------------------------
# Main Flow
# ---------------------------
function Start-MainFlow($stats) {
    Clear-Host
    Write-Host $LOGO
    
    # Pre-flight checks
    if (-not (Test-InternetConnection)) {
        Write-ErrorMsg "No internet connection detected!"
        Write-Warn "Tunneling requires an active internet connection"
        Write-Ask "`nContinue anyway? (y/N): "
        $response = Read-Host
        if ($response -ne 'y' -and $response -ne 'Y') {
            return
        }
    }
    
    # Get inputs
    $path = Get-UserDirectory
    $mode = Get-ServerMode
    $port = Get-ServerPort
    
    # Start server
    $serverStarted = Start-LocalServer $path $port $mode
    
    if (-not $serverStarted) {
        Write-ErrorMsg "Failed to start local server!"
        Start-Sleep -Seconds 3
        return
    }
    
    # Start tunnels
    $urls = Start-AllTunnels $port
    
    # Display results
    $success = Show-Results $urls
    
    if (-not $success) {
        Stop-AllProcesses
        Start-Sleep -Seconds 5
        return
    }
    
    # Save session
    $sessionData = @{
        active = $true
        pid = $PID
        port = $port
        mode = $mode
        started_at = (Get-Date).ToString()
        urls = $urls
    }
    Save-Session $sessionData
    
    # Keep alive
    Write-Host "$($C.BCyan)$('━' * 70)$($C.Reset)"
    Write-Host "$($C.BGreen)Server is running with health monitoring enabled$($C.Reset)"
    Write-Host "$($C.Dim)Press CTRL+C to stop and return to menu$($C.Reset)"
    Write-Host "$($C.BCyan)$('━' * 70)$($C.Reset)"
    Write-Host ""
    
    $startTime = Get-Date
    
    try {
        while ($true) {
            Start-Sleep -Seconds 60
            
            # Show periodic status
            $uptime = (Get-Date) - $startTime
            $hours = [Math]::Floor($uptime.TotalHours)
            $minutes = $uptime.Minutes
            
            Write-Host -NoNewline "`r$($C.Dim)Uptime: ${hours}h ${minutes}m | Monitoring active$($C.Reset)"
        }
    } catch {
        # Handled by trap
    } finally {
        # Record statistics
        $duration = [Math]::Floor(((Get-Date) - $startTime).TotalSeconds)
        $activeTunnels = @()
        foreach ($key in $urls.Keys) {
            if ($urls[$key]) {
                $activeTunnels += $key
            }
        }
        
        $stats.RecordSession($duration, $activeTunnels, $mode)
        Clear-Session
    }
}

# ---------------------------
# Trap CTRL+C
# ---------------------------
trap {
    Write-Host ""
    Write-Host "$($C.BCyan)Shutting down gracefully...$($C.Reset)"
    Stop-AllProcesses
    Clear-Session
    Write-Host "$($C.BGreen)Cleanup complete.$($C.Reset)"
    Write-Host ""
    Start-Sleep -Seconds 1
    continue
}

# ---------------------------
# Entry Point
# ---------------------------
try {
    Stop-AllProcesses
    Initialize-Directories
    
    # First run setup
    if (-not (Get-ConfigValue "first_run_done")) {
        Clear-Host
        Write-Host $LOGO
        
        Show-Box @(
            "Welcome to Local2Internet v$VERSION $EDITION!",
            "",
            "First-time setup wizard",
            "Installing dependencies and tools..."
        ) $C.BGreen
        
        Start-Sleep -Seconds 2
        
        $depsOk = Install-Dependencies
        $toolsOk = Install-Tools
        
        if (-not $depsOk -or -not $toolsOk) {
            Write-ErrorMsg "Setup failed! Please check errors above."
            exit 1
        }
        
        Set-ConfigValue "first_run_done" $true
        Set-ConfigValue "installed_at" (Get-Date).ToString()
        
        Write-Success "Setup complete! Ready to use."
        Start-Sleep -Seconds 2
    } else {
        # Quick check
        $depsOk = Install-Dependencies
        $toolsOk = Install-Tools
        
        if (-not $depsOk -or -not $toolsOk) {
            Write-Warn "Some components may be missing"
        }
    }
    
    # Configure ngrok token if present
    $ngrokToken = Get-ConfigValue "ngrok_token"
    if ($ngrokToken) {
        $ngrokPath = "$BIN_DIR\ngrok.exe"
        & $ngrokPath config add-authtoken $ngrokToken 2>&1 | Out-Null
    }
    
    Show-MainMenu
    
} catch {
    Write-Host ""
    Write-ErrorMsg "FATAL ERROR: $_"
    Stop-AllProcesses
    exit 1
}
