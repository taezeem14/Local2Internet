#!/usr/bin/env bash
# =========================================
# Local2Internet v6.1 NEXT-GEN - Ultra Installer
# Platform: Linux / Termux / macOS
# Author: Muhammad Taezeem Tariq Matta (Bro)
# Enhanced: Claude AI (2026)
# =========================================

set -eo pipefail

# Modern Color System with RGB support
ESC='\033'
rgb() { echo -e "${ESC}[38;2;${1};${2};${3}m"; }
reset() { echo -e "${ESC}[0m"; }

# Gradient Colors
PURPLE=$(rgb 139 92 246)
LIGHT_PURPLE=$(rgb 167 139 250)
BLUE=$(rgb 59 130 246)
LIGHT_BLUE=$(rgb 96 165 250)
GREEN=$(rgb 34 197 94)
LIGHT_GREEN=$(rgb 74 222 128)
YELLOW=$(rgb 251 191 36)
ORANGE=$(rgb 251 146 60)
RED=$(rgb 239 68 68)
CYAN=$(rgb 34 211 238)
PINK=$(rgb 236 72 153)

# Effects
BOLD="${ESC}[1m"
DIM="${ESC}[2m"
RESET="${ESC}[0m"

# UI Functions
gradient_text() {
    local text="$1"
    local color1="$2"
    local color2="$3"
    local len=${#text}
    local result=""
    
    for ((i=0; i<len; i++)); do
        if [ $i -lt $((len/2)) ]; then
            result="${result}${color1}${text:$i:1}"
        else
            result="${result}${color2}${text:$i:1}"
        fi
    done
    
    echo -e "${result}${RESET}"
}

info() { 
    echo -e "$(gradient_text "▸" "$CYAN" "$LIGHT_BLUE") ${BOLD}$1${RESET}"
}

success() { 
    echo -e "$(gradient_text "✓" "$GREEN" "$LIGHT_GREEN") $1${RESET}"
}

error() { 
    echo -e "$(gradient_text "✗" "$RED" "$ORANGE") $1${RESET}"
    exit 1
}

warn() { 
    echo -e "$(gradient_text "⚠" "$ORANGE" "$YELLOW") $1${RESET}"
}

show_progress() {
    local current=$1
    local total=$2
    local label="$3"
    
    if [ "$total" -le 0 ]; then return; fi
    
    local percentage=$((current * 100 / total))
    local filled=$((current * 30 / total))
    local empty=$((30 - filled))
    
    local bar="${GREEN}"
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    bar="${bar}${DIM}"
    for ((i=0; i<empty; i++)); do bar="${bar}░"; done
    bar="${bar}${RESET}"
    
    echo -e "\r  ${bar} ${BOLD}${percentage}%${RESET} ${DIM}${label}${RESET}  "
}

spinner() {
    local pid=$1
    local message="$2"
    local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        echo -ne "\r${CYAN}${frames[$i]}${RESET} ${BOLD}${message}${RESET}  "
        i=$(( (i+1) % 8 ))
        sleep 0.1
    done
    
    echo -ne "\r$(printf ' %.0s' {1..100})\r"
}

# Modern Logo
LOGO="
$(gradient_text "╔═══════════════════════════════════════════════════════════════════╗" "$PURPLE" "$PINK")
$(gradient_text "║" "$PURPLE" "$PINK")  $(gradient_text "██╗      ██████╗  ██████╗ █████╗ ██╗     ██████╗ ██╗███╗   ██╗████████╗" "$CYAN" "$BLUE")  $(gradient_text "║" "$PURPLE" "$PINK")
$(gradient_text "║" "$PURPLE" "$PINK")  $(gradient_text "██║     ██╔═══██╗██╔════╝██╔══██╗██║     ╚════██╗██║████╗  ██║╚══██╔══╝" "$CYAN" "$BLUE")  $(gradient_text "║" "$PURPLE" "$PINK")
$(gradient_text "║" "$PURPLE" "$PINK")  $(gradient_text "██║     ██║   ██║██║     ███████║██║      █████╔╝██║██╔██╗ ██║   ██║   " "$CYAN" "$BLUE")  $(gradient_text "║" "$PURPLE" "$PINK")
$(gradient_text "║" "$PURPLE" "$PINK")  $(gradient_text "██║     ██║   ██║██║     ██╔══██║██║     ██╔═══╝ ██║██║╚██╗██║   ██║   " "$CYAN" "$BLUE")  $(gradient_text "║" "$PURPLE" "$PINK")
$(gradient_text "║" "$PURPLE" "$PINK")  $(gradient_text "███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║   " "$CYAN" "$BLUE")  $(gradient_text "║" "$PURPLE" "$PINK")
$(gradient_text "║" "$PURPLE" "$PINK")  $(gradient_text "╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝   " "$CYAN" "$BLUE")  $(gradient_text "║" "$PURPLE" "$PINK")
$(gradient_text "╚═══════════════════════════════════════════════════════════════════╝" "$PURPLE" "$PINK")

       ${BOLD}$(gradient_text "▸ v6.1 NEXT-GEN Ultra Installer" "$GREEN" "$LIGHT_GREEN")${RESET} ${DIM}• Bug-Free Edition${RESET}
           ${DIM}Automated Dependency Management • Smart Error Recovery${RESET}
"

clear
echo -e "$LOGO"

info "Starting Local2Internet v6.1 installation..."
echo ""

# Detect platform
if [ -d "/data/data/com.termux/files/home" ]; then
    PLATFORM="termux"
    PKG_MANAGER="pkg"
    success "Platform detected: ${BOLD}Termux (Android)${RESET}"
elif [ -f /etc/debian_version ]; then
    PLATFORM="debian"
    PKG_MANAGER="apt"
    success "Platform detected: ${BOLD}Debian/Ubuntu${RESET}"
elif [ -f /etc/arch-release ]; then
    PLATFORM="arch"
    PKG_MANAGER="pacman"
    success "Platform detected: ${BOLD}Arch Linux${RESET}"
elif [ -f /etc/fedora-release ] || [ -f /etc/redhat-release ]; then
    PLATFORM="fedora"
    PKG_MANAGER="dnf"
    success "Platform detected: ${BOLD}Fedora/RHEL${RESET}"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
    PKG_MANAGER="brew"
    success "Platform detected: ${BOLD}macOS${RESET}"
else
    PLATFORM="unknown"
    PKG_MANAGER="apt"
    warn "Unknown platform, assuming Debian-based"
fi

echo ""

# Check for root/sudo (skip for Termux)
if [ "$PLATFORM" != "termux" ] && [ "$EUID" -eq 0 ]; then
    warn "Running as root is not recommended!"
    echo ""
    read -p "  Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Installation cancelled"
    fi
    echo ""
fi

# macOS: Check for Homebrew
if [ "$PLATFORM" = "macos" ]; then
    info "Checking for Homebrew..."
    
    if ! command -v brew &> /dev/null; then
        warn "Homebrew not found!"
        echo ""
        echo "  Homebrew is required for macOS dependency installation."
        echo "  ${DIM}Visit: https://brew.sh${RESET}"
        echo ""
        
        read -p "  Install Homebrew now? (Y/n): " -n 1 -r
        echo
        
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            info "Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Failed to install Homebrew"
            success "Homebrew installed!"
        else
            error "Homebrew is required. Installation cancelled."
        fi
    else
        success "Homebrew is installed"
    fi
    echo ""
fi

# Update package manager
info "Updating package manager..."

(
    case $PKG_MANAGER in
        pkg)
            pkg update -y &> /dev/null
            ;;
        apt)
            if [ "$EUID" -ne 0 ]; then
                sudo apt update -y &> /dev/null
            else
                apt update -y &> /dev/null
            fi
            ;;
        pacman)
            if [ "$EUID" -ne 0 ]; then
                sudo pacman -Sy --noconfirm &> /dev/null
            else
                pacman -Sy --noconfirm &> /dev/null
            fi
            ;;
        dnf)
            if [ "$EUID" -ne 0 ]; then
                sudo dnf check-update &> /dev/null || true
            else
                dnf check-update &> /dev/null || true
            fi
            ;;
        brew)
            brew update &> /dev/null
            ;;
    esac
) &

