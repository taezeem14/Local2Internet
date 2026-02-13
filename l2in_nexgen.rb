#!/usr/bin/env ruby
# ==========================================================
# Local2Internet v5.0 ULTIMATE - Next Generation Edition
# NGROK AUTH FIX - Proper token authentication
#
# Description:
#   Professional-grade localhost exposure tool with advanced
#   monitoring, auto-recovery, modern UI, and enterprise features
#
# Original Author  : KasRoudra
# Enhanced By      : Muhammad Taezeem Tariq Matta (Bro)
# Ultimate Edition : Claude AI (2026)
# Repository       : github.com/Taezeem14/Local2Internet
# License          : MIT
# ==========================================================

require 'fileutils'
require 'json'
require 'yaml'
require 'net/http'
require 'uri'
require 'socket'
require 'timeout'
require 'time'

# ------------------ CONFIGURATION ------------------

HOME = ENV["HOME"]
BASE_DIR = "#{HOME}/.local2internet"
LOG_DIR  = "#{BASE_DIR}/logs"
BIN_DIR  = "#{BASE_DIR}/bin"
STATS_DIR = "#{BASE_DIR}/stats"
CONFIG_FILE = "#{BASE_DIR}/config.yml"
SESSION_FILE = "#{BASE_DIR}/session.json"

TOOLS = {
  ngrok: "#{BIN_DIR}/ngrok",
  cloudflared: "#{BIN_DIR}/cloudflared",
  loclx: "#{BIN_DIR}/loclx"
}

DEPENDENCIES = %w[python3 php wget unzip curl]
DEFAULT_PORT = 8888
VERSION = "6.0"
EDITION = "ULTIMATE"

# ------------------ ENHANCED COLORS & UI ------------------

module Colors
  BLACK   = "\033[0;30m"
  RED     = "\033[0;31m"
  GREEN   = "\033[0;32m"
  YELLOW  = "\033[0;33m"
  BLUE    = "\033[0;34m"
  PURPLE  = "\033[0;35m"
  CYAN    = "\033[0;36m"
  WHITE   = "\033[0;37m"
  
  # Bright variants
  BRED    = "\033[1;31m"
  BGREEN  = "\033[1;32m"
  BYELLOW = "\033[1;33m"
  BBLUE   = "\033[1;34m"
  BPURPLE = "\033[1;35m"
  BCYAN   = "\033[1;36m"
  BWHITE  = "\033[1;37m"
  
  # Backgrounds
  BG_RED    = "\033[41m"
  BG_GREEN  = "\033[42m"
  BG_YELLOW = "\033[43m"
  BG_BLUE   = "\033[44m"
  BG_PURPLE = "\033[45m"
  BG_CYAN   = "\033[46m"
  
  RESET   = "\033[0m"
  BOLD    = "\033[1m"
  DIM     = "\033[2m"
  ITALIC  = "\033[3m"
  UNDERLINE = "\033[4m"
  BLINK   = "\033[5m"
end

include Colors

# ------------------ MODERN LOGO ------------------

LOGO = <<~LOGO_TEXT
#{BPURPLE}╔═══════════════════════════════════════════════════════════════════╗
#{BPURPLE}║  #{BRED}▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀#{BPURPLE}  ║
#{BPURPLE}║  #{BYELLOW}▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░#{BPURPLE}  ║
#{BPURPLE}║  #{BGREEN}▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░#{BPURPLE}  ║
╚═══════════════════════════════════════════════════════════════════╝
    #{BCYAN}v#{VERSION} #{EDITION} Edition#{RESET} #{DIM}• Professional Grade Tunneling#{RESET}
    #{DIM}Multi-Protocol • Auto-Recovery • Real-Time Monitoring#{RESET}
#{RESET}
LOGO_TEXT

# ------------------ ENHANCED UI COMPONENTS ------------------

class UI
  def self.header(title)
    width = 70
    padding = (width - title.length - 2) / 2
    puts "\n#{BPURPLE}╔#{'═' * width}╗"
    puts "#{BPURPLE}║#{' ' * padding}#{BWHITE}#{title}#{BPURPLE}#{' ' * (width - padding - title.length)}║"
    puts "#{BPURPLE}╚#{'═' * width}╝#{RESET}\n"
  end

  def self.box(lines, color = BCYAN)
    max_width = lines.map(&:length).max + 4
    puts "\n#{color}╔#{'═' * max_width}╗"
    lines.each do |line|
      padding = max_width - line.length - 2
      puts "#{color}║ #{BWHITE}#{line}#{' ' * padding}#{color}║"
    end
    puts "#{color}╚#{'═' * max_width}╝#{RESET}\n"
  end

  def self.progress_bar(current, total, width = 40)
    return if total <= 0
    percentage = (current.to_f / total * 100).round
    filled = (width * current / total.to_f).round
    bar = "#{BGREEN}#{'█' * filled}#{DIM}#{'░' * (width - filled)}#{RESET}"
    print "\r#{BCYAN}[#{bar}#{BCYAN}] #{BWHITE}#{percentage}%#{RESET}"
    puts if current >= total
  end

  def self.spinner(message)
    spinners = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏']
    i = 0
    thread = Thread.new do
      loop do
        print "\r#{BCYAN}#{spinners[i]} #{BWHITE}#{message}#{RESET}"
        i = (i + 1) % spinners.length
        sleep 0.1
      end
    end
    yield
    thread.kill
    print "\r#{' ' * (message.length + 5)}\r"
  end

  def self.table(headers, rows)
    col_widths = headers.each_with_index.map do |header, i|
      [header.length, *rows.map { |row| row[i].to_s.length }].max + 2
    end

    # Header
    puts "\n#{BPURPLE}┌#{col_widths.map { |w| '─' * w }.join('┬')}┐"
    puts "#{BPURPLE}│#{headers.each_with_index.map { |h, i| " #{BWHITE}#{h.ljust(col_widths[i] - 1)}#{BPURPLE}" }.join('│')}│"
    puts "#{BPURPLE}├#{col_widths.map { |w| '─' * w }.join('┼')}┤"

    # Rows
    rows.each do |row|
      puts "#{BPURPLE}│#{row.each_with_index.map { |cell, i| " #{WHITE}#{cell.to_s.ljust(col_widths[i] - 1)}#{BPURPLE}" }.join('│')}│"
    end
    
    puts "#{BPURPLE}└#{col_widths.map { |w| '─' * w }.join('┴')}┘#{RESET}\n"
  end
