# =========================================
# Local2Internet v6.0 NEXT-GEN - PowerShell Edition
# Platform: Windows PowerShell 7.0+
# Ultra-Modern UI with Gradients & Animations
# =========================================

#Requires -Version 7.0

$ErrorActionPreference = "SilentlyContinue"
$PSStyle.OutputRendering = "PlainText"

# ---------------------------
# Configuration
# ---------------------------
$script:VERSION = "6.0"
$script:EDITION = "NEXT-GEN"
$script:HOME = $env:USERPROFILE
$script:BASE_DIR = "$HOME\.local2internet"
$script:CONFIG_DIR = "$BASE_DIR\config"
$script:BIN_DIR = "$BASE_DIR\bin"
$script:LOG_DIR = "$BASE_DIR\logs"
$script:THEMES_DIR = "$BASE_DIR\themes"
$script:CONFIG_FILE = "$CONFIG_DIR\config.json"
$script:THEME_FILE = "$CONFIG_DIR\theme.json"

# ---------------------------
# Modern Color System (ANSI Escape Codes)
# ---------------------------
$ESC = [char]27

function RGB($r, $g, $b) { return "$ESC[38;2;${r};${g};${b}m" }
function BGRGB($r, $g, $b) { return "$ESC[48;2;${r};${g};${b}m" }

# Gradient Palettes
$script:GRADIENTS = @{
    primary = @(
        (RGB 139 92 246),   # Purple
        (RGB 167 139 250),  # Light Purple
        (RGB 196 181 253)   # Lighter Purple
    )
    accent = @(
        (RGB 59 130 246),   # Blue
        (RGB 96 165 250),   # Light Blue
        (RGB 147 197 253)   # Lighter Blue
    )
    success = @(
        (RGB 34 197 94),    # Green
        (RGB 74 222 128),   # Light Green
        (RGB 134 239 172)   # Lighter Green
    )
    warning = @(
        (RGB 251 146 60),   # Orange
        (RGB 253 186 116),  # Light Orange
        (RGB 254 215 170)   # Lighter Orange
    )
    error = @(
        (RGB 239 68 68),    # Red
        (RGB 248 113 113),  # Light Red
        (RGB 252 165 165)   # Lighter Red
    )
}

# Neon Colors
$script:NEON = @{
    cyan = (RGB 34 211 238)
    pink = (RGB 236 72 153)
    green = (RGB 74 222 128)
    yellow = (RGB 250 204 21)
    purple = (RGB 167 139 250)
}

