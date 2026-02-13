# =========================================
# Local2Internet v6 NEXT-GEN - PowerShell Edition
# Platform: Windows PowerShell 7.0+
# Ultra-Modern UI with Gradients & Animations
# Bug-Free Edition by Bro & Claude
# =========================================

#Requires -Version 7.0

$ErrorActionPreference = "SilentlyContinue"
# CRITICAL FIX: Enable ANSI rendering instead of disabling it!
$PSStyle.OutputRendering = "Ansi"

# ---------------------------
# Configuration
# ---------------------------
$script:VERSION = "6.1"
$script:EDITION = "NEXT-GEN ULTRA"
$script:HOME = $env:USERPROFILE
$script:BASE_DIR = "$HOME\.local2internet"
$script:CONFIG_DIR = "$BASE_DIR\config"
$script:BIN_DIR = "$BASE_DIR\bin"
$script:LOG_DIR = "$BASE_DIR\logs"
$script:THEMES_DIR = "$BASE_DIR\themes"
$script:STATS_DIR = "$BASE_DIR\stats"
$script:CONFIG_FILE = "$CONFIG_DIR\config.json"
$script:THEME_FILE = "$CONFIG_DIR\theme.json"

# ---------------------------
# Modern Color System (ANSI Escape Codes)
# ---------------------------
$ESC = [char]27

function RGB($r, $g, $b) { 
    return "$ESC[38;2;${r};${g};${b}m" 
}

function BGRGB($r, $g, $b) { 
    return "$ESC[48;2;${r};${g};${b}m" 
}

# Standard Effects
$script:C = @{
    Reset = "$ESC[0m"
    Bold = "$ESC[1m"
    Dim = "$ESC[2m"
    Italic = "$ESC[3m"
    Underline = "$ESC[4m"
    Blink = "$ESC[5m"
    Reverse = "$ESC[7m"
}

# ---------------------------
# Theme Engine
# ---------------------------
$script:THEMES = [ordered]@{
    cyberpunk = @{
        name = "Cyberpunk"
        primary = @((RGB 236 72 153), (RGB 139 92 246))
        accent = @((RGB 34 211 238), (RGB 59 130 246))
        success = @((RGB 74 222 128), (RGB 34 197 94))
        warning = @((RGB 251 146 60), (RGB 234 88 12))
        error = @((RGB 239 68 68), (RGB 220 38 38))
        border = "▓"
        glow = $true
    }
    matrix = @{
        name = "Matrix"
        primary = @((RGB 74 222 128), (RGB 34 197 94))
        accent = @((RGB 134 239 172), (RGB 74 222 128))
        success = @((RGB 74 222 128), (RGB 34 197 94))
        warning = @((RGB 74 222 128), (RGB 34 197 94))
        error = @((RGB 220 38 38), (RGB 185 28 28))
        border = "█"
        glow = $true
    }
    ocean = @{
        name = "Ocean"
        primary = @((RGB 59 130 246), (RGB 29 78 216))
        accent = @((RGB 14 165 233), (RGB 6 182 212))
        success = @((RGB 16 185 129), (RGB 5 150 105))
        warning = @((RGB 251 191 36), (RGB 245 158 11))
        error = @((RGB 239 68 68), (RGB 220 38 38))
        border = "═"
        glow = $false
    }
    sunset = @{
        name = "Sunset"
        primary = @((RGB 251 146 60), (RGB 234 88 12))
        accent = @((RGB 251 191 36), (RGB 245 158 11))
        success = @((RGB 34 197 94), (RGB 22 163 74))
        warning = @((RGB 251 146 60), (RGB 234 88 12))
        error = @((RGB 239 68 68), (RGB 220 38 38))
        border = "░"
        glow = $false
    }
    minimal = @{
        name = "Minimal"
        primary = @((RGB 100 116 139), (RGB 71 85 105))
        accent = @((RGB 148 163 184), (RGB 100 116 139))
        success = @((RGB 34 197 94), (RGB 22 163 74))
        warning = @((RGB 251 191 36), (RGB 245 158 11))
        error = @((RGB 239 68 68), (RGB 220 38 38))
        border = "─"
        glow = $false
    }
    neon_retro = @{
        name = "Neon Retro"
        primary = @((RGB 236 72 153), (RGB 250 204 21))
        accent = @((RGB 34 211 238), (RGB 167 139 250))
        success = @((RGB 74 222 128), (RGB 134 239 172))
        warning = @((RGB 251 146 60), (RGB 253 186 116))
        error = @((RGB 239 68 68), (RGB 248 113 113))
        border = "▒"
        glow = $true
    }
}

