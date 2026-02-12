#!/usr/bin/env ruby
# ==========================================================
# Local2Internet v4.1 - Advanced Edition
#
# Description:
#   Expose a local directory to the internet using
#   Python, PHP, or NodeJS with tunneling via:
#   - Ngrok (with API key support)
#   - Cloudflare Tunnel (Termux compatible)
#   - Loclx (with API key support)
#
# Original Author  : KasRoudra
# Enhanced By      : Muhammad Taezeem Tariq Matta
# Repository       : github.com/Taezeem14/Local2Internet
# License          : MIT
# ==========================================================

require 'fileutils'
require 'json'
require 'yaml'

# ------------------ CONFIGURATION ------------------

HOME = ENV["HOME"]
BASE_DIR = "#{HOME}/.local2internet"
LOG_DIR  = "#{BASE_DIR}/logs"
BIN_DIR  = "#{BASE_DIR}/bin"
CONFIG_FILE = "#{BASE_DIR}/config.yml"

TOOLS = {
  ngrok: "#{BIN_DIR}/ngrok",
  cloudflared: "#{BIN_DIR}/cloudflared",
  loclx: "#{BIN_DIR}/loclx"
}

DEPENDENCIES = %w[python3 php wget unzip curl]
DEFAULT_PORT = 8888
VERSION = "4.1"

# ------------------ COLORS ------------------

BLACK  = "\033[0;30m"
RED    = "\033[0;31m"
GREEN  = "\033[0;32m"
YELLOW = "\033[0;33m"  
BLUE   = "\033[0;34m"
PURPLE = "\033[0;35m"
CYAN   = "\033[0;36m"
WHITE  = "\033[0;37m"
RESET  = "\033[0m"

# ------------------ LOGO ------------------

LOGO = <<~LOGO_TEXT
#{RED}
▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀ 
#{YELLOW}▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░ 
#{GREEN}▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░
#{BLUE}                                      [v#{VERSION} Advanced - API Support]
#{RESET}
LOGO_TEXT

# ------------------ CONFIGURATION MANAGER ------------------

class ConfigManager
  def initialize
    @config = load_config
  end

  def load_config
    if File.exist?(CONFIG_FILE)
      YAML.safe_load(File.read(CONFIG_FILE)) rescue {}
    else
      {}
    end
  end

  def save_config
    FileUtils.mkdir_p(File.dirname(CONFIG_FILE))
    File.write(CONFIG_FILE, @config.to_yaml)
  end

  def get(key)
    @config[key.to_s]
  end

  def set(key, value)
    @config[key.to_s] = value
    save_config
  end

  def delete(key)
    @config.delete(key.to_s)
    save_config
  end

  def has?(key)
    @config.key?(key.to_s)
  end
end

# ------------------ UTILITIES ------------------

def exec_silent(cmd)
  system("#{cmd} > /dev/null 2>&1")
end

def command_exists?(cmd)
  system("command -v #{cmd} > /dev/null 2>&1")
end

def ensure_dirs
  [BASE_DIR, LOG_DIR, BIN_DIR].each { |d| FileUtils.mkdir_p(d) }
end

def arch
  @arch ||= `uname -m`.strip
end

def log_file(name)
  "#{LOG_DIR}/#{name}.log"
end

def abort_with(msg)
  puts "#{RED}[✗] #{msg}#{RESET}"
  cleanup
  exit 1
end

def success(msg)
  puts "#{GREEN}[✓] #{msg}#{RESET}"
end

def info(msg)
  puts "#{CYAN}[+] #{msg}#{RESET}"
end

def warn(msg)
  puts "#{YELLOW}[!] #{msg}#{RESET}"
end

def ask(msg)
  print "#{YELLOW}[?] #{msg}#{RESET}"
end

def termux?
  @is_termux ||= Dir.exist?("/data/data/com.termux/files/home")
end

def proot_available?
  command_exists?("proot")
end

# ------------------ CLEANUP ------------------

def cleanup
  info "Cleaning up processes..."
  %w[ngrok cloudflared loclx http-server].each do |proc|
    exec_silent("pkill -f #{proc}")
  end
  sleep 1
end


# ------------------ DEPENDENCY MANAGER ------------------

