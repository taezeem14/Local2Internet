#!/usr/bin/env ruby
# ==========================================================
# Local2Internet v4 - Professional Open-Source Edition
#
# Description:
#   Expose a local directory to the internet using
#   Python, PHP, or NodeJS with tunneling via:
#   - Ngrok
#   - Cloudflare Tunnel
#   - Loclx
#
# Original Author  : KasRoudra
# Contributor      : Muhammad Taezeem Tariq Matta
# Repository       : Open Source
# License          : MIT
# ==========================================================

require 'fileutils'
require 'json'

# ------------------ CONFIGURATION ------------------

HOME = ENV["HOME"]
BASE_DIR = "#{HOME}/.local2internet"
LOG_DIR  = "#{BASE_DIR}/logs"
BIN_DIR  = "#{BASE_DIR}/bin"

TOOLS = {
  ngrok: "#{BIN_DIR}/ngrok",
  cloudflared: "#{BIN_DIR}/cloudflared",
  loclx: "#{BIN_DIR}/loclx"
}

DEPENDENCIES = %w[python3 php wget unzip curl]
DEFAULT_PORT = 8888

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

LOGO = """
#{RED}
▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀ 
#{YELLOW}▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░ 
#{GREEN}▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░
#{BLUE}                                                    [v4 Enhanced - FIXED]
#{RESET}
"""

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
  Dir.exist?("/data/data/com.termux/files/home")
end

# ------------------ CLEANUP ------------------

def cleanup
  info "Cleaning up processes..."
  %w[php ngrok cloudflared wget curl unzip python3 http-server loclx].each do |proc|
    exec_silent("killall #{proc}")
  end
  sleep 1
end

# ------------------ DEPENDENCY MANAGER ------------------

def check_package(pkg)
  `dpkg -l | grep -o #{pkg}`.include?(pkg)
end

def install_dependencies
  info "Checking system dependencies..."

  DEPENDENCIES.each do |dep|
    pkg_name = dep == "python3" ? "python" : dep
    
    unless check_package(pkg_name)
      info "Installing #{dep}..."
      exec_silent("apt install #{dep} -y") || abort_with("Failed to install #{dep}")
    end
  end

  # Check NodeJS separately
  unless check_package("node")
    info "Installing NodeJS..."
    exec_silent("apt install nodejs -y") || abort_with("Failed to install nodejs")
  end

  # Install http-server globally
  unless `npm list -g --depth=0 2>/dev/null | grep -o http-server`.include?("http-server")
    info "Installing Node http-server..."
    exec_silent("npm install -g http-server") || abort_with("Failed to install http-server")
  end

  # Termux specific: proot
  if termux? && !command_exists?("proot")
    info "Installing proot (Termux)..."
    exec_silent("pkg install proot -y")
  end
end

# ------------------ TOOL DOWNLOADS ------------------

def download_ngrok
  return if File.exist?(TOOLS[:ngrok])

  info "Downloading ngrok..."

  url = case arch
  when /arm(?!64)/ then "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-arm.zip"
  when /aarch64|arm64/ then "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-arm64.tgz"
  when /x86_64/ then "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-amd64.zip"
  else "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-386.zip"
  end

  tmp = "#{BASE_DIR}/ngrok.tmp"
  
  unless exec_silent("wget -q --show-progress #{url} -O #{tmp}")
    abort_with("Failed to download ngrok - check your internet connection")
  end

  if url.include?(".tgz")
    unless exec_silent("tar -xzf #{tmp} -C #{BIN_DIR}")
      File.delete(tmp) if File.exist?(tmp)
      abort_with("Failed to extract ngrok")
    end
  else
    unless exec_silent("unzip -q #{tmp} -d #{BIN_DIR}")
      File.delete(tmp) if File.exist?(tmp)
      abort_with("Failed to extract ngrok")
    end
  end

  exec_silent("chmod +x #{TOOLS[:ngrok]}")
  File.delete(tmp) if File.exist?(tmp)
  success "Ngrok installed!"
end