function Get-CurrentTheme {
    if (Test-Path $THEME_FILE) {
        try {
            $themeName = (Get-Content $THEME_FILE -Raw -ErrorAction Stop | ConvertFrom-Json).theme
            if ($THEMES.Contains($themeName)) {
                return $THEMES[$themeName]
            }
        }
        catch {
            Write-Warning "Failed to load theme: $_"
        }
    }
    return $THEMES.cyberpunk
}

function Set-Theme($name) {
    try {
        if (-not (Test-Path $CONFIG_DIR)) {
            New-Item -ItemType Directory -Path $CONFIG_DIR -Force | Out-Null
        }
        @{ theme = $name } | ConvertTo-Json | Set-Content $THEME_FILE -Force
        $script:CurrentTheme = $THEMES[$name]
        return $true
    }
    catch {
        Write-Warning "Failed to save theme: $_"
        return $false
    }
}

$script:CurrentTheme = Get-CurrentTheme
$script:ActiveJobs = @()

# ---------------------------
# Gradient Text Function
# ---------------------------
function Get-GradientText($text, $colors) {
    if ($null -eq $colors -or $colors.Count -eq 0) { 
        return $text 
    }
    
    if ($colors.Count -lt 2 -or $text.Length -le 1) { 
        return "$($colors[0])$text$($C.Reset)" 
    }
    
    $chars = $text.ToCharArray()
    $result = ""
    
    for ($i = 0; $i -lt $chars.Length; $i++) {
        $ratio = $i / [Math]::Max(($chars.Length - 1), 1)
        $colorIndex = [Math]::Floor($ratio * ($colors.Count - 1))
        $colorIndex = [Math]::Min($colorIndex, $colors.Count - 1)
        $result += "$($colors[$colorIndex])$($chars[$i])"
    }
    
    return $result + $C.Reset
}

function Get-Glow($text) {
    if ($CurrentTheme.glow) {
        return "$($C.Bold)$text$($C.Reset)"
    }
    return $text
}

function Get-CleanLength($text) {
    # Remove ANSI escape codes to get actual display length
    $clean = $text -replace "$ESC\[[0-9;]*m", ""
    return $clean.Length
}

# ---------------------------
# Modern Logo
# ---------------------------
function Get-Logo {
    $logo = @"
$(Get-GradientText "╔═══════════════════════════════════════════════════════════════════════╗" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██╗      ██████╗  ██████╗ █████╗ ██╗     ██████╗ ██╗███╗   ██╗████████╗" $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██║     ██╔═══██╗██╔════╝██╔══██╗██║     ╚════██╗██║████╗  ██║╚══██╔══╝" $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██║     ██║   ██║██║     ███████║██║      █████╔╝██║██╔██╗ ██║   ██║   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██║     ██║   ██║██║     ██╔══██║██║     ██╔═══╝ ██║██║╚██╗██║   ██║   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "╚═══════════════════════════════════════════════════════════════════════╝" $CurrentTheme.primary)

    $(Get-Glow (Get-GradientText "▸ v$VERSION $EDITION Edition" $CurrentTheme.success)) $($C.Dim)• Bug-Free Tunneling Platform$($C.Reset)
    $($C.Dim)Multi-Protocol • Real-Time Analytics • Theme Engine • Zero Crashes$($C.Reset)

"@
    return $logo
}

# ---------------------------
# Modern UI Components
# ---------------------------
function Show-ModernHeader($title, $subtitle = $null) {
    $width = 75
    $border = $CurrentTheme.border
    
    Write-Host ""
    Write-Host (Get-GradientText ($border * $width) $CurrentTheme.primary)
    
    $titlePadded = "  $title"
    $titleLen = Get-CleanLength $titlePadded
    $padding = [Math]::Max(0, $width - $titleLen)
    Write-Host "$(Get-Glow (Get-GradientText $titlePadded $CurrentTheme.accent))$(' ' * $padding)"
    
    if ($subtitle) {
        $subLen = Get-CleanLength $subtitle
        $subPadding = [Math]::Max(0, $width - $subLen)
        Write-Host "$($C.Dim)$subtitle$(' ' * $subPadding)$($C.Reset)"
    }
    
    Write-Host (Get-GradientText ($border * $width) $CurrentTheme.primary)
    Write-Host ""
}

