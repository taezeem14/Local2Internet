# =========================================
# Local2Internet v6.1 NEXT-GEN - Ultra Installer
# Platform: Windows PowerShell 5.1+
# Author: Muhammad Taezeem Tariq Matta (Bro)
# Enhanced: Claude AI (2026)
# =========================================

#Requires -Version 5.1

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# ---------------------------
# Modern Color System
# ---------------------------
$ESC = [char]27

function RGB($r, $g, $b) { return "$ESC[38;2;${r};${g};${b}m" }

$C = @{
    # Gradient Colors
    Purple = (RGB 139 92 246)
    LightPurple = (RGB 167 139 250)
    Blue = (RGB 59 130 246)
    LightBlue = (RGB 96 165 250)
    Green = (RGB 34 197 94)
    LightGreen = (RGB 74 222 128)
    Yellow = (RGB 251 191 36)
    Orange = (RGB 251 146 60)
    Red = (RGB 239 68 68)
    Cyan = (RGB 34 211 238)
    Pink = (RGB 236 72 153)
    
    # Effects
    Reset = "$ESC[0m"
    Bold = "$ESC[1m"
    Dim = "$ESC[2m"
}

# ---------------------------
# UI Helper Functions
# ---------------------------
function Show-Gradient($text, $color1, $color2) {
    if ($text.Length -le 1) { return "$color1$text$($C.Reset)" }
    
    $chars = $text.ToCharArray()
    $result = ""
    
    for ($i = 0; $i -lt $chars.Length; $i++) {
        $ratio = $i / [Math]::Max(($chars.Length - 1), 1)
        if ($ratio -lt 0.5) {
            $result += "$color1$($chars[$i])"
        } else {
            $result += "$color2$($chars[$i])"
        }
    }
    
    return $result + $C.Reset
}

function Write-Info($msg) { 
    Write-Host "$(Show-Gradient "▸" $C.Cyan $C.LightBlue) $($C.Bold)$msg$($C.Reset)" 
}

function Write-Success($msg) { 
    Write-Host "$(Show-Gradient "✓" $C.Green $C.LightGreen) $msg$($C.Reset)" 
}

function Write-ErrorMsg($msg) { 
    Write-Host "$(Show-Gradient "✗" $C.Red $C.Orange) $msg$($C.Reset)" 
}

function Write-Warn($msg) { 
    Write-Host "$(Show-Gradient "⚠" $C.Orange $C.Yellow) $msg$($C.Reset)" 
}

function Show-Progress($current, $total, $label) {
    if ($total -le 0) { return }
    $percentage = [Math]::Round(($current / $total) * 100)
    $filled = [Math]::Max(0, [Math]::Min(30, [Math]::Round((30 * $current) / $total)))
    $empty = [Math]::Max(0, 30 - $filled)
    
    $bar = "$($C.Green)$('█' * $filled)$($C.Dim)$('░' * $empty)$($C.Reset)"
    Write-Host -NoNewline "`r  $bar $($C.Bold)$percentage%$($C.Reset) $($C.Dim)$label$($C.Reset)  "
    
    if ($current -ge $total) { Write-Host "" }
}

function Show-Spinner($message, $scriptBlock) {
    $frames = @('⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷')
    $i = 0
    $completed = $false
    
    $job = Start-Job -ScriptBlock $scriptBlock
    
    try {
        while ($job.State -eq "Running") {
            Write-Host -NoNewline "`r$($C.Cyan)$($frames[$i])$($C.Reset) $($C.Bold)$message$($C.Reset)  "
            $i = ($i + 1) % $frames.Count
            Start-Sleep -Milliseconds 100
        }
        
        Write-Host "`r$(' ' * 100)`r" -NoNewline
        
        $result = Receive-Job $job -ErrorAction Stop
        return $result
    }
    catch {
        Write-Host "`r$(' ' * 100)`r" -NoNewline
        throw
    }
    finally {
        Remove-Job $job -Force -ErrorAction SilentlyContinue
    }
}