end

# ------------------ UTILITIES ------------------

def success(msg, icon = "-✓-")
  puts "#{BGREEN}[#{icon}]#{BWHITE} #{msg}#{RESET}"
end

def info(msg, icon = "-ℹ-")
  puts "#{BCYAN}[#{icon}]#{BWHITE} #{msg}#{RESET}"
end

def warn(msg, icon = "-⚠-")
  puts "#{BYELLOW}[#{icon}]#{BWHITE} #{msg}#{RESET}"
end

def error(msg, icon = "-✗-")
  puts "#{BRED}[#{icon}]#{BWHITE} #{msg}#{RESET}"
end

def ask(msg, icon = "--❯")
  print "#{BYELLOW}[#{icon}]#{BWHITE} #{msg}#{RESET}"
end

def log_event(event, details = {})
  begin
    timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
    log_entry = {
      timestamp: timestamp,
      event: event,
      details: details
    }
    
    log_file = "#{LOG_DIR}/events.log"
    File.open(log_file, 'a') do |f|
      f.puts log_entry.to_json
    end
  rescue => e
    # Silently fail logging to avoid breaking main flow
  end
end

def command_exists?(cmd)
  system("command -v #{cmd} > /dev/null 2>&1")
end

def ensure_dirs
  [BASE_DIR, LOG_DIR, BIN_DIR, STATS_DIR].each do |d|
    begin
      FileUtils.mkdir_p(d)
    rescue => e
      warn "Failed to create directory #{d}: #{e.message}"
    end
  end
end

def arch
  @arch ||= `uname -m`.strip
end

def termux?
  @is_termux ||= Dir.exist?("/data/data/com.termux/files/home")
end

def proot_available?
  command_exists?("proot")
end

def exec_silent(cmd)
  system(cmd + " > /dev/null 2>&1")
end

# ------------------ NETWORK UTILITIES ------------------

class NetworkUtils
  def self.port_available?(port)
    begin
      Timeout::timeout(1) do
        begin
          s = TCPServer.new('127.0.0.1', port)
          s.close
          return true
        rescue Errno::EADDRINUSE, Errno::EACCES
          return false
        end
      end
    rescue Timeout::Error
      return false
    end
  end

  def self.find_available_port(start_port = 8888)
    (start_port..65535).each do |port|
      return port if port_available?(port)
    end
    nil
  end

  def self.check_internet
    begin
      Timeout::timeout(5) do
        Socket.tcp("1.1.1.1", 80, connect_timeout: 5) {}
        return true
      end
    rescue
      return false
    end
  end

  def self.get_local_ip
    Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? }&.ip_address || "127.0.0.1"
  end

  def self.ping_url(url)
    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == 'https')
      http.open_timeout = 5
      http.read_timeout = 5
      
      response = http.head(uri.path.empty? ? '/' : uri.path)
      return response.code.to_i < 400
    rescue
      return false
    end
  end
end

# ------------------ CONFIGURATION MANAGER ------------------

class ConfigManager
  def initialize
    @config = load_config
  end

  def load_config
    if File.exist?(CONFIG_FILE)
      begin
        YAML.safe_load(File.read(CONFIG_FILE), permitted_classes: [Symbol, Time], aliases: true) || {}
      rescue => e
        warn "Failed to load config: #{e.message}"
        {}
      end
    else
      {}
    end
  end

  def save_config
    begin
      FileUtils.mkdir_p(File.dirname(CONFIG_FILE))
      File.write(CONFIG_FILE, @config.to_yaml)
      true
    rescue => e
      warn "Failed to save config: #{e.message}"
      false
    end
  end

  def get(key, default = nil)
    @config[key.to_s] || default
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

  def all
    @config
  end
end

# ------------------ SESSION MANAGER ------------------

class SessionManager
  def self.save_session(data)
    begin
      File.write(SESSION_FILE, data.to_json)
    rescue => e
      warn "Failed to save session: #{e.message}"
    end
  end

  def self.load_session
    return {} unless File.exist?(SESSION_FILE)
    begin
      JSON.parse(File.read(SESSION_FILE))
    rescue => e
      {}
    end
  end

  def self.clear_session
    File.delete(SESSION_FILE) if File.exist?(SESSION_FILE)
  rescue => e
    # Silently ignore
  end

  def self.active?
    data = load_session
    data['active'] == true && data['pid'] && process_running?(data['pid'])
  end

  def self.process_running?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end
end

# ------------------ PROCESS MANAGER ------------------

class ProcessManager
  @processes = {}

  def self.register(name, pid)
    @processes[name] = pid
    log_event("process_started", { name: name, pid: pid })
  end

  def self.kill(name)
    pid = @processes[name]
    return unless pid
    
    begin
      Process.kill("TERM", pid)
      sleep 1
      Process.kill("KILL", pid) if process_running?(pid)
      log_event("process_killed", { name: name, pid: pid })
    rescue => e
      # Process already dead
    end
    
    @processes.delete(name)
  end

  def self.kill_all
    @processes.keys.each { |name| kill(name) }
  end

  def self.cleanup
    info "Cleaning up processes..."
    
    %w[ngrok loclx http-server].each do |proc|
      exec_silent("pkill -f #{proc}")
    end
    
    exec_silent("pkill -f 'cloudflared tunnel'")
    exec_silent("pkill -f 'python3 -m http.server'")
    exec_silent("pkill -f 'php -S'")
    
    kill_all
    sleep 1
    success "Cleanup complete"
  end

  def self.process_running?(pid)
    Process.kill(0, pid)
    true
  rescue Errno::ESRCH, Errno::EPERM
    false
  end
