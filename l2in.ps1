# =========================================
# Local2Internet v4 - Windows Edition
# Author: KasRoudra + Muhammad Taezeem Tariq Matta
# GitHub: https://github.com/KasRoudra/Local2Internet
# Description: Expose localhost to internet with triple tunneling
# License: MIT
# =========================================

# Requires -RunAsAdministrator for some operations
$ErrorActionPreference = "SilentlyContinue"

# ---------------------------
# Configuration
# ---------------------------
$script:HOME = $env:USERPROFILE
$script:BASE_DIR = "$HOME\.local2internet"
$script:BIN_DIR = "$BASE_DIR\bin"
$script:LOG_DIR = "$BASE_DIR\logs"
$script:DEFAULT_PORT = 8888

# ---------------------------
# Colors & Formatting
# ---------------------------
$ESC = [char]27
$C = @{
    Red = "$ESC[31m"
    Green = "$ESC[32m"
    Yellow = "$ESC[33m"
    Blue = "$ESC[34m"
    Cyan = "$ESC[36m"
    White = "$ESC[37m"
    Reset = "$ESC[0m"
}

function Write-Info($msg) { Write-Host "$($C.Cyan)[+]$($C.White) $msg$($C.Reset)" }
function Write-Success($msg) { Write-Host "$($C.Green)[✓]$($C.White) $msg$($C.Reset)" }
function Write-ErrorMsg($msg) { Write-Host "$($C.Red)[✗]$($C.White) $msg$($C.Reset)" }
function Write-Warn($msg) { Write-Host "$($C.Yellow)[!]$($C.White) $msg$($C.Reset)" }
function Write-Ask($msg) { Write-Host "$($C.Yellow)[?]$($C.White) $msg$($C.Reset)" -NoNewline }

# ---------------------------
# Logo
# ---------------------------
$LOGO = @"
$($C.Red)
▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀
$($C.Yellow)▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░
$($C.Green)▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░
$($C.Blue)                                      [v4 Windows Enhanced]
$($C.Reset)
"@

# ---------------------------
# Process Management
# ---------------------------
$script:ServerProcess = $null
$script:NgrokProcess = $null
$script:CloudflaredProcess = $null
$script:LoclxProcess = $null

function Stop-AllProcesses {
    Write-Info "Cleaning up processes..."
    
    @("python", "php", "node", "http-server", "ngrok", "cloudflared", "loclx") | ForEach-Object {
        Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    
    if ($script:ServerProcess) { Stop-Process -Id $script:ServerProcess.Id -Force -ErrorAction SilentlyContinue }
    if ($script:NgrokProcess) { Stop-Process -Id $script:NgrokProcess.Id -Force -ErrorAction SilentlyContinue }
    if ($script:CloudflaredProcess) { Stop-Process -Id $script:CloudflaredProcess.Id -Force -ErrorAction SilentlyContinue }
    if ($script:LoclxProcess) { Stop-Process -Id $script:LoclxProcess.Id -Force -ErrorAction SilentlyContinue }
    
    Start-Sleep -Seconds 1
}

# ---------------------------
# Setup Directories
# ---------------------------
function Initialize-Directories {
    @($BASE_DIR, $BIN_DIR, $LOG_DIR) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
}

# ---------------------------
# Dependency Management
# ---------------------------
function Test-CommandExists($cmd) {
    return (Get-Command $cmd -ErrorAction SilentlyContinue) -ne $null
}

function Install-Dependencies {
    Write-Info "Checking dependencies..."
    
    $deps = @{
        "python" = "python"
        "php" = "php"
        "node" = "nodejs"
    }
    
    $chocoInstalled = Test-CommandExists "choco"
    
    foreach ($dep in $deps.Keys) {
        if (-not (Test-CommandExists $dep)) {
            if ($chocoInstalled) {
                Write-Info "Installing $dep via Chocolatey..."
                choco install $deps[$dep] -y --force
            } else {
                Write-ErrorMsg "Missing dependency: $dep"
                Write-ErrorMsg "Please install Chocolatey: https://chocolatey.org/install"
                exit 1
            }
        }
    }
    
    # Install http-server via npm
    if (Test-CommandExists "npm") {
        $httpServer = npm list -g http-server 2>$null | Select-String "http-server"
        if (-not $httpServer) {
            Write-Info "Installing http-server..."
            npm install -g http-server
        }
    }
}

# ---------------------------
# Architecture Detection
# ---------------------------
function Get-SystemArchitecture {
    $arch = (Get-WmiObject Win32_Processor).AddressWidth
    
    if ($arch -eq 64) {
        return "amd64"
    } elseif ($arch -eq 32) {
        return "386"
    } else {
        return "amd64"  # Default fallback
    }
}

# ---------------------------
# Download Ngrok
# ---------------------------
function Install-Ngrok {
    $ngrokPath = "$BIN_DIR\ngrok.exe"
    
    if (Test-Path $ngrokPath) {
        return
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
    } catch {
        Write-ErrorMsg "Failed to download Ngrok: $_"
    }
}

# ---------------------------
# Download Cloudflared
# ---------------------------
function Install-Cloudflared {
    $cfPath = "$BIN_DIR\cloudflared.exe"
    
    if (Test-Path $cfPath) {
        return
    }
    
    Write-Info "Downloading Cloudflared..."
    $arch = Get-SystemArchitecture
    $url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-$arch.exe"
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $cfPath -UseBasicParsing
        Write-Success "Cloudflared installed!"
    } catch {
        Write-ErrorMsg "Failed to download Cloudflared: $_"
    }
}

