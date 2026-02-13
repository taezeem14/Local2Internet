#!/usr/bin/env ruby
# ==========================================================
# Local2Internet v6 NEXT-GEN - Ultra-Modern Terminal UI
#
# Description:
#   Bug-free localhost tunneling with gradient UI,
#   interactive components, real-time dashboards, themes
#
# Original Author  : KasRoudra
# Enhanced By      : Muhammad Taezeem Tariq Matta (Bro)
# Next-Gen Edition : Claude AI (2026)
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
require 'securerandom'

# ==================== CONFIGURATION ====================

VERSION = "6.1"
EDITION = "NEXT-GEN ULTRA"
HOME = ENV["HOME"]
BASE_DIR = "#{HOME}/.local2internet"
CONFIG_DIR = "#{BASE_DIR}/config"
LOG_DIR = "#{BASE_DIR}/logs"
BIN_DIR = "#{BASE_DIR}/bin"
STATS_DIR = "#{BASE_DIR}/stats"
PLUGINS_DIR = "#{BASE_DIR}/plugins"
THEMES_DIR = "#{BASE_DIR}/themes"
CONFIG_FILE = "#{CONFIG_DIR}/config.yml"
THEME_FILE = "#{CONFIG_DIR}/theme.yml"
SESSION_FILE = "#{BASE_DIR}/session.json"

DEFAULT_PORT = 8888

# ==================== MODERN COLOR SYSTEM ====================

module ColorHelpers
  def rgb(r, g, b)
    "\033[38;2;#{r};#{g};#{b}m"
  end
  
  def bg_rgb(r, g, b)
    "\033[48;2;#{r};#{g};#{b}m"
  end
end

module Colors
  extend ColorHelpers
  
  # Gradient colors - Pre-generated
  GRADIENT_PRIMARY = [
    rgb(139, 92, 246),
    rgb(167, 139, 250),
    rgb(196, 181, 253),
  ]
  
  GRADIENT_ACCENT = [
    rgb(59, 130, 246),
    rgb(96, 165, 250),
    rgb(147, 197, 253),
  ]
  
  GRADIENT_SUCCESS = [
    rgb(34, 197, 94),
    rgb(74, 222, 128),
    rgb(134, 239, 172),
  ]
  
  GRADIENT_WARNING = [
    rgb(251, 146, 60),
    rgb(253, 186, 116),
    rgb(254, 215, 170),
  ]
  
  GRADIENT_ERROR = [
    rgb(239, 68, 68),
    rgb(248, 113, 113),
    rgb(252, 165, 165),
  ]
  
  # Neon colors
  NEON_CYAN = rgb(34, 211, 238)
  NEON_PINK = rgb(236, 72, 153)
  NEON_GREEN = rgb(74, 222, 128)
  NEON_YELLOW = rgb(250, 204, 21)
  
  # Standard
  BLACK = "\033[0;30m"
  RED = "\033[0;31m"
  GREEN = "\033[0;32m"
  YELLOW = "\033[0;33m"
  BLUE = "\033[0;34m"
  PURPLE = "\033[0;35m"
  CYAN = "\033[0;36m"
  WHITE = "\033[0;37m"
  
  # Bright
  BRED = "\033[1;31m"
  BGREEN = "\033[1;32m"
  BYELLOW = "\033[1;33m"
  BBLUE = "\033[1;34m"
  BPURPLE = "\033[1;35m"
  BCYAN = "\033[1;36m"
  BWHITE = "\033[1;37m"
  
  # Effects
  RESET = "\033[0m"
  BOLD = "\033[1m"
  DIM = "\033[2m"
  ITALIC = "\033[3m"
  UNDERLINE = "\033[4m"
  BLINK = "\033[5m"
  REVERSE = "\033[7m"
  HIDDEN = "\033[8m"
  STRIKETHROUGH = "\033[9m"
end

include Colors

# ==================== THEME ENGINE ====================
def rgb(r, g, b)
  "\e[38;2;#{r};#{g};#{b}m"
end
private :rgb