end

# ------------------ STATISTICS TRACKER ------------------

class StatsTracker
  def initialize
    @stats_file = "#{STATS_DIR}/usage_stats.json"
    @stats = load_stats
  end

  def load_stats
    return {} unless File.exist?(@stats_file)
    begin
      JSON.parse(File.read(@stats_file))
    rescue => e
      {}
    end
  end

  def save_stats
    begin
      File.write(@stats_file, JSON.pretty_generate(@stats))
    rescue => e
      warn "Failed to save stats: #{e.message}"
    end
  end

  def record_session(duration, tunnels_used, protocol)
    @stats['total_sessions'] ||= 0
    @stats['total_duration'] ||= 0
    @stats['tunnels_count'] ||= Hash.new(0)
    @stats['protocols_used'] ||= Hash.new(0)
    
    @stats['total_sessions'] += 1
    @stats['total_duration'] += duration
    
    tunnels_used.each { |tunnel| @stats['tunnels_count'][tunnel.to_s] += 1 }
    @stats['protocols_used'][protocol.to_s] += 1
    
    save_stats
  end

  def display_stats
    UI.header("📊 USAGE STATISTICS")
    
    return info("No statistics available yet") if @stats.empty?
    
    puts "#{BCYAN}Total Sessions:#{BWHITE} #{@stats['total_sessions'] || 0}#{RESET}"
    puts "#{BCYAN}Total Runtime:#{BWHITE} #{format_duration(@stats['total_duration'] || 0)}#{RESET}"
    
    if @stats['tunnels_count']
      puts "\n#{BPURPLE}Tunnel Usage:#{RESET}"
      @stats['tunnels_count'].each do |tunnel, count|
        puts "  #{BWHITE}#{tunnel.capitalize}:#{RESET} #{count} times"
      end
    end
    
    if @stats['protocols_used']
      puts "\n#{BPURPLE}Protocol Preference:#{RESET}"
      @stats['protocols_used'].each do |protocol, count|
        puts "  #{BWHITE}#{protocol.capitalize}:#{RESET} #{count} times"
      end
    end
    
    puts ""
  end

  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60
    
    parts = []
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{secs}s"
    
    parts.join(' ')
  end
end

# ------------------ DEPENDENCY MANAGER ------------------

class DependencyManager
  def self.check_and_install
    info "Checking system dependencies..."
    
    pkg_cmd = termux? ? "pkg" : "apt"
    missing = []
    
    DEPENDENCIES.each do |dep|
      pkg_name = dep == "python3" ? "python" : dep
      
      unless check_package(pkg_name) || command_exists?(dep)
        missing << dep
      end
    end
    
    # Check NodeJS
    unless check_package("nodejs") || command_exists?("node")
      missing << "nodejs"
    end
    
    if missing.empty?
      success "All dependencies installed"
      return true
    end
    
    warn "Missing dependencies: #{missing.join(', ')}"
    ask "\nInstall missing dependencies? (y/N): "
    return false unless gets.chomp.downcase == 'y'
    
    UI.spinner("Installing dependencies") do
      missing.each_with_index do |dep, i|
        UI.progress_bar(i, missing.length)
        exec_silent("#{pkg_cmd} install #{dep} -y")
      end
      UI.progress_bar(missing.length, missing.length)
    end
    
    # Install http-server
    if command_exists?("npm")
      unless `npm list -g --depth=0 2>/dev/null | grep -o http-server`.include?("http-server")
        info "Installing http-server..."
        exec_silent("npm install -g http-server")
      end
    end
    
    # Termux: proot
    if termux? && !proot_available?
      info "Installing proot for Termux compatibility..."
      exec_silent("pkg install proot -y")
    end
    
    success "Dependencies installed successfully"
    true
  end

  def self.check_package(pkg)
    `dpkg -l 2>/dev/null | grep -o #{pkg}`.include?(pkg) ||
    `pkg list-installed 2>/dev/null | grep -o #{pkg}`.include?(pkg)
  end
end

# ------------------ TOOL DOWNLOADER ------------------

class ToolDownloader
  def self.download_all
    info "Checking tunneling tools..."
    
    tools_status = {
      ngrok: File.exist?(TOOLS[:ngrok]),
      cloudflared: File.exist?(TOOLS[:cloudflared]),
      loclx: File.exist?(TOOLS[:loclx])
    }
    
    to_download = tools_status.select { |_, exists| !exists }.keys
    
    if to_download.empty?
      success "All tools installed"
      return true
    end
    
    info "Downloading: #{to_download.map(&:to_s).join(', ')}"
    
    to_download.each_with_index do |tool, i|
      UI.progress_bar(i, to_download.length)
      
      case tool
      when :ngrok then download_ngrok
      when :cloudflared then download_cloudflared
      when :loclx then download_loclx
      end
      
      sleep 0.5
    end
    
    UI.progress_bar(to_download.length, to_download.length)
    success "All tools downloaded"
    true
  end

  def self.download_ngrok
    url = case arch
    when /arm(?!64)/ then "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm.tgz"
    when /aarch64|arm64/ then "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz"
    when /x86_64/ then "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz"
    else "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-386.tgz"
    end

    tmp = "#{BASE_DIR}/ngrok.tmp"
    
    return false unless exec_silent("wget -q #{url} -O #{tmp}")
    return false unless exec_silent("tar -xzf #{tmp} -C #{BIN_DIR}")
    
    exec_silent("chmod +x #{TOOLS[:ngrok]}")
    File.delete(tmp) if File.exist?(tmp)
    true
  end

  def self.download_cloudflared
    url = if termux? && arch.match?(/aarch64|arm64/)
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    else
      case arch
      when /arm(?!64)/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
      when /aarch64|arm64/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
      when /x86_64/ then "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
      else "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386"
      end
    end

    return false unless exec_silent("wget -q #{url} -O #{TOOLS[:cloudflared]}")
    exec_silent("chmod +x #{TOOLS[:cloudflared]}")
    true
  end

  def self.download_loclx
    # Determine correct architecture-specific binary
    url = case arch
    when /arm(?!64)/ then "npm install -g loclx"
    when /aarch64|arm64/ then "npm install -g loclx"
    when /x86_64/ then "npm install -g loclx"
    else "npm install -g loclx"
    end
    
    tmp = "#{BASE_DIR}/loclx.tmp"

    return false unless exec_silent("wget -q #{url} -O #{tmp}")
    return false unless exec_silent("tar -xzf #{tmp} -C #{BIN_DIR}")
    
    # The extracted binary might be named 'loclx' already
    exec_silent("mv #{BIN_DIR}/loclx #{TOOLS[:loclx]} 2>/dev/null")
    exec_silent("chmod +x #{TOOLS[:loclx]}")
    
    File.delete(tmp) rescue nil
    File.exist?(TOOLS[:loclx])
  end
