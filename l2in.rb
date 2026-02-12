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

require 'open3'
require 'fileutils'

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

DEPENDENCIES = %w[python3 php wget unzip curl node]

DEFAULT_PORT = 8888

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
  `uname -m`.strip
end

def log_file(name)
  "#{LOG_DIR}/#{name}.log"
end

def abort_with(msg)
  puts "[ERROR] #{msg}"
  exit 1
end

# ------------------ DEPENDENCY MANAGER ------------------

def install_dependencies
  puts "[INFO] Checking system dependencies..."

  DEPENDENCIES.each do |dep|
    next if command_exists?(dep)
    puts "[INFO] Installing #{dep}..."
    exec_silent("apt install #{dep} -y") || abort_with("Failed to install #{dep}")
  end

  unless command_exists?("http-server")
    puts "[INFO] Installing Node http-server..."
    exec_silent("npm install -g http-server") || abort_with("Failed to install http-server")
  end
end

# ------------------ TOOL DOWNLOADS ------------------

def download_ngrok
  return if File.exist?(TOOLS[:ngrok])

  puts "[INFO] Downloading ngrok..."

  url =
    case arch
    when /arm/
      "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-arm.zip"
    when /aarch64/
      "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-arm64.tgz"
    when /x86_64/
      "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-amd64.zip"
    else
      "https://github.com/KasRoudra/files/raw/main/ngrok/ngrok-stable-linux-386.zip"
    end

  tmp = "#{BASE_DIR}/ngrok.tmp"
  exec_silent("wget -q #{url} -O #{tmp}")

  if tmp.end_with?(".zip")
    exec_silent("unzip #{tmp} -d #{BIN_DIR}")
  else
    exec_silent("tar -xf #{tmp} -C #{BIN_DIR}")
  end

  exec_silent("chmod +x #{TOOLS[:ngrok]}")
  File.delete(tmp) if File.exist?(tmp)
end

def download_cloudflared
  return if File.exist?(TOOLS[:cloudflared])

  puts "[INFO] Downloading cloudflared..."

  url =
    case arch
    when /arm/
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
    when /aarch64/
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
    when /x86_64/
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
    else
      "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-386"
    end

  exec_silent("wget -q #{url} -O #{TOOLS[:cloudflared]}")
  exec_silent("chmod +x #{TOOLS[:cloudflared]}")
end

def download_loclx
  return if File.exist?(TOOLS[:loclx])

  puts "[INFO] Downloading loclx..."

  url =
    case arch
    when /arm/
      "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-arm.zip"
    when /aarch64/
      "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-arm64.zip"
    when /x86_64/
      "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-amd64.zip"
    else
      "https://lxpdownloads.sgp1.digitaloceanspaces.com/cli/loclx-linux-386.zip"
    end

  tmp = "#{BASE_DIR}/loclx.zip"
  exec_silent("wget -q #{url} -O #{tmp}")
  exec_silent("unzip #{tmp} -d #{BIN_DIR}")
  exec_silent("chmod +x #{TOOLS[:loclx]}")
  File.delete(tmp) if File.exist?(tmp)
end

def download_tools
  download_ngrok
  download_cloudflared
  download_loclx
end

# ------------------ SERVER MANAGER ------------------

def start_server(path, port, mode)
  case mode
  when :python
    exec_silent("cd #{path} && python3 -m http.server #{port} &")
  when :php
    exec_silent("cd #{path} && php -S 127.0.0.1:#{port} &")
  when :node
    exec_silent("cd #{path} && http-server -p #{port} &")
  else
    abort_with("Invalid server mode")
  end
end

# ------------------ TUNNEL MANAGER ------------------

def start_ngrok(port)
  exec_silent("#{TOOLS[:ngrok]} http #{port} &")
  sleep 4
  `curl -s http://127.0.0.1:4040/api/tunnels | grep -o "https://[^ ]*ngrok.io"`.strip
end

def start_cloudflare(port)
  exec_silent("#{TOOLS[:cloudflared]} tunnel -url 127.0.0.1:#{port} > #{log_file("cloudflare")} 2>&1 &")
  sleep 4
  `grep -o "https://[^ ]*trycloudflare.com" #{log_file("cloudflare")}`.strip
end

def start_loclx(port)
  exec_silent("#{TOOLS[:loclx]} tunnel http --to :#{port} > #{log_file("loclx")} 2>&1 &")
  sleep 4
  `grep -o "https://[^ ]*loclx.io" #{log_file("loclx")}`.strip
end

def start_tunnel(type, port)
  case type
  when :ngrok then start_ngrok(port)
  when :cloudflare then start_cloudflare(port)
  when :loclx then start_loclx(port)
  else abort_with("Invalid tunnel type")
  end
end

# ------------------ CLI INTERFACE ------------------

def select_server
  puts "Select server type:"
  puts "1) Python"
  puts "2) PHP"
  puts "3) NodeJS"
  print "> "

  case gets.to_i
  when 1 then :python
  when 2 then :php
  when 3 then :node
  else :python
  end
end

def select_tunnel
  puts "Select tunnel provider:"
  puts "1) Ngrok"
  puts "2) Cloudflare"
  puts "3) Loclx"
  print "> "

  case gets.to_i
  when 1 then :ngrok
  when 2 then :cloudflare
  when 3 then :loclx
  else :ngrok
  end
end

# ------------------ MAIN ------------------

ensure_dirs
install_dependencies
download_tools

print "Enter directory to host: "
path = gets.chomp
abort_with("Directory not found") unless Dir.exist?(path)

server_mode = select_server

print "Enter port (default #{DEFAULT_PORT}): "
port = gets.chomp
port = DEFAULT_PORT if port.empty?

start_server(path, port, server_mode)

tunnel_type = select_tunnel
url = start_tunnel(tunnel_type, port)

puts "\nPublic URL:"
puts url.empty? ? "Failed to generate tunnel URL" : url

puts "\nPress CTRL+C to exit."
sleep