def download_cloudflared
  return if File.exist?(TOOLS[:cloudflared])

  info "Downloading cloudflared..."

  url = case arch
  when /arm(?!64)/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
  when /aarch64|arm64/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
  when /x86_64/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
  else "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386"
  end

  if exec_silent("wget -q --show-progress #{url} -O #{TOOLS[:cloudflared]}")
    exec_silent("chmod +x #{TOOLS[:cloudflared]}")
    success "Cloudflared installed!"
  else
    warn "Failed to download cloudflared (non-critical)"
  end
end

def download_loclx
  return if File.exist?(TOOLS[:loclx])

  info "Downloading loclx..."

  url = case arch
  when /arm(?!64)/ then "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-arm.zip"
  when /aarch64|arm64/ then "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-arm64.zip"
  when /x86_64/ then "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-amd64.zip"
  else "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-386.zip"
  end

  tmp = "#{BASE_DIR}/loclx.zip"
  
  if exec_silent("wget -q --show-progress #{url} -O #{tmp}")
    if exec_silent("unzip -q #{tmp} -d #{BIN_DIR}")
      exec_silent("chmod +x #{TOOLS[:loclx]}")
      File.delete(tmp) if File.exist?(tmp)
      success "Loclx installed!"
    else
      warn "Failed to extract loclx (non-critical)"
      File.delete(tmp) if File.exist?(tmp)
    end
  else
    warn "Failed to download loclx (non-critical)"
    File.delete(tmp) if File.exist?(tmp)
  end
end

def download_tools
  download_ngrok
  download_cloudflared
  download_loclx
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

  sleep 2

  # Verify server started
  status = `curl -s --head -w %{http_code} 127.0.0.1:#{port} -o /dev/null 2>&1`.strip
  if status.include?("000") || status.empty?
    abort_with("Local server failed to start!")
  end

  success "Server running at http://127.0.0.1:#{port}"
end

# ------------------ TUNNEL MANAGER ------------------

def start_ngrok(port)
  info "Starting Ngrok tunnel..."
  
  cmd = termux? ? 
    "cd #{BIN_DIR} && termux-chroot ./ngrok http #{port} &" :
    "#{TOOLS[:ngrok]} http #{port} > /dev/null 2>&1 &"
  
  exec_silent(cmd)
  sleep 5

  url = `curl -s http://127.0.0.1:4040/api/tunnels 2>/dev/null | grep -o "https://[^\"]*ngrok.io"`.strip
  url.empty? ? nil : url
end

def start_cloudflare(port)
  info "Starting Cloudflare tunnel..."
  
  File.delete(log_file("cloudflare")) if File.exist?(log_file("cloudflare"))
  
  cmd = termux? ?
    "cd #{BIN_DIR} && termux-chroot ./cloudflared tunnel -url 127.0.0.1:#{port} --logfile #{log_file("cloudflare")} &" :
    "#{TOOLS[:cloudflared]} tunnel -url 127.0.0.1:#{port} --logfile #{log_file("cloudflare")} > /dev/null 2>&1 &"
  
  exec_silent(cmd)
  sleep 6

  url = `grep -o "https://[^ ]*trycloudflare.com" #{log_file("cloudflare")} 2>/dev/null`.strip
  url.empty? ? nil : url
end

def start_loclx(port)
  info "Starting Loclx tunnel..."
  
  File.delete(log_file("loclx")) if File.exist?(log_file("loclx"))
  
  cmd = termux? ?
    "cd #{BIN_DIR} && termux-chroot ./loclx tunnel http --to :#{port} > #{log_file("loclx")} 2>&1 &" :
    "#{TOOLS[:loclx]} tunnel http --to :#{port} > #{log_file("loclx")} 2>&1 &"
  
  exec_silent(cmd)
  sleep 6

  url = `grep -o "https://[^ ]*loclx.io" #{log_file("loclx")} 2>/dev/null`.strip
  url.empty? ? nil : url
end