end

# ------------------ TUNNEL MANAGER ------------------

class TunnelManager
  def initialize(port, config)
    @port = port
    @config = config
    @tunnels = {}
    @monitoring = false
  end

  def start_ngrok
    info "Starting Ngrok tunnel..."
    log_file = "#{LOG_DIR}/ngrok.log"
    File.delete(log_file) if File.exist?(log_file)

    # Apply authtoken if configured
    if @config.has?('ngrok_token')
      token = @config.get('ngrok_token')
      info "Applying Ngrok authtoken..."
      
      # Use ngrok authtoken command (works for v2 and v3)
      auth_result = system("#{TOOLS[:ngrok]} authtoken #{token} > /dev/null 2>&1")
      
      if auth_result
        success "Ngrok authenticated successfully"
      else
        warn "Ngrok authentication may have failed"
      end
    else
      warn "Ngrok authtoken not configured (may have rate limits)"
    end

    cmd = "#{TOOLS[:ngrok]} http --log=stdout --log-level=info #{@port}"
    cmd = "cd #{BIN_DIR} && termux-chroot #{cmd}" if termux? && proot_available?

    pid = spawn("#{cmd} > #{log_file} 2>&1")
    ProcessManager.register(:ngrok, pid)
    
    sleep(termux? ? 8 : 5)

    # Try API first (best method)
    12.times do
      begin
        uri = URI.parse("http://127.0.0.1:4040/api/tunnels")
        response = Net::HTTP.get(uri)
        data = JSON.parse(response)
        
        if data['tunnels'] && data['tunnels'][0]
          url = data['tunnels'][0]['public_url']
          
          # Check if it's the auth error URL
          if url && !url.include?('dashboard.ngrok.com')
            return url.gsub('http://', 'https://')
          elsif url && url.include?('dashboard.ngrok.com')
            error "Ngrok authentication required!"
            warn "Please configure your authtoken in API Key Management (Menu option 2)"
            return nil
          end
        end
      rescue => e
        # Continue retrying
      end
      
      sleep 1
    end

    # Fallback: parse logs
    6.times do
      if File.exist?(log_file)
        # Check for auth error first
        if File.read(log_file).include?('dashboard.ngrok.com/get-started/your-authtoken')
          error "Ngrok authentication required!"
          warn "Get your authtoken from: https://dashboard.ngrok.com/get-started/your-authtoken"
          warn "Then configure it in API Key Management (Menu option 2)"
          return nil
        end
        
        url = `grep -o "https://[a-zA-Z0-9.-]*\.ngrok[^ ]*" #{log_file} 2>/dev/null | head -1`.strip
        
        # Make sure it's not the dashboard URL
        if !url.empty? && !url.include?('dashboard.ngrok.com')
          return url
        end
      end
      sleep 1
    end

    nil
  end

  def start_cloudflare
    info "Starting Cloudflare tunnel..."
    log_file = "#{LOG_DIR}/cloudflare.log"
    File.delete(log_file) if File.exist?(log_file)

    cmd = "#{TOOLS[:cloudflared]} tunnel --url http://127.0.0.1:#{@port}"
    cmd = "cd #{BIN_DIR} && termux-chroot #{cmd}" if termux? && proot_available?

    pid = spawn("#{cmd} > #{log_file} 2>&1")
    ProcessManager.register(:cloudflared, pid)
    
    sleep(termux? ? 12 : 7)

    20.times do
      if File.exist?(log_file)
        url = `grep -o "https://[^ ]*trycloudflare.com" #{log_file} 2>/dev/null | head -1`.strip
        return url unless url.empty?
      end
      sleep 1
    end

    nil
  end

  def start_loclx
    info "Starting Loclx tunnel..."
    log_file = "#{LOG_DIR}/loclx.log"
    File.delete(log_file) if File.exist?(log_file)

    cmd = "#{TOOLS[:loclx]} tunnel http --to :#{@port} --region=us"
    cmd += " --token=#{@config.get('loclx_token')}" if @config.has?('loclx_token')

    cmd = "cd #{BIN_DIR} && termux-chroot #{cmd}" if termux? && proot_available?

    pid = spawn("#{cmd} > #{log_file} 2>&1")
    ProcessManager.register(:loclx, pid)
    
    sleep(termux? ? 10 : 6)

    20.times do
      if File.exist?(log_file)
        url = `grep -o "https://[a-zA-Z0-9.-]*\.loclx.io" #{log_file} 2>/dev/null | head -1`.strip
        return url unless url.empty?
      end
      sleep 1
    end

    nil
  end

  def start_all
    warn "Initializing all tunnels..." if termux?
    
    results = {}
    
    if File.exist?(TOOLS[:ngrok])
      results[:ngrok] = start_ngrok
    else
      warn "Ngrok binary not found"
    end

    if File.exist?(TOOLS[:cloudflared])
      results[:cloudflare] = start_cloudflare
    else
      warn "Cloudflared binary not found"
    end

    if File.exist?(TOOLS[:loclx])
      results[:loclx] = start_loclx
    else
      warn "Loclx binary not found"
    end

    @tunnels = results
    results
  end

  def start_monitoring
    @monitoring = true
    
    Thread.new do
      while @monitoring
        sleep 30
        check_tunnel_health
      end
    end
  end

  def stop_monitoring
    @monitoring = false
  end

  def check_tunnel_health
    @tunnels.each do |service, url|
      next unless url
      
      if NetworkUtils.ping_url(url)
        log_event("tunnel_health_check", { service: service, status: "healthy" })
      else
        warn "#{service.to_s.capitalize} tunnel appears down, attempting recovery..."
        log_event("tunnel_health_check", { service: service, status: "unhealthy" })
        
        # Attempt recovery
        ProcessManager.kill(service)
        sleep 2
        
        new_url = case service
        when :ngrok then start_ngrok
        when :cloudflare then start_cloudflare
        when :loclx then start_loclx
        end
        
        if new_url
          @tunnels[service] = new_url
          success "#{service.to_s.capitalize} tunnel recovered: #{new_url}"
        else
          error "Failed to recover #{service.to_s.capitalize} tunnel"
        end
      end
    end
  end
