# 🌍 Local2Internet

<p align="center">
  <img src="https://img.shields.io/badge/Original%20Author-KasRoudra-magenta?style=flat-square">
  <img src="https://img.shields.io/badge/Maintainer-Muhammad%20Taezeem%20Tariq%20Matta-green?style=flat-square">
  <img src="https://img.shields.io/badge/Open%20Source-Yes-orange?style=flat-square">
  <img src="https://img.shields.io/badge/Language-Ruby-blue?style=flat-square">
  <img src="https://img.shields.io/badge/License-MIT-lightgrey?style=flat-square">
</p>

---

## 🚀 What is Local2Internet?

**Local2Internet** is an open-source tool that exposes your locally hosted website to the public internet using powerful tunneling services.

Perfect for:

* 🧪 Development & testing
* 🎯 Demos & presentations
* 🌐 Sharing local projects instantly

---

## ✨ Features

### 🖥️ Hosting Engines

* 🐍 Python HTTP Server
* 🐘 PHP Built-in Server
* 🟢 Node.js (`http-server`)

### 🌍 Tunneling Providers

* 🔗 Ngrok
* ☁️ Cloudflare Tunnel
* 🌐 Loclx

### ⚙️ Core Capabilities

* 📁 Custom directory hosting
* 🔢 Custom port selection
* 🧠 Automatic dependency handling
* 📊 Process & log management
* 🧩 Modular architecture
* 💻 Linux, Termux & Windows support

---

## 🛠️ Installation

### 1️⃣ Linux / Termux

#### Install Dependencies

```bash
apt install ruby python3 nodejs php wget curl unzip -y
```

#### Install Node HTTP Server

```bash
npm install -g http-server
```

#### Clone the Repository

```bash
git clone https://github.com/Taezeem14/Local2Internet
```

#### Enter the Project Directory

```bash
cd Local2Internet
```

#### Run the Tool

```bash
ruby l2in.rb
```

### 2️⃣ Windows (PowerShell)

#### Install Dependencies

```powershell
# Install Ruby
choco install ruby -y
# Install Python
choco install python -y
# Install Node.js
choco install nodejs -y
# Install PHP
choco install php -y
# Install Wget & Curl
choco install wget curl -y
# Install Unzip
choco install unzip -y
```

#### Install Node HTTP Server

```powershell
npm install -g http-server
```

#### Clone & Run

```powershell
git clone https://github.com/Taezeem14/Local2Internet
cd Local2Internet
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
.\Local2Internet.ps1
```

---

## ⚡ One-Line Setup

### Linux / Termux

```bash
apt install ruby python3 nodejs php wget curl unzip -y && \
npm install -g http-server && \
git clone https://github.com/KasRoudra/Local2Internet && \
cd Local2Internet && \
chmod +x l2in.rb && \
ruby l2in.rb
```

### Windows (PowerShell)

```powershell
choco install ruby python nodejs php wget curl unzip -y; npm install -g http-server; git clone https://github.com/KasRoudra/Local2Internet; cd Local2Internet; Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; .\Local2Internet.ps1
```

---

## 📖 Usage Guide

1. 📂 Enter the directory containing your website files.
2. 🖥️ Choose a hosting engine (Python / PHP / Node.js).
3. 🔢 Select a port (or use the default).
4. 🌍 Choose a tunneling provider.
5. 🔗 Use the generated public URL to access your site from anywhere.

---

## 🖼️ Preview

<img src="https://github.com/KasRoudra/Local2Internet/raw/main/main.jpg">

---

## 👥 Authors & Credits

* 👑 Original Author: **KasRoudra**
* 🧠 Maintainer & Contributor: **Muhammad Taezeem Tariq Matta**

---

## 📬 Contact

### Original Author

* 📧 Email: [kasroudrakrd@gmail.com](mailto:kasroudrakrd@gmail.com)
* 💬 Messenger: [https://m.me/KasRoudra](https://m.me/KasRoudra)

### Maintainer

* 📧 Email: [taezeem@taezeem.me](mailto:taezeem@taezeem.me)  <!-- Replace with your actual email -->
* 💬 Messenger: [https://t.me/Taezeem](https://t.me/Taezeem_14) <!-- Replace with your actual link -->

---

## ⭐ Open Source Spirit

Local2Internet is an open-source project. Contributions, improvements, and ideas are welcome.
If you like this project, consider giving it a ⭐ on GitHub.
