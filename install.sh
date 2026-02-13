#!/usr/bin/env bash
# =========================================
# Local2Internet v5 - Advanced Auto Installer
# Platform: Linux / Termux
# Author: Muhammad Taezeem Tariq Matta
# =========================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

# Functions
info() { echo -e "${CYAN}[+]${WHITE} $1${RESET}"; }
success() { echo -e "${GREEN}[✓]${WHITE} $1${RESET}"; }
error() { echo -e "${RED}[✗]${WHITE} $1${RESET}"; exit 1; }
warn() { echo -e "${YELLOW}[!]${WHITE} $1${RESET}"; }

# Logo
echo -e "${RED}
▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀
${YELLOW}▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░
${GREEN}▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░
${BLUE}                                      [Auto Installer]
${RESET}"

info "Starting Local2Internet Advanced installation..."
echo ""

# Detect OS
if [ -d "/data/data/com.termux/files/home" ]; then
    PLATFORM="termux"
    PKG_MANAGER="pkg"
    info "Platform detected: ${GREEN}Termux (Android)${RESET}"
elif [ -f /etc/debian_version ]; then
    PLATFORM="debian"
    PKG_MANAGER="apt"
    info "Platform detected: ${GREEN}Debian/Ubuntu${RESET}"
elif [ -f /etc/arch-release ]; then
    PLATFORM="arch"
    PKG_MANAGER="pacman"
    info "Platform detected: ${GREEN}Arch Linux${RESET}"
elif [ -f /etc/fedora-release ]; then
    PLATFORM="fedora"
    PKG_MANAGER="dnf"
    info "Platform detected: ${GREEN}Fedora/RHEL${RESET}"
else
    PLATFORM="unknown"
    PKG_MANAGER="apt"
    warn "Unknown platform, assuming Debian-based"
fi

echo ""

# Check if running as root (skip for Termux)
if [ "$PLATFORM" != "termux" ] && [ "$EUID" -eq 0 ]; then
    warn "Running as root. This is not recommended!"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        error "Installation cancelled"
    fi
fi

# Update package manager
info "Updating package manager..."
case $PKG_MANAGER in
    pkg)
        pkg update -y 2>&1 | grep -v "^Reading" || error "Failed to update package manager"
        ;;
    apt)
        if [ "$EUID" -ne 0 ]; then
            sudo apt update -y 2>&1 | grep -v "^Hit:" || error "Failed to update package manager"
        else
            apt update -y 2>&1 | grep -v "^Hit:" || error "Failed to update package manager"
        fi
        ;;
    pacman)
        if [ "$EUID" -ne 0 ]; then
            sudo pacman -Sy || error "Failed to update package manager"
        else
            pacman -Sy || error "Failed to update package manager"
        fi
        ;;
    dnf)
        if [ "$EUID" -ne 0 ]; then
            sudo dnf check-update || true
        else
            dnf check-update || true
        fi
        ;;
esac
success "Package manager updated!"

# Install dependencies
info "Checking and installing dependencies..."
echo ""

DEPS_TO_INSTALL=""

# Check Ruby
if ! command -v ruby &> /dev/null; then
    info "  → Ruby not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL ruby"
else
    success "  → Ruby already installed ($(ruby --version | cut -d' ' -f2))"
fi

# Check Python3
if ! command -v python3 &> /dev/null; then
    info "  → Python3 not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL python3"
else
    success "  → Python3 already installed ($(python3 --version | cut -d' ' -f2))"
fi

# Check Node.js
if ! command -v node &> /dev/null; then
    info "  → Node.js not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL nodejs"
else
    success "  → Node.js already installed ($(node --version))"
fi

# Check PHP
if ! command -v php &> /dev/null; then
    info "  → PHP not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL php"
else
    success "  → PHP already installed ($(php --version | head -n1 | cut -d' ' -f2))"
fi

# Check wget
if ! command -v wget &> /dev/null; then
    info "  → wget not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL wget"
else
    success "  → wget already installed"
fi

# Check curl
if ! command -v curl &> /dev/null; then
    info "  → curl not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL curl"
else
    success "  → curl already installed"
fi

# Check unzip
if ! command -v unzip &> /dev/null; then
    info "  → unzip not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL unzip"
else
    success "  → unzip already installed"
fi

# Check git
if ! command -v git &> /dev/null; then
    info "  → git not found, will install"
    DEPS_TO_INSTALL="$DEPS_TO_INSTALL git"
else
    success "  → git already installed"
fi