end

# ------------------ SERVER MANAGER ------------------

class ServerManager
  def initialize(path, port, mode)
    @path = path
    @port = port
    @mode = mode
  end

  def start
    info "Starting #{@mode.to_s.upcase} server on port #{@port}..."
    
    case @mode
    when :python
      pid = spawn("cd #{@path} && python3 -m http.server #{@port} > /dev/null 2>&1")
    when :php
      unless File.exist?("#{@path}/index.php") || File.exist?("#{@path}/index.html")
        error "No index.php or index.html found in directory!"
        return false
      end
      pid = spawn("cd #{@path} && php -S 127.0.0.1:#{@port} > /dev/null 2>&1")
    when :node
      pid = spawn("cd #{@path} && http-server -p #{@port} > /dev/null 2>&1")
    else
      error "Invalid server mode"
      return false
    end

    ProcessManager.register(:server, pid)
    sleep 3

    # Verify server started
    5.times do
      begin
        uri = URI.parse("http://127.0.0.1:#{@port}")
        response = Net::HTTP.get_response(uri)
        
        if response.code.to_i < 400
          success "Server running at http://127.0.0.1:#{@port}"
          log_event("server_started", { mode: @mode, port: @port, path: @path })
          return true
        end
      rescue => e
        # Continue retrying
      end
      sleep 1
    end
    
    error "Local server failed to start!"
    error "Check if port #{@port} is already in use"
    false
  end
end

# ------------------ API KEY MANAGER ------------------

class APIKeyManager
  def initialize(config)
    @config = config
  end

  def manage
    loop do
      system("clear")
      puts LOGO
      UI.header("🔑 API KEY MANAGEMENT")
      
      puts "#{BWHITE}1)#{RESET} Set Ngrok Authtoken"
      puts "#{BWHITE}2)#{RESET} Set Loclx Access Token"
      puts "#{BWHITE}3)#{RESET} View Current Keys"
      puts "#{BWHITE}4)#{RESET} Test API Keys"
      puts "#{BWHITE}5)#{RESET} Remove Keys"
      puts "#{BWHITE}0)#{RESET} Back to Main Menu"
      
      ask "\nChoice: "
      choice = gets.chomp.strip

      case choice
      when "1" then set_ngrok_token
      when "2" then set_loclx_token
      when "3" then view_keys
      when "4" then test_keys
      when "5" then remove_keys
      when "0" then break
      else
        warn "Invalid choice!"
        sleep 1
      end
    end
  end

  def set_ngrok_token
    puts ""
    
    # Check if ngrok is downloaded
    unless File.exist?(TOOLS[:ngrok])
      error "Ngrok binary not found!"
      warn "Please download tools first (run main setup)"
      sleep 3
      return
    end
    
    ask "Enter Ngrok authtoken (from https://dashboard.ngrok.com/get-started/your-authtoken): "
    token = gets.chomp.strip
    
    if token.empty?
      warn "Token cannot be empty!"
      sleep 2
      return
    end
    
    puts ""
    info "Configuring Ngrok authtoken..."
    
    # Use ngrok authtoken command (works for both v2 and v3)
    # This command adds the token to ~/.ngrok2/ngrok.yml
    result = system("#{TOOLS[:ngrok]} authtoken #{token} 2>&1")
    
    if result
      @config.set('ngrok_token', token)
      success "Ngrok authtoken saved and configured!"
      success "Token stored in config and ngrok configuration file"
      log_event("api_key_configured", { service: "ngrok", status: "success" })
    else
      error "Failed to configure ngrok authtoken!"
      error "Please check if the token is valid"
      log_event("api_key_configured", { service: "ngrok", status: "failed" })
    end
    
    sleep 3
  end

  def set_loclx_token
    puts ""
    ask "Enter Loclx access token (from https://localxpose.io): "
    token = gets.chomp.strip
    
    if token.empty?
      warn "Token cannot be empty!"
      sleep 2
      return
    end
    
    @config.set('loclx_token', token)
    success "Loclx access token saved!"
    log_event("api_key_configured", { service: "loclx" })
    sleep 2
  end

  def view_keys
    puts ""
    UI.header("Current API Keys")
    
    ngrok_token = @config.get('ngrok_token')
    loclx_token = @config.get('loclx_token')
    
    rows = [
      ["Ngrok", ngrok_token ? "#{ngrok_token[0..15]}***" : "Not configured", ngrok_token ? "✓" : "✗"],
      ["Loclx", loclx_token ? "#{loclx_token[0..15]}***" : "Not configured", loclx_token ? "✓" : "✗"]
    ]
    
    UI.table(["Service", "Token", "Status"], rows)
    
    puts "#{DIM}Benefits: Remove rate limits • Persistent URLs • Priority support#{RESET}"
    
    ask "\nPress ENTER to continue..."
    gets
  end

  def test_keys
    puts ""
    info "Testing API key configurations..."
    
    # Test Ngrok
    if @config.has?('ngrok_token') && File.exist?(TOOLS[:ngrok])
      print "#{BCYAN}Testing Ngrok...#{RESET} "
      
      # Check if token is in ngrok config (works for v2 and v3)
      config_check = `#{TOOLS[:ngrok]} config check 2>&1`
      
      if config_check.include?("Valid") || config_check.include?("OK") || config_check.downcase.include?("success")
        puts "#{BGREEN}✓ Valid#{RESET}"
      else
        # Alternative: check if authtoken is set
        auth_check = `#{TOOLS[:ngrok]} config check 2>&1 | grep -i authtoken`
        if !auth_check.empty?
          puts "#{BGREEN}✓ Configured#{RESET}"
        else
          puts "#{BYELLOW}⚠ Cannot verify (may still work)#{RESET}"
        end
      end
    else
      puts "#{BYELLOW}Ngrok: Not configured#{RESET}"
    end
    
    # Test Loclx
    if @config.has?('loclx_token')
      puts "#{BGREEN}✓#{RESET} Loclx: Token configured (cannot validate without starting tunnel)"
    else
      puts "#{BYELLOW}Loclx: Not configured#{RESET}"
    end
    
    ask "\nPress ENTER to continue..."
    gets
  end

  def remove_keys
    puts ""
    warn "Remove which key?"
    puts "#{BWHITE}1)#{RESET} Ngrok"
    puts "#{BWHITE}2)#{RESET} Loclx"
    puts "#{BWHITE}3)#{RESET} Both"
    puts "#{BWHITE}0)#{RESET} Cancel"
    
    ask "\nChoice: "
    choice = gets.chomp.strip
    
    case choice
    when "1"
      @config.delete('ngrok_token')
      success "Ngrok token removed!"
    when "2"
      @config.delete('loclx_token')
      success "Loclx token removed!"
    when "3"
      @config.delete('ngrok_token')
      @config.delete('loclx_token')
      success "All tokens removed!"
    end
    
    sleep 2
  end