# ---------------------------
# Modern Logo
# ---------------------------
$LOGO = @"
$(Show-Gradient "╔═══════════════════════════════════════════════════════════════════╗" $C.Purple $C.Pink)
$(Show-Gradient "║" $C.Purple $C.Pink)  $(Show-Gradient "██╗      ██████╗  ██████╗ █████╗ ██╗     ██████╗ ██╗███╗   ██╗████████╗" $C.Cyan $C.Blue)  $(Show-Gradient "║" $C.Purple $C.Pink)
$(Show-Gradient "║" $C.Purple $C.Pink)  $(Show-Gradient "██║     ██╔═══██╗██╔════╝██╔══██╗██║     ╚════██╗██║████╗  ██║╚══██╔══╝" $C.Cyan $C.Blue)  $(Show-Gradient "║" $C.Purple $C.Pink)
$(Show-Gradient "║" $C.Purple $C.Pink)  $(Show-Gradient "██║     ██║   ██║██║     ███████║██║      █████╔╝██║██╔██╗ ██║   ██║   " $C.Cyan $C.Blue)  $(Show-Gradient "║" $C.Purple $C.Pink)
$(Show-Gradient "║" $C.Purple $C.Pink)  $(Show-Gradient "██║     ██║   ██║██║     ██╔══██║██║     ██╔═══╝ ██║██║╚██╗██║   ██║   " $C.Cyan $C.Blue)  $(Show-Gradient "║" $C.Purple $C.Pink)
$(Show-Gradient "║" $C.Purple $C.Pink)  $(Show-Gradient "███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║   " $C.Cyan $C.Blue)  $(Show-Gradient "║" $C.Purple $C.Pink)
$(Show-Gradient "║" $C.Purple $C.Pink)  $(Show-Gradient "╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝   " $C.Cyan $C.Blue)  $(Show-Gradient "║" $C.Purple $C.Pink)
$(Show-Gradient "╚═══════════════════════════════════════════════════════════════════╝" $C.Purple $C.Pink)

       $($C.Bold)$(Show-Gradient "▸ v6.1 NEXT-GEN Ultra Installer" $C.Green $C.LightGreen)$($C.Reset) $($C.Dim)• Bug-Free Edition$($C.Reset)
           $($C.Dim)Automated Dependency Management • Smart Error Recovery$($C.Reset)

"@

# ---------------------------
# Main Installation
# ---------------------------
Clear-Host
Write-Host $LOGO

Write-Info "Starting Local2Internet v6.1 installation..."
Write-Host ""

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-ErrorMsg "PowerShell 5.1 or higher is required!"
    Write-ErrorMsg "Current version: $($PSVersionTable.PSVersion)"
    Write-Host ""
    Write-Host "$($C.Dim)Download PowerShell 7: https://aka.ms/powershell$($C.Reset)"
    exit 1
}

Write-Success "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warn "Not running as Administrator"
    Write-Host "  $($C.Dim)Some features may require elevated privileges$($C.Reset)"
    Write-Host ""
}

# Check Chocolatey
Write-Info "Checking for Chocolatey package manager..."
$chocoInstalled = $false

