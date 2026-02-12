# =========================================
# Local2Internet v4.1 - Advanced Auto Installer
# Platform: Windows PowerShell
# Author: Muhammad Taezeem Tariq Matta
# =========================================

#Requires -Version 5.1

$ErrorActionPreference = "Stop"

# Colors
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

# Logo
$LOGO = @"
$($C.Red)
▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀
$($C.Yellow)▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░
$($C.Green)▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░
$($C.Blue)                                      [Auto Installer v4.1 Advanced]
$($C.Reset)
"@

Clear-Host
Write-Host $LOGO
Write-Info "Starting Local2Internet Advanced installation..."
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-ErrorMsg "PowerShell 5.1 or higher is required!"
    Write-ErrorMsg "Current version: $($PSVersionTable.PSVersion)"
    exit 1
}

Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warn "Not running as Administrator"
    Write-Warn "Some features may require elevated privileges"
    Write-Host ""
}

# Check Chocolatey
Write-Info "Checking for Chocolatey..."
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Warn "Chocolatey not found!"
    Write-Host ""
    Write-Host "Chocolatey is required to install dependencies automatically."
    Write-Host "Visit: https://chocolatey.org/install"
    Write-Host ""
    
    $install = Read-Host "Install Chocolatey now? (Y/n)"
    
    if ($install -ne 'n' -and $install -ne 'N') {
        if (-not $isAdmin) {
            Write-ErrorMsg "Administrator privileges required to install Chocolatey!"
            Write-Info "Please run this script as Administrator or install Chocolatey manually."
            exit 1
        }
        
        Write-Info "Installing Chocolatey..."
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            
            # Refresh environment
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            
            Write-Success "Chocolatey installed successfully!"
        } catch {
            Write-ErrorMsg "Failed to install Chocolatey: $_"
            exit 1
        }
    } else {
        Write-ErrorMsg "Chocolatey is required. Installation cancelled."
        exit 1
    }
} else {
    Write-Success "Chocolatey is installed ($(choco --version))"
}

Write-Host ""

# Install dependencies
Write-Info "Checking dependencies..."
Write-Host ""

$dependencies = @{
    "ruby" = "ruby"
    "python" = "python3"
    "node" = "nodejs"
    "php" = "php"
    "git" = "git"
}

$toInstall = @()

foreach ($cmd in $dependencies.Keys) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        $version = switch ($cmd) {
            "ruby" { (ruby --version 2>$null).Split()[1] }
            "python" { (python --version 2>$null).Split()[1] }
            "node" { (node --version 2>$null) }
            "php" { (php --version 2>$null).Split()[0].Split()[1] }
            "git" { (git --version 2>$null).Split()[2] }
        }
        Write-Success "  → $cmd already installed ($version)"
    } else {
        Write-Info "  → $cmd not found, will install"
        $toInstall += $dependencies[$cmd]
    }
}

Write-Host ""

if ($toInstall.Count -gt 0) {
    if (-not $isAdmin) {
        Write-ErrorMsg "Administrator privileges required to install dependencies!"
        Write-Info "Please run this script as Administrator."
        Write-Host ""
        Write-Info "Missing packages: $($toInstall -join ', ')"
        exit 1
    }
    
    Write-Info "Installing missing packages: $($toInstall -join ', ')"
    Write-Host ""
    
    foreach ($pkg in $toInstall) {
        try {
            Write-Info "Installing $pkg..."
            $output = choco install $pkg -y --force 2>&1
            Write-Success "$pkg installed!"
        } catch {
            Write-Warn "Failed to install $pkg (non-critical)"
        }
    }
    
    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    
    Write-Host ""
    Write-Success "All dependencies installed!"
} else {
    Write-Success "All dependencies already installed!"
}

Write-Host ""

# Install npm packages
Write-Info "Checking npm packages..."
if (Get-Command npm -ErrorAction SilentlyContinue) {
    try {
        $httpServer = npm list -g http-server 2>$null | Select-String "http-server"
        
        if (-not $httpServer) {
            Write-Info "Installing http-server..."
            npm install -g http-server 2>&1 | Out-Null
            Write-Success "http-server installed!"
        } else {
            Write-Success "http-server already installed"
        }
    } catch {
        Write-Warn "Could not verify http-server installation"
    }
} else {
    Write-Warn "npm not found, skipping http-server installation"
}

Write-Host ""

# Clone repository
$installDir = "$env:USERPROFILE\Local2Internet"