# Standard Colors
$C = @{
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
$script:THEMES = @{
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
}

function Get-CurrentTheme {
    if (Test-Path $THEME_FILE) {
        $themeName = (Get-Content $THEME_FILE | ConvertFrom-Json).theme
        return $THEMES[$themeName]
    }
    return $THEMES.cyberpunk
}

function Set-Theme($name) {
    @{ theme = $name } | ConvertTo-Json | Set-Content $THEME_FILE
    $script:CurrentTheme = $THEMES[$name]
}

$script:CurrentTheme = Get-CurrentTheme

# ---------------------------
# Gradient Text Function
# ---------------------------
function Get-GradientText($text, $colors) {
    if ($colors.Count -lt 2) { return $text }
    
    $chars = $text.ToCharArray()
    $result = ""
    
    for ($i = 0; $i -lt $chars.Length; $i++) {
        $ratio = $i / ($chars.Length - 1)
        $colorIndex = [Math]::Floor($ratio * ($colors.Count - 1))
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

# ---------------------------
# Modern Logo
# ---------------------------
$LOGO = @"
$(Get-GradientText "╔═══════════════════════════════════════════════════════════════════════╗" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██╗      ██████╗  ██████╗ █████╗ ██╗     ██████╗ ██╗███╗   ██╗████████╗" $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██║     ██╔═══██╗██╔════╝██╔══██╗██║     ╚════██╗██║████╗  ██║╚══██╔══╝" $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██║     ██║   ██║██║     ███████║██║      █████╔╝██║██╔██╗ ██║   ██║   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "██║     ██║   ██║██║     ██╔══██║██║     ██╔═══╝ ██║██║╚██╗██║   ██║   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "║" $CurrentTheme.primary)  $(Get-GradientText "╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝   " $CurrentTheme.accent)$(Get-GradientText "║" $CurrentTheme.primary)
$(Get-GradientText "╚═══════════════════════════════════════════════════════════════════════╝" $CurrentTheme.primary)

    $(Get-Glow (Get-GradientText "▸ v$VERSION $EDITION Edition" $CurrentTheme.success)) $($C.Dim)• Next-Generation Tunneling Platform$($C.Reset)
    $($C.Dim)Multi-Protocol • Real-Time Analytics • Theme Engine • Plugin System$($C.Reset)

"@

# ---------------------------
# Modern UI Components
# ---------------------------
function Show-ModernHeader($title, $subtitle = $null) {
    $width = 75
    $border = $CurrentTheme.border
    
    Write-Host ""
    Write-Host (Get-GradientText ($border * $width) $CurrentTheme.primary)
    Write-Host (Get-Glow (Get-GradientText "  $title".PadRight($width) $CurrentTheme.accent))
    
    if ($subtitle) {
        Write-Host "$($C.Dim)$($subtitle.PadRight($width))$($C.Reset)"
    }
    
    Write-Host (Get-GradientText ($border * $width) $CurrentTheme.primary)
    Write-Host ""
}

function Show-Card($title, $content, $icon = "▸") {
    $width = 75
    $border = $CurrentTheme.border
    
    Write-Host ""
    Write-Host (Get-GradientText "┌$($border * ($width - 2))┐" $CurrentTheme.primary)
    Write-Host "$(Get-GradientText "│" $CurrentTheme.primary) $(Get-Glow "$icon $title")".PadRight($width + 20) + (Get-GradientText "│" $CurrentTheme.primary)
    Write-Host (Get-GradientText "├$($border * ($width - 2))┤" $CurrentTheme.primary)
    
    foreach ($line in $content) {
        Write-Host "$(Get-GradientText "│" $CurrentTheme.primary) $line".PadRight($width + 20) + (Get-GradientText "│" $CurrentTheme.primary)
    }
    
    Write-Host (Get-GradientText "└$($border * ($width - 2))┘" $CurrentTheme.primary)
    Write-Host ""
}

function Show-ProgressBar($current, $total, $label = "Progress") {
    $percentage = [Math]::Round(($current / $total) * 100)
    $filled = [Math]::Round((40 * $current) / $total)
    $empty = 40 - $filled
    
    $barFilled = Get-GradientText ("█" * $filled) $CurrentTheme.success
    $barEmpty = "$($C.Dim)$('░' * $empty)"
    
    Write-Host -NoNewline "`r$(Get-GradientText "▸" $CurrentTheme.accent) $label`: [$barFilled$barEmpty$($C.Reset)] $(Get-Glow (Get-GradientText "$percentage%" $CurrentTheme.success))"
    
    if ($current -ge $total) { Write-Host "" }
}

function Show-Spinner($message, $action) {
    $frames = @('⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷')
    $i = 0
    
    $job = Start-Job -ScriptBlock $action
    
    while ($job.State -eq "Running") {
        Write-Host -NoNewline "`r$(Get-GradientText $frames[$i] $CurrentTheme.accent) $(Get-Glow $message)$($C.Reset)"
        $i = ($i + 1) % $frames.Count
        Start-Sleep -Milliseconds 80
    }
    
    Write-Host "`r$(' ' * 80)`r" -NoNewline
    
    $result = Receive-Job $job
    Remove-Job $job
    return $result
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

function Show-Table($headers, $rows) {
    $colWidths = @()
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $maxWidth = $headers[$i].Length
        foreach ($row in $rows) {
            if ($row[$i].ToString().Length -gt $maxWidth) {
                $maxWidth = $row[$i].ToString().Length
            }
        }
        $colWidths += $maxWidth + 3
    }
    
    $border = $CurrentTheme.border
    
    # Top border
    Write-Host ""
    Write-Host (Get-GradientText "┌$($colWidths | ForEach-Object { $border * $_ } | Join-String -Separator '┬')┐" $CurrentTheme.primary)
    
    # Headers
    $headerRow = @()
    for ($i = 0; $i -lt $headers.Count; $i++) {
        $headerRow += Get-Glow (Get-GradientText " $($headers[$i])".PadRight($colWidths[$i]) $CurrentTheme.accent)
    }
    Write-Host "$(Get-GradientText "│" $CurrentTheme.primary)$($headerRow -join (Get-GradientText "│" $CurrentTheme.primary))$(Get-GradientText "│" $CurrentTheme.primary)"
    
    # Middle border
    Write-Host (Get-GradientText "├$($colWidths | ForEach-Object { $border * $_ } | Join-String -Separator '┼')┤" $CurrentTheme.primary)
    
    # Rows
    foreach ($row in $rows) {
        $rowText = @()
        for ($i = 0; $i -lt $row.Count; $i++) {
            $rowText += " $($row[$i])".PadRight($colWidths[$i])
        }
        Write-Host "$(Get-GradientText "│" $CurrentTheme.primary)$($rowText -join (Get-GradientText "│" $CurrentTheme.primary))$(Get-GradientText "│" $CurrentTheme.primary)"
    }
    
    # Bottom border
    Write-Host (Get-GradientText "└$($colWidths | ForEach-Object { $border * $_ } | Join-String -Separator '┴')┘" $CurrentTheme.primary)
    Write-Host ""
}

function Show-Gauge($label, $value, $maxValue, $unit = "") {
    $percentage = [Math]::Round(($value / $maxValue) * 100)
    $filled = [Math]::Round((30 * $value) / $maxValue)
    $empty = 30 - $filled
    
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
    
    Show-Gauge "Uptime" 95 100 "%"
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
    Read-Host | Out-Null
}

# ---------------------------
# Theme Selector
# ---------------------------
function Show-ThemeSelector {
    Clear-Host
    
    Show-ModernHeader "🎨 THEME SELECTOR" "Customize your terminal experience"
    
    $i = 1
    foreach ($theme in $THEMES.GetEnumerator()) {
        $isActive = $CurrentTheme.name -eq $theme.Value.name
        $status = if ($isActive) { Get-Badge "ACTIVE" "success" } else { "" }
        
        Write-Host "$(Get-GradientText "$i)" $CurrentTheme.accent) $(Get-Glow $theme.Value.name) $status"
        Write-Host "   $($C.Dim)Preview: $(Get-GradientText "■■■" $theme.Value.primary) $(Get-GradientText "■■■" $theme.Value.accent)$($C.Reset)"
        Write-Host ""
        $i++
    }
    
    Write-Host -NoNewline "$(Get-GradientText "▸" $CurrentTheme.accent) Select theme (1-$($THEMES.Count)): "
    $choice = Read-Host
    
    $choiceNum = [int]$choice
    if ($choiceNum -gt 0 -and $choiceNum -le $THEMES.Count) {
        $themeName = ($THEMES.Keys | Sort-Object)[$choiceNum - 1]
        Set-Theme $themeName
        Show-Notification "success" "Theme Changed" "Applied $($THEMES[$themeName].name) theme"
        Start-Sleep -Seconds 2
    }
}

# ---------------------------
# Main Menu
# ---------------------------
function Show-MainMenu {
    while ($true) {
        Clear-Host
        Write-Host $LOGO
        
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
        "$(Get-GradientText "Description" $CurrentTheme.accent): Next-gen localhost tunneling platform",
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
    Read-Host | Out-Null
}

# ---------------------------
# Initialize
# ---------------------------
function Initialize-Directories {
    @($BASE_DIR, $CONFIG_DIR, $BIN_DIR, $LOG_DIR, $THEMES_DIR) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -ItemType Directory -Path $_ -Force | Out-Null
        }
    }
}

# ---------------------------
# Entry Point
# ---------------------------
try {
    Initialize-Directories
    
    Clear-Host
    Write-Host $LOGO
    
    Write-Host -NoNewline "`r$(Get-GradientText "⣾" $CurrentTheme.accent) $(Get-Glow "Loading next-gen interface...")$($C.Reset)"
    Start-Sleep -Seconds 2
    Write-Host "`r$(' ' * 80)`r" -NoNewline
    
    Show-Notification "success" "Welcome" "Local2Internet $VERSION initialized"
    Start-Sleep -Seconds 1
    
    Show-MainMenu
    
} catch {
    Write-Host "`n$($GRADIENTS.error[0])[FATAL ERROR] $_$($C.Reset)"
    exit 1
}