def check_package(pkg)
  `dpkg -l 2>/dev/null | grep -o #{pkg}`.include?(pkg) ||
  `pkg list-installed 2>/dev/null | grep -o #{pkg}`.include?(pkg)
end

def install_dependencies
  info "Checking system dependencies..."

  pkg_cmd = termux? ? "pkg" : "apt"

  DEPENDENCIES.each do |dep|
    pkg_name = dep == "python3" ? "python" : dep
    
    unless check_package(pkg_name) || command_exists?(dep)
      info "Installing #{dep}..."
      exec_silent("#{pkg_cmd} install #{dep} -y") || abort_with("Failed to install #{dep}")
    end
  end

  # Check NodeJS separately
  unless check_package("nodejs") || command_exists?("node")
    info "Installing NodeJS..."
    exec_silent("#{pkg_cmd} install nodejs -y") || abort_with("Failed to install nodejs")
  end

  # Install http-server globally
  if command_exists?("npm")
    unless `npm list -g --depth=0 2>/dev/null | grep -o http-server`.include?("http-server")
      info "Installing Node http-server..."
      exec_silent("npm install -g http-server") || warn("Failed to install http-server")
    end
  end

  # Termux specific: proot for compatibility
  if termux? && !proot_available?
    info "Installing proot for Termux compatibility..."
    exec_silent("pkg install proot -y")
  end
end

# ------------------ TOOL DOWNLOADS ------------------

def download_ngrok
  return if File.exist?(TOOLS[:ngrok])

  info "Downloading ngrok..."

  url = case arch
  when /arm(?!64)/ then "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz"
  when /aarch64|arm64/ then "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
  when /x86_64/ then "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
  else "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.tgz"
  end

  tmp = "#{BASE_DIR}/ngrok.tmp"
  
  unless exec_silent("wget -q --show-progress #{url} -O #{tmp}")
    abort_with("Failed to download ngrok - check your internet connection")
  end

  unless exec_silent("tar -xzf #{tmp} -C #{BIN_DIR}")
    File.delete(tmp) if File.exist?(tmp)
    abort_with("Failed to extract ngrok")
  end

  exec_silent("chmod +x #{TOOLS[:ngrok]}")
  File.delete(tmp) if File.exist?(tmp)
  success "Ngrok installed!"
end

def download_cloudflared
  return if File.exist?(TOOLS[:cloudflared])

  info "Downloading cloudflared..."

  # Termux ARM64 requires special handling
  if termux? && arch.match?(/aarch64|arm64/)
    url = "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
  else
    url = case arch
    when /arm(?!64)/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
    when /aarch64|arm64/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    when /x86_64/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    else "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386"
    end
  end

  if exec_silent("wget -q --show-progress #{url} -O #{TOOLS[:cloudflared]}")
    exec_silent("chmod +x #{TOOLS[:cloudflared]}")
    
    # Termux: Additional proot wrapper if needed
    if termux?
      success "Cloudflared installed! (Termux mode: will use proot wrapper)"
    else
      success "Cloudflared installed!"
    end
  else
    warn "Failed to download cloudflared (non-critical)"
  end
end

def download_loclx
  return if File.exist?(TOOLS[:loclx])

  info "Downloading loclx..."

  url = "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-amd64.zip"
  tmp = "#{BASE_DIR}/loclx.zip"

  abort_with("wget not found!") unless command_exists?("wget")
  abort_with("unzip not found!") unless command_exists?("unzip")

  unless exec_silent("wget #{url} -O #{tmp}")
    warn "Loclx download failed"
    return
  end

  unless exec_silent("unzip -o #{tmp} -d #{BIN_DIR}")
    warn "Loclx unzip failed"
    return
  end

  exec_silent("chmod +x #{TOOLS[:loclx]}")
  File.delete(tmp) rescue nil

  success "Loclx installed!"
end

def download_tools
  info "Checking and downloading tunneling tools..."

  download_ngrok
  download_cloudflared
  download_loclx
end

# ------------------ API KEY MANAGER ------------------