# Termux: check for proot
if [ "$PLATFORM" = "termux" ]; then
    if ! command -v proot &> /dev/null; then
        info "  → proot not found (needed for Termux), will install"
        DEPS_TO_INSTALL="$DEPS_TO_INSTALL proot"
    else
        success "  → proot already installed (Termux compatibility)"
    fi
fi

echo ""

# Install missing dependencies
if [ -n "$DEPS_TO_INSTALL" ]; then
    info "Installing missing packages:$DEPS_TO_INSTALL"
    
    case $PKG_MANAGER in
        pkg)
            pkg install -y $DEPS_TO_INSTALL 2>&1 | grep -E "Installing|Upgrading|Setting up" || error "Failed to install dependencies"
            ;;
        apt)
            if [ "$EUID" -ne 0 ]; then
                sudo apt install -y $DEPS_TO_INSTALL 2>&1 | grep -E "Setting up|Unpacking" || error "Failed to install dependencies"
            else
                apt install -y $DEPS_TO_INSTALL 2>&1 | grep -E "Setting up|Unpacking" || error "Failed to install dependencies"
            fi
            ;;
        pacman)
            if [ "$EUID" -ne 0 ]; then
                sudo pacman -S --noconfirm $DEPS_TO_INSTALL || error "Failed to install dependencies"
            else
                pacman -S --noconfirm $DEPS_TO_INSTALL || error "Failed to install dependencies"
            fi
            ;;
        dnf)
            if [ "$EUID" -ne 0 ]; then
                sudo dnf install -y $DEPS_TO_INSTALL || error "Failed to install dependencies"
            else
                dnf install -y $DEPS_TO_INSTALL || error "Failed to install dependencies"
            fi
            ;;
    esac
    
    success "All dependencies installed!"
else
    success "All dependencies already installed!"
fi

echo ""

# === INSTALL LOCLX ===
info "Installing Loclx (LocalXpose)..."

LOC_DIR="$HOME/.local2internet/tools"
mkdir -p "$LOC_DIR"

ARCH=$(uname -m)
LOC_URL=""

case "$ARCH" in
    aarch64|armv8*) 
        LOC_URL="https://loclx-client.s3.amazonaws.com/loclx-linux-arm64.zip"
        ;;
    armv7l|armv6l) 
        LOC_URL="https://loclx-client.s3.amazonaws.com/loclx-linux-arm.zip"
        ;;
    x86_64) 
        LOC_URL="https://loclx-client.s3.amazonaws.com/loclx-linux-amd64.zip"
        ;;
    i386|i686) 
        LOC_URL="https://loclx-client.s3.amazonaws.com/loclx-linux-386.zip"
        ;;
    *) 
        warn "Unsupported architecture: $ARCH"
        LOC_URL=""
        ;;
esac

if [ -n "$LOC_URL" ]; then
    info "Downloading Loclx for $ARCH..."
    wget -L -O "$LOC_DIR/loclx.zip" "$LOC_URL" || {
        error "Download failed"
        exit 1
    }

    info "Extracting Loclx..."
    unzip -o "$LOC_DIR/loclx.zip" -d "$LOC_DIR" >/dev/null 2>&1 || {
        error "Extraction failed"
        exit 1
    }

    # Find the loclx binary even if inside a folder
    LOCLX_BIN=$(find "$LOC_DIR" -type f -name "loclx" | head -n 1)

    if [ -n "$LOCLX_BIN" ]; then
        mv "$LOCLX_BIN" "$LOC_DIR/loclx"
        chmod +x "$LOC_DIR/loclx"
        success "Loclx installed at $LOC_DIR/loclx"
    else
        error "Loclx binary not found after extraction"
        exit 1
    fi

    rm -f "$LOC_DIR/loclx.zip"
fi
# === END LOCLX INSTALL ===

# Install YAML support for Ruby
info "Checking Ruby YAML support..."
if ! ruby -e "require 'yaml'" 2>/dev/null; then
    warn "YAML gem not found, installing..."
    gem install yaml 2>&1 | tail -5 || warn "YAML gem installation failed (non-critical)"
else
    success "Ruby YAML support available"
fi

echo ""

# Install npm packages
info "Checking npm packages..."
if command -v npm &> /dev/null; then
    if ! npm list -g http-server &> /dev/null; then
        info "Installing http-server..."
        if [ "$PLATFORM" = "termux" ]; then
            npm install -g http-server 2>&1 | tail -3 || error "Failed to install http-server"
        else
            if [ "$EUID" -ne 0 ]; then
                sudo npm install -g http-server 2>&1 | tail -3 || error "Failed to install http-server"
            else
                npm install -g http-server 2>&1 | tail -3 || error "Failed to install http-server"
            fi
        fi
        success "http-server installed!"
    else
        success "http-server already installed"
    fi
