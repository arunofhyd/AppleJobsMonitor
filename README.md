<div align="center">
  <img src="logo-jobsmonitor.png" alt="Jobs Monitor Logo" width="120" height="120">
  <h1>Jobs Monitor</h1>
  <p><strong>Native macOS Menu Bar App for Apple Job Openings</strong></p>
  <p align="center">
  Made for <img src="https://cdn.simpleicons.org/apple/white" width="11" height="11" valign="middle"> <strong>macOS</strong>
  </p>

  <p>
    <img src="https://img.shields.io/badge/Built%20With-Swift-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift">
    <img src="https://img.shields.io/badge/Privacy-100%25%20Local-34C759?style=flat-square&logo=apple&logoColor=white" alt="100% Local">
    <img src="https://img.shields.io/badge/Platform-macOS-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS">
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
  </p>

  <p><em>Never miss an opening at Apple.</em></p>
</div>

---

**Jobs Monitor** is a free, lightweight, privacy-first native macOS application that tracks new job postings on **jobs.apple.com** in real-time. It lives quietly in your menu bar, sends instant macOS alerts when new positions open, and generates a clean interactive web dashboard.

Built specifically for engineers, designers, and professionals tracking roles across **India, US, UK, Canada, Australia, Germany, Japan, Singapore**, and 20+ global tech hubs — **100% on-device, zero telemetry, no accounts required.**

## 🎯 Features

*   **100% Local & Privacy-First**: 🔒 Zero tracking, zero telemetry. Connects directly from your Mac to `jobs.apple.com`.
*   **Global & City Search Support**: 🌍 Track openings across **20+ countries** and **24 major tech hubs** (Cupertino, Austin, SF, Seattle, London, Hyderabad, Bengaluru, Singapore, Munich, etc.) or set a custom Apple Jobs search URL.
*   **Instant macOS Alerts**: 🔔 Get instant, non-intrusive macOS system alerts whenever new matching roles are posted.
*   **Interactive Web Dashboard**: 📊 Click "View Dashboard" to open a clean HTML dashboard showing role title, team, location, and direct application links.
*   **Custom Check Intervals**: ⏱️ Set background check intervals from **5 minutes to 6 hours**.
*   **Daily Digest Schedule**: 🗓️ Schedule daily summaries at your preferred time (e.g. 10:00 AM) on active weekdays (Mon–Fri).
*   **Adaptive Menu Bar Icon**:  Features a custom monochrome vector menu bar icon (Apple logo inside a magnifying glass) that dynamically adapts to macOS Light & Dark Modes.
*   **Automatic Updates**: 🔄 Includes built-in version checking against GitHub Releases with release notes & one-click updates.
*   **Launch at Login**: 🚀 Starts automatically at system startup via macOS `SMAppService` and LaunchAgent.


## 🍺 Install via Homebrew

You can install **Jobs Monitor** using Homebrew:

```bash
brew install --cask arunofhyd/jobsmonitor/jobsmonitor
```

To update via Homebrew in the future:
```bash
brew upgrade --cask jobsmonitor
```

## 📦 Install

Install by running the installer in **Terminal**:

1. **Download** [`install-jobsmonitor.command`](install-jobsmonitor.command) (open the file, then click **Download raw file**).
2. Open **Terminal** (`⌘ + Space`, type `Terminal`, press Enter).
3. Type `sh ` — that's **s**, **h**, then a **space**.
4. **Drag** the downloaded `install-jobsmonitor.command` into the Terminal window.
5. Press **Enter** to compile and launch **Jobs Monitor**.

> **First time only:** The installer builds the application natively on your Mac so macOS Gatekeeper trusts it completely with no security warnings.

## ⚙️ How It Works

The installer compiles the app's Swift source and icon assets **right on your Mac**. Because it's compiled locally rather than downloaded pre-made, macOS Gatekeeper trusts it natively without security warnings.

## 🗑️ Uninstall

1. Run `install-jobsmonitor.command` in Terminal.
2. Select option **`2) Uninstall Jobs Monitor`**.

## 📦 Tech Stack
*   **Swift** (AppKit, ServiceManagement)
*   **Python** (Standalone Installer Engine)
*   **HTML/CSS** (Native Dashboard UI)

## 📄 License
MIT License. Free for personal use.

---

<p align="center">
  Made with ❤️ by <a href="mailto:arunthomashyd@gmail.com">Arun Thomas</a>
</p>