def manage_api_keys(config)
  loop do
    system("clear")
    puts LOGO
    puts "\n#{YELLOW}╔════════════════════════════════════════╗#{RESET}"
    puts "#{YELLOW}║         API KEY MANAGEMENT             ║#{RESET}"
    puts "#{YELLOW}╚════════════════════════════════════════╝#{RESET}\n"
    
    puts "1) Set Ngrok Authtoken"
    puts "2) Set Loclx Access Token"
    puts "3) View Current Keys"
    puts "4) Remove Keys"
    puts "0) Back to Main Menu"
    
    ask "\nChoice: "
    choice = gets.chomp.strip

    case choice
    when "1"
      ask "\nEnter Ngrok authtoken (from https://dashboard.ngrok.com): "
      token = gets.chomp.strip
      
      if token.empty?
        warn "Token cannot be empty!"
        sleep 2
        next
      end
      
      # Configure ngrok with authtoken
      if exec_silent("#{TOOLS[:ngrok]} config add-authtoken #{token}")
        config.set('ngrok_token', token)
        success "Ngrok authtoken saved and configured!"
      else
        warn "Failed to configure ngrok authtoken"
      end
      sleep 2
      
    when "2"
      ask "\nEnter Loclx access token (from https://localxpose.io): "
      token = gets.chomp.strip
      
      if token.empty?
        warn "Token cannot be empty!"
        sleep 2
        next
      end
      
      config.set('loclx_token', token)
      success "Loclx access token saved!"
      sleep 2
      
    when "3"
      puts "\n#{CYAN}Current API Keys:#{RESET}"
      puts "━" * 40
      
      if config.has?('ngrok_token')
        puts "#{GREEN}[✓]#{RESET} Ngrok: #{config.get('ngrok_token')[0..15]}***"
      else
        puts "#{RED}[✗]#{RESET} Ngrok: Not configured"
      end
      
      if config.has?('loclx_token')
        puts "#{GREEN}[✓]#{RESET} Loclx: #{config.get('loclx_token')[0..15]}***"
      else
        puts "#{RED}[✗]#{RESET} Loclx: Not configured"
      end
      
      puts "\n#{YELLOW}Note: API keys enable premium features and remove rate limits#{RESET}"
      ask "\nPress ENTER to continue..."
      gets
      
    when "4"
      puts "\n#{YELLOW}Remove which key?#{RESET}"
      puts "1) Ngrok"
      puts "2) Loclx"
      puts "3) Both"
      puts "0) Cancel"
      
      ask "\nChoice: "
      remove_choice = gets.chomp.strip
      
      case remove_choice
      when "1"
        config.delete('ngrok_token')
        success "Ngrok token removed!"
      when "2"
        config.delete('loclx_token')
        success "Loclx token removed!"
      when "3"
        config.delete('ngrok_token')
        config.delete('loclx_token')
        success "All tokens removed!"
      end
      sleep 2
      
    when "0"
      break
    else
      warn "Invalid choice!"
      sleep 2
    end
  end
end

# ------------------ SERVER MANAGER ------------------

def start_server(path, port, mode)
  info "Starting #{mode.to_s.upcase} server on port #{port}..."
  
  case mode
  when :python
    exec_silent("cd #{path} && python3 -m http.server #{port} &")
  when :php
    unless File.exist?("#{path}/index.php") || File.exist?("#{path}/index.html")
      abort_with("No index.php or index.html found in directory!")
    end
    exec_silent("cd #{path} && php -S 127.0.0.1:#{port} &")
  when :node
    exec_silent("cd #{path} && http-server -p #{port} &")
  else
    abort_with("Invalid server mode")
  end

  sleep 3

  # Verify server started
  5.times do
    status = `curl -s --head -w %{http_code} 127.0.0.1:#{port} -o /dev/null 2>&1`.strip
    unless status.include?("000") || status.empty?
      success "Server running at http://127.0.0.1:#{port}"
      return true
    end
    sleep 1
  end
  
  abort_with("Local server failed to start! Check if port #{port} is already in use.")
end

# ------------------ TUNNEL MANAGER ------------------

def start_ngrok(port, config)
  info "Starting Ngrok tunnel..."
  
  # Use authtoken if configured
  authtoken_configured = config.has?('ngrok_token')
  
cmd = if termux? && proot_available?
  "cd #{BIN_DIR} && termux-chroot #{base_cmd} > #{log_file("loclx")} 2>&1 &"
else
  "#{base_cmd} > #{log_file("loclx")} 2>&1 &"
end
  
  exec_silent(cmd)
  sleep 6

  # Try to get URL from API
  10.times do
    url = `curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | grep -o "https://[^\\"]*ngrok[^\\"]*"`.strip
    return url unless url.empty?
    sleep 1
  end
  
  nil