else
    warn "npm not found, skipping http-server installation"
    info "You may need to install Node.js first"
fi

echo ""

# Clone repository
INSTALL_DIR="$HOME/Local2Internet"

if [ -d "$INSTALL_DIR" ]; then
    warn "Local2Internet directory already exists at: $INSTALL_DIR"
    read -p "Remove and reinstall? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        info "Removing old installation..."
        rm -rf "$INSTALL_DIR"
        success "Old installation removed"
    else
        info "Updating existing installation..."
        cd "$INSTALL_DIR"
        git pull origin main 2>&1 | grep -E "Already up to date|Updating" || warn "Failed to update repository"
        success "Repository updated!"
        cd - > /dev/null
        echo ""
        echo -e "${GREEN}╔════════════════════════════════════════╗${RESET}"
        echo -e "${GREEN}║       UPDATE SUCCESSFUL! 🎉            ║${RESET}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${RESET}"
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

info "Cloning Local2Internet repository..."
git clone https://github.com/Taezeem14/Local2Internet.git "$INSTALL_DIR" 2>&1 | grep -E "Cloning|Receiving" || error "Failed to clone repository"
success "Repository cloned!"

echo ""

# Make executables
info "Setting permissions..."
chmod +x "$INSTALL_DIR/l2in_nexgen.rb" 2>/dev/null || chmod +x "$INSTALL_DIR/l2in.rb" || error "Failed to set executable permission"
success "Permissions set!"

echo ""

# Create symlink (optional)
if [ "$PLATFORM" != "termux" ]; then
    read -p "Create system-wide command 'l2in'? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$INSTALL_DIR/l2in_nexgen.rb" ]; then
            SCRIPT_NAME="l2in_nexgen.rb"
        else
            SCRIPT_NAME="l2in.rb"
        fi
        
        if [ "$EUID" -ne 0 ]; then
            sudo ln -sf "$INSTALL_DIR/$SCRIPT_NAME" /usr/local/bin/l2in || warn "Failed to create symlink"
        else
            ln -sf "$INSTALL_DIR/$SCRIPT_NAME" /usr/local/bin/l2in || warn "Failed to create symlink"
        fi
        success "Command 'l2in' created! You can now run it from anywhere."
    fi
fi

# Termux: Create alias
if [ "$PLATFORM" = "termux" ]; then
    echo ""
    read -p "Add 'l2in' alias to .bashrc? (Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        SCRIPT_NAME="l2in_nexgen.rb"
        [ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ] && SCRIPT_NAME="l2in.rb"
        
        echo "alias l2in='$INSTALL_DIR/$SCRIPT_NAME'" >> ~/.bashrc
        success "Alias added! Restart Termux or run: source ~/.bashrc"
    fi
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║     INSTALLATION SUCCESSFUL! 🎉        ║${RESET}"
echo -e "${GREEN}╚════════════════════════════════════════╝${RESET}"
echo ""

success "Local2Internet v5 Advanced installed successfully!"
echo ""
info "Installation location: ${YELLOW}$INSTALL_DIR${RESET}"
echo ""
info "New features in v5:"
echo -e "  ${CYAN}• API Key Support (Ngrok & Loclx)${RESET}"
echo -e "  ${CYAN}• Enhanced Termux Compatibility${RESET}"
echo -e "  ${CYAN}• Improved Error Handling${RESET}"
echo -e "  ${CYAN}• Auto Port Detection${RESET}"
echo -e "  ${CYAN}• Configuration Persistence${RESET}"
echo ""
info "To start using Local2Internet:"
echo -e "  ${YELLOW}cd $INSTALL_DIR${RESET}"
SCRIPT_NAME="l2in_nexgen.rb"
[ ! -f "$INSTALL_DIR/$SCRIPT_NAME" ] && SCRIPT_NAME="l2in.rb"
echo -e "  ${YELLOW}./$SCRIPT_NAME${RESET}"
echo ""

if [[ $REPLY =~ ^[Yy]$ ]] && [ "$PLATFORM" != "termux" ]; then
    info "Or simply run: ${YELLOW}l2in${RESET}"
    echo ""
fi

# Ask to run now
read -p "Run Local2Internet now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    info "Starting Local2Internet..."
    sleep 1
    cd "$INSTALL_DIR"
    ./$SCRIPT_NAME
else
    echo ""
    info "Thanks for installing! Happy tunneling! 🚀"
    echo ""
fi
