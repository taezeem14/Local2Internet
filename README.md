# 🌍 Local2Internet v4.1 - Advanced Edition

<p align="center">
  <img src="https://img.shields.io/badge/Original%20Author-KasRoudra-magenta?style=for-the-badge">
  <img src="https://img.shields.io/badge/Enhanced%20By-Muhammad%20Taezeem%20Tariq%20Matta-green?style=for-the-badge">
  <img src="https://img.shields.io/badge/Version-4.1%20Advanced-blue?style=for-the-badge">
  <img src="https://img.shields.io/badge/Open%20Source-Yes-orange?style=for-the-badge">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=for-the-badge">
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Ruby-3.0+-red?style=flat-square&logo=ruby">
  <img src="https://img.shields.io/badge/PowerShell-7.0+-blue?style=flat-square&logo=powershell">
  <img src="https://img.shields.io/badge/Platform-Linux%20%7C%20Termux%20%7C%20Windows-success?style=flat-square">
</p>

---

## 🚀 What's New in v4.1?

### 🎯 Advanced Features

* ✅ **API Key Support** - Configure Ngrok and Loclx tokens for premium features
* ✅ **Enhanced Termux Support** - Full ARM64 compatibility with proot wrapper
* ✅ **Configuration Persistence** - Save your settings across sessions
* ✅ **Auto Port Detection** - Intelligent port availability checking
* ✅ **Improved Error Handling** - Better debugging and troubleshooting
* ✅ **Retry Mechanisms** - Auto-retry for failed tunnel connections
* ✅ **Cloudflared Termux Fix** - Fully functional in Termux environment
* ✅ **Interactive Help System** - Built-in documentation and guides

---

## 🎯 Perfect For:

* 🧪 **Development & Testing** - Test webhooks, APIs, and integrations
* 🎯 **Demos & Presentations** - Share your work instantly without deployment
* 🌐 **Remote Collaboration** - Let teammates access your local environment
* 📱 **Mobile Testing** - Test your web apps on real devices
* 🔐 **Penetration Testing** - Ethical hacking and security research (sandboxed)

---

## ✨ Core Features

### 🖥️ Multi-Protocol Hosting

| Protocol | Description | Use Case |
|----------|-------------|----------|
| 🐍 **Python** | Built-in HTTP server | Static sites, APIs |
| 🐘 **PHP** | Native PHP server | WordPress, Laravel |
| 🟢 **Node.js** | http-server via npm | React, Vue, Angular |

### 🌍 Triple Tunneling Technology

| Provider | Speed | Uptime | API Support | Custom Domains |
|----------|-------|--------|-------------|----------------|
| 🔗 **Ngrok** | ⚡⚡⚡ | 99.9% | ✅ | ✅ (Premium) |
| ☁️ **Cloudflare** | ⚡⚡⚡⚡ | 99.99% | ➖ | ✅ (Free) |
| 🌐 **Loclx** | ⚡⚡ | 99% | ✅ | ✅ (Premium) |

> **Pro Tip:** All three tunnels run simultaneously for maximum reliability! Configure API keys for enhanced performance.

---

## 🛠️ Installation

### 📦 Quick Install (Recommended)

#### Linux / Termux
```bash
curl -sL https://raw.githubusercontent.com/Taezeem14/Local2Internet/main/install_advanced.sh | bash
```

#### Windows PowerShell
```powershell
iwr -useb https://raw.githubusercontent.com/Taezeem14/Local2Internet/main/install_advanced.ps1 | iex
```

---

### 🔧 Manual Installation

#### 1️⃣ Linux / Termux

**Step 1: Install System Dependencies**
```bash
# Debian/Ubuntu/Termux
pkg update && pkg install -y ruby python3 nodejs php wget curl unzip git proot

# OR for Debian/Ubuntu (non-Termux)
sudo apt update && sudo apt install -y ruby python3 nodejs php wget curl unzip git

# Arch Linux
sudo pacman -S ruby python nodejs php wget curl unzip git

# Fedora/RHEL
sudo dnf install ruby python3 nodejs php wget curl unzip git
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
chmod +x l2in_advanced.rb
./l2in_advanced.rb
```

---

#### 2️⃣ Windows (PowerShell)

**Step 1: Install Chocolatey** (if not installed)
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
.\l2in_advanced.ps1
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

---

## 🔑 API Key Configuration

### Why Configure API Keys?

* 🚀 **Remove Rate Limits** - No connection/bandwidth restrictions
* 🔒 **Persistent URLs** - Keep the same URL across sessions (Ngrok)
* ⚡ **Priority Support** - Faster connection establishment
* 🌟 **Premium Features** - Custom domains, TCP tunnels, etc.

### How to Configure

#### Ngrok Authtoken

