# CodeReady v2.0

**Developer Environment Setup Tool** - Interactive installer for programming languages, IDEs, and developer tools with **version selection**.

> *Select your languages, pick your versions, choose your IDEs - CodeReady handles the rest.*

![Version](https://img.shields.io/badge/version-2.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Windows%20%7C%20Linux%20%7C%20macOS-green)
![License](https://img.shields.io/badge/license-MIT-orange)

---

## What's New in v2.0

- **Version selection** - Choose which version to install (e.g., Python 3.14 / 3.13 / 3.12 / 3.11)
- **New languages** - Zig, Mojo, WebAssembly (WASI), TypeScript, Elixir, Scala
- **New IDEs** - RustRover, Windsurf, Zed, Cursor
- **Updated versions** - VS 2026, JDK 25, Python 3.14, .NET 9, Node.js 24
- **AI/ML profile** - New quick setup for AI engineers
- **Version managers** - nvm, pyenv support

## Supported Software

### Languages & Runtimes (18 languages)

| Language | Available Versions | Windows | macOS | Linux |
|----------|-------------------|---------|-------|-------|
| Python | 3.14, 3.13, 3.12, 3.11 | Yes | Yes | Yes |
| Node.js | 24 LTS, 25, 22 LTS, 20 LTS | Yes | Yes | Yes |
| Java (JDK) | 25, 23 LTS, 21 LTS, 17 LTS | Yes | Yes | Yes |
| C# / .NET | 9, 8 LTS, 7, 6 LTS | Yes | Yes | Yes |
| C/C++ | GCC/MinGW, LLVM/Clang, MSVC | Yes | Yes | Yes |
| Go | 1.23, 1.22, 1.21 | Yes | Yes | Yes |
| Rust | latest (via rustup) | Yes | Yes | Yes |
| PHP | 8.4, 8.3, 8.2 | Yes | Yes | Yes |
| Ruby | 3.3, 3.2, 3.1 | Yes | Yes | Yes |
| Kotlin | latest | Yes | Yes | Yes |
| Dart/Flutter | latest | Yes | Yes | Yes |
| Swift | latest | Yes | Yes | Partial |
| Zig | 0.13, 0.12 | Yes | Yes | Yes |
| Mojo | latest (pip) | WSL | Yes | Yes |
| WebAssembly | Wasmtime, Wasmer | Yes | Yes | Yes |
| TypeScript | latest (npm) | Yes | Yes | Yes |
| Elixir | latest | Yes | Yes | Yes |
| Scala | latest | Yes | Yes | Yes |

### IDEs & Editors (17 editors)

| IDE | Type | Windows | macOS | Linux |
|-----|------|---------|-------|-------|
| VS Code | Free | Yes | Yes | Yes |
| Visual Studio 2026 Community | Free | Yes | - | - |
| IntelliJ IDEA Community | Free | Yes | Yes | Yes |
| PyCharm Community | Free | Yes | Yes | Yes |
| WebStorm | Paid | Yes | Yes | Yes |
| GoLand | Paid | Yes | Yes | Yes |
| CLion | Paid | Yes | Yes | Yes |
| Rider | Paid | Yes | Yes | Yes |
| RustRover | Free | Yes | Yes | Yes |
| Eclipse IDE | Free | Yes | Yes | Yes |
| Android Studio | Free | Yes | Yes | Yes |
| Sublime Text | Freemium | Yes | Yes | Yes |
| Neovim | Free | Yes | Yes | Yes |
| Notepad++ | Free | Yes | - | - |
| Cursor | Freemium | Yes | Yes | Yes |
| Windsurf | Free | Yes | Yes | Yes |
| Zed | Free | Yes | Yes | Yes |

### Developer Tools (9 tools)

Git, Docker Desktop, Postman, CMake, GitHub CLI, NVM, pyenv, WSL 2, Windows Terminal

### Frameworks, Libraries & Package Managers (37 items)

| Category | Items |
|----------|-------|
| JS/TS Package Managers | npm, Yarn, pnpm, Bun |
| Python Package Managers | uv, Poetry, pipx, Miniconda, VenvStudio |
| JS/TS Frameworks | React, Next.js, Vue, Nuxt, Angular, SvelteKit, Vite, Astro, Express.js, NestJS, Remix |
| Python Frameworks | Django, Flask, FastAPI, Streamlit |
| CSS/UI Frameworks | Tailwind CSS, Bootstrap |
| Mobile/Cross-platform | React Native, Expo, Ionic, Electron Forge, Tauri |
| Rust Ecosystem | cargo-watch, wasm-pack |
| .NET Ecosystem | Blazor, .NET MAUI |
| DevOps/Infra | Terraform, kubectl, Helm |

## Quick Setup Profiles (8 profiles)

| # | Profile | Languages | IDEs | Frameworks |
|---|---------|-----------|------|------------|
| 1 | Web Developer | Node.js, Python, PHP, TS | VS Code, Sublime | Yarn, pnpm, Vite, React, Tailwind, Express |
| 2 | Mobile Developer | Java, Kotlin, Dart | Android Studio, VS Code | React Native, Expo |
| 3 | Data Scientist | Python, Mojo | VS Code, PyCharm | uv, Conda, VenvStudio, Streamlit, FastAPI |
| 4 | Systems Programmer | C/C++, Rust, Zig, Go | VS Code, CLion, Neovim | cargo-watch, wasm-pack |
| 5 | Full Stack .NET | C#/.NET, Node.js, TS | VS 2026, VS Code | Yarn, Vite, React, Next.js |
| 6 | Game Developer | C/C++, C# | VS 2026, VS Code, Rider | - |
| 7 | AI / ML Engineer | Python, Mojo, Rust | VS Code, PyCharm, Cursor | uv, Conda, VenvStudio, Streamlit, FastAPI |
| 8 | Custom Setup | Your choice | Your choice | Your choice |

## Quick Start

### Windows
```powershell
# Double-click codeready.bat
# Or run in Admin PowerShell:
Set-ExecutionPolicy Bypass -Scope Process -Force
.\codeready.ps1
```

### Linux / macOS
```bash
chmod +x codeready.sh
./codeready.sh
```

## How It Works

1. Select a **profile** or choose **custom setup**
2. Pick your **programming languages**
3. Choose **which version** of each language
4. Select your **IDEs and editors**
5. Pick **developer tools**
6. Choose **frameworks, libraries and package managers**
7. Confirm and let CodeReady install everything

## Project Structure

```
CodeReady/
├── codeready.bat       # Windows launcher (auto-elevates)
├── codeready.ps1       # Windows PowerShell script
├── codeready.sh        # Linux/macOS bash script
└── README.md
```

## Requirements

- **Windows:** 10/11, Administrator, Internet
- **macOS:** 12+, Internet
- **Linux:** Ubuntu 20.04+ / Debian 11+ / Fedora 36+ / Arch / openSUSE, sudo, Internet

## License

MIT License

---

**Made with care for developers who value their time.**
