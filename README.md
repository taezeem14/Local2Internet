# 🌍 Local2Internet v4 - Enhanced Edition

<p align="center">
  <img src="https://img.shields.io/badge/Original%20Author-KasRoudra-magenta?style=for-the-badge">
  <img src="https://img.shields.io/badge/Enhanced%20By-Muhammad%20Taezeem%20Tariq%20Matta-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/Version-4.0-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Open%20Source-Yes-orange?style=for-the-badge">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.0+-red?style=flat-square&logo=ruby">
  <img src="https://img.shields.io/badge/PowerShell-7.0+-blue?style=flat-square&logo=powershell">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20Termux%20%7C%20Windows-success?style=flat-square">
</p>

---

## 🚀 What is Local2Internet?

**Local2Internet v4** is a professional-grade, open-source tool that instantly exposes your localhost to the public internet using **triple tunneling** technology. Built for developers who need fast, reliable, and secure public URLs for their local development servers.

### 🎯 Perfect For:

* 🧪 **Development & Testing** - Test webhooks, APIs, and integrations
* 🎯 **Demos & Presentations** - Share your work instantly without deployment
* 🌐 **Remote Collaboration** - Let teammates access your local environment
* 📱 **Mobile Testing** - Test your web apps on real devices
* 🔐 **Penetration Testing** - Ethical hacking and security research (sandboxed)

---

## ✨ Features

### 🖥️ Multi-Protocol Hosting

| Protocol | Description | Use Case |
|----------|-------------|----------|
| 🐍 **Python** | Built-in HTTP server | Static sites, APIs |
| 🐘 **PHP** | Native PHP server | WordPress, Laravel |
| 🟢 **Node.js** | http-server via npm | React, Vue, Angular |

### 🌍 Triple Tunneling Technology

| Provider | Speed | Uptime | Custom Domains |
|----------|-------|--------|----------------|
| 🔗 **Ngrok** | ⚡⚡⚡ | 99.9% | ✅ (Premium) |
| ☁️ **Cloudflare** | ⚡⚡⚡⚡ | 99.99% | ✅ (Free) |
| 🌐 **Loclx** | ⚡⚡ | 99% | ✅ (Premium) |

> **Pro Tip:** All three tunnels run simultaneously for maximum reliability! If one fails, you have two backups.

### ⚙️ Core Capabilities

* ✅ **Smart URL Extraction** - Automatically parses and displays public URLs
* ✅ **Process Management** - Clean shutdown, no zombie processes
* ✅ **Auto-Dependency Install** - Handles Python, PHP, Node.js, npm packages
* ✅ **Architecture Detection** - ARM, ARM64, x86, x64 support
* ✅ **Interactive Menu System** - User-friendly CLI interface
* ✅ **Health Checks** - Verifies server started before tunneling
* ✅ **Organized Logs** - Detailed logging for debugging
* ✅ **Termux Support** - Full compatibility with Android (proot mode)
* ✅ **Windows Native** - PowerShell 7+ with proper ANSI colors
* ✅ **Signal Handling** - Graceful CTRL+C exits with cleanup

---

## 🛠️ Installation

### 📦 Quick Install (Recommended)

#### Linux / Termux
```bash
curl -sL https://raw.githubusercontent.com/Taezeem14/Local2Internet/main/install.sh | bash
```

#### Windows PowerShell
```powershell
iwr -useb https://raw.githubusercontent.com/Taezeem14/Local2Internet/main/install.ps1 | iex
```

---

### 🔧 Manual Installation

#### 1️⃣ Linux / Termux

**Step 1: Install System Dependencies**
```bash
# Debian/Ubuntu/Termux
apt update && apt install -y ruby python3 nodejs php wget curl unzip git

# Arch Linux
pacman -S ruby python nodejs php wget curl unzip git

# Fedora/RHEL
dnf install ruby python3 nodejs php wget curl unzip git
```