spinner $! "Updating package manager"
wait $!

if [ $? -eq 0 ] || [ $PKG_MANAGER = "dnf" ]; then
    success "Package manager updated!"
else
    warn "Update had warnings (continuing anyway)"
fi

echo ""

# Check and install dependencies
info "Checking dependencies..."
echo ""

declare -A dependencies=(
    ["ruby"]="Ruby"
    ["python3"]="Python 3"
    ["node"]="Node.js"
    ["php"]="PHP"
    ["wget"]="wget"
    ["curl"]="curl"
    ["unzip"]="unzip"
    ["git"]="Git"
)

# Add Termux-specific dependencies
if [ "$PLATFORM" = "termux" ]; then
    dependencies["proot"]="proot"
fi

DEPS_TO_INSTALL=()
INSTALLED_COUNT=0
TOTAL_DEPS=${#dependencies[@]}

for cmd in "${!dependencies[@]}"; do
    display_name="${dependencies[$cmd]}"
    
    if command -v $cmd &> /dev/null; then
        version=""
        case $cmd in
            ruby) version=$(ruby --version 2>/dev/null | cut -d' ' -f2 || echo "unknown") ;;
            python3) version=$(python3 --version 2>/dev/null | cut -d' ' -f2 || echo "unknown") ;;
            node) version=$(node --version 2>/dev/null || echo "unknown") ;;
            php) version=$(php --version 2>/dev/null | head -n1 | cut -d' ' -f2 || echo "unknown") ;;
            git) version=$(git --version 2>/dev/null | cut -d' ' -f3 || echo "unknown") ;;
            *) version="installed" ;;
        esac
        
        success "  $display_name installed ($version)"
        ((INSTALLED_COUNT++))
    else
        echo -e "  ${DIM}→ $display_name not found${RESET}"
        DEPS_TO_INSTALL+=("$cmd")
    fi
