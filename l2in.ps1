# =========================================
# Local2Internet v4.1 - Advanced Windows Edition
# Author: KasRoudra + Muhammad Taezeem Tariq Matta
# GitHub: https://github.com/Taezeem14/Local2Internet
# Description: Expose localhost to internet with advanced features
# License: MIT
# =========================================

#Requires -Version 5.1

$ErrorActionPreference = "SilentlyContinue"

# ---------------------------
# Configuration
# ---------------------------
$script:HOME = $env:USERPROFILE
$script:BASE_DIR = "$HOME\.local2internet"
$script:BIN_DIR = "$BASE_DIR\bin"
$script:LOG_DIR = "$BASE_DIR\logs"
$script:CONFIG_FILE = "$BASE_DIR\config.json"
$script:DEFAULT_PORT = 8888
$script:VERSION = "4.1"

# ---------------------------
# Colors & Formatting (ANSI)
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
$($C.Blue)                                      [v$VERSION Advanced - API Support]
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
    $config | ConvertTo-Json | Set-Content $CONFIG_FILE
}

function Get-ConfigValue($key) {
    $config = Get-Config
    return $config.$key
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
                choco install $deps[$dep] -y --force | Out-Null
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
            npm install -g http-server | Out-Null
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
        return "amd64"
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
# API Key Management
# ---------------------------
function Manage-APIKeys {
    while ($true) {
        Clear-Host
        Write-Host $LOGO
        Write-Host ""
        Write-Host "$($C.Yellow)╔════════════════════════════════════════╗$($C.Reset)"
        Write-Host "$($C.Yellow)║         API KEY MANAGEMENT             ║$($C.Reset)"
        Write-Host "$($C.Yellow)╚════════════════════════════════════════╝$($C.Reset)"
        Write-Host ""
        Write-Host "1) Set Ngrok Authtoken"
        Write-Host "2) Set Loclx Access Token"
        Write-Host "3) View Current Keys"
        Write-Host "4) Remove Keys"
        Write-Host "0) Back to Main Menu"
        Write-Host ""
        Write-Ask "Choice: "
        
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                Write-Host ""
                Write-Ask "Enter Ngrok authtoken (from https://dashboard.ngrok.com): "
                $token = Read-Host
                
                if ($token) {
                    # Configure ngrok
                    $ngrokPath = "$BIN_DIR\ngrok.exe"
                    $result = & $ngrokPath config add-authtoken $token 2>&1
                    
                    if ($LASTEXITCODE -eq 0) {
                        Set-ConfigValue "ngrok_token" $token
                        Write-Success "Ngrok authtoken saved and configured!"
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
                } else {
                    Write-Warn "Token cannot be empty!"
                }
                Start-Sleep -Seconds 2
            }
            "3" {
                Write-Host ""
                Write-Host "$($C.Cyan)Current API Keys:$($C.Reset)"
                Write-Host ("━" * 40)
                
                $ngrokToken = Get-ConfigValue "ngrok_token"
                $loclxToken = Get-ConfigValue "loclx_token"
                
                if ($ngrokToken) {
                    Write-Host "$($C.Green)[✓]$($C.Reset) Ngrok: $($ngrokToken.Substring(0, [Math]::Min(15, $ngrokToken.Length)))***"
                } else {
                    Write-Host "$($C.Red)[✗]$($C.Reset) Ngrok: Not configured"
                }
                
                if ($loclxToken) {
                    Write-Host "$($C.Green)[✓]$($C.Reset) Loclx: $($loclxToken.Substring(0, [Math]::Min(15, $loclxToken.Length)))***"
                } else {
                    Write-Host "$($C.Red)[✗]$($C.Reset) Loclx: Not configured"
                }
                
                Write-Host ""
                Write-Host "$($C.Yellow)Note: API keys enable premium features and remove rate limits$($C.Reset)"
                Write-Ask "`nPress ENTER to continue..."
                Read-Host | Out-Null
            }
            "4" {
                Write-Host ""
                Write-Host "$($C.Yellow)Remove which key?$($C.Reset)"
                Write-Host "1) Ngrok"
                Write-Host "2) Loclx"
                Write-Host "3) Both"
                Write-Host "0) Cancel"
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
                Start-Sleep -Seconds 2
            }
        }
    }
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
        Start-Sleep -Seconds 3
        
        # Verify server started (retry up to 5 times)
        $retries = 0
        while ($retries -lt 5) {
            try {
                $response = Invoke-WebRequest -Uri "http://127.0.0.1:$port" -Method Head -TimeoutSec 2 -ErrorAction SilentlyContinue
                
                if ($response) {
                    Write-Success "Server running at http://127.0.0.1:$port"
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
        Start-Sleep -Seconds 6
        
        # Extract URL from Ngrok API (retry up to 10 times)
        $retries = 0
        while ($retries -lt 10) {
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

# ---------------------------
# Start Cloudflared Tunnel
# ---------------------------
function Start-CloudflareTunnel($port) {
    Write-Info "Starting Cloudflare tunnel..."
    
    $cfPath = "$BIN_DIR\cloudflared.exe"
    $logPath = "$LOG_DIR\cloudflare.log"
    
    # Clear old log
    if (Test-Path $logPath) {
        Remove-Item $logPath -Force
    }
    
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $cfPath
    $psi.Arguments = "tunnel --url http://127.0.0.1:$port --logfile `"$logPath`""
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    
    try {
        $script:CloudflaredProcess = [System.Diagnostics.Process]::Start($psi)
        Start-Sleep -Seconds 8
        
        # Extract URL from log file (retry up to 15 times)
        $retries = 0
        while ($retries -lt 15) {
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
    
    # Clear old log
    if (Test-Path $logPath) {
        Remove-Item $logPath -Force
    }
    
    # Build arguments with token if available
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
        $script:LoclxProcess = [System.Diagnostics.Process]::Start($psi)
        
        # Redirect output to log file
        $outputReader = $script:LoclxProcess.StandardOutput
        $errorReader = $script:LoclxProcess.StandardError
        
        Start-Sleep -Seconds 8
        
        # Try to read URL from output
        $retries = 0
        while ($retries -lt 15) {
            # Check if process wrote any output
            $output = ""
            if (-not $outputReader.EndOfStream) {
                $output = $outputReader.ReadLine()
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

# ---------------------------
# Start All Tunnels
# ---------------------------
function Start-AllTunnels($port) {
    Write-Warn "Starting all tunnels (this may take ~30 seconds)..."
    
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
            $serviceName = $service.PadRight(12)
            Write-Success "$serviceName : $($C.Cyan)$($urls[$service])$($C.Reset)"
            $activeCount++
        } else {
            $serviceName = $service.PadRight(12)
            Write-Warn "$serviceName : Failed to start"
        }
    }
    
    Write-Host ""
    
    if ($activeCount -eq 0) {
        Write-ErrorMsg "All tunnels failed to start!"
        Write-Warn "Troubleshooting:"
        Write-Warn "• Check your internet connection"
        Write-Warn "• Verify firewall settings"
        Write-Warn "• Try configuring API keys (Menu option 2)"
        Write-Warn "• Check logs in: $LOG_DIR"
        Write-Host ""
        Write-Host "$($C.Yellow)Server is still accessible locally at the displayed port$($C.Reset)"
        return $false
    } else {
        Write-Host "$($C.Green)$activeCount/$($urls.Count) tunnels active$($C.Reset)"
        
        if ($activeCount -lt $urls.Count) {
            Write-Host ""
            Write-Host "$($C.Cyan)TIP: Configure API keys for better reliability (Menu option 2)$($C.Reset)"
        }
        
        return $true
    }
}

# ---------------------------
# Get User Input
# ---------------------------
function Get-UserDirectory {
    while ($true) {
        Write-Ask "Enter directory path to host (or '.' for current): "
        $input = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($input)) {
            Write-Warn "Please enter a valid directory path!"
            continue
        }
        
        # Convert to absolute path
        $path = [System.IO.Path]::GetFullPath($input)
        
        if (Test-Path $path -PathType Container) {
            Write-Info "Selected directory: $path"
            return $path
        } else {
            Write-Warn "Directory '$path' does not exist!"
            Write-Warn "Please enter a valid path (e.g., C:\mysite or .\mysite)"
        }
    }
}

function Get-ServerMode {
    Write-Host ""
    Write-Host "$($C.Yellow)Select hosting protocol:$($C.Reset)"
    Write-Host "1) Python (http.server) - Recommended"
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
    
    # Check if port is in use
    $portInUse = Get-NetTCPConnection -LocalPort $portNum -ErrorAction SilentlyContinue
    
    if ($portInUse) {
        Write-Warn "Port $portNum is already in use!"
        Write-Ask "Try anyway? (y/N): "
        $choice = Read-Host
        
        if ($choice -eq "y" -or $choice -eq "Y") {
            return $portNum
        } else {
            return Get-ServerPort
        }
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

$($C.Red)[Tool Name]   $($C.Cyan): Local2Internet v$VERSION
$($C.Red)[Description] $($C.Cyan): Advanced LocalHost Exposing Tool
$($C.Red)[Author]      $($C.Cyan): KasRoudra
$($C.Red)[Enhanced By] $($C.Cyan): Muhammad Taezeem Tariq Matta
$($C.Red)[Platform]    $($C.Cyan): Windows PowerShell
$($C.Red)[Github]      $($C.Cyan): https://github.com/Taezeem14/Local2Internet
$($C.Red)[License]     $($C.Cyan): MIT Open Source
$($C.Red)[Features]    $($C.Cyan): • Triple Tunneling (Ngrok, Cloudflare, Loclx)
              $($C.Cyan)  • API Key Support
              $($C.Cyan)  • Auto Port Detection
              $($C.Cyan)  • Multi-Protocol Server (Python/PHP/NodeJS)
              $($C.Cyan)  • Enhanced Error Handling
$($C.Reset)

"@
    Write-Ask "Press ENTER to continue..."
    Read-Host | Out-Null
}

# ---------------------------
# Help Screen
# ---------------------------
function Show-Help {
    Clear-Host
    Write-Host $LOGO
    Write-Host @"

$($C.Cyan)═══════════════════════════════════════════════════════════
                        HELP GUIDE
═══════════════════════════════════════════════════════════$($C.Reset)

$($C.Yellow)GETTING STARTED:$($C.Reset)
  1. Select "Start Server & Tunnels" from main menu
  2. Enter the directory path you want to host
  3. Choose your preferred server protocol
  4. Enter a port number (or use default)
  5. Wait for tunnels to initialize (~30 seconds)
  6. Share the public URLs with others!

$($C.Yellow)API KEY CONFIGURATION:$($C.Reset)
  • Ngrok: Get authtoken from https://dashboard.ngrok.com
  • Loclx: Get access token from https://localxpose.io/dashboard
  
  Benefits: Remove rate limits, persistent URLs, priority support

$($C.Yellow)TROUBLESHOOTING:$($C.Reset)
  • Port in use: Choose a different port or close conflicting apps
  • Tunnels fail: Check firewall, internet connection, add API keys
  • Server fails: Ensure directory has index.html or index.php
  • Permission errors: Run PowerShell as Administrator

$($C.Yellow)LOGS LOCATION:$($C.Reset)
  $LOG_DIR

$($C.Yellow)KEYBOARD SHORTCUTS:$($C.Reset)
  • CTRL+C: Stop server and return to menu
  • Any menu: Type number and press ENTER

$($C.Cyan)═══════════════════════════════════════════════════════════$($C.Reset)

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
        Write-Host "2) Manage API Keys"
        Write-Host "3) Help & Documentation"
        Write-Host "4) About"
        Write-Host "0) Exit"
        
        # Show API key status
        Write-Host ""
        Write-Host "$($C.Cyan)API Keys Status:$($C.Reset)"
        
        $ngrokToken = Get-ConfigValue "ngrok_token"
        $loclxToken = Get-ConfigValue "loclx_token"
        
        $ngrokStatus = if ($ngrokToken) { "$($C.Green)Configured$($C.Reset)" } else { "$($C.Red)Not Set$($C.Reset)" }
        $loclxStatus = if ($loclxToken) { "$($C.Green)Configured$($C.Reset)" } else { "$($C.Red)Not Set$($C.Reset)" }
        
        Write-Host "  Ngrok: $ngrokStatus | Loclx: $loclxStatus"
        
        Write-Host ""
        Write-Ask "Choice: "
        
        $choice = Read-Host
        
        switch ($choice) {
            "1" { Start-MainFlow }
            "2" { Manage-APIKeys }
            "3" { Show-Help }
            "4" { Show-About }
            "0" {
                Write-Host ""
                Write-Host "$($C.Green)Goodbye! 👋$($C.Reset)"
                Write-Host ""
                exit 0
            }
            default {
                Write-Warn "Invalid choice! Please select 1-4 or 0"
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
        Start-Sleep -Seconds 5
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
    
    # Show welcome message on first run
    $firstRun = Get-ConfigValue "first_run_done"
    
    if (-not $firstRun) {
        Clear-Host
        Write-Host $LOGO
        Write-Host ""
        Write-Host "$($C.Green)╔════════════════════════════════════════╗$($C.Reset)"
        Write-Host "$($C.Green)║     WELCOME TO LOCAL2INTERNET v$VERSION   ║$($C.Reset)"
        Write-Host "$($C.Green)╚════════════════════════════════════════╝$($C.Reset)"
        Write-Host ""
        Write-Host "$($C.Cyan)First-time setup complete!$($C.Reset)"
        Write-Host "$($C.Yellow)• All dependencies verified$($C.Reset)"
        Write-Host "$($C.Yellow)• Tunneling tools downloaded$($C.Reset)"
        Write-Host "$($C.Yellow)• Ready to expose your localhost!$($C.Reset)"
        Write-Host ""
        Write-Host "$($C.Cyan)TIP: Configure API keys for premium features (Menu option 2)$($C.Reset)"
        Write-Host ""
        Set-ConfigValue "first_run_done" $true
        Start-Sleep -Seconds 3
    }
    
    Show-MainMenu
} catch {
    Write-Host ""
    Write-ErrorMsg "FATAL ERROR: $_"
    Stop-AllProcesses
    exit 1
}