end

def start_cloudflare(port)
  info "Starting Cloudflare tunnel..."
  
  File.delete(log_file("cloudflare")) if File.exist?(log_file("cloudflare"))
  
  cmd = if termux? && proot_available?
    "cd #{BIN_DIR} && termux-chroot ./cloudflared tunnel --url http://127.0.0.1:#{port} --logfile #{log_file("cloudflare")} > /dev/null 2>&1 &"
  elsif termux?
    # Fallback for Termux without proot
    "#{TOOLS[:cloudflared]} tunnel --url http://127.0.0.1:#{port} --logfile #{log_file("cloudflare")} > /dev/null 2>&1 &"
  else
    "#{TOOLS[:cloudflared]} tunnel --url http://127.0.0.1:#{port} --logfile #{log_file("cloudflare")} > /dev/null 2>&1 &"
  end
  
  exec_silent(cmd)
  sleep 8

  # Try multiple times to get URL from log
  15.times do
    url = `grep -o "https://[^ ]*trycloudflare.com" #{log_file("cloudflare")} 2>/dev/null | head -1`.strip
    return url unless url.empty?
    sleep 1
  end
  
  nil
end

def start_loclx(port, config)
  info "Starting Loclx tunnel..."
  
  File.delete(log_file("loclx")) if File.exist?(log_file("loclx"))
  
  # Build command with access token if available
  base_cmd = "#{TOOLS[:loclx]} tunnel http --to :#{port}"
  
  if config.has?('loclx_token')
    base_cmd += " --token #{config.get('loclx_token')}"
  end
  
  cmd = if termux? && proot_available?
    "cd #{BIN_DIR} && termux-chroot ./loclx tunnel http --to :#{port} > #{log_file("loclx")} 2>&1 &"
  else
    "#{base_cmd} > #{log_file("loclx")} 2>&1 &"
  end
  
  exec_silent(cmd)
  sleep 8

  # Try to get URL from log
  15.times do
    url = `grep -o "https://[^ ]*loclx.io" #{log_file("loclx")} 2>/dev/null | head -1`.strip
    return url unless url.empty?
    sleep 1
  end
  
  nil
end

def start_all_tunnels(port, config)
  warn "Starting all tunnels (this may take ~30 seconds)..." if termux?
  
  results = {}
  
  # Start ngrok if binary exists
  if File.exist?(TOOLS[:ngrok])
    results[:ngrok] = start_ngrok(port, config)
  else
    warn "Ngrok binary not found, skipping..."
    results[:ngrok] = nil
  end
  
  # Start cloudflare if binary exists
  if File.exist?(TOOLS[:cloudflared])
    results[:cloudflare] = start_cloudflare(port)
  else
    warn "Cloudflared binary not found, skipping..."
    results[:cloudflare] = nil
  end
  
  # Start loclx if binary exists
  if File.exist?(TOOLS[:loclx])
    results[:loclx] = start_loclx(port, config)
  else
    warn "Loclx binary not found, skipping..."
    results[:loclx] = nil
  end
  
  results
end

# ------------------ CLI INTERFACE ------------------

def select_server
  puts "\n#{YELLOW}Select hosting protocol:#{RESET}"
  puts "1) Python (http.server) - Recommended"
  puts "2) PHP (built-in server)"
  puts "3) NodeJS (http-server)"
  ask "Choice [1-3] (default: 1): "

  choice = gets.chomp.strip
  choice = "1" if choice.empty?

  case choice
  when "1" then :python
  when "2" then :php
  when "3" then :node
  else
    warn "Invalid choice, using Python"
    :python
  end
end

def get_directory
  loop do
    ask "Enter directory path to host (or '.' for current): "
    input = gets.chomp.strip
    
    if input.empty?
      warn "Please enter a valid directory path!"
      next
    end
    
    # Convert relative paths to absolute
    path = File.expand_path(input)
    
    if Dir.exist?(path)
      info "Selected directory: #{path}"
      return path
    else
      warn "Directory '#{path}' does not exist!"
      warn "Please enter a valid path (e.g., /home/user/mysite or ./mysite)"
    end
  end
end

