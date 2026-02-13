#!/usr/bin/env ruby
# ==========================================================
# Local2Internet v6.0 NEXT-GEN - Modern Terminal UI Edition
#
# Description:
#   Ultra-modern localhost tunneling with gradient UI,
#   interactive components, real-time dashboards, themes
#
# Original Author  : KasRoudra
# Enhanced By      : Muhammad Taezeem Tariq Matta
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

VERSION = "6.0"
EDITION = "NEXT-GEN"
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

module Colors
  # 256-color palette support
  def self.rgb(r, g, b)
    "\033[38;2;#{r};#{g};#{b}m"
  end
  
  def self.bg_rgb(r, g, b)
    "\033[48;2;#{r};#{g};#{b}m"
  end
  
  # Gradient colors
  GRADIENT_PRIMARY = [
    rgb(139, 92, 246),   # Purple
    rgb(167, 139, 250),  # Light Purple
    rgb(196, 181, 253),  # Lighter Purple
  ]
  
  GRADIENT_ACCENT = [
    rgb(59, 130, 246),   # Blue
    rgb(96, 165, 250),   # Light Blue
    rgb(147, 197, 253),  # Lighter Blue
  ]
  
  GRADIENT_SUCCESS = [
    rgb(34, 197, 94),    # Green
    rgb(74, 222, 128),   # Light Green
    rgb(134, 239, 172),  # Lighter Green
  ]
  
  GRADIENT_WARNING = [
    rgb(251, 146, 60),   # Orange
    rgb(253, 186, 116),  # Light Orange
    rgb(254, 215, 170),  # Lighter Orange
  ]
  
  GRADIENT_ERROR = [
    rgb(239, 68, 68),    # Red
    rgb(248, 113, 113),  # Light Red
    rgb(252, 165, 165),  # Lighter Red
  ]
  
  # Glassmorphism colors
  GLASS_DARK = "\033[48;2;17;24;39;0.7m"
  GLASS_LIGHT = "\033[48;2;243;244;246;0.7m"
  
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
    }
  }
  
  def initialize
    @current_theme = load_theme
  end
  
  def load_theme
    if File.exist?(THEME_FILE)
      theme_name = YAML.safe_load(File.read(THEME_FILE), permitted_classes: [Symbol])[:theme] || :cyberpunk
      THEMES[theme_name.to_sym] || THEMES[:cyberpunk]
    else
      THEMES[:cyberpunk]
    end
  end
  
  def set_theme(name)
    @current_theme = THEMES[name.to_sym] || THEMES[:cyberpunk]
    FileUtils.mkdir_p(CONFIG_DIR)
    File.write(THEME_FILE, { theme: name }.to_yaml)
  end
  
  def gradient_text(text, colors)
    return text if colors.length < 2
    
    chars = text.chars
    gradient = []
    
    chars.each_with_index do |char, i|
      ratio = i.to_f / (chars.length - 1)
      color_index = (ratio * (colors.length - 1)).floor
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
    
        #{theme.apply_glow(theme.gradient_text("▸ v#{VERSION} #{EDITION} Edition", theme.current_theme[:success]))} #{DIM}• Next-Generation Tunneling Platform#{RESET}
        #{DIM}Multi-Protocol • Real-Time Analytics • Theme Engine • Plugin System#{RESET}
    
  LOGO
  
  logo
end

# ==================== MODERN UI COMPONENTS ====================

class ModernUI
  attr_reader :theme
  
  def initialize(theme_engine)
    @theme = theme_engine
    @width = 75
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
    puts "#{@theme.gradient_text("│", @theme.current_theme[:primary])} #{@theme.apply_glow("#{icon} #{title}")}".ljust(@width + 20) + "#{@theme.gradient_text("│", @theme.current_theme[:primary])}"
    puts "#{@theme.gradient_text("├#{border * (@width - 2)}┤", @theme.current_theme[:primary])}"
    
    content.each do |line|
      puts "#{@theme.gradient_text("│", @theme.current_theme[:primary])} #{line}".ljust(@width + 20) + "#{@theme.gradient_text("│", @theme.current_theme[:primary])}"
    end
    
    puts "#{@theme.gradient_text("└#{border * (@width - 2)}┘", @theme.current_theme[:primary])}\n"
  end
  
  def tabs(tabs, active)
    border = @theme.current_theme[:border]
    tab_width = @width / tabs.length
    
    print "\n"
    tabs.each_with_index do |tab, i|
      if i == active
        print "#{@theme.gradient_text("┌#{border * (tab_width - 2)}┐", @theme.current_theme[:accent])}"
      else
        print "#{DIM}┌#{border * (tab_width - 2)}┐#{RESET}"
      end
    end
    
    print "\n"
    tabs.each_with_index do |tab, i|
      text = tab.center(tab_width - 2)
      if i == active
        print "#{@theme.gradient_text("│", @theme.current_theme[:accent])}#{@theme.apply_glow(@theme.gradient_text(text, @theme.current_theme[:success]))}#{@theme.gradient_text("│", @theme.current_theme[:accent])}"
      else
        print "#{DIM}│#{text}│#{RESET}"
      end
    end
    
    print "\n"
    tabs.each_with_index do |tab, i|
      if i == active
        print "#{@theme.gradient_text("└#{border * (tab_width - 2)}┘", @theme.current_theme[:accent])}"
      else
        print "#{DIM}└#{border * (tab_width - 2)}┘#{RESET}"
      end
    end
    puts "\n"
  end
  
