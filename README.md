# 🚀 CodeReady

**Developer Environment Setup Tool** — Interactive installer for programming languages, IDEs, and developer tools.

> *"Which languages do you need? Which IDEs do you prefer? Let CodeReady handle the rest."*

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-green)
![License](https://img.shields.io/badge/license-MIT-orange)

---

## ✨ Features

- **Interactive menu** — Select languages and IDEs from a user-friendly interface
- **Quick Setup Profiles** — Pre-configured setups for Web, Mobile, Data Science, Systems, .NET, and Game developers
- **Cross-platform** — Works on Windows, macOS, Ubuntu/Debian, Fedora, Arch, openSUSE
- **Smart package management** — Uses winget/Chocolatey (Windows), Homebrew (macOS), apt/dnf/pacman (Linux)
- **Installation logging** — Full log file for troubleshooting
- **Config export** — Save your selections for reuse on other machines

## 📦 Supported Software

### Programming Languages & Runtimes
| Language | Windows | macOS | Linux |
|----------|---------|-------|-------|
| Python 3.12 | ✅ winget | ✅ brew | ✅ apt/dnf/pacman |
| Node.js (LTS via nvm) | ✅ winget | ✅ nvm | ✅ nvm |
| Java (JDK 21) | ✅ winget | ✅ brew | ✅ apt/dnf/pacman |
| C# / .NET 8 SDK | ✅ winget | ✅ brew | ✅ apt/dnf/pacman |
| C/C++ (GCC/MinGW/Clang) | ✅ choco | ✅ brew | ✅ apt/dnf/pacman |
| Go (Golang) | ✅ winget | ✅ brew | ✅ official binary |
| Rust (via rustup) | ✅ winget | ✅ rustup | ✅ rustup |
| PHP | ✅ choco | ✅ brew | ✅ apt/dnf/pacman |
| Ruby | ✅ winget | ✅ brew | ✅ apt/dnf/pacman |
| Kotlin | ✅ choco | ✅ brew | ✅ snap/SDKMAN |
| Dart & Flutter | ✅ choco | ✅ brew | ✅ snap |
| Swift | ✅ winget | ✅ Xcode | ⚠️ manual |

### IDEs & Editors
| IDE | Windows | macOS | Linux |
|-----|---------|-------|-------|
| VS Code | ✅ | ✅ | ✅ |
| Visual Studio 2022 Community | ✅ | ❌ | ❌ |
| IntelliJ IDEA Community | ✅ | ✅ | ✅ |
| PyCharm Community | ✅ | ✅ | ✅ |
| WebStorm | ✅ | ✅ | ✅ |
| GoLand | ✅ | ✅ | ✅ |
| CLion | ✅ | ✅ | ✅ |
| Rider | ✅ | ✅ | ✅ |
| Eclipse IDE | ✅ | ✅ | ✅ |
| Android Studio | ✅ | ✅ | ✅ |
| Sublime Text | ✅ | ✅ | ✅ |
| Neovim | ✅ | ✅ | ✅ |
| Notepad++ | ✅ | ❌ | ❌ |
| Cursor | ✅ | ✅ | ⚠️ manual |

### Developer Tools
| Tool | Windows | macOS | Linux |
|------|---------|-------|-------|
| Git | ✅ | ✅ | ✅ |
| Docker | ✅ | ✅ | ✅ |
| Postman | ✅ | ✅ | ✅ |
| CMake | ✅ | ✅ | ✅ |
| GitHub CLI | ✅ | ✅ | ✅ |
| WSL 2 (Ubuntu) | ✅ | ❌ | ❌ |
| Windows Terminal | ✅ | ❌ | ❌ |

## 🏃 Quick Start

### Windows
```powershell
# Option 1: Double-click
codeready.bat

# Option 2: PowerShell (as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force
.\codeready.ps1
```

### Linux / macOS
```bash
chmod +x codeready.sh
./codeready.sh
```

## 🎯 Quick Setup Profiles

Instead of selecting individual items, choose a pre-configured profile:

| # | Profile | Languages | IDEs | Tools |
|---|---------|-----------|------|-------|
| 1 | **Web Developer** | Node.js, Python, PHP | VS Code, Sublime | Git, Docker, Postman |
| 2 | **Mobile Developer** | Java, Kotlin, Dart | Android Studio, VS Code | Git |
| 3 | **Data Scientist** | Python, Node.js | VS Code, PyCharm | Git, Docker |
| 4 | **Systems Programmer** | C/C++, Rust, Go | VS Code, CLion, Vim | Git, CMake |
| 5 | **Full Stack .NET** | C#/.NET, Node.js | VS 2022, VS Code | Git, Docker, Postman |
| 6 | **Game Developer** | C/C++, C# | VS 2022, VS Code | Git, CMake |
| 7 | **Custom Setup** | Your choice | Your choice | Your choice |

## 📁 Project Structure

```
codeready/
├── codeready.bat       # Windows launcher (auto-elevates to admin)
├── codeready.ps1       # Windows PowerShell script (main logic)
├── codeready.sh        # Linux/macOS bash script (main logic)
└── README.md           # This file
```

## 📋 Output Files

After installation, CodeReady creates:
- `~/codeready_install.log` — Detailed installation log
- `~/codeready_config.json` — Your selections (Windows only, for reuse)

## 🔧 Requirements

### Windows
- Windows 10 version 1809+ or Windows 11
- Administrator privileges
- Internet connection

### macOS
- macOS 12 Monterey or later
- Command Line Tools (`xcode-select --install`)
- Internet connection

### Linux
- Ubuntu 20.04+ / Debian 11+ / Fedora 36+ / Arch / openSUSE
- sudo privileges
- Internet connection

## 🤝 Contributing

Contributions are welcome! To add a new language or IDE:

1. **Windows:** Add entry to `Get-LanguageDefinitions` or `Get-IDEDefinitions` in `codeready.ps1`
2. **Linux/macOS:** Add an `install_<name>()` function in `codeready.sh` and register it in the dispatcher

## 📄 License

MIT License — feel free to use, modify, and distribute.

---

**Made with ❤️ for developers who value their time.**