def start_all_tunnels(port)
  warn "Starting all tunnels (this may take a moment)..." if termux?
  
  results = {}
  
  # Only start ngrok if binary exists
  if File.exist?(TOOLS[:ngrok])
    results[:ngrok] = start_ngrok(port)
  else
    warn "Ngrok binary not found, skipping..."
    results[:ngrok] = nil
  end
  
  # Only start cloudflare if binary exists
  if File.exist?(TOOLS[:cloudflared])
    results[:cloudflare] = start_cloudflare(port)
  else
    warn "Cloudflared binary not found, skipping..."
    results[:cloudflare] = nil
  end
  
  # Only start loclx if binary exists
  if File.exist?(TOOLS[:loclx])
    results[:loclx] = start_loclx(port)
  else
    warn "Loclx binary not found, skipping..."
    results[:loclx] = nil
  end
  
  results
end

# ------------------ CLI INTERFACE ------------------

def select_server
  puts "\n#{YELLOW}Select hosting protocol:#{RESET}"
  puts "1) Python (http.server)"
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
    
    # Handle empty input
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
      warn "Please enter a valid absolute or relative path (without 'cd')"
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
  
  port_num
end

def display_results(urls)
  puts "\n#{GREEN}╔════════════════════════════════════════╗#{RESET}"
  puts "#{GREEN}║          PUBLIC URLS READY!            ║#{RESET}"
  puts "#{GREEN}╚════════════════════════════════════════╝#{RESET}\n"
  
  active_count = 0
  
  urls.each do |service, url|
    if url
      success "#{service.to_s.capitalize}: #{CYAN}#{url}#{RESET}"
      active_count += 1
    else
      warn "#{service.to_s.capitalize}: Failed to start"
    end
  end
  
  if active_count == 0
    puts "\n#{RED}All tunnels failed to start!#{RESET}"
    warn "This might be due to network issues or firewall restrictions"
    warn "You can still access your server locally at the displayed port"
    return false
  else
    puts "\n#{GREEN}#{active_count}/#{urls.size} tunnels active#{RESET}"
    return true
  end
end

def show_about
  system("clear")
  puts LOGO
  puts """
#{RED}[Tool Name]   #{CYAN}: Local2Internet v4
#{RED}[Version]     #{CYAN}: 4.0 Enhanced (Fixed)
#{RED}[Description] #{CYAN}: LocalHost Exposing Tool
#{RED}[Author]      #{CYAN}: KasRoudra
#{RED}[Contributor] #{CYAN}: Muhammad Taezeem Tariq Matta
#{RED}[Github]      #{CYAN}: https://github.com/KasRoudra
#{RED}[License]     #{CYAN}: MIT Open Source
#{RESET}
"""
  ask "Press ENTER to continue..."
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

def main_menu
  loop do
    system("clear")
    puts LOGO
    puts "\n#{YELLOW}╔════════════════════════════════════════╗#{RESET}"
    puts "#{YELLOW}║            MAIN MENU                   ║#{RESET}"
    puts "#{YELLOW}╚════════════════════════════════════════╝#{RESET}\n"
    puts "1) Start Server & Tunnels"
    puts "2) About"
    puts "0) Exit"
    
    ask "\nChoice: "
    choice = gets.chomp.strip

    case choice
    when "1"
      run_server
    when "2"
      show_about
    when "0"
      cleanup
      puts "\n#{GREEN}Goodbye! 👋#{RESET}\n"
      exit 0
    else
      warn "Invalid choice! Please select 1, 2, or 0"
      sleep 2
    end
  end
end

def run_server
  system("clear")
  puts LOGO
  
  # Get user inputs
  path = get_directory
  server_mode = select_server
  port = get_port
  
  # Enable hotspot reminder for Termux
  warn "Please enable mobile hotspot if needed..." if termux?
  
  # Start local server
  start_server(path, port, server_mode)
  
  # Start tunnels
  urls = start_all_tunnels(port)
  
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
  install_dependencies
  download_tools
  main_menu
rescue Exception => e
  puts "\n#{RED}[FATAL ERROR] #{e.message}#{RESET}"
  puts e.backtrace.join("\n") if ENV["DEBUG"]
  cleanup
  exit 1
end