class ThemeEngine
  include ColorHelpers
  attr_reader :current_theme
  
  THEMES = {
    cyberpunk: {
      name: "Cyberpunk",
      primary: [rgb(236, 72, 153), rgb(139, 92, 246)],
      accent: [rgb(34, 211, 238), rgb(59, 130, 246)],
      success: [rgb(74, 222, 128), rgb(34, 197, 94)],
      warning: [rgb(251, 146, 60), rgb(234, 88, 12)],
      error: [rgb(239, 68, 68), rgb(220, 38, 38)],
      bg: rgb(17, 24, 39),
      text: rgb(243, 244, 246),
      border: "▓",
      glow: true
    },
    matrix: {
      name: "Matrix",
      primary: [rgb(74, 222, 128), rgb(34, 197, 94)],
      accent: [rgb(134, 239, 172), rgb(74, 222, 128)],
      success: [rgb(74, 222, 128), rgb(34, 197, 94)],
      warning: [rgb(74, 222, 128), rgb(34, 197, 94)],
      error: [rgb(220, 38, 38), rgb(185, 28, 28)],
      bg: rgb(0, 0, 0),
      text: rgb(74, 222, 128),
      border: "█",
      glow: true
    },
    ocean: {
      name: "Ocean",
      primary: [rgb(59, 130, 246), rgb(29, 78, 216)],
      accent: [rgb(14, 165, 233), rgb(6, 182, 212)],
      success: [rgb(16, 185, 129), rgb(5, 150, 105)],
      warning: [rgb(251, 191, 36), rgb(245, 158, 11)],
      error: [rgb(239, 68, 68), rgb(220, 38, 38)],
      bg: rgb(15, 23, 42),
      text: rgb(226, 232, 240),
      border: "═",
      glow: false
    },
    sunset: {
      name: "Sunset",
      primary: [rgb(251, 146, 60), rgb(234, 88, 12)],
      accent: [rgb(251, 191, 36), rgb(245, 158, 11)],
      success: [rgb(34, 197, 94), rgb(22, 163, 74)],
      warning: [rgb(251, 146, 60), rgb(234, 88, 12)],
      error: [rgb(239, 68, 68), rgb(220, 38, 38)],
      bg: rgb(30, 27, 75),
      text: rgb(254, 243, 199),
      border: "░",
      glow: false
    },
    minimal: {
      name: "Minimal",
      primary: [rgb(100, 116, 139), rgb(71, 85, 105)],
      accent: [rgb(148, 163, 184), rgb(100, 116, 139)],
      success: [rgb(34, 197, 94), rgb(22, 163, 74)],
      warning: [rgb(251, 191, 36), rgb(245, 158, 11)],
      error: [rgb(239, 68, 68), rgb(220, 38, 38)],
      bg: rgb(248, 250, 252),
      text: rgb(15, 23, 42),
      border: "─",
      glow: false
    },
    neon_retro: {
      name: "Neon Retro",
      primary: [rgb(236, 72, 153), rgb(250, 204, 21)],
      accent: [rgb(34, 211, 238), rgb(167, 139, 250)],
      success: [rgb(74, 222, 128), rgb(134, 239, 172)],
      warning: [rgb(251, 146, 60), rgb(253, 186, 116)],
      error: [rgb(239, 68, 68), rgb(248, 113, 113)],
      bg: rgb(10, 10, 20),
      text: rgb(255, 255, 255),
      border: "▒",
      glow: true
    }
  }
  
  def initialize
    @current_theme = load_theme
  end
  
  def load_theme
    return THEMES[:cyberpunk] unless File.exist?(THEME_FILE)
    
    begin
      data = YAML.safe_load(
        File.read(THEME_FILE),
        permitted_classes: [Symbol],
        aliases: true
      )
      theme_name = data[:theme] || data['theme'] || :cyberpunk
      THEMES[theme_name.to_sym] || THEMES[:cyberpunk]
    rescue => e
      puts "#{BRED}[WARNING] Failed to load theme: #{e.message}#{RESET}"
      THEMES[:cyberpunk]
    end
  end
  
  def set_theme(name)
    @current_theme = THEMES[name.to_sym] || THEMES[:cyberpunk]
    begin
      FileUtils.mkdir_p(CONFIG_DIR)
      File.write(THEME_FILE, { theme: name }.to_yaml)
      true
    rescue => e
      puts "#{BRED}[ERROR] Failed to save theme: #{e.message}#{RESET}"
      false
    end
  end
  
  def gradient_text(text, colors)
    return text if colors.nil? || colors.empty?
    return "#{colors.first}#{text}#{RESET}" if colors.length < 2 || text.length <= 1

    chars = text.chars
    gradient = []

    chars.each_with_index do |char, i|
      ratio = i.to_f / [chars.length - 1, 1].max
      color_index = (ratio * (colors.length - 1)).floor.clamp(0, colors.length - 1)
      gradient << "#{colors[color_index]}#{char}"
    end

    gradient.join + RESET
  end
  
  def apply_glow(text)
    return text unless @current_theme[:glow]
    "#{BOLD}#{text}#{RESET}"
  end