def get_port
  ask "Enter port (default: #{DEFAULT_PORT}): "
  port = gets.chomp.strip
  
  return DEFAULT_PORT if port.empty?
  
  port_num = port.to_i
  if port_num <= 0 || port_num > 65535
    warn "Invalid port, using default #{DEFAULT_PORT}"
    return DEFAULT_PORT
  end
  
  # Check if port is in use
  if `lsof -i :#{port_num} 2>/dev/null`.include?("LISTEN")
    warn "Port #{port_num} is already in use!"
    ask "Try anyway? (y/N): "
    choice = gets.chomp.strip.downcase
    return port_num if choice == 'y'
    return get_port
  end
  
  port_num
end

def display_results(urls)
  puts "\n#{GREEN}╔════════════════════════════════════════╗#{RESET}"
  puts "#{GREEN}║          PUBLIC URLS READY!            ║#{RESET}"
  puts "#{GREEN}╚════════════════════════════════════════╝#{RESET}\n"
  
  active_count = 0
  
  urls.each do |service, url|
    if url
      success "#{service.to_s.capitalize.ljust(12)}: #{CYAN}#{url}#{RESET}"
      active_count += 1
    else
      warn "#{service.to_s.capitalize.ljust(12)}: Failed to start"
    end
  end
  
  if active_count == 0
    puts "\n#{RED}All tunnels failed to start!#{RESET}"
    warn "Troubleshooting:"
    warn "• Check your internet connection"
    warn "• Verify firewall settings"
    warn "• Try configuring API keys (Menu option 3)"
    warn "• Check logs in: #{LOG_DIR}"
    puts "\n#{YELLOW}Server is still accessible locally at the displayed port#{RESET}"
    return false
  else
    puts "\n#{GREEN}#{active_count}/#{urls.size} tunnels active#{RESET}"
    puts "\n#{CYAN}TIP: Configure API keys for better reliability (Menu option 3)#{RESET}" if active_count < urls.size
    return true
  end
end

def show_about
  system("clear")
  puts LOGO
  puts <<~ABOUT_TEXT

#{RED}[Tool Name]   #{CYAN}: Local2Internet v#{VERSION}
#{RED}[Description] #{CYAN}: Advanced LocalHost Exposing Tool
#{RED}[Author]      #{CYAN}: KasRoudra
#{RED}[Enhanced By] #{CYAN}: Muhammad Taezeem Tariq Matta
#{RED}[Github]      #{CYAN}: https://github.com/Taezeem14/Local2Internet
#{RED}[License]     #{CYAN}: MIT Open Source
#{RED}[Features]    #{CYAN}: • Triple Tunneling (Ngrok, Cloudflare, Loclx)
              #{CYAN}  • API Key Support
              #{CYAN}  • Termux Compatible
              #{CYAN}  • Auto Port Detection
              #{CYAN}  • Multi-Protocol Server (Python/PHP/NodeJS)
#{RESET}
  ABOUT_TEXT
  ask "Press ENTER to continue..."
  gets
end

def show_help
  system("clear")
  puts LOGO
  puts <<~HELP_TEXT

#{CYAN}═══════════════════════════════════════════════════════════
                        HELP GUIDE
═══════════════════════════════════════════════════════════#{RESET}

#{YELLOW}GETTING STARTED:#{RESET}
  1. Select "Start Server & Tunnels" from main menu
  2. Enter the directory path you want to host
  3. Choose your preferred server protocol
  4. Enter a port number (or use default)
  5. Wait for tunnels to initialize
  6. Share the public URLs with others!

#{YELLOW}API KEY CONFIGURATION:#{RESET}
  • Ngrok: Get authtoken from https://dashboard.ngrok.com
  • Loclx: Get access token from https://localxpose.io/dashboard
  
  Benefits: Remove rate limits, get persistent URLs, priority support

#{YELLOW}TROUBLESHOOTING:#{RESET}
  • Port in use: Choose a different port
  • Tunnels fail: Check internet connection, firewall, add API keys
  • Server fails: Ensure directory has index.html or index.php
  • Termux issues: Make sure proot is installed (pkg install proot)

#{YELLOW}LOGS LOCATION:#{RESET}
  #{LOG_DIR}

#{YELLOW}SUPPORTED PLATFORMS:#{RESET}
  • Linux (Debian, Ubuntu, Arch, Fedora)
  • Termux (Android)
  • Any system with Ruby support