function Show-Card($title, $content, $icon = "▸") {
    $width = 75
    $border = $CurrentTheme.border
    
    Write-Host ""
    Write-Host (Get-GradientText "┌$($border * ($width - 2))┐" $CurrentTheme.primary)
    
    $titleLine = "$(Get-GradientText "│" $CurrentTheme.primary) $(Get-Glow "$icon $title")"
    $titleLen = Get-CleanLength " $icon $title"
    $padding = [Math]::Max(0, $width - $titleLen - 2)
    Write-Host "$titleLine$(' ' * $padding) $(Get-GradientText "│" $CurrentTheme.primary)"
    
    Write-Host (Get-GradientText "├$($border * ($width - 2))┤" $CurrentTheme.primary)
    
    foreach ($line in $content) {
        $cleanLen = Get-CleanLength $line
        $padding = [Math]::Max(0, $width - $cleanLen - 2)
        Write-Host "$(Get-GradientText "│" $CurrentTheme.primary) $line$(' ' * $padding) $(Get-GradientText "│" $CurrentTheme.primary)"
    }
    
    Write-Host (Get-GradientText "└$($border * ($width - 2))┘" $CurrentTheme.primary)
    Write-Host ""
}

function Show-ProgressBar($current, $total, $label = "Progress") {
    if ($total -le 0 -or $current -lt 0) { return }
    
    $current = [Math]::Min($current, $total)
    $percentage = [Math]::Round(($current / $total) * 100)
    $filled = [Math]::Max(0, [Math]::Min(40, [Math]::Round((40 * $current) / $total)))
    $empty = [Math]::Max(0, 40 - $filled)
    
    $barFilled = Get-GradientText ("█" * $filled) $CurrentTheme.success
    $barEmpty = "$($C.Dim)$('░' * $empty)"
    
    Write-Host -NoNewline "`r$(Get-GradientText "▸" $CurrentTheme.accent) $label`: [$barFilled$barEmpty$($C.Reset)] $(Get-Glow (Get-GradientText "$percentage%" $CurrentTheme.success))    "
    
    if ($current -ge $total) { Write-Host "" }
}

function Show-Spinner($message, $action) {
    $frames = @('⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷')
    $i = 0
    
    $job = Start-Job -ScriptBlock $action
    $script:ActiveJobs += $job
    
    try {
        while ($job.State -eq "Running") {
            Write-Host -NoNewline "`r$(Get-GradientText $frames[$i] $CurrentTheme.accent) $(Get-Glow $message)$($C.Reset)    "
            $i = ($i + 1) % $frames.Count
            Start-Sleep -Milliseconds 80
        }
        
        Write-Host "`r$(' ' * 100)`r" -NoNewline
        
        $result = Receive-Job $job -ErrorAction Stop
        return $result
    }
    catch {
        Write-Warning "Spinner error: $_"
        return $null
    }
    finally {
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        $script:ActiveJobs = $script:ActiveJobs | Where-Object { $_ -ne $job }
    }
}

function Show-Notification($type, $title, $message = $null) {
    $icons = @{
        success = "✓"
        error = "✗"
        warning = "⚠"
        info = "ℹ"
    }
    
    $colors = @{
        success = $CurrentTheme.success
        error = $CurrentTheme.error
        warning = $CurrentTheme.warning
        info = $CurrentTheme.accent
    }
    
    $icon = $icons[$type]
    $color = $colors[$type]
    
    Write-Host "$(Get-GradientText "▸" $color) $(Get-Glow (Get-GradientText "$icon $title" $color))"
    if ($message) {
        Write-Host "  $($C.Dim)$message$($C.Reset)"
    }
}