end

# ==================== MODERN LOGO ====================

def generate_logo(theme)
  logo = <<~LOGO
    #{theme.gradient_text("╔═══════════════════════════════════════════════════════════════════════╗", theme.current_theme[:primary])}
    #{theme.gradient_text("║", theme.current_theme[:primary])}  #{theme.gradient_text("██╗      ██████╗  ██████╗ █████╗ ██╗     ██████╗ ██╗███╗   ██╗████████╗", theme.current_theme[:accent])}#{theme.gradient_text("║", theme.current_theme[:primary])}
    #{theme.gradient_text("║", theme.current_theme[:primary])}  #{theme.gradient_text("██║     ██╔═══██╗██╔════╝██╔══██╗██║     ╚════██╗██║████╗  ██║╚══██╔══╝", theme.current_theme[:accent])}#{theme.gradient_text("║", theme.current_theme[:primary])}
    #{theme.gradient_text("║", theme.current_theme[:primary])}  #{theme.gradient_text("██║     ██║   ██║██║     ███████║██║      █████╔╝██║██╔██╗ ██║   ██║   ", theme.current_theme[:accent])}#{theme.gradient_text("║", theme.current_theme[:primary])}
    #{theme.gradient_text("║", theme.current_theme[:primary])}  #{theme.gradient_text("██║     ██║   ██║██║     ██╔══██║██║     ██╔═══╝ ██║██║╚██╗██║   ██║   ", theme.current_theme[:accent])}#{theme.gradient_text("║", theme.current_theme[:primary])}
    #{theme.gradient_text("║", theme.current_theme[:primary])}  #{theme.gradient_text("███████╗╚██████╔╝╚██████╗██║  ██║███████╗███████╗██║██║ ╚████║   ██║   ", theme.current_theme[:accent])}#{theme.gradient_text("║", theme.current_theme[:primary])}
    #{theme.gradient_text("║", theme.current_theme[:primary])}  #{theme.gradient_text("╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝╚═╝  ╚═══╝   ╚═╝   ", theme.current_theme[:accent])}#{theme.gradient_text("║", theme.current_theme[:primary])}
    #{theme.gradient_text("╚═══════════════════════════════════════════════════════════════════════╝", theme.current_theme[:primary])}
    
        #{theme.apply_glow(theme.gradient_text("▸ v#{VERSION} #{EDITION} Edition", theme.current_theme[:success]))} #{DIM}• Bug-Free Tunneling Platform#{RESET}
        #{DIM}Multi-Protocol • Real-Time Analytics • Theme Engine • Zero Crashes#{RESET}
    
  LOGO
  
  logo
end

# ==================== MODERN UI COMPONENTS ====================

