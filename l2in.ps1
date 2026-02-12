# =========================================
# Local2Internet v4 - Windows Edition
# Author: KasRoudra + Muhammad Taezeem
# GitHub: https://github.com/KasRoudra/Local2Internet
# Description: Expose a local folder to the internet with triple tunneling
# =========================================

# Colors
$green = "`e[32m"
$yellow = "`e[33m"
$red = "`e[31m"
$cyan = "`e[36m"
$white = "`e[37m"
$reset = "`e[0m"

function Write-Info($msg){ Write-Host "$cyan[+]$white $msg" }
function Write-Success($msg){ Write-Host "$green[√]$white $msg" }
function Write-ErrorMsg($msg){ Write-Host "$red[!]$white $msg" }

# Welcome Logo
Write-Host "
▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀
▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░
▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░
                     [By KasRoudra + Muhammad Taezeem]
"

# ---------------------------
# Function: Check & Install Dependencies via Chocolatey
# ---------------------------
function Check-Dependency($dep, $chocoName){
    $installed = Get-Command $dep -ErrorAction SilentlyContinue
    if (-not $installed){
        Write-Info "Installing $dep..."
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)){
            Write-ErrorMsg "Chocolatey not found! Please install it first: https://chocolatey.org/install"
            exit
        }
        choco install $chocoName -y
    }
}

# Check main dependencies
Check-Dependency python python
Check-Dependency php php
Check-Dependency node nodejs
Check-Dependency wget wget
Check-Dependency curl curl
Check-Dependency unzip unzip

# ---------------------------
# Ask User Input
# ---------------------------
$dir = Read-Host "[?] Enter directory to host"
if (-not (Test-Path $dir)){
    Write-ErrorMsg "Directory does not exist!"
    exit
}

$hostProtocol = Read-Host "[?] Choose hosting protocol (1=Python, 2=PHP, 3=NodeJS, default=Python)"
if ($hostProtocol -eq ""){ $hostProtocol = "1" }

$port = Read-Host "[?] Enter port (default 8888)"
if ($port -eq ""){ $port = "8888" }

# ---------------------------
# Start Local Server
# ---------------------------
Write-Info "Starting local server..."
switch ($hostProtocol){
    "1" { Start-Process -NoNewWindow -FilePath python -ArgumentList "-m http.server $port" -WorkingDirectory $dir }
    "2" { Start-Process -NoNewWindow -FilePath php -ArgumentList "-S 127.0.0.1:$port" -WorkingDirectory $dir }
    "3" { Start-Process -NoNewWindow -FilePath http-server -ArgumentList "-p $port" -WorkingDirectory $dir }
    default { Write-ErrorMsg "Invalid protocol"; exit }
}
Start-Sleep -Seconds 2
Write-Success "Local server started on port $port!"

# ---------------------------
# Download Tunnelers (Ngrok + Cloudflared)
# ---------------------------
$home = $env:USERPROFILE

# Ngrok
$ngrokPath = "$home\.local2internet\ngrok.exe"
if (-not (Test-Path $ngrokPath)){
    Write-Info "Downloading Ngrok..."
    Invoke-WebRequest "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-windows-amd64.zip" -OutFile "$home\ngrok.zip"
    Expand-Archive "$home\ngrok.zip" -DestinationPath "$home\.local2internet"
    Remove-Item "$home\ngrok.zip"
}

# Cloudflared
$cfPath = "$home\.local2internet\cloudflared.exe"
if (-not (Test-Path $cfPath)){
    Write-Info "Downloading Cloudflared..."
    Invoke-WebRequest "https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/windows/Cloudflared-Windows-amd64.exe" -OutFile $cfPath
}

# ---------------------------
# Start Tunnels
# ---------------------------
Write-Info "Starting tunnels..."
Start-Process -NoNewWindow -FilePath $ngrokPath -ArgumentList "http $port"
Start-Process -NoNewWindow -FilePath $cfPath -ArgumentList "tunnel --url http://127.0.0.1:$port"

Write-Success "Tunnelers started! Visit your public URLs from Ngrok & Cloudflared"

Write-Host "`n[!] Press CTRL+C to exit"
while ($true){ Start-Sleep -Seconds 86400 }