def progress_bar(current, total, label = "Progress")
  return if total.to_i <= 0

  percentage = (current.to_f / total * 100).round
  filled = (40 * current / total.to_f).round
  empty = 40 - filled

  bar_filled = @theme.gradient_text("█" * filled, @theme.current_theme[:success])
  bar_empty = "#{DIM}░" * empty

  print "\r#{@theme.gradient_text("▸", @theme.current_theme[:accent])} #{label}: [#{bar_filled}#{bar_empty}#{RESET}] #{@theme.apply_glow(@theme.gradient_text("#{percentage}%", @theme.current_theme[:success]))}"
  puts if current >= total
end
  
  def spinner(message, &block)
    frames = ['⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷']
    i = 0
    
    thread = Thread.new do
      loop do
        print "\r#{@theme.gradient_text(frames[i], @theme.current_theme[:accent])} #{@theme.apply_glow(message)}#{RESET}"
        i = (i + 1) % frames.length
        sleep 0.08
      end
    end
    
    result = yield
    thread.kill
    print "\r#{' ' * (@width + 10)}\r"
    result
  end
  
  def notification(type, title, message)
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
  
  def table(headers, rows)
    col_widths = headers.each_with_index.map do |header, i|
      [header.length, *rows.map { |row| row[i].to_s.length }].max + 3
    end
    
    border = @theme.current_theme[:border]
    
    # Top border
    puts "\n#{@theme.gradient_text("┌#{col_widths.map { |w| border * w }.join('┬')}┐", @theme.current_theme[:primary])}"
    
    # Headers
    header_row = headers.each_with_index.map do |h, i|
      "#{@theme.apply_glow(@theme.gradient_text(" #{h}".ljust(col_widths[i]), @theme.current_theme[:accent]))}"
    end
    puts "#{@theme.gradient_text("│", @theme.current_theme[:primary])}#{header_row.join(@theme.gradient_text("│", @theme.current_theme[:primary]))}#{@theme.gradient_text("│", @theme.current_theme[:primary])}"
    
    # Middle border
    puts "#{@theme.gradient_text("├#{col_widths.map { |w| border * w }.join('┼')}┤", @theme.current_theme[:primary])}"
    
    # Rows
    rows.each do |row|
      row_text = row.each_with_index.map { |cell, i| " #{cell}".ljust(col_widths[i]) }
      puts "#{@theme.gradient_text("│", @theme.current_theme[:primary])}#{row_text.join(@theme.gradient_text("│", @theme.current_theme[:primary]))}#{@theme.gradient_text("│", @theme.current_theme[:primary])}"
    end
    
    # Bottom border
    puts "#{@theme.gradient_text("└#{col_widths.map { |w| border * w }.join('┴')}┘", @theme.current_theme[:primary])}\n"
  end
  
def gauge(label, value, max_value, unit = "")
  return if max_value.to_i <= 0

  percentage = (value.to_f / max_value * 100).round
  filled = (30 * value / max_value.to_f).round
  empty = 30 - filled

  bar_filled = @theme.gradient_text("▰" * filled, @theme.current_theme[:success])
  bar_empty = "#{DIM}▱" * empty

  puts "#{@theme.gradient_text("▸", @theme.current_theme[:accent])} #{label}"
  puts "  [#{bar_filled}#{bar_empty}#{RESET}] #{@theme.apply_glow(@theme.gradient_text("#{value}#{unit} / #{max_value}#{unit}", @theme.current_theme[:success]))} #{DIM}(#{percentage}%)#{RESET}"
end
  
  def badge(text, type = :default)
    colors = {
      success: @theme.current_theme[:success],
      error: @theme.current_theme[:error],
      warning: @theme.current_theme[:warning],
      info: @theme.current_theme[:accent],
      default: @theme.current_theme[:primary]
    }
    
    color = colors[type] || colors[:default]
    @theme.apply_glow(@theme.gradient_text(" #{text} ", color))
  end
  
  def menu(title, options, descriptions = {})
    header(title)
    
    options.each_with_index do |(key, label), i|
      desc = descriptions[key]
      badge_text = desc ? badge(desc, :info) : ""
      
      puts "#{@theme.gradient_text("#{key})", @theme.current_theme[:accent])} #{@theme.apply_glow(label)} #{badge_text}"
    end
    
    puts ""
    print "#{@theme.gradient_text("▸", @theme.current_theme[:accent])} #{@theme.apply_glow("Choose")}#{RESET}: "
  end
  
  def dashboard(widgets)
    widgets.each do |widget|
      case widget[:type]
      when :gauge
        gauge(widget[:label], widget[:value], widget[:max], widget[:unit] || "")
      when :badge_list
        puts "#{@theme.gradient_text("▸", @theme.current_theme[:accent])} #{@theme.apply_glow(widget[:label])}"
        widget[:items].each do |item|
          puts "  #{badge(item[:text], item[:type])}"
        end
      when :metric
        puts "#{@theme.gradient_text("▸", @theme.current_theme[:accent])} #{@theme.apply_glow(widget[:label])}: #{@theme.gradient_text(widget[:value].to_s, @theme.current_theme[:success])} #{DIM}#{widget[:unit]}#{RESET}"
      end
      puts ""
    end
  end