# ---------------------------
# Download Loclx
# ---------------------------
function Install-Loclx {
    $loclxPath = "$BIN_DIR\loclx.exe"
    
    if (Test-Path $loclxPath) {
        return
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
    } catch {
        Write-Warn "Loclx download failed (non-critical)"
    }
}

# ---------------------------
# Install All Tools
# ---------------------------
function Install-Tools {
    Install-Ngrok
    Install-Cloudflared
    Install-Loclx
}

# ---------------------------
# Start Local Server
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
        $script:ServerProcess = [System.Diagnostics.Process]::Start($psi)
        Start-Sleep -Seconds 2
        
        # Verify server started
        $response = Invoke-WebRequest -Uri "http://127.0.0.1:$port" -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue
        
        if ($response.StatusCode -eq 200 -or $response) {
            Write-Success "Server running at http://127.0.0.1:$port"
            return $true
        } else {
            Write-ErrorMsg "Server failed to start!"
            return $false
        }
    } catch {
        Write-ErrorMsg "Server startup error: $_"
        return $false
    }
}

# ---------------------------
# Start Ngrok Tunnel
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
        $script:NgrokProcess = [System.Diagnostics.Process]::Start($psi)
        Start-Sleep -Seconds 5
        
        # Extract URL from Ngrok API
        $apiResponse = Invoke-RestMethod -Uri "http://127.0.0.1:4040/api/tunnels" -ErrorAction SilentlyContinue
        $url = $apiResponse.tunnels[0].public_url
        
        if ($url) {
            return $url.Replace("http://", "https://")
        } else {
            return $null
        }
    } catch {
        Write-Warn "Ngrok tunnel failed"
        return $null
    }
}