try {
    $null = Get-Command choco -ErrorAction Stop
    $chocoVersion = (choco --version 2>$null) -replace '[^0-9.]', ''
    Write-Success "Chocolatey is installed (v$chocoVersion)"
    $chocoInstalled = $true
}
catch {
    Write-Warn "Chocolatey not found!"
    Write-Host ""
    Write-Host "  Chocolatey is $($C.Bold)recommended$($C.Reset) for automatic dependency installation."
    Write-Host "  $($C.Dim)Visit: https://chocolatey.org/install$($C.Reset)"
    Write-Host ""
    
    $install = Read-Host "  Install Chocolatey now? (Y/n)"
    
    if ($install -ne 'n' -and $install -ne 'N') {
        if (-not $isAdmin) {
            Write-ErrorMsg "Administrator privileges required to install Chocolatey!"
            Write-Host ""
            Write-Host "  $($C.Yellow)Please restart this script as Administrator$($C.Reset)"
            Write-Host "  $($C.Dim)Right-click PowerShell → Run as Administrator$($C.Reset)"
            Write-Host ""
            pause
            exit 1
        }
        
        Write-Host ""
        Write-Info "Installing Chocolatey..."
        
        try {
            $result = Show-Spinner "Setting up Chocolatey" {
                Set-ExecutionPolicy Bypass -Scope Process -Force -ErrorAction Stop
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                
                $installScript = (New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')
                Invoke-Expression $installScript
                
                # Refresh PATH
                $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            }
            
            Write-Success "Chocolatey installed successfully!"
            $chocoInstalled = $true
        }
        catch {
            Write-ErrorMsg "Failed to install Chocolatey: $_"
            Write-Host ""
            Write-Warn "Continuing without Chocolatey (manual dependency installation required)"
            Start-Sleep -Seconds 2
        }
    }
    else {
        Write-Host ""
        Write-Warn "Continuing without Chocolatey"
        Write-Host "  $($C.Dim)You'll need to install dependencies manually$($C.Reset)"
        Start-Sleep -Seconds 2
    }
}

Write-Host ""

# Install dependencies
Write-Info "Checking dependencies..."
Write-Host ""

$dependencies = [ordered]@{
    "ruby" = @{ package = "ruby"; displayName = "Ruby" }
    "python" = @{ package = "python3"; displayName = "Python 3" }
    "node" = @{ package = "nodejs"; displayName = "Node.js" }
    "php" = @{ package = "php"; displayName = "PHP" }
    "git" = @{ package = "git"; displayName = "Git" }
}

$toInstall = @()
$installedCount = 0

foreach ($cmd in $dependencies.Keys) {
    $dep = $dependencies[$cmd]
    
    try {
        $null = Get-Command $cmd -ErrorAction Stop
        
        $version = switch ($cmd) {
            "ruby" { try { (ruby --version 2>$null).Split()[1] } catch { "unknown" } }
            "python" { try { (python --version 2>$null).Split()[1] } catch { "unknown" } }
            "node" { try { (node --version 2>$null) } catch { "unknown" } }
            "php" { try { (php --version 2>$null).Split()[0..1] -join ' ' } catch { "unknown" } }
            "git" { try { (git --version 2>$null).Split()[2] } catch { "unknown" } }
        }
        
        Write-Success "  $($dep.displayName) installed ($version)"
        $installedCount++
    }
    catch {
        Write-Host "  $($C.Dim)→ $($dep.displayName) not found$($C.Reset)"
        $toInstall += $dep.package
    }
}

Write-Host ""
Show-Progress $installedCount $dependencies.Count "Dependencies checked"
Write-Host ""

if ($toInstall.Count -gt 0) {
    if (-not $chocoInstalled) {
        Write-Warn "Missing dependencies: $($toInstall -join ', ')"
        Write-Host ""
        Write-Host "  Please install these manually:"
        foreach ($pkg in $toInstall) {
            Write-Host "    $($C.Cyan)•$($C.Reset) $pkg"
        }
        Write-Host ""
        Write-Host "  $($C.Dim)Or restart this script as Administrator to auto-install via Chocolatey$($C.Reset)"
        Write-Host ""
    }
    else {
        if (-not $isAdmin) {
            Write-ErrorMsg "Administrator privileges required to install dependencies!"
            Write-Host ""
            Write-Warn "Missing packages: $($toInstall -join ', ')"
            Write-Host ""
            Write-Host "  $($C.Yellow)Please restart this script as Administrator$($C.Reset)"
            Write-Host "  $($C.Dim)Right-click PowerShell → Run as Administrator$($C.Reset)"
            Write-Host ""
            pause
            exit 1
        }
        
        Write-Info "Installing missing packages: $($toInstall -join ', ')"
        Write-Host ""
        
        $successCount = 0
        foreach ($pkg in $toInstall) {
            try {
                Write-Host "  $($C.Cyan)→$($C.Reset) Installing $pkg..."
                
                $output = choco install $pkg -y --force --limit-output 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "  $pkg installed!"
                    $successCount++
                }
                else {
                    Write-Warn "  $pkg installation had warnings (may still work)"
                }
            }
            catch {
                Write-Warn "  Failed to install $pkg (non-critical)"
            }
        }
        
        Write-Host ""
        Show-Progress $successCount $toInstall.Count "Packages installed"
        Write-Host ""
        
        # Refresh PATH
        try {
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
            Write-Success "Environment refreshed!"
        }
        catch {
            Write-Warn "Could not refresh environment (restart terminal after installation)"
        }
    }
}
else {
    Write-Success "All dependencies already installed!"
}

Write-Host ""

# Install npm packages
Write-Info "Checking npm packages..."