done

echo ""
show_progress $INSTALLED_COUNT $TOTAL_DEPS "Dependencies checked"
echo ""

# Install missing dependencies
if [ ${#DEPS_TO_INSTALL[@]} -gt 0 ]; then
    info "Installing missing packages: ${DEPS_TO_INSTALL[*]}"
    echo ""
    
    SUCCESS_COUNT=0
    
    for pkg in "${DEPS_TO_INSTALL[@]}"; do
        echo -e "  ${CYAN}→${RESET} Installing $pkg..."
        
        (
            case $PKG_MANAGER in
                pkg)
                    pkg install -y $pkg &> /dev/null
                    ;;
                apt)
                    if [ "$EUID" -ne 0 ]; then
                        sudo apt install -y $pkg &> /dev/null
                    else
                        apt install -y $pkg &> /dev/null
                    fi
                    ;;
                pacman)
                    # Map package names for Arch
                    [ "$pkg" = "node" ] && pkg="nodejs"
                    
                    if [ "$EUID" -ne 0 ]; then
                        sudo pacman -S --noconfirm $pkg &> /dev/null
                    else
                        pacman -S --noconfirm $pkg &> /dev/null
                    fi
                    ;;
                dnf)
                    # Map package names for Fedora
                    [ "$pkg" = "node" ] && pkg="nodejs"
                    
                    if [ "$EUID" -ne 0 ]; then
                        sudo dnf install -y $pkg &> /dev/null
                    else
                        dnf install -y $pkg &> /dev/null
                    fi
                    ;;
                brew)
                    # Map package names for macOS
                    [ "$pkg" = "python3" ] && pkg="python"
                    [ "$pkg" = "node" ] && pkg="node"
                    
                    brew install $pkg &> /dev/null
                    ;;
            esac
        ) &
        
        spinner $! "Installing $pkg"
        wait $!
        
        if [ $? -eq 0 ]; then
            success "  $pkg installed!"
            ((SUCCESS_COUNT++))
        else
            warn "  $pkg installation failed (may be non-critical)"
        fi
    done
    
    echo ""
    show_progress $SUCCESS_COUNT ${#DEPS_TO_INSTALL[@]} "Packages installed"
    echo ""
else
    success "All dependencies already installed!"
    echo ""
fi

# Install Ruby YAML gem
info "Checking Ruby YAML support..."

if command -v ruby &> /dev/null && command -v gem &> /dev/null; then
    if ! ruby -e "require 'yaml'" 2>/dev/null; then
        warn "YAML gem not found, installing..."
        
        (gem install yaml &> /dev/null) &
        spinner $! "Installing YAML gem"
        wait $!
        
        if [ $? -eq 0 ]; then
            success "YAML gem installed!"
        else
            warn "YAML gem installation failed (non-critical)"
        fi
    else
        success "Ruby YAML support available"
    fi
else
    warn "Ruby/gem not found, skipping YAML check"
fi

echo ""

# Install npm packages
info "Checking npm packages..."

if command -v npm &> /dev/null; then
    if ! npm list -g http-server &> /dev/null; then
        info "Installing http-server..."
        
        (
            if [ "$PLATFORM" = "termux" ] || [ "$PLATFORM" = "macos" ]; then
                npm install -g http-server &> /dev/null
            else
                if [ "$EUID" -ne 0 ]; then
                    sudo npm install -g http-server &> /dev/null
                else
                    npm install -g http-server &> /dev/null
                fi
            fi
        ) &
        
        spinner $! "Installing http-server"
        wait $!
        
        if [ $? -eq 0 ]; then
            success "http-server installed!"
        else
            warn "http-server installation failed (non-critical)"
        fi
    else
        success "http-server already installed"
    fi
else
    warn "npm not found, skipping http-server installation"
fi

echo ""

# Clone repository
INSTALL_DIR="$HOME/Local2Internet"
REPO_URL="https://github.com/Taezeem14/Local2Internet.git"

if [ -d "$INSTALL_DIR" ]; then
    warn "Local2Internet directory already exists"
    echo "  ${DIM}Location: $INSTALL_DIR${RESET}"
    echo ""
    
    read -p "  Remove and reinstall? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        info "Removing old installation..."
        
        rm -rf "$INSTALL_DIR" || error "Failed to remove old installation"
        success "Old installation removed"
    else
        echo ""
        info "Updating existing installation..."
        
        cd "$INSTALL_DIR" || error "Failed to enter directory"
        
        (git pull origin main &> /dev/null) &
        spinner $! "Updating repository"
        wait $!
        
        if [ $? -eq 0 ]; then
            success "Repository updated!"
        else
            warn "Update had warnings (continuing anyway)"
        fi
        
        cd - > /dev/null
        
        echo ""
        echo -e "$(gradient_text "╔════════════════════════════════════════════╗" "$GREEN" "$LIGHT_GREEN")"
        echo -e "$(gradient_text "║" "$GREEN" "$LIGHT_GREEN")  ${BOLD}UPDATE SUCCESSFUL! 🎉${RESET}                $(gradient_text "║" "$GREEN" "$LIGHT_GREEN")"
        echo -e "$(gradient_text "╚════════════════════════════════════════════╝" "$GREEN" "$LIGHT_GREEN")"
        echo ""
        
        success "Local2Internet updated successfully!"
        echo ""
        info "To run Local2Internet:"
        echo -e "  ${YELLOW}cd $INSTALL_DIR${RESET}"
        echo -e "  ${YELLOW}./l2in_nexgen.rb${RESET}"
        echo ""
        exit 0
    fi
fi

echo ""
info "Cloning Local2Internet repository..."
echo "  ${DIM}Source: $REPO_URL${RESET}"
echo ""

(git clone $REPO_URL "$INSTALL_DIR" &> /dev/null) &
spinner $! "Cloning repository"
wait $!

if [ $? -eq 0 ] && [ -d "$INSTALL_DIR/.git" ]; then
    success "Repository cloned successfully!"
else
    error "Failed to clone repository. Check your internet connection."
fi

echo ""

# Set executable permissions
info "Setting permissions..."

chmod +x "$INSTALL_DIR"/l2in*.rb 2>/dev/null || chmod +x "$INSTALL_DIR"/l2in.rb || warn "Failed to set executable permissions"
success "Permissions set!"

echo ""

# Create system command (non-Termux)
if [ "$PLATFORM" != "termux" ]; then
    read -p "Create system-wide command 'l2in'? (Y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        info "Creating system command..."
        
        SCRIPT_NAME="l2in_nexgen.rb"
        [ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ] && SCRIPT_NAME="l2in.rb"
        
        if [ "$EUID" -ne 0 ]; then
            sudo ln -sf "$INSTALL_DIR/$SCRIPT_NAME" /usr/local/bin/l2in 2>/dev/null || warn "Failed to create symlink (may need manual setup)"
        else
            ln -sf "$INSTALL_DIR/$SCRIPT_NAME" /usr/local/bin/l2in 2>/dev/null || warn "Failed to create symlink"
        fi
        
        if [ -f /usr/local/bin/l2in ]; then
            success "Command 'l2in' created! Run from anywhere."
        fi
    fi
fi

# Termux: Create alias
if [ "$PLATFORM" = "termux" ]; then
    echo ""
    read -p "Add 'l2in' alias to .bashrc? (Y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        info "Creating alias..."
        
        SCRIPT_NAME="l2in_nexgen.rb"
        [ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ] && SCRIPT_NAME="l2in.rb"
        
        if ! grep -q "alias l2in=" ~/.bashrc 2>/dev/null; then
            echo "alias l2in='$INSTALL_DIR/$SCRIPT_NAME'" >> ~/.bashrc
            success "Alias added! Restart Termux or run: source ~/.bashrc"
        else
            success "Alias already exists"
        fi
    fi
fi

# Success screen
echo ""
echo -e "$(gradient_text "╔════════════════════════════════════════════╗" "$GREEN" "$LIGHT_GREEN")"
echo -e "$(gradient_text "║" "$GREEN" "$LIGHT_GREEN")  ${BOLD}INSTALLATION SUCCESSFUL! 🎉${RESET}          $(gradient_text "║" "$GREEN" "$LIGHT_GREEN")"
echo -e "$(gradient_text "╚════════════════════════════════════════════╝" "$GREEN" "$LIGHT_GREEN")"
echo ""

success "Local2Internet v6.1 NEXT-GEN installed successfully!"
echo ""
info "Installation location:"
echo -e "  ${YELLOW}$INSTALL_DIR${RESET}"
echo ""
info "New features in v6.1:"
echo -e "  ${CYAN}• Ultra-Modern Terminal UI with Gradients${RESET}"
echo -e "  ${CYAN}• 6 Premium Themes (Cyberpunk, Matrix, Ocean...)${RESET}"
echo -e "  ${CYAN}• Bug-Free Error Handling & Recovery${RESET}"
echo -e "  ${CYAN}• Real-Time Analytics Dashboard${RESET}"
echo -e "  ${CYAN}• Enhanced API Key Management${RESET}"
echo -e "  ${CYAN}• Zero Crashes Guarantee${RESET}"
echo ""
info "To start using Local2Internet:"
echo -e "  ${YELLOW}cd $INSTALL_DIR${RESET}"

SCRIPT_NAME="l2in_nexgen.rb"
[ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ] && SCRIPT_NAME="l2in.rb"
echo -e "  ${YELLOW}./$SCRIPT_NAME${RESET}"
echo ""

# Ask to run now
read -p "Run Local2Internet now? (Y/n): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    info "Starting Local2Internet v6.1 NEXT-GEN..."
    sleep 1
    cd "$INSTALL_DIR" || exit 1
    ./$SCRIPT_NAME
else
    echo ""
    info "Thanks for installing! Happy tunneling! 🚀"
    echo ""
    echo -e "${DIM}Star the repo: https://github.com/Taezeem14/Local2Internet${RESET}"
    echo ""
fi