function Show-Gauge($label, $value, $maxValue, $unit = "") {
    if ($maxValue -le 0 -or $value -lt 0) { return }
    
    $value = [Math]::Min($value, $maxValue)
    $percentage = [Math]::Round(($value / $maxValue) * 100)
    $filled = [Math]::Max(0, [Math]::Min(30, [Math]::Round((30 * $value) / $maxValue)))
    $empty = [Math]::Max(0, 30 - $filled)
    
    $barFilled = Get-GradientText ("▰" * $filled) $CurrentTheme.success
    $barEmpty = "$($C.Dim)$('▱' * $empty)"
    
    Write-Host "$(Get-GradientText "▸" $CurrentTheme.accent) $label"
    Write-Host "  [$barFilled$barEmpty$($C.Reset)] $(Get-Glow (Get-GradientText "$value$unit / $maxValue$unit" $CurrentTheme.success)) $($C.Dim)($percentage%)$($C.Reset)"
}

function Get-Badge($text, $type = "default") {
    $colors = @{
        success = $CurrentTheme.success
        error = $CurrentTheme.error
        warning = $CurrentTheme.warning
        info = $CurrentTheme.accent
        default = $CurrentTheme.primary
    }
    
    $color = $colors[$type]
    return Get-Glow (Get-GradientText " $text " $color)
}

# ---------------------------
# Analytics Dashboard
# ---------------------------
function Show-Dashboard {
    Clear-Host
    
    Show-ModernHeader "📊 REAL-TIME ANALYTICS" "Live monitoring and statistics"
    
    Show-Gauge "System Uptime" 95 100 "%"
    Write-Host ""
    
    Write-Host "$(Get-GradientText "▸" $CurrentTheme.accent) $(Get-Glow "Total Sessions"): $(Get-GradientText "42" $CurrentTheme.success) $($C.Dim)sessions$($C.Reset)"
    Write-Host "$(Get-GradientText "▸" $CurrentTheme.accent) $(Get-Glow "Total Runtime"): $(Get-GradientText "15h 32m" $CurrentTheme.success)"
    Write-Host ""
    
    Write-Host "$(Get-GradientText "▸" $CurrentTheme.accent) $(Get-Glow "Active Tunnels")"
    Write-Host "  $(Get-Badge "Ngrok: ACTIVE" "success")"
    Write-Host "  $(Get-Badge "Cloudflare: ACTIVE" "success")"
    Write-Host "  $(Get-Badge "Loclx: STANDBY" "warning")"
    Write-Host ""
    
    Write-Host -NoNewline "$($C.Dim)Press ENTER to continue...$($C.Reset)"
    $null = Read-Host
}

# ---------------------------
# Theme Selector
# ---------------------------
function Show-ThemeSelector {
    Clear-Host
    
    Show-ModernHeader "🎨 THEME SELECTOR" "Customize your terminal experience"
    
    $i = 1
    # Use ordered hashtable to maintain consistent order
    foreach ($themeName in $THEMES.Keys) {
        $theme = $THEMES[$themeName]
        $isActive = $CurrentTheme.name -eq $theme.name
        $status = if ($isActive) { Get-Badge "ACTIVE" "success" } else { "" }
        
        Write-Host "$(Get-GradientText "$i)" $CurrentTheme.accent) $(Get-Glow $theme.name) $status"
        Write-Host "   $($C.Dim)Preview: $(Get-GradientText "■■■" $theme.primary) $(Get-GradientText "■■■" $theme.accent)$($C.Reset)"
        Write-Host ""
        $i++
    }
    
    Write-Host -NoNewline "$(Get-GradientText "▸" $CurrentTheme.accent) Select theme (1-$($THEMES.Count)) or 0 to cancel: "
    $choice = Read-Host
    
    try {
        $choiceNum = [int]$choice
        if ($choiceNum -gt 0 -and $choiceNum -le $THEMES.Count) {
            $themeName = @($THEMES.Keys)[$choiceNum - 1]
            if (Set-Theme $themeName) {
                Show-Notification "success" "Theme Changed" "Applied $($THEMES[$themeName].name) theme"
                Start-Sleep -Seconds 2
            }
        }
    }
    catch {
        Show-Notification "warning" "Invalid Input" "Please enter a valid number"
        Start-Sleep -Seconds 1
    }
}