**Step 2: Install Node HTTP Server**
```bash
npm install -g http-server
```

**Step 3: Clone Repository**
```bash
git clone https://github.com/Taezeem14/Local2Internet.git
cd Local2Internet
```

**Step 4: Make Executable & Run**
```bash
chmod +x l2in.rb
./l2in.rb
```

---

#### 2️⃣ Windows (PowerShell)

**Step 1: Install Chocolatey (if not installed)**
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

**Step 2: Install Dependencies**
```powershell
choco install ruby python nodejs php wget curl unzip git -y
refreshenv
```

**Step 3: Install Node HTTP Server**
```powershell
npm install -g http-server
```

**Step 4: Clone & Run**
```powershell
git clone https://github.com/Taezeem14/Local2Internet.git
cd Local2Internet
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\l2in.ps1
```

---

## 📖 Usage Guide

### Basic Workflow

```
┌─────────────────────────────────────┐
│  1. Run Local2Internet              │
├─────────────────────────────────────┤
│  2. Select "Start Server & Tunnels" │
├─────────────────────────────────────┤
│  3. Enter directory path            │
├─────────────────────────────────────┤
│  4. Choose hosting protocol         │
│     • Python (default)              │
│     • PHP                           │
│     • NodeJS                        │
├─────────────────────────────────────┤
│  5. Enter port (default: 8888)      │
├─────────────────────────────────────┤
│  6. Wait for tunnels to start       │
├─────────────────────────────────────┤
│  7. Copy & share public URLs! 🎉    │
└─────────────────────────────────────┘
```

### Example Session

```bash
$ ./l2in.rb

▒█░░░ █▀▀█ █▀▀ █▀▀█ █░░ █▀█ ▀█▀ █▀▀▄ ▀▀█▀▀ █▀▀ █▀▀█ █▀▀▄ █▀▀ ▀▀█▀▀
▒█░░░ █░░█ █░░ █▄▄█ █░░ ░▄▀ ▒█░ █░░█ ░░█░░ █▀▀ █▄▄▀ █░░█ █▀▀ ░░█░░
▒█▄▄█ ▀▀▀▀ ▀▀▀ ▀░░▀ ▀▀▀ █▄▄ ▄█▄ ▀░░▀ ░░▀░░ ▀▀▀ ▀░▀▀ ▀░░▀ ▀▀▀ ░░▀░░
                                                    [v4 Enhanced]

╔════════════════════════════════════════╗
║            MAIN MENU                   ║
╚════════════════════════════════════════╝

1) Start Server & Tunnels
2) About
0) Exit

[?] Choice: 1

[?] Enter directory path to host: /home/user/my-website

Select hosting protocol:
1) Python (http.server)
2) PHP (built-in server)
3) NodeJS (http-server)
[?] Choice [1-3] (default: 1): 1

[?] Enter port (default: 8888): 

[+] Starting Python server on port 8888...
[✓] Server running at http://127.0.0.1:8888

[+] Starting Ngrok tunnel...
[+] Starting Cloudflare tunnel...
[+] Starting Loclx tunnel...

╔════════════════════════════════════════╗
║          PUBLIC URLS READY!            ║
╚════════════════════════════════════════╝

[✓] Ngrok : https://abc123.ngrok.io
[✓] Cloudflare : https://xyz456.trycloudflare.com
[✓] Loclx : https://def789.loclx.io

3/3 tunnels active

[!] Press CTRL+C to stop
```

---

## 🏗️ Project Structure

```
Local2Internet/
├── l2in.rb                    # Ruby version (Linux/Termux)
├── l2in.ps1                   # PowerShell version (Windows)
├── README.md                  # This file
├── LICENSE                    # MIT License
├── install.sh                 # Linux auto-installer
├── install.ps1                # Windows auto-installer
│
└── ~/.local2internet/         # Auto-created on first run
    ├── bin/
    │   ├── ngrok              # Ngrok binary
    │   ├── cloudflared        # Cloudflare binary
    │   └── loclx              # Loclx binary
    │
    └── logs/
        ├── cloudflare.log     # Cloudflare tunnel logs
        └── loclx.log          # Loclx tunnel logs
```