end

# ------------------ CLI INTERFACE ------------------

class CLI
  def initialize(config)
    @config = config
    @stats = StatsTracker.new
  end

  def select_server
    puts ""
    UI.header("Select Hosting Protocol")
    puts "#{BWHITE}1)#{RESET} Python (http.server) #{DIM}- Recommended, universal#{RESET}"
    puts "#{BWHITE}2)#{RESET} PHP (built-in server) #{DIM}- For PHP applications#{RESET}"
    puts "#{BWHITE}3)#{RESET} NodeJS (http-server) #{DIM}- Modern, feature-rich#{RESET}"
    
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
      puts ""
      ask "Enter directory path to host (or '.' for current): "
      input = gets.chomp.strip
      
      if input.empty?
        warn "Please enter a valid directory path!"
        next
      end
      
      path = File.expand_path(input)
      
      if Dir.exist?(path)
        success "Selected directory: #{path}"
        
        # Show directory contents preview
        files = Dir.entries(path).reject { |f| f.start_with?('.') }.take(5)
        if files.any?
          puts "\n#{DIM}Preview (first 5 items):#{RESET}"
          files.each { |f| puts "  #{DIM}•#{RESET} #{f}" }
          puts "  #{DIM}... (#{Dir.entries(path).length - 5} more)#{RESET}" if Dir.entries(path).length > 5
        end
        
        return path
      else
        error "Directory '#{path}' does not exist!"
        warn "Please enter a valid path (e.g., /home/user/mysite or ./mysite)"
      end
    end
  end

  def get_port
    last_port = @config.get('last_port', DEFAULT_PORT)
    
    puts ""
    ask "Enter port (default: #{last_port}): "
    port = gets.chomp.strip
    
    port = last_port if port.empty?
    port_num = port.to_i
    
    if port_num <= 0 || port_num > 65535
      warn "Invalid port, using default #{DEFAULT_PORT}"
      return DEFAULT_PORT
    end
    
    unless NetworkUtils.port_available?(port_num)
      error "Port #{port_num} is already in use!"
      
      # Find alternative
      alt_port = NetworkUtils.find_available_port(port_num + 1)
      
      if alt_port
        info "Suggested alternative port: #{alt_port}"
        ask "Use port #{alt_port}? (Y/n): "
        choice = gets.chomp.strip.downcase
        
        return alt_port unless choice == 'n'
      end
      
      return get_port
    end
    
    @config.set('last_port', port_num)
    port_num
  end

  def display_results(urls)
    puts ""
    UI.header(" 🌍 PUBLIC URLS READY ")
    
    active_tunnels = urls.select { |_, url| url }
    
    if active_tunnels.empty?
      error "All tunnels failed to start!"
      
      UI.box([
        "Troubleshooting:",
        "• Check your internet connection",
        "• Verify firewall settings",
        "• Configure API keys (Menu option 2)",
        "• Check logs in: #{LOG_DIR}",
        "",
        "Server is still accessible locally"
      ], BYELLOW)
      
      return false
    end
    
    # Display as table
    rows = urls.map do |service, url|
      status = url ? "#{BGREEN}Active#{RESET}" : "#{BRED}Failed#{RESET}"
      [service.to_s.capitalize, url || "N/A", status]
    end
    
    UI.table(["Service", "Public URL", "Status"], rows)
    
    # Summary
    puts "#{BGREEN}#{active_tunnels.length}/#{urls.length} tunnels active#{RESET}"
    
    if active_tunnels.length < urls.length
      puts "#{DIM}TIP: Configure API keys for better reliability (Menu option 2)#{RESET}"
    end
    
    # Copy suggestion
    if active_tunnels.length == 1
      url = active_tunnels.values.first
      puts "\n#{BCYAN}Quick copy:#{RESET} #{url}"
    end
    
    true
  end

  def show_about
    system("clear")
    puts LOGO
    
    UI.box([
      "Tool Name    : Local2Internet v#{VERSION}",
      "Edition      : #{EDITION}",
      "Description  : Professional LocalHost Exposing Tool",
      "Author       : KasRoudra",
      "Enhanced By  : Muhammad Taezeem Tariq Matta",
      "Ultimate By  : Claude AI (2026)",
      "Github       : github.com/Taezeem14/Local2Internet",
      "License      : MIT Open Source"
    ], BPURPLE)
    
    puts "\n#{BCYAN}✨ Features:#{RESET}"
    features = [
      "Triple Tunneling (Ngrok, Cloudflare, Loclx)",
      "API Key Support & Management",
      "Auto-Recovery & Health Monitoring",
      "Real-Time Statistics Tracking",
      "Multi-Protocol Server Support",
      "Enhanced Termux Compatibility",
      "Intelligent Port Detection",
      "Session Management",
      "Advanced Error Handling",
      "Modern Terminal UI"
    ]
    
    features.each { |f| puts "  #{BGREEN}•#{RESET} #{f}" }
    
    ask "\n#{DIM}Press ENTER to continue...#{RESET}"
    gets
  end

  def show_help
    system("clear")
    puts LOGO
    UI.header("📚 HELP & DOCUMENTATION")
    
    puts "\n#{BCYAN}GETTING STARTED:#{RESET}"
    puts "  1. Select 'Start Server & Tunnels' from main menu"
    puts "  2. Enter the directory path you want to host"
    puts "  3. Choose your preferred server protocol"
    puts "  4. Enter a port number (or use default)"
    puts "  5. Wait for tunnels to initialize"
    puts "  6. Share the public URLs with others!"
    
    puts "\n#{BCYAN}API KEY CONFIGURATION:#{RESET}"
    puts "  • Ngrok: Get authtoken from https://dashboard.ngrok.com/get-started/your-authtoken"
    puts "  • Loclx: Get access token from https://localxpose.io/dashboard"
    puts "  #{DIM}Benefits: Remove rate limits, persistent URLs, priority support#{RESET}"
    
    puts "\n#{BCYAN}TROUBLESHOOTING:#{RESET}"
    puts "  • Port in use: Tool will suggest alternatives automatically"
    puts "  • Tunnels fail: Check internet, firewall, add API keys"
    puts "  • Server fails: Ensure directory has index.html or index.php"
    puts "  • Termux issues: Make sure proot is installed (pkg install proot)"
    
    puts "\n#{BCYAN}LOGS & STATISTICS:#{RESET}"
    puts "  • Event logs: #{LOG_DIR}/events.log"
    puts "  • Tunnel logs: #{LOG_DIR}/<service>.log"
    puts "  • Statistics: Menu option 3"
    
    puts "\n#{BCYAN}ADVANCED FEATURES:#{RESET}"
    puts "  • Auto-recovery: Tunnels auto-restart on failure"
    puts "  • Health monitoring: Real-time tunnel status checking"
    puts "  • Session persistence: Remembers your preferences"
    
    ask "\n#{DIM}Press ENTER to continue...#{RESET}"
    gets
  end