#{CYAN}═══════════════════════════════════════════════════════════#{RESET}
  HELP_TEXT
  ask "\nPress ENTER to continue..."
  gets
end

# ------------------ SIGNAL HANDLERS ------------------

def setup_signal_handlers
  Signal.trap("INT") do
    puts "\n\n#{CYAN}Caught interrupt signal...#{RESET}"
    cleanup
    puts "#{GREEN}Thanks for using Local2Internet! 👋#{RESET}\n"
    exit 0
  end

  Signal.trap("TERM") do
    cleanup
    exit 0
  end
end

# ------------------ MAIN PROGRAM ------------------

def main_menu(config)
  loop do
    system("clear")
    puts LOGO
    puts "\n#{YELLOW}╔════════════════════════════════════════╗#{RESET}"
    puts "#{YELLOW}║            MAIN MENU                   ║#{RESET}"
    puts "#{YELLOW}╚════════════════════════════════════════╝#{RESET}\n"
    puts "1) Start Server & Tunnels"
    puts "2) Manage API Keys"
    puts "3) Help & Documentation"
    puts "4) About"
    puts "0) Exit"
    
    # Show API key status
    puts "\n#{CYAN}API Keys Status:#{RESET}"
    ngrok_status = config.has?('ngrok_token') ? "#{GREEN}Configured#{RESET}" : "#{RED}Not Set#{RESET}"
    loclx_status = config.has?('loclx_token') ? "#{GREEN}Configured#{RESET}" : "#{RED}Not Set#{RESET}"
    puts "  Ngrok: #{ngrok_status} | Loclx: #{loclx_status}"
    
    ask "\nChoice: "
    choice = gets.chomp.strip

    case choice
    when "1"
      run_server(config)
    when "2"
      manage_api_keys(config)
    when "3"
      show_help
    when "4"
      show_about
    when "0"
      cleanup
      puts "\n#{GREEN}Goodbye! 👋#{RESET}\n"
      exit 0
    else
      warn "Invalid choice! Please select 1-4 or 0"
      sleep 2
    end
  end
end

def run_server(config)
  system("clear")
  puts LOGO
  
  # Get user inputs
  path = get_directory
  server_mode = select_server
  port = get_port
  
  # Enable hotspot reminder for Termux
  if termux?
    warn "Termux detected!"
    warn "For best results, enable mobile hotspot or connect to WiFi"
    sleep 2
  end
  
  # Start local server
  start_server(path, port, server_mode)
  
  # Start tunnels
  urls = start_all_tunnels(port, config)
  
  # Display results
  has_urls = display_results(urls)
  
  # Keep alive
  puts "\n#{RED}Press CTRL+C to stop and return to menu#{RESET}\n"
  begin
    loop { sleep 10 }
  rescue SystemExit, Interrupt
    # Handled by signal trap
  end
end

# ------------------ ENTRY POINT ------------------

begin
  setup_signal_handlers
  cleanup # Clean any previous instances
  ensure_dirs
  
  # Initialize config manager
  config = ConfigManager.new
  
  # Install dependencies and tools
  install_dependencies
  download_tools
  
  # Show welcome message on first run
  unless config.has?('first_run_done')
    system("clear")
    puts LOGO
    puts "\n#{GREEN}╔════════════════════════════════════════╗#{RESET}"
    puts "#{GREEN}║     WELCOME TO LOCAL2INTERNET v#{VERSION}   ║#{RESET}"
    puts "#{GREEN}╚════════════════════════════════════════╝#{RESET}\n"
    puts "#{CYAN}First-time setup complete!#{RESET}"
    puts "#{YELLOW}• All dependencies installed#{RESET}"
    puts "#{YELLOW}• Tunneling tools downloaded#{RESET}"
    puts "#{YELLOW}• Ready to expose your localhost!#{RESET}\n"
    puts "#{CYAN}TIP: Configure API keys for premium features (Menu option 2)#{RESET}\n"
    config.set('first_run_done', true)
    sleep 3
  end
  
  # Start main menu
  main_menu(config)
  
rescue StandardError => e
  puts "\n#{RED}[FATAL ERROR] #{e.message}#{RESET}"
  puts e.backtrace.join("\n") if ENV["DEBUG"]
  cleanup
  exit 1
end