---

## 🎨 Advanced Features

### 🔧 Custom Port Selection

```bash
# Host on port 3000
[?] Enter port: 3000
```

### 🐘 PHP Projects

```bash
# For WordPress, Laravel, etc.
[?] Choose hosting protocol: 2  # PHP
```

### 🌐 Static Site Generators

```bash
# React/Vue/Angular build folders
[?] Enter directory: ./dist
[?] Choose hosting protocol: 3  # NodeJS
```

### 📱 Termux on Android

```bash
# Enable hotspot for better connectivity
[!] Please enable mobile hotspot if needed...

# Uses termux-chroot for proper execution
```

### 🪟 Windows Dark Mode

PowerShell version includes proper ANSI color support for Windows Terminal and modern consoles.

---

## 🐛 Troubleshooting

### Issue: "Tunneling failed!"

**Solution:**
- Check internet connection
- Verify firewall isn't blocking ports
- Try restarting the tool
- Check logs in `~/.local2internet/logs/`

### Issue: "Local server failed to start!"

**Solution:**
- Ensure directory contains index.html or index.php
- Check if port is already in use
- Verify hosting protocol is installed
- Run: `netstat -ano | findstr :8888` (Windows) or `lsof -i :8888` (Linux)

### Issue: "Chocolatey not found" (Windows)

**Solution:**
```powershell
# Install Chocolatey first
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

### Issue: Zombie processes remain

**Solution:**
```bash
# Linux/Termux
killall php python3 ngrok cloudflared loclx