if (Test-Path $installDir) {
    Write-Warn "Local2Internet directory already exists at: $installDir"
    $response = Read-Host "Remove and reinstall? (y/N)"
    
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Info "Removing old installation..."
        Remove-Item -Path $installDir -Recurse -Force
        Write-Success "Old installation removed"
    } else {
        Write-Info "Updating existing installation..."
        try {
            Push-Location $installDir
            $output = git pull origin main 2>&1
            Write-Success "Repository updated!"
            Pop-Location
            
            Write-Host ""
            Write-Host "$($C.Green)╔════════════════════════════════════════╗$($C.Reset)"
            Write-Host "$($C.Green)║       UPDATE SUCCESSFUL! 🎉            ║$($C.Reset)"
            Write-Host "$($C.Green)╚════════════════════════════════════════╝$($C.Reset)"
            Write-Host ""
            
            Write-Success "Local2Internet updated successfully!"
            Write-Host ""
            Write-Info "To run Local2Internet:"
            Write-Host "  $($C.Yellow)cd $installDir$($C.Reset)"
            
            if (Test-Path "$installDir\l2in_advanced.ps1") {
                Write-Host "  $($C.Yellow).\l2in_advanced.ps1$($C.Reset)"
            } else {
                Write-Host "  $($C.Yellow).\l2in.ps1$($C.Reset)"
            }
            Write-Host ""
            exit 0
        } catch {
            Write-Warn "Failed to update repository: $_"
        }
    }
}

Write-Info "Cloning Local2Internet repository..."
try {
    $output = git clone https://github.com/Taezeem14/Local2Internet.git $installDir 2>&1
    Write-Success "Repository cloned!"
} catch {
    Write-ErrorMsg "Failed to clone repository: $_"
    exit 1
}

Write-Host ""

# Set execution policy for the script
Write-Info "Setting execution policy..."
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
    Write-Success "Execution policy set!"
} catch {
    Write-Warn "Could not set execution policy (non-critical)"
}

Write-Host ""

# Create shortcut (optional)
$createShortcut = Read-Host "Create Desktop shortcut? (Y/n)"

if ($createShortcut -ne 'n' -and $createShortcut -ne 'N') {
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Local2Internet.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        
        # Use advanced version if available
        if (Test-Path "$installDir\l2in_advanced.ps1") {
            $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\l2in_advanced.ps1`""
        } else {
            $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\l2in.ps1`""
        }
        
        $Shortcut.WorkingDirectory = $installDir
        $Shortcut.IconLocation = "powershell.exe,0"
        $Shortcut.Description = "Local2Internet v4.1 Advanced - Expose localhost to internet"
        $Shortcut.Save()
        
        Write-Success "Desktop shortcut created!"
    } catch {
        Write-Warn "Failed to create shortcut (non-critical)"
    }
}

Write-Host ""

# Add to PATH (optional)
$addToPath = Read-Host "Add Local2Internet to PATH? (Y/n)"

if ($addToPath -ne 'n' -and $addToPath -ne 'N') {
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        
        if ($currentPath -notlike "*$installDir*") {
            [Environment]::SetEnvironmentVariable("Path", "$currentPath;$installDir", "User")
            $env:Path += ";$installDir"
            Write-Success "Added to PATH! You can now run scripts from anywhere"
        } else {
            Write-Success "Already in PATH"
        }
    } catch {
        Write-Warn "Failed to add to PATH (non-critical)"
    }
}

Write-Host ""
Write-Host "$($C.Green)╔════════════════════════════════════════╗$($C.Reset)"
Write-Host "$($C.Green)║     INSTALLATION SUCCESSFUL! 🎉        ║$($C.Reset)"
Write-Host "$($C.Green)╚════════════════════════════════════════╝$($C.Reset)"
Write-Host ""

Write-Success "Local2Internet v4.1 Advanced installed successfully!"
Write-Host ""
Write-Info "Installation location: $($C.Yellow)$installDir$($C.Reset)"
Write-Host ""
Write-Info "New features in v4.1:"
Write-Host "  $($C.Cyan)• API Key Support (Ngrok & Loclx)$($C.Reset)"
Write-Host "  $($C.Cyan)• Enhanced Error Handling$($C.Reset)"
Write-Host "  $($C.Cyan)• Auto Port Detection$($C.Reset)"
Write-Host "  $($C.Cyan)• Configuration Persistence$($C.Reset)"
Write-Host "  $($C.Cyan)• Improved Tunnel Reliability$($C.Reset)"
Write-Host ""
Write-Info "To start using Local2Internet:"
Write-Host "  $($C.Yellow)cd $installDir$($C.Reset)"

if (Test-Path "$installDir\l2in_advanced.ps1") {
    Write-Host "  $($C.Yellow).\l2in_advanced.ps1$($C.Reset)"
} else {
    Write-Host "  $($C.Yellow).\l2in.ps1$($C.Reset)"
}
Write-Host ""

if ($addToPath -ne 'n' -and $addToPath -ne 'N') {
    Write-Info "Or simply run the script from anywhere (after restarting terminal)"
    Write-Host ""
}

# Ask to run now
$runNow = Read-Host "Run Local2Internet now? (Y/n)"

if ($runNow -ne 'n' -and $runNow -ne 'N') {
    Write-Host ""
    Write-Info "Starting Local2Internet..."
    Start-Sleep -Seconds 1
    Set-Location $installDir
    
    if (Test-Path ".\l2in_advanced.ps1") {
        & ".\l2in_advanced.ps1"
    } else {
        & ".\l2in.ps1"
    }
} else {
    Write-Host ""
    Write-Info "Thanks for installing! Happy tunneling! 🚀"
    Write-Host ""
}