1. Visit [Ngrok Dashboard](https://dashboard.ngrok.com)
2. Sign up / Log in
3. Copy your authtoken
4. In Local2Internet:
   - Select `2) Manage API Keys`
   - Select `1) Set Ngrok Authtoken`
   - Paste your token

#### Loclx Access Token

1. Visit [Loclx Dashboard](https://localxpose.io/dashboard)
2. Sign up / Log in
3. Copy your access token
4. In Local2Internet:
   - Select `2) Manage API Keys`
   - Select `2) Set Loclx Access Token`
   - Paste your token

---

## 🏗️ Project Structure

```
Local2Internet/
├── l2in_advanced.rb           # Ruby version (Linux/Termux) - ADVANCED
├── l2in_advanced.ps1          # PowerShell version (Windows) - ADVANCED
├── l2in.rb                    # Ruby version (Legacy)
├── l2in.ps1                   # PowerShell version (Legacy)
├── README.md                  # This file
├── README_ADVANCED.md         # Advanced features documentation
├── LICENSE                    # MIT License
├── install_advanced.sh        # Linux/Termux auto-installer
├── install_advanced.ps1       # Windows auto-installer
│
└── ~/.local2internet/         # Auto-created on first run
    ├── bin/
    │   ├── ngrok              # Ngrok binary
    │   ├── cloudflared        # Cloudflare binary
    │   └── loclx              # Loclx binary
    │
    ├── logs/
    │   ├── cloudflare.log     # Cloudflare tunnel logs
    │   └── loclx.log          # Loclx tunnel logs
    │
    └── config.yml / config.json  # Configuration file
        └── API keys stored here
```

---

## 🎨 Advanced Features

### 🔧 Configuration Persistence

Your settings are automatically saved:
- API keys (encrypted)
- Last used port
- Preferred server protocol
- First-run setup completion

Location:
- Linux/Termux: `~/.local2internet/config.yml`
- Windows: `%USERPROFILE%\.local2internet\config.json`

### 🔄 Auto Port Detection

The tool automatically:
- Checks if the port is available
- Suggests alternatives if port is in use
- Retries connection on failure
- Validates port number (1-65535)

### 📱 Enhanced Termux Support

Special features for Android/Termux:
- ARM64 architecture support
- Proot wrapper for cloudflared
- Mobile hotspot reminders
- Battery optimization warnings
- Automatic dependency installation

### 🛠️ Improved Error Handling

- Detailed error messages with solutions
- Automatic retry mechanisms (up to 15 retries)
- Fallback options for failed tunnels
- Debug mode with verbose logging
- Log file creation for troubleshooting

---

## 🐛 Troubleshooting

### Issue: "Tunneling failed!"

**Solution:**
- Check internet connection
- Verify firewall isn't blocking ports
- Configure API keys (Menu option 2)
- Check logs in `~/.local2internet/logs/`
- Try restarting the tool

### Issue: "Local server failed to start!"

**Solution:**
- Ensure directory contains index.html or index.php
- Check if port is already in use
- Verify hosting protocol is installed
- Run: `netstat -ano | findstr :8888` (Windows) or `lsof -i :8888` (Linux)

### Issue: "Cloudflared not working in Termux"

**Solution:**
- Install proot: `pkg install proot`
- Restart Local2Internet
- Cloudflared will now use proot wrapper
- Check if ARM64 architecture is detected

### Issue: "API key not saving"

**Solution:**
- Check write permissions on config file
- Verify config directory exists
- Try running with elevated privileges
- Manual config: Edit `~/.local2internet/config.yml`

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
5. **API Key Security** - Keys are stored in config files - keep them secure
6. **Educational Use** - Perfect for learning, testing, demos - not production
7. **Firewall Rules** - Consider firewall restrictions for added security

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
**Muhammad Taezeem Tariq Matta**
- 🎓 Grade 8 Student @ SRM WELKIN Higher Secondary School, Sopore
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
Copyright (c) 2026 Muhammad Taezeem Tariq Matta

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

## 📈 Changelog

### v4.1 (Advanced Edition) - Current

#### 🎉 New Features
- ✅ API key support for Ngrok and Loclx
- ✅ Configuration persistence (YAML/JSON)
- ✅ Enhanced Termux compatibility with proot
- ✅ Auto port detection and validation
- ✅ Interactive help system
- ✅ Improved error handling with retry logic
- ✅ First-run setup wizard
- ✅ API key status display in menu

#### 🐛 Bug Fixes
- ✅ Fixed cloudflared ARM64 issues in Termux
- ✅ Fixed port already in use detection
- ✅ Fixed zombie process cleanup
- ✅ Fixed URL extraction retry mechanisms
- ✅ Fixed directory path validation
- ✅ Fixed config file permissions

#### 🔧 Improvements
- ✅ Better logging system
- ✅ More informative error messages
- ✅ Faster tunnel initialization
- ✅ More robust signal handling
- ✅ Enhanced color support
- ✅ Better cross-platform compatibility

### v4.0 (Enhanced Edition)
- ✅ Triple tunneling support
- ✅ Interactive menu system
- ✅ Windows PowerShell version
- ✅ Clean process management
- ✅ Auto-dependency installation
- ✅ Health check system
- ✅ Organized logging

---

## 🚧 Roadmap

### 🚀 Planned Features (v4.2+)

- 🔜 Web UI Dashboard
- 🔜 QR code generation for mobile access
- 🔜 Bandwidth usage statistics
- 🔜 Connection analytics
- 🔜 Docker support
- 🔜 Custom domain configuration UI
- 🔜 Multiple simultaneous servers
- 🔜 Webhook integration
- 🔜 Desktop notifications
- 🔜 macOS native support
- 🔜 SSH tunnel support
- 🔜 Load balancing

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
- 💬 Telegram: [@Taezeem_14](https://t.me/Taezeem_14)

### 🌟 Stay Updated
- ⭐ Star the repo to get notifications
- 👀 Watch for releases
- 🔔 Enable GitHub notifications

---

## 🎉 Fun Facts

- 🚀 **Lines of Code**: ~1200 (Ruby) + ~800 (PowerShell)
- 🌍 **Supported Platforms**: 3 (Linux, Windows, Android/Termux)
- 🔗 **Tunneling Services**: 3 (Ngrok, Cloudflare, Loclx)
- 🖥️ **Hosting Protocols**: 3 (Python, PHP, Node.js)
- 🔑 **API Integrations**: 2 (Ngrok, Loclx)
- ⭐ **GitHub Stars**: [Your stars matter!]
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