if (Get-Command npm -ErrorAction SilentlyContinue) {
    try {
        $httpServerCheck = npm list -g http-server 2>$null
        
        if ($httpServerCheck -notmatch "http-server@") {
            Write-Host "  $($C.Dim)→ http-server not found$($C.Reset)"
            Write-Host ""
            Write-Info "Installing http-server..."
            
            $npmOutput = npm install -g http-server 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "http-server installed!"
            }
            else {
                Write-Warn "http-server installation had warnings (may still work)"
            }
        }
        else {
            Write-Success "http-server already installed"
        }
    }
    catch {
        Write-Warn "Could not verify http-server installation (non-critical)"
    }
}
else {
    Write-Warn "npm not found, skipping http-server installation"
}

Write-Host ""

# Clone repository
$installDir = "$env:USERPROFILE\Local2Internet"
$repoUrl = "https://github.com/Taezeem14/Local2Internet.git"

if (Test-Path $installDir) {
    Write-Warn "Local2Internet directory already exists"
    Write-Host "  $($C.Dim)Location: $installDir$($C.Reset)"
    Write-Host ""
    
    $response = Read-Host "  Remove and reinstall? (y/N)"
    
    if ($response -eq 'y' -or $response -eq 'Y') {
        Write-Host ""
        Write-Info "Removing old installation..."
        
        try {
            Remove-Item -Path $installDir -Recurse -Force -ErrorAction Stop
            Write-Success "Old installation removed"
        }
        catch {
            Write-ErrorMsg "Failed to remove old installation: $_"
            Write-Host ""
            Write-Host "  $($C.Yellow)Please manually delete: $installDir$($C.Reset)"
            pause
            exit 1
        }
    }
    else {
        Write-Host ""
        Write-Info "Updating existing installation..."
        
        try {
            Push-Location $installDir -ErrorAction Stop
            
            $gitOutput = git pull origin main 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                Write-Success "Repository updated!"
            }
            else {
                Write-Warn "Update had warnings: $gitOutput"
            }
            
            Pop-Location
            
            Write-Host ""
            Write-Host "$(Show-Gradient "╔════════════════════════════════════════════╗" $C.Green $C.LightGreen)"
            Write-Host "$(Show-Gradient "║" $C.Green $C.LightGreen)  $($C.Bold)UPDATE SUCCESSFUL! 🎉$($C.Reset)                $(Show-Gradient "║" $C.Green $C.LightGreen)"
            Write-Host "$(Show-Gradient "╚════════════════════════════════════════════╝" $C.Green $C.LightGreen)"
            Write-Host ""
            
            Write-Success "Local2Internet updated successfully!"
            Write-Host ""
            Write-Info "To run Local2Internet:"
            Write-Host "  $($C.Yellow)cd $installDir$($C.Reset)"
            Write-Host "  $($C.Yellow).\l2in_nexgen.ps1$($C.Reset)"
            Write-Host ""
            pause
            exit 0
        }
        catch {
            Write-ErrorMsg "Failed to update repository: $_"
            Write-Host ""
            pause
            exit 1
        }
    }
}

Write-Host ""
Write-Info "Cloning Local2Internet repository..."
Write-Host "  $($C.Dim)Source: $repoUrl$($C.Reset)"
Write-Host ""

try {
    $cloneOutput = git clone $repoUrl $installDir 2>&1
    
    if ($LASTEXITCODE -eq 0 -and (Test-Path "$installDir\.git")) {
        Write-Success "Repository cloned successfully!"
    }
    else {
        throw "Git clone failed or repository incomplete"
    }
}
catch {
    Write-ErrorMsg "Failed to clone repository: $_"
    Write-Host ""
    Write-Host "  $($C.Yellow)Please check your internet connection and try again$($C.Reset)"
    Write-Host "  $($C.Dim)Or manually clone: git clone $repoUrl$($C.Reset)"
    Write-Host ""
    pause
    exit 1
}

Write-Host ""

# Set execution policy
Write-Info "Configuring execution policy..."

try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
    Write-Success "Execution policy set to RemoteSigned"
}
catch {
    Write-Warn "Could not set execution policy (non-critical)"
}

Write-Host ""

# Create shortcut (optional)
$createShortcut = Read-Host "Create Desktop shortcut? (Y/n)"