end

# ------------------ MAIN MENU ------------------

def main_menu(config, stats)
  loop do
    system("clear")
    puts LOGO
    UI.header("MAIN MENU")
    
    puts "#{BWHITE}1)#{RESET} Start Server & Tunnels #{BGREEN}[Recommended]#{RESET}"
    puts "#{BWHITE}2)#{RESET} Manage API Keys #{DIM}[Configure tokens]#{RESET}"
    puts "#{BWHITE}3)#{RESET} View Statistics #{DIM}[Usage data]#{RESET}"
    puts "#{BWHITE}4)#{RESET} System Status #{DIM}[Check dependencies]#{RESET}"
    puts "#{BWHITE}5)#{RESET} Help & Documentation"
    puts "#{BWHITE}6)#{RESET} About"
    puts "#{BWHITE}0)#{RESET} Exit"
    
    # Show status
    puts "\n#{BCYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
    
    ngrok_status = config.has?('ngrok_token') ? "#{BGREEN}✓ Configured#{RESET}" : "#{BRED}✗ Not Set#{RESET}"
    loclx_status = config.has?('loclx_token') ? "#{BGREEN}✓ Configured#{RESET}" : "#{BRED}✗ Not Set#{RESET}"
    
    puts "#{DIM}API Keys:#{RESET} Ngrok: #{ngrok_status} | Loclx: #{loclx_status}"
    
    if SessionManager.active?
      puts "#{BYELLOW}⚠ Active session detected#{RESET}"
    end
    
    local_ip = NetworkUtils.get_local_ip
    internet = NetworkUtils.check_internet ? "#{BGREEN}Connected#{RESET}" : "#{BRED}No Connection#{RESET}"
    puts "#{DIM}Network:#{RESET} Local IP: #{local_ip} | Internet: #{internet}"
    
    ask "\nChoice: "
    choice = gets.chomp.strip

    case choice
    when "1" then run_server(config, stats)
    when "2" then APIKeyManager.new(config).manage
    when "3" then stats.display_stats; ask("\n#{DIM}Press ENTER...#{RESET}"); gets
    when "4" then system_status; ask("\n#{DIM}Press ENTER...#{RESET}"); gets
    when "5" then CLI.new(config).show_help
    when "6" then CLI.new(config).show_about
    when "0"
      ProcessManager.cleanup
      puts "\n#{BGREEN}Thanks for using Local2Internet! 👋#{RESET}\n"
      exit 0
    else
      warn "Invalid choice! Please select 0-6"
      sleep 1
    end
  end
end