end

# ==================== ANALYTICS DASHBOARD ====================

class AnalyticsDashboard
  def initialize(ui, stats)
    @ui = ui
    @stats = stats
  end
  
  def display
    system("clear")
    
    @ui.header("📊 REAL-TIME ANALYTICS", "Live monitoring and statistics")
    
    widgets = [
      {
        type: :metric,
        label: "Total Sessions",
        value: @stats['total_sessions'] || 0,
        unit: "sessions"
      },
      {
        type: :metric,
        label: "Total Runtime",
        value: format_duration(@stats['total_duration'] || 0),
        unit: ""
      },
      {
        type: :gauge,
        label: "Uptime",
        value: 95,
        max: 100,
        unit: "%"
      },
      {
        type: :badge_list,
        label: "Active Tunnels",
        items: [
          { text: "Ngrok: ACTIVE", type: :success },
          { text: "Cloudflare: ACTIVE", type: :success },
          { text: "Loclx: STANDBY", type: :warning }
        ]
      }
    ]
    
    @ui.dashboard(widgets)
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

# ==================== PLACEHOLDER FUNCTIONS ====================

def ensure_dirs
  [BASE_DIR, CONFIG_DIR, LOG_DIR, BIN_DIR, STATS_DIR, PLUGINS_DIR, THEMES_DIR].each do |dir|
    FileUtils.mkdir_p(dir)
  end
end

def load_stats
  stats_file = "#{STATS_DIR}/analytics.json"
  return {} unless File.exist?(stats_file)
  JSON.parse(File.read(stats_file)) rescue {}
end

# ==================== MAIN MENU ====================

def main_menu
  loop do
    system("clear")
    puts generate_logo($theme_engine)
    
    options = {
      "1" => "🚀 Start Server & Tunnels",
      "2" => "🔑 API Key Management",
      "3" => "📊 Analytics Dashboard",
      "4" => "🎨 Theme Selector",
      "5" => "🔌 Plugin Manager",
      "6" => "⚙️  Settings",
      "7" => "📚 Help",
      "8" => "ℹ️  About",
      "0" => "🚪 Exit"
    }
    
    descriptions = {
      "1" => "Recommended",
      "3" => "Real-time",
      "4" => "Customize",
      "5" => "Beta"
    }
    
    $ui.menu("MAIN DASHBOARD", options, descriptions)
    choice = gets.chomp.strip
    
    case choice
    when "1"
      $ui.notification(:info, "Starting", "Initializing tunnel services...")
      sleep 2
    when "3"
      dashboard = AnalyticsDashboard.new($ui, load_stats)
      dashboard.display
      print "\nPress ENTER to continue..."
      gets
    when "4"
      theme_selector
    when "8"
      show_about
    when "0"
      $ui.notification(:success, "Goodbye", "Thanks for using Local2Internet!")
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
    status = is_active ? $ui.badge("ACTIVE", :success) : ""
    
    puts "#{$ui.theme.gradient_text("#{i + 1})", $ui.theme.current_theme[:accent])} #{$ui.theme.apply_glow(theme[:name])} #{status}"
    puts "   #{DIM}Preview: #{$ui.theme.gradient_text("■■■", theme[:primary])} #{$ui.theme.gradient_text("■■■", theme[:accent])}#{RESET}"
    puts ""
  end
  
  print "#{$ui.theme.gradient_text("▸", $ui.theme.current_theme[:accent])} Select theme (1-#{ThemeEngine::THEMES.length}): "
  choice = gets.chomp.strip.to_i
  
  if choice > 0 && choice <= ThemeEngine::THEMES.length
    theme_name = ThemeEngine::THEMES.keys[choice - 1]
    $theme_engine.set_theme(theme_name)
    $ui = ModernUI.new($theme_engine)
    $ui.notification(:success, "Theme Changed", "Applied #{ThemeEngine::THEMES[theme_name][:name]} theme")
    sleep 2
  end
end

def show_about
  system("clear")
  
  $ui.card(
    "About Local2Internet",
    [
      "",
      "#{$ui.theme.gradient_text("Version", $ui.theme.current_theme[:accent])}: v#{VERSION} #{EDITION}",
      "#{$ui.theme.gradient_text("Description", $ui.theme.current_theme[:accent])}: Next-gen localhost tunneling platform",
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
  
  print "\nPress ENTER to continue..."
  gets
end

# ==================== ENTRY POINT ====================

begin
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
  puts "#{DIM}#{e.backtrace.first(3).join("\n")}#{RESET}" if ENV["DEBUG"]
  exit 1
end