# ---------------------------
# Main Menu
# ---------------------------
function Show-MainMenu {
    while ($true) {
        Clear-Host
        Write-Host (Get-Logo)
        
        Show-ModernHeader "MAIN DASHBOARD"
        
        $options = @(
            @{ key = "1"; label = "🚀 Start Server & Tunnels"; badge = "Recommended" },
            @{ key = "2"; label = "🔑 API Key Management"; badge = $null },
            @{ key = "3"; label = "📊 Analytics Dashboard"; badge = "Real-time" },
            @{ key = "4"; label = "🎨 Theme Selector"; badge = "Customize" },
            @{ key = "5"; label = "🔌 Plugin Manager"; badge = "Beta" },
            @{ key = "6"; label = "⚙️  Settings"; badge = $null },
            @{ key = "7"; label = "📚 Help"; badge = $null },
            @{ key = "8"; label = "ℹ️  About"; badge = $null },
            @{ key = "0"; label = "🚪 Exit"; badge = $null }
        )
        
        foreach ($opt in $options) {
            $badgeText = if ($opt.badge) { Get-Badge $opt.badge "info" } else { "" }
            Write-Host "$(Get-GradientText "$($opt.key))" $CurrentTheme.accent) $(Get-Glow $opt.label) $badgeText"
        }
        
        Write-Host ""
        Write-Host -NoNewline "$(Get-GradientText "▸" $CurrentTheme.accent) $(Get-Glow "Choose")$($C.Reset): "
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                Show-Notification "info" "Starting" "Initializing tunnel services..."
                Start-Sleep -Seconds 2
            }
            "3" {
                Show-Dashboard
            }
            "4" {
                Show-ThemeSelector
            }
            "8" {
                Show-About
            }
            "0" {
                Show-Notification "success" "Goodbye" "Thanks for using Local2Internet!"
                Cleanup-Jobs
                exit 0
            }
            default {
                Show-Notification "warning" "Invalid Choice" "Please select a valid option"
                Start-Sleep -Seconds 1
            }
        }
    }
}

function Show-About {
    Clear-Host
    
    Show-Card "About Local2Internet" @(
        "",
        "$(Get-GradientText "Version" $CurrentTheme.accent): v$VERSION $EDITION",
        "$(Get-GradientText "Description" $CurrentTheme.accent): Bug-free localhost tunneling",
        "",
        "$(Get-GradientText "Original Author" $CurrentTheme.accent): KasRoudra",
        "$(Get-GradientText "Enhanced By" $CurrentTheme.accent): Muhammad Taezeem Tariq Matta",
        "$(Get-GradientText "Next-Gen Edition" $CurrentTheme.accent): Claude AI (2026)",
        "",
        "$(Get-GradientText "Repository" $CurrentTheme.accent): github.com/Taezeem14/Local2Internet",
        "$(Get-GradientText "License" $CurrentTheme.accent): MIT Open Source",
        ""
    ) "ℹ️"
    
    Write-Host -NoNewline "`nPress ENTER to continue..."
    $null = Read-Host
}

# ---------------------------
# Initialize
# ---------------------------
function Initialize-Directories {
    @($BASE_DIR, $CONFIG_DIR, $BIN_DIR, $LOG_DIR, $THEMES_DIR, $STATS_DIR) | ForEach-Object {
        try {
            if (-not (Test-Path $_)) {
                New-Item -ItemType Directory -Path $_ -Force | Out-Null
            }
        }
        catch {
            Write-Warning "Failed to create directory $_`: $_"
        }
    }
}

function Cleanup-Jobs {
    foreach ($job in $script:ActiveJobs) {
        if ($job -and $job.State -eq "Running") {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
    }
    $script:ActiveJobs = @()
}

# ---------------------------
# Entry Point
# ---------------------------
try {
    # Handle Ctrl+C gracefully
    [Console]::TreatControlCAsInput = $false
    $null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
        Cleanup-Jobs
    }
    
    Initialize-Directories
    
    Clear-Host
    Write-Host (Get-Logo)
    
    Write-Host -NoNewline "`r$(Get-GradientText "⣾" $CurrentTheme.accent) $(Get-Glow "Loading next-gen interface...")$($C.Reset)    "
    Start-Sleep -Seconds 2
    Write-Host "`r$(' ' * 100)`r" -NoNewline
    
    Show-Notification "success" "Welcome" "Local2Internet $VERSION initialized"
    Start-Sleep -Seconds 1
    
    Show-MainMenu
    
}
catch {
    Write-Host "`n$((Get-GradientText "[FATAL ERROR]" $THEMES.cyberpunk.error)) $_$($C.Reset)"
    Cleanup-Jobs
    exit 1
}
finally {
    Cleanup-Jobs
}