def system_status
  system("clear")
  puts LOGO
  UI.header("💻 SYSTEM STATUS")
  
  # Dependencies
  puts "\n#{BCYAN}Dependencies:#{RESET}"
  deps_status = DEPENDENCIES.map do |dep|
    status = command_exists?(dep) ? "#{BGREEN}✓#{RESET}" : "#{BRED}✗#{RESET}"
    [dep, status]
  end
  
  UI.table(["Package", "Status"], deps_status)
  
  # Tunneling tools
  puts "#{BCYAN}Tunneling Tools:#{RESET}"
  tools_status = TOOLS.map do |name, path|
    status = File.exist?(path) ? "#{BGREEN}✓ Installed#{RESET}" : "#{BRED}✗ Missing#{RESET}"
    [name.to_s.capitalize, status]
  end
  
  UI.table(["Tool", "Status"], tools_status)
  
  # System info
  puts "#{BCYAN}System Information:#{RESET}"
  puts "  Platform: #{termux? ? 'Termux (Android)' : 'Linux'}"
  puts "  Architecture: #{arch}"
  puts "  Ruby Version: #{RUBY_VERSION}"
  puts "  Internet: #{NetworkUtils.check_internet ? 'Connected' : 'Disconnected'}"
  puts "  Local IP: #{NetworkUtils.get_local_ip}"
end

def run_server(config, stats)
  system("clear")
  puts LOGO
  
  # Pre-flight checks
  unless NetworkUtils.check_internet
    error "No internet connection detected!"
    warn "Tunneling requires an active internet connection"
    ask "\nContinue anyway? (y/N): "
    return unless gets.chomp.downcase == 'y'
  end
  
  cli = CLI.new(config)
  
  # Get user inputs
  path = cli.get_directory
  server_mode = cli.select_server
  port = cli.get_port
  
  # Termux reminder
  if termux?
    warn "Termux detected!"
    info "For best results, enable mobile hotspot or connect to WiFi"
    sleep 2
  end
  
  # Start local server
  server = ServerManager.new(path, port, server_mode)
  return unless server.start
  
  # Start tunnels
  tunnel_manager = TunnelManager.new(port, config)
  urls = tunnel_manager.start_all
  
  # Display results
  has_urls = cli.display_results(urls)
  
  return unless has_urls
  
  # Save session
  session_data = {
    active: true,
    pid: Process.pid,
    port: port,
    mode: server_mode,
    started_at: Time.now,
    urls: urls
  }
  SessionManager.save_session(session_data)
  
  # Start monitoring
  tunnel_manager.start_monitoring
  
  # Keep alive with status updates
  start_time = Time.now
  
  puts "\n#{BCYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}"
  puts "#{BGREEN}Server is running with health monitoring enabled#{RESET}"
  puts "#{DIM}Press CTRL+C to stop and return to menu#{RESET}"
  puts "#{BCYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━#{RESET}\n"
  
  begin
    loop do
      sleep 60
      
      # Show periodic status
      uptime = Time.now - start_time
      hours = (uptime / 3600).to_i
      minutes = ((uptime % 3600) / 60).to_i
      
      print "\r#{DIM}Uptime: #{hours}h #{minutes}m | Monitoring active#{RESET}"
    end
  rescue Interrupt
    # Handled by signal trap
  ensure
    tunnel_manager.stop_monitoring
    
    # Record session statistics
    duration = (Time.now - start_time).to_i
    active_tunnels = urls.select { |_, url| url }.keys
    stats.record_session(duration, active_tunnels, server_mode)
    
    SessionManager.clear_session
  end
end

# ------------------ SIGNAL HANDLERS ------------------

def setup_signal_handlers
  Signal.trap("INT") do
    puts "\n\n#{BCYAN}Shutting down gracefully...#{RESET}"
    ProcessManager.cleanup
    SessionManager.clear_session
    puts "#{BGREEN}Thanks for using Local2Internet! 👋#{RESET}\n"
    exit 0
  end

  Signal.trap("TERM") do
    ProcessManager.cleanup
    SessionManager.clear_session
    exit 0
  end
end

# ------------------ ENTRY POINT ------------------

begin
  setup_signal_handlers
  ProcessManager.cleanup
  ensure_dirs
  
  # Initialize managers
  config = ConfigManager.new
  stats = StatsTracker.new
  
  # First run setup
  unless config.has?('first_run_done')
    system("clear")
    puts LOGO
    
    UI.box([
      "Welcome to Local2Internet v#{VERSION} #{EDITION}!",
      "",
      "First-time setup wizard",
      "Installing dependencies and tools..."
    ], BGREEN)
    
    sleep 2
    
    DependencyManager.check_and_install
    ToolDownloader.download_all
    
    # Configure ngrok token if present
    if config.has?('ngrok_token') && File.exist?(TOOLS[:ngrok])
      info "Applying saved Ngrok token..."
      token = config.get('ngrok_token')
      system("#{TOOLS[:ngrok]} authtoken #{token} > /dev/null 2>&1")
    end
    
    config.set('first_run_done', true)
    config.set('installed_at', Time.now.to_s)
    
    success "Setup complete! Ready to use."
    sleep 2
  else
    # Quick check
    unless DependencyManager.check_and_install
      error "Dependency check failed"
      exit 1
    end
    
    unless ToolDownloader.download_all
      error "Tool download failed"
      exit 1
    end
    
    # Re-apply ngrok token on startup if configured
    if config.has?('ngrok_token') && File.exist?(TOOLS[:ngrok])
      token = config.get('ngrok_token')
      system("#{TOOLS[:ngrok]} authtoken #{token} > /dev/null 2>&1")
    end
  end
  
  # Start main menu
  main_menu(config, stats)
  
rescue StandardError => e
  puts "\n#{BRED}[FATAL ERROR] #{e.message}#{RESET}"
  puts "#{DIM}#{e.backtrace.first(5).join("\n")}#{RESET}" if ENV["DEBUG"]
  ProcessManager.cleanup
  exit 1
end