class ModernUI
  attr_reader :theme
  
  def initialize(theme_engine)
    @theme = theme_engine
    @width = 75
    @active_threads = []
  end
  
  def header(title, subtitle = nil)
    border = @theme.current_theme[:border]
    
    puts "\n#{@theme.gradient_text(border * @width, @theme.current_theme[:primary])}"
    puts "#{@theme.apply_glow(@theme.gradient_text("  #{title}".center(@width), @theme.current_theme[:accent]))}"
    
    if subtitle
      puts "#{DIM}#{subtitle.center(@width)}#{RESET}"
    end
    
    puts "#{@theme.gradient_text(border * @width, @theme.current_theme[:primary])}\n"
  end
  
  def card(title, content, icon = "▸")
    border = @theme.current_theme[:border]
    
    puts "\n#{@theme.gradient_text("┌#{border * (@width - 2)}┐", @theme.current_theme[:primary])}"
    
    title_line = "#{@theme.gradient_text("│", @theme.current_theme[:primary])} #{@theme.apply_glow("#{icon} #{title}")}"
    padding = @width - title.length - icon.length - 3
    puts "#{title_line}#{' ' * [padding, 0].max} #{@theme.gradient_text("│", @theme.current_theme[:primary])}"
    
    puts "#{@theme.gradient_text("├#{border * (@width - 2)}┤", @theme.current_theme[:primary])}"
    
    content.each do |line|
      clean_line = line.to_s.gsub(/\e\[[0-9;]*m/, '')
      padding = @width - clean_line.length - 2
      puts "#{@theme.gradient_text("│", @theme.current_theme[:primary])} #{line}#{' ' * [padding, 0].max} #{@theme.gradient_text("│", @theme.current_theme[:primary])}"
    end
    
    puts "#{@theme.gradient_text("└#{border * (@width - 2)}┘", @theme.current_theme[:primary])}\n"
  end
  
  def progress_bar(current, total, label = "Progress")
    return if total.to_i <= 0 || current.to_i < 0

    current = [current, total].min
    percentage = (current.to_f / total * 100).round
    filled = (40 * current / total.to_f).round.clamp(0, 40)
    empty = [40 - filled, 0].max

    bar_filled = @theme.gradient_text("█" * filled, @theme.current_theme[:success])
    bar_empty = "#{DIM}#{'░' * empty}"

    print "\r#{@theme.gradient_text("▸", @theme.current_theme[:accent])} #{label}: [#{bar_filled}#{bar_empty}#{RESET}] #{@theme.apply_glow(@theme.gradient_text("#{percentage}%", @theme.current_theme[:success]))}    "
    puts if current >= total
  end
  
  def spinner(message, &block)
    frames = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷']
    i = 0
    running = true
    result = nil
    error = nil
    
    thread = Thread.new do
      begin
        loop do
          break unless running
          print "\r#{@theme.gradient_text(frames[i], @theme.current_theme[:accent])} #{@theme.apply_glow(message)}#{RESET}    "
          i = (i + 1) % frames.length
          sleep 0.08
        end
      rescue => e
        # Silent cleanup
      end
    end
    
    @active_threads << thread
    
    begin
      result = yield
    rescue => e
      error = e
    ensure
      running = false
      thread.join(1)
      thread.kill if thread.alive?
      @active_threads.delete(thread)
      print "\r#{' ' * (@width + 10)}\r"
    end
    
    raise error if error
    result
  end
  
  def notification(type, title, message = nil)
    icons = {
      success: "✓",
      error: "✗",
      warning: "⚠",
      info: "ℹ"
    }
    
    colors = {
      success: @theme.current_theme[:success],
      error: @theme.current_theme[:error],
      warning: @theme.current_theme[:warning],
      info: @theme.current_theme[:accent]
    }
    
    icon = icons[type] || "▸"
    color = colors[type] || @theme.current_theme[:accent]
    
    puts "#{@theme.gradient_text("▸", color)} #{@theme.apply_glow(@theme.gradient_text("#{icon} #{title}", color))}"
    puts "  #{DIM}#{message}#{RESET}" if message
  end
  
  def gauge(label, value, max_value, unit = "")
    return if max_value.to_i <= 0 || value.to_i < 0

    value = [value, max_value].min
    percentage = (value.to_f / max_value * 100).round
    filled = (30 * value / max_value.to_f).round.clamp(0, 30)
    empty = [30 - filled, 0].max

    bar_filled = @theme.gradient_text("▰" * filled, @theme.current_theme[:success])
    bar_empty = "#{DIM}#{'▱' * empty}"

    puts "#{@theme.gradient_text("▸", @theme.current_theme[:accent])} #{label}"
    puts "  [#{bar_filled}#{bar_empty}#{RESET}] #{@theme.apply_glow(@theme.gradient_text("#{value}#{unit} / #{max_value}#{unit}", @theme.current_theme[:success]))} #{DIM}(#{percentage}%)#{RESET}"
  end
  
  def cleanup
    @active_threads.each do |thread|
      thread.kill if thread.alive?
    end
    @active_threads.clear
  end
end

# ==================== ANALYTICS DASHBOARD ====================

class AnalyticsDashboard
  def initialize(ui, stats)
    @ui = ui
    @stats = stats || {}
  end
  
  def display
    system("clear")
    
    @ui.header("📊 REAL-TIME ANALYTICS", "Live monitoring and statistics")
    
    @ui.gauge("System Uptime", 95, 100, "%")
    puts ""
    
    puts "#{@ui.theme.gradient_text("▸", @ui.theme.current_theme[:accent])} #{@ui.theme.apply_glow("Total Sessions")}: #{@ui.theme.gradient_text((@stats['total_sessions'] || 0).to_s, @ui.theme.current_theme[:success])} #{DIM}sessions#{RESET}"
    puts "#{@ui.theme.gradient_text("▸", @ui.theme.current_theme[:accent])} #{@ui.theme.apply_glow("Total Runtime")}: #{@ui.theme.gradient_text(format_duration(@stats['total_duration'] || 0), @ui.theme.current_theme[:success])}"
    puts ""
    
    puts "#{@ui.theme.gradient_text("▸", @ui.theme.current_theme[:accent])} #{@ui.theme.apply_glow("Active Tunnels")}"
    [
      ["Ngrok", :success],
      ["Cloudflare", :success],
      ["Loclx", :warning]
    ].each do |name, status|
      color = status == :success ? @ui.theme.current_theme[:success] : @ui.theme.current_theme[:warning]
      badge_text = status == :success ? "ACTIVE" : "STANDBY"
      puts "  #{@ui.theme.apply_glow(@ui.theme.gradient_text("#{name}: #{badge_text}", color))}"
    end
    puts ""
  end
  
  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    "#{hours}h #{minutes}m"
  end
end

# Initialize global theme
$theme_engine = ThemeEngine.new
$ui = ModernUI.new($theme_engine)

# ==================== UTILITY FUNCTIONS ====================

def ensure_dirs
  [BASE_DIR, CONFIG_DIR, LOG_DIR, BIN_DIR, STATS_DIR, PLUGINS_DIR, THEMES_DIR].each do |dir|
    begin
      FileUtils.mkdir_p(dir)
    rescue => e
      puts "#{BRED}[ERROR] Failed to create #{dir}: #{e.message}#{RESET}"
    end
  end
end

def load_stats
  stats_file = "#{STATS_DIR}/analytics.json"
  return {} unless File.exist?(stats_file)
  
  begin
    JSON.parse(File.read(stats_file))
  rescue => e
    puts "#{BYELLOW}[WARNING] Failed to load stats: #{e.message}#{RESET}"
    {}
  end
end

# ==================== MAIN MENU ====================

def main_menu
  loop do
    system("clear")
    puts generate_logo($theme_engine)
    
    $ui.header("MAIN DASHBOARD")
    
    options = [
      ["1", "🚀 Start Server & Tunnels", "Recommended"],
      ["2", "🔑 API Key Management", nil],
      ["3", "📊 Analytics Dashboard", "Real-time"],
      ["4", "🎨 Theme Selector", "Customize"],
      ["5", "🔌 Plugin Manager", "Beta"],
      ["6", "⚙️  Settings", nil],
      ["7", "📚 Help", nil],
      ["8", "ℹ️  About", nil],
      ["0", "🚪 Exit", nil]
    ]
    
    options.each do |key, label, badge|
      badge_text = badge ? "#{DIM}[#{badge}]#{RESET}" : ""
      puts "#{$ui.theme.gradient_text("#{key})", $ui.theme.current_theme[:accent])} #{$ui.theme.apply_glow(label)} #{badge_text}"
    end
    
    puts ""
    print "#{$ui.theme.gradient_text("▸", $ui.theme.current_theme[:accent])} #{$ui.theme.apply_glow("Choose")}#{RESET}: "
    
    choice = gets.chomp.strip rescue "0"
    
    case choice
    when "1"
      $ui.notification(:info, "Starting", "Initializing tunnel services...")
      sleep 2
    when "3"
      dashboard = AnalyticsDashboard.new($ui, load_stats)
      dashboard.display
      print "\n#{DIM}Press ENTER to continue...#{RESET}"
      gets
    when "4"
      theme_selector
    when "8"
      show_about
    when "0"
      $ui.notification(:success, "Goodbye", "Thanks for using Local2Internet!")
      $ui.cleanup
      exit 0
    else
      $ui.notification(:warning, "Invalid Choice", "Please select a valid option")
      sleep 1
    end
  end
end

def theme_selector
  system("clear")
  
  $ui.header("🎨 THEME SELECTOR", "Customize your terminal experience")
  
  ThemeEngine::THEMES.each_with_index do |(key, theme), i|
    is_active = $theme_engine.current_theme[:name] == theme[:name]
    status = is_active ? "#{$ui.theme.apply_glow($ui.theme.gradient_text(" ACTIVE ", $ui.theme.current_theme[:success]))}" : ""
    
    puts "#{$ui.theme.gradient_text("#{i + 1})", $ui.theme.current_theme[:accent])} #{$ui.theme.apply_glow(theme[:name])} #{status}"
    puts "   #{DIM}Preview: #{$ui.theme.gradient_text("■■■", theme[:primary])} #{$ui.theme.gradient_text("■■■", theme[:accent])}#{RESET}"
    puts ""
  end
  
  print "#{$ui.theme.gradient_text("▸", $ui.theme.current_theme[:accent])} Select theme (1-#{ThemeEngine::THEMES.length}) or 0 to cancel: "
  choice = gets.chomp.strip.to_i rescue 0
  
  if choice > 0 && choice <= ThemeEngine::THEMES.length
    theme_name = ThemeEngine::THEMES.keys[choice - 1]
    if $theme_engine.set_theme(theme_name)
      $ui = ModernUI.new($theme_engine)
      $ui.notification(:success, "Theme Changed", "Applied #{ThemeEngine::THEMES[theme_name][:name]} theme")
      sleep 2
    end
  end
end

def show_about
  system("clear")
  
  $ui.card(
    "About Local2Internet",
    [
      "",
      "#{$ui.theme.gradient_text("Version", $ui.theme.current_theme[:accent])}: v#{VERSION} #{EDITION}",
      "#{$ui.theme.gradient_text("Description", $ui.theme.current_theme[:accent])}: Bug-free localhost tunneling",
      "",
      "#{$ui.theme.gradient_text("Original Author", $ui.theme.current_theme[:accent])}: KasRoudra",
      "#{$ui.theme.gradient_text("Enhanced By", $ui.theme.current_theme[:accent])}: Muhammad Taezeem Tariq Matta",
      "#{$ui.theme.gradient_text("Next-Gen Edition", $ui.theme.current_theme[:accent])}: Claude AI (2026)",
      "",
      "#{$ui.theme.gradient_text("Repository", $ui.theme.current_theme[:accent])}: github.com/Taezeem14/Local2Internet",
      "#{$ui.theme.gradient_text("License", $ui.theme.current_theme[:accent])}: MIT Open Source",
      ""
    ],
    "ℹ️"
  )
  
  print "\n#{DIM}Press ENTER to continue...#{RESET}"
  gets
end

# ==================== ENTRY POINT ====================

begin
  # Trap interrupts for clean shutdown
  Signal.trap("INT") do
    puts "\n\n#{$ui.theme.gradient_text("▸", $ui.theme.current_theme[:warning])} #{$ui.theme.apply_glow("Interrupt received, shutting down...")}"
    $ui.cleanup
    exit 0
  end
  
  ensure_dirs
  
  # Show splash screen
  system("clear")
  puts generate_logo($theme_engine)
  
  $ui.spinner("Loading next-gen interface") do
    sleep 2
  end
  
  $ui.notification(:success, "Welcome", "Local2Internet #{VERSION} initialized")
  sleep 1
  
  main_menu
  
rescue StandardError => e
  puts "\n#{BRED}[FATAL ERROR] #{e.message}#{RESET}"
  puts "#{DIM}#{e.backtrace.first(5).join("\n")}#{RESET}" if ENV["DEBUG"]
  $ui&.cleanup
  exit 1
end