if ($createShortcut -ne 'n' -and $createShortcut -ne 'N') {
    Write-Host ""
    Write-Info "Creating desktop shortcut..."
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell -ErrorAction Stop
        $Shortcut = $WshShell.CreateShortcut("$env:USERPROFILE\Desktop\Local2Internet.lnk")
        $Shortcut.TargetPath = "powershell.exe"
        
        # Use Next-Gen version if available
        if (Test-Path "$installDir\l2in_nexgen.ps1") {
            $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\l2in_nexgen.ps1`""
        }
        else {
            $Shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\l2in.ps1`""
        }
        
        $Shortcut.WorkingDirectory = $installDir
        $Shortcut.IconLocation = "powershell.exe,0"
        $Shortcut.Description = "Local2Internet v6.1 NEXT-GEN - Expose localhost to internet"
        $Shortcut.Save()
        
        Write-Success "Desktop shortcut created!"
    }
    catch {
        Write-Warn "Failed to create shortcut: $_"
    }
}

Write-Host ""

# Add to PATH (optional)
$addToPath = Read-Host "Add Local2Internet to PATH? (Y/n)"

if ($addToPath -ne 'n' -and $addToPath -ne 'N') {
    Write-Host ""
    Write-Info "Adding to system PATH..."
    
    try {
        $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
        
        if ($currentPath -notlike "*$installDir*") {
            $newPath = "$currentPath;$installDir"
            [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
            $env:Path += ";$installDir"
            
            Write-Success "Added to PATH! Restart terminal to use from anywhere"
        }
        else {
            Write-Success "Already in PATH"
        }
    }
    catch {
        Write-Warn "Failed to add to PATH: $_"
    }
}

# Success screen
Write-Host ""
Write-Host "$(Show-Gradient "╔════════════════════════════════════════════╗" $C.Green $C.LightGreen)"
Write-Host "$(Show-Gradient "║" $C.Green $C.LightGreen)  $($C.Bold)INSTALLATION SUCCESSFUL! 🎉$($C.Reset)          $(Show-Gradient "║" $C.Green $C.LightGreen)"
Write-Host "$(Show-Gradient "╚════════════════════════════════════════════╝" $C.Green $C.LightGreen)"
Write-Host ""

Write-Success "Local2Internet v6.1 NEXT-GEN installed successfully!"
Write-Host ""
Write-Info "Installation location:"
Write-Host "  $($C.Yellow)$installDir$($C.Reset)"
Write-Host ""
Write-Info "New features in v6.1:"
Write-Host "  $($C.Cyan)• Ultra-Modern Terminal UI with Gradients$($C.Reset)"
Write-Host "  $($C.Cyan)• 6 Premium Themes (Cyberpunk, Matrix, Ocean...)$($C.Reset)"
Write-Host "  $($C.Cyan)• Bug-Free Error Handling & Recovery$($C.Reset)"
Write-Host "  $($C.Cyan)• Real-Time Analytics Dashboard$($C.Reset)"
Write-Host "  $($C.Cyan)• Enhanced API Key Management$($C.Reset)"
Write-Host "  $($C.Cyan)• Zero Crashes Guarantee$($C.Reset)"
Write-Host ""
Write-Info "To start using Local2Internet:"
Write-Host "  $($C.Yellow)cd $installDir$($C.Reset)"
Write-Host "  $($C.Yellow).\l2in_nexgen.ps1$($C.Reset)"
Write-Host ""

if ($addToPath -ne 'n' -and $addToPath -ne 'N') {
    Write-Host "  $($C.Dim)Or run from anywhere after restarting terminal$($C.Reset)"
    Write-Host ""
}

# Ask to run now
$runNow = Read-Host "Run Local2Internet now? (Y/n)"

if ($runNow -ne 'n' -and $runNow -ne 'N') {
    Write-Host ""
    Write-Info "Starting Local2Internet v6.1 NEXT-GEN..."
    Start-Sleep -Seconds 1
    Set-Location $installDir
    
    if (Test-Path ".\l2in_nexgen.ps1") {
        & ".\l2in_nexgen.ps1"
    }
    else {
        & ".\l2in.ps1"
    }
}
else {
    Write-Host ""
    Write-Info "Thanks for installing! Happy tunneling! 🚀"
    Write-Host ""
    Write-Host "$($C.Dim)Star the repo: https://github.com/Taezeem14/Local2Internet$($C.Reset)"
    Write-Host ""
}