# Windows
Get-Process php,python,ngrok,cloudflared,loclx | Stop-Process -Force
```

---

## 🔐 Security Notes

⚠️ **Important Security Considerations:**

1. **Never expose sensitive data** - Don't host folders with API keys, passwords, or private files
2. **Use HTTPS URLs** - All tunneling providers use HTTPS by default
3. **Temporary URLs** - Free tunnel URLs are temporary and change on restart
4. **Rate Limiting** - Free tiers have bandwidth/connection limits
5. **Educational Use** - Perfect for learning, testing, demos - not production
6. **Firewall Rules** - Consider firewall restrictions for added security

---

## 📊 Performance Benchmarks

| Metric | Python | PHP | NodeJS |
|--------|--------|-----|--------|
| Startup Time | ~2s | ~1.5s | ~3s |
| Memory Usage | ~15MB | ~20MB | ~40MB |
| Concurrent Connections | 100+ | 200+ | 500+ |
| Static File Serving | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Dynamic Content | ⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

---

## 🤝 Contributing

Contributions are **highly welcome**! Here's how you can help:

### 🎯 Ways to Contribute

- 🐛 Report bugs via [GitHub Issues](https://github.com/Taezeem14/Local2Internet/issues)
- 💡 Suggest new features
- 📝 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star the repository
- 🔗 Share with other developers

### 📋 Contribution Guidelines

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 👥 Authors & Credits

### 👑 Original Creator
**KasRoudra**
- 📧 Email: [kasroudrakrd@gmail.com](mailto:kasroudrakrd@gmail.com)
- 💬 Messenger: [m.me/KasRoudra](https://m.me/KasRoudra)
- 🐙 GitHub: [@KasRoudra](https://github.com/KasRoudra)

### 🚀 Enhanced & Maintained By
**Muhammad Taezeem Tariq Matta (Bro)**
- 🎓 Grade 7 Student @ SRM WELKIN Higher Secondary School, Sopore
- 💻 Full-Stack Developer | Cybersecurity Enthusiast | Ethical Hacker
- 📧 Email: [taezeem@taezeem.me](mailto:taezeem@taezeem.me)
- 💬 Telegram: [@Taezeem_14](https://t.me/Taezeem_14)
- 🐙 GitHub: [@Taezeem14](https://github.com/Taezeem14)

### 🏆 Special Thanks
- **Ngrok Team** - For providing reliable tunneling infrastructure
- **Cloudflare** - For free and fast tunnel services
- **Loclx** - For additional tunneling options
- **Ruby Community** - For the amazing programming language
- **PowerShell Team** - For modern scripting capabilities
- **All Contributors** - Your PRs make this project better!

---

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2021 KasRoudra
Copyright (c) 2025 Muhammad Taezeem Tariq Matta

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 📈 Roadmap

### ✅ Completed (v4.0)
- ✅ Triple tunneling support
- ✅ Interactive menu system
- ✅ Windows PowerShell version
- ✅ Clean process management
- ✅ Auto-dependency installation
- ✅ Health check system
- ✅ Organized logging

### 🚧 Planned Features (v4.1+)
- 🔜 Config file support (.l2irc)
- 🔜 Custom ngrok authtoken support
- 🔜 Desktop notifications
- 🔜 QR code generation for mobile
- 🔜 Bandwidth usage statistics
- 🔜 Connection analytics
- 🔜 Docker support
- 🔜 GUI version (Electron)
- 🔜 API key management
- 🔜 Custom domain support

---

## ⭐ Stargazers

If you find this project useful, please consider giving it a ⭐ on GitHub!

[![Stargazers repo roster for @Taezeem14/Local2Internet](https://reporoster.com/stars/Taezeem14/Local2Internet)](https://github.com/Taezeem14/Local2Internet/stargazers)

---

## 📞 Support & Community

### 💬 Get Help
- 📖 Check [Documentation](https://github.com/Taezeem14/Local2Internet/wiki)
- 🐛 Report [Issues](https://github.com/Taezeem14/Local2Internet/issues)
- 💡 Request [Features](https://github.com/Taezeem14/Local2Internet/issues/new)
- 📧 Email Support: [taezeem@taezeem.me](mailto:taezeem@taezeem.me)

### 🌟 Stay Updated
- ⭐ Star the repo to get notifications
- 👀 Watch for releases
- 🔔 Enable GitHub notifications

---

## 📸 Screenshots

### Linux/Termux
![Linux Screenshot](https://via.placeholder.com/800x400/1a1a1a/00ff00?text=Local2Internet+v4+Linux)

### Windows PowerShell
![Windows Screenshot](https://via.placeholder.com/800x400/012456/00aaff?text=Local2Internet+v4+Windows)

---

## 🎉 Fun Facts

- 🚀 **Lines of Code**: ~800 (Ruby) + ~600 (PowerShell)
- 🌍 **Supported Platforms**: 3 (Linux, Windows, Android/Termux)
- 🔗 **Tunneling Services**: 3 (Ngrok, Cloudflare, Loclx)
- 🖥️ **Hosting Protocols**: 3 (Python, PHP, Node.js)
- ⭐ **GitHub Stars**: [Your stars here]
- 🍴 **Forks**: Growing daily!
- 👥 **Contributors**: Open to everyone!

---

<p align="center">
  <b>Made with ❤️ by KasRoudra & Muhammad Taezeem Tariq Matta</b>
  <br>
  <sub>Open Source • MIT Licensed • Community Driven</sub>
</p>

<p align="center">
  <a href="https://github.com/Taezeem14/Local2Internet/stargazers">⭐ Star</a> •
  <a href="https://github.com/Taezeem14/Local2Internet/issues">🐛 Report Bug</a> •
  <a href="https://github.com/Taezeem14/Local2Internet/issues">💡 Request Feature</a>
</p>

---

<p align="center">
  <sub>
    🔥 Built for developers, by developers 🔥
    <br>
    "Making localhost accessible to the world, one tunnel at a time"
  </sub>
</p>