# ---------------------------
# Start Cloudflared Tunnel
# ---------------------------
function Start-CloudflareTunnel($port) {
    Write-Info "Starting Cloudflare tunnel..."
    
    $cfPath = "$BIN_DIR\cloudflared.exe"
    $logPath = "$LOG_DIR\cloudflare.log"
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $cfPath
    $psi.Arguments = "tunnel --url http://127.0.0.1:$port --logfile `"$logPath`""
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    
    try {
        $script:CloudflaredProcess = [System.Diagnostics.Process]::Start($psi)
        Start-Sleep -Seconds 6
        
        # Extract URL from log file
        if (Test-Path $logPath) {
            $logContent = Get-Content $logPath -Raw
            if ($logContent -match "https://[\w-]+\.trycloudflare\.com") {
                return $matches[0]
            }
        }
        
        return $null
    } catch {
        Write-Warn "Cloudflare tunnel failed"
        return $null
    }
}

# ---------------------------
# Start Loclx Tunnel
# ---------------------------
function Start-LoclxTunnel($port) {
    Write-Info "Starting Loclx tunnel..."
    
    $loclxPath = "$BIN_DIR\loclx.exe"
    
    if (-not (Test-Path $loclxPath)) {
        return $null
    }
    
    $logPath = "$LOG_DIR\loclx.log"
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $loclxPath
    $psi.Arguments = "tunnel http --to :$port"
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    
    try {
        $script:LoclxProcess = [System.Diagnostics.Process]::Start($psi)
        $script:LoclxProcess.StandardOutput.BaseStream.BeginRead((New-Object byte[] 4096), 0, 4096, $null, $null)
        $script:LoclxProcess.StandardError.BaseStream.BeginRead((New-Object byte[] 4096), 0, 4096, $null, $null)
        
        Start-Sleep -Seconds 6
        
        # Try to read from log or output
        if (Test-Path $logPath) {
            $logContent = Get-Content $logPath -Raw
            if ($logContent -match "https://[\w-]+\.loclx\.io") {
                return $matches[0]
            }
        }
        
        return $null
    } catch {
        Write-Warn "Loclx tunnel failed (non-critical)"
        return $null
    }
}

# ---------------------------
# Start All Tunnels
# ---------------------------
function Start-AllTunnels($port) {
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
    Write-Host "$($C.Green)╔════════════════════════════════════════╗$($C.Reset)"
    Write-Host "$($C.Green)║          PUBLIC URLS READY!            ║$($C.Reset)"
    Write-Host "$($C.Green)╚════════════════════════════════════════╝$($C.Reset)"
    Write-Host ""
    
    $activeCount = 0
    
    foreach ($service in $urls.Keys) {
        if ($urls[$service]) {
            Write-Success "$service : $($C.Cyan)$($urls[$service])$($C.Reset)"
            $activeCount++
        } else {
            Write-Warn "$service : Failed to start"
        }
    }
    
    Write-Host ""
    
    if ($activeCount -eq 0) {
        Write-ErrorMsg "All tunnels failed to start!"
        return $false
    } else {
        Write-Host "$($C.Green)$activeCount/$($urls.Count) tunnels active$($C.Reset)"
        return $true
    }
}

# ---------------------------
# Get User Input
# ---------------------------
function Get-UserDirectory {
    while ($true) {
        Write-Ask "Enter directory path to host: "
        $path = Read-Host
        
        if (Test-Path $path -PathType Container) {
            return $path
        } else {
            Write-Warn "Directory '$path' does not exist!"
        }
    }
}

function Get-ServerMode {
    Write-Host ""
    Write-Host "$($C.Yellow)Select hosting protocol:$($C.Reset)"
    Write-Host "1) Python (http.server)"
    Write-Host "2) PHP (built-in server)"
    Write-Host "3) NodeJS (http-server)"
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
    Write-Ask "Enter port (default: $DEFAULT_PORT): "
    $port = Read-Host
    
    if ($port -eq "") {
        return $DEFAULT_PORT
    }
    
    $portNum = [int]$port
    if ($portNum -le 0 -or $portNum -gt 65535) {
        Write-Warn "Invalid port, using default $DEFAULT_PORT"
        return $DEFAULT_PORT
    }
    
    return $portNum
}

# ---------------------------
# About Screen
# ---------------------------
function Show-About {
    Clear-Host
    Write-Host $LOGO
    Write-Host @"

$($C.Red)[Tool Name]   $($C.Cyan): Local2Internet v4
$($C.Red)[Version]     $($C.Cyan): 4.0 Windows Edition
$($C.Red)[Description] $($C.Cyan): Localhost Exposing Tool
$($C.Red)[Author]      $($C.Cyan): KasRoudra
$($C.Red)[Contributor] $($C.Cyan): Muhammad Taezeem Tariq Matta
$($C.Red)[Platform]    $($C.Cyan): Windows PowerShell
$($C.Red)[License]     $($C.Cyan): MIT Open Source
$($C.Reset)

"@
    Write-Ask "Press ENTER to continue..."
    Read-Host | Out-Null
}

# ---------------------------
# Main Menu
# ---------------------------
function Show-MainMenu {
    while ($true) {
        Clear-Host
        Write-Host $LOGO
        Write-Host ""
        Write-Host "$($C.Yellow)╔════════════════════════════════════════╗$($C.Reset)"
        Write-Host "$($C.Yellow)║            MAIN MENU                   ║$($C.Reset)"
        Write-Host "$($C.Yellow)╚════════════════════════════════════════╝$($C.Reset)"
        Write-Host ""
        Write-Host "1) Start Server & Tunnels"
        Write-Host "2) About"
        Write-Host "0) Exit"
        Write-Host ""
        Write-Ask "Choice: "
        
        $choice = Read-Host
        
        switch ($choice) {
            "1" { Start-MainFlow }
            "2" { Show-About }
            "0" {
                Write-Host ""
                Write-Host "$($C.Green)Goodbye! 👋$($C.Reset)"
                Write-Host ""
                exit 0
            }
            default {
                Write-Warn "Invalid choice! Please select 1, 2, or 0"
                Start-Sleep -Seconds 2
            }
        }
    }
}

# ---------------------------
# Main Flow
# ---------------------------
function Start-MainFlow {
    Clear-Host
    Write-Host $LOGO
    
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
        Start-Sleep -Seconds 3
        return
    }
    
    # Keep alive
    Write-Host ""
    Write-Host "$($C.Red)Press CTRL+C to stop and return to menu$($C.Reset)"
    Write-Host ""
    
    try {
        while ($true) {
            Start-Sleep -Seconds 10
        }
    } catch {
        # Cleanup handled by trap
    }
}

# ---------------------------
# Trap CTRL+C
# ---------------------------
trap {
    Write-Host ""
    Write-Host "$($C.Cyan)Caught interrupt signal...$($C.Reset)"
    Stop-AllProcesses
    Write-Host "$($C.Green)Processes stopped.$($C.Reset)"
    Write-Host ""
    Start-Sleep -Seconds 2
    continue
}

# ---------------------------
# Entry Point
# ---------------------------
try {
    Stop-AllProcesses  # Clean any previous instances
    Initialize-Directories
    Install-Dependencies
    Install-Tools
    Show-MainMenu
} catch {
    Write-Host ""
    Write-ErrorMsg "FATAL ERROR: $_"
    Stop-AllProcesses
    exit 1
}
