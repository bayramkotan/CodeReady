<p align="center">
  <img src="https://img.shields.io/badge/CodeReady-v2.0.0-00d4ff?style=for-the-badge&labelColor=0a0a0a" alt="Version" />
  <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

<h1 align="center">CodeReady</h1>

<p align="center">
  <b>The ultimate developer environment setup tool.</b><br/>
  Select your languages. Pick your versions. Choose your IDEs. CodeReady handles the rest.
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> &bull;
  <a href="#-features">Features</a> &bull;
  <a href="#-supported-software">Supported Software</a> &bull;
  <a href="#-profiles">Profiles</a> &bull;
  <a href="#-how-it-works">How It Works</a>
</p>

---

## Why CodeReady?

Setting up a new development machine is painful. You spend hours downloading compilers, configuring IDEs, installing package managers, and getting frameworks working. **CodeReady automates all of it** with a single interactive script.

- **One command** sets up your entire dev environment
- **Version selection** — choose Python 3.14 or 3.11, JDK 25 or 17, you decide
- **Multi-profile support** — combine Web Dev + Data Science in one go
- **Cross-platform** — same experience on Windows, macOS, and Linux
- **82+ packages** — languages, IDEs, tools, frameworks, all in one place

---

## Quick Start

### Windows

```powershell
# Option 1: Double-click codeready.bat (auto-elevates to Admin)

# Option 2: Run in Admin PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\codeready.ps1
```

### Linux / macOS

```bash
chmod +x codeready.sh
./codeready.sh
```

---

## Features

| Feature | Description |
|---------|-------------|
| **Interactive Menus** | Number-based selection with multi-select support |
| **Version Selection** | Pick specific versions for each language (e.g., Python 3.14 / 3.13 / 3.12 / 3.11) |
| **8 Quick Profiles** | Pre-configured setups for common developer roles |
| **Multi-Profile** | Select `1 3 7` to combine Web Dev + Data Science + AI/ML |
| **Install Everything** | Option 9 installs all 82+ packages (with safety warnings) |
| **Smart Deduplication** | Combining profiles never installs the same package twice |
| **Auto Package Manager** | Detects and installs winget/Chocolatey (Win) or Homebrew/apt/dnf/pacman (Unix) |
| **Failure Resilience** | Failed installs don't block remaining items |
| **Installation Log** | Full log saved to `~/codeready_install.log` |
| **Pure ASCII** | No encoding issues on any terminal or locale |

---

## Supported Software

### Programming Languages and Runtimes — 18 languages

| Language | Versions | Win | Mac | Linux | Notes |
|----------|----------|:---:|:---:|:-----:|-------|
| **Python** | 3.14, 3.13, 3.12, 3.11 | ✅ | ✅ | ✅ | Via system pkg or official installer |
| **Node.js** | 24 LTS, 25, 22 LTS, 20 LTS | ✅ | ✅ | ✅ | Via nvm (preferred) |
| **Java (JDK)** | 25, 23 LTS, 21 LTS, 17 LTS | ✅ | ✅ | ✅ | Eclipse Temurin / OpenJDK |
| **C# / .NET** | 9, 8 LTS, 7, 6 LTS | ✅ | ✅ | ✅ | Microsoft .NET SDK |
| **C / C++** | GCC, Clang/LLVM, MSVC | ✅ | ✅ | ✅ | MinGW on Windows |
| **Go** | 1.23, 1.22, 1.21 | ✅ | ✅ | ✅ | Official binary |
| **Rust** | latest (via rustup) | ✅ | ✅ | ✅ | Always latest stable |
| **PHP** | 8.4, 8.3, 8.2 | ✅ | ✅ | ✅ | Includes Composer |
| **Ruby** | 3.3, 3.2, 3.1 | ✅ | ✅ | ✅ | |
| **Kotlin** | latest | ✅ | ✅ | ✅ | Via SDKMAN or snap |
| **Dart / Flutter** | latest | ✅ | ✅ | ✅ | Flutter includes Dart |
| **Swift** | latest | ✅ | ✅ | ⚠️ | macOS via Xcode, Linux partial |
| **Zig** | 0.13, 0.12 | ✅ | ✅ | ✅ | Next-gen systems language |
| **Mojo** | latest (pip) | WSL | ✅ | ✅ | AI/GPU programming by Modular |
| **WebAssembly** | Wasmtime / Wasmer | ✅ | ✅ | ✅ | WASI runtimes |
| **TypeScript** | latest (npm) | ✅ | ✅ | ✅ | Requires Node.js |
| **Elixir** | latest | ✅ | ✅ | ✅ | Functional, concurrent |
| **Scala** | 3 (latest) | ✅ | ✅ | ✅ | JVM functional/OOP |

### IDEs and Editors — 17 editors

| IDE | License | Win | Mac | Linux |
|-----|---------|:---:|:---:|:-----:|
| **VS Code** | Free | ✅ | ✅ | ✅ |
| **Visual Studio 2026** Community | Free | ✅ | — | — |
| **IntelliJ IDEA** Community | Free | ✅ | ✅ | ✅ |
| **PyCharm** Community | Free | ✅ | ✅ | ✅ |
| **WebStorm** | Paid | ✅ | ✅ | ✅ |
| **GoLand** | Paid | ✅ | ✅ | ✅ |
| **CLion** | Paid | ✅ | ✅ | ✅ |
| **Rider** | Paid | ✅ | ✅ | ✅ |
| **RustRover** | Free | ✅ | ✅ | ✅ |
| **Eclipse IDE** | Free | ✅ | ✅ | ✅ |
| **Android Studio** | Free | ✅ | ✅ | ✅ |
| **Sublime Text** | Freemium | ✅ | ✅ | ✅ |
| **Neovim** | Free | ✅ | ✅ | ✅ |
| **Notepad++** | Free | ✅ | — | — |
| **Cursor** | Freemium | ✅ | ✅ | ✅ |
| **Windsurf** | Free | ✅ | ✅ | ✅ |
| **Zed** | Free | ✅ | ✅ | ✅ |

### Developer Tools — 9 tools

| Tool | Description |
|------|-------------|
| **Git** | Distributed version control |
| **Docker Desktop** | Container platform |
| **Postman** | API testing and development |
| **CMake** | Cross-platform build system |
| **GitHub CLI** | GitHub from the command line |
| **NVM** | Node.js version manager |
| **pyenv** | Python version manager |
| **WSL 2** | Linux subsystem for Windows |
| **Windows Terminal** | Modern terminal app |

### Frameworks, Libraries and Package Managers — 38 items

#### Package Managers

| Name | Ecosystem | Description |
|------|-----------|-------------|
| [**VenvStudio**](https://github.com/bayramkotan/VenvStudio) | Python | GUI virtual environment manager with modern PySide6 interface |
| **uv** | Python | Ultra-fast package manager written in Rust by Astral |
| **Poetry** | Python | Dependency management and packaging |
| **pipx** | Python | Install CLI tools in isolated environments |
| **Miniconda** | Python/R | Data science package and environment manager |
| **npm** | Node.js | Default Node.js package manager |
| **Yarn** | Node.js | Fast, reliable package manager |
| **pnpm** | Node.js | Disk-efficient package manager |
| **Bun** | Node.js | Ultra-fast JavaScript runtime and package manager |

#### Web Frameworks — Frontend

| Name | Language | Description |
|------|----------|-------------|
| **React** | JS/TS | Facebook UI library (create-react-app) |
| **Next.js** | JS/TS | React fullstack framework with SSR/SSG |
| **Vue CLI** | JS/TS | Progressive JavaScript framework |
| **Nuxt** | JS/TS | Vue fullstack framework |
| **Angular CLI** | TS | Google enterprise web framework |
| **SvelteKit** | JS/TS | Lightweight compiled reactive framework |
| **Vite** | JS/TS | Next-generation frontend build tool |
| **Astro** | JS/TS | Content-focused web framework |

#### Web Frameworks — Backend

| Name | Language | Description |
|------|----------|-------------|
| **Express.js** | Node.js | Minimal and flexible web framework |
| **NestJS** | Node.js/TS | Progressive server-side framework |
| **Remix** | JS/TS | Full-stack web framework |
| **Django** | Python | Batteries-included web framework |
| **Flask** | Python | Lightweight WSGI web framework |
| **FastAPI** | Python | Modern async API framework with auto-docs |
| **Streamlit** | Python | Data app framework for ML/AI dashboards |

#### CSS and UI Frameworks

| Name | Description |
|------|-------------|
| **Tailwind CSS** | Utility-first CSS framework |
| **Bootstrap** | Popular responsive CSS framework |

#### Mobile and Cross-Platform

| Name | Description |
|------|-------------|
| **React Native CLI** | Cross-platform mobile apps with React |
| **Expo CLI** | Managed React Native toolchain |
| **Ionic CLI** | Hybrid mobile framework |
| **Electron Forge** | Desktop apps with web technologies |
| **Tauri CLI** | Lightweight desktop apps with Rust backend |

#### Language Ecosystems

| Name | Ecosystem | Description |
|------|-----------|-------------|
| **cargo-watch** | Rust | Auto-rebuild on file changes |
| **wasm-pack** | Rust/WASM | Build Rust-generated WebAssembly packages |
| **Blazor** | .NET | C# web UI framework (included in .NET SDK) |
| **.NET MAUI** | .NET | Cross-platform native UI framework |

#### DevOps and Infrastructure

| Name | Description |
|------|-------------|
| **Terraform** | Infrastructure as code by HashiCorp |
| **kubectl** | Kubernetes command-line tool |
| **Helm** | Kubernetes package manager |

---

## Profiles

CodeReady ships with **8 profiles** for common developer roles. You can select **one or multiple** profiles, or go fully custom.

```
Select profile(s): 1 3 7     <- combine multiple profiles
Select profile(s): 9         <- install EVERYTHING (with safety warnings)
```

| # | Profile | Languages | IDEs | Frameworks and Tools |
|:-:|---------|-----------|------|--------------------|
| **1** | **Web Developer** | Node.js, Python, PHP, TypeScript | VS Code, Sublime | Yarn, pnpm, Vite, React, Tailwind, Express |
| **2** | **Mobile Developer** | Java, Kotlin, Dart/Flutter | Android Studio, VS Code | React Native, Expo |
| **3** | **Data Scientist** | Python, Mojo | VS Code, PyCharm | VenvStudio, uv, Conda, Streamlit, FastAPI |
| **4** | **Systems Programmer** | C/C++, Rust, Zig, Go | VS Code, CLion, Neovim | cargo-watch, wasm-pack |
| **5** | **Full Stack .NET** | C#/.NET, Node.js, TypeScript | VS 2026, VS Code | Yarn, Vite, React, Next.js |
| **6** | **Game Developer** | C/C++, C# | VS 2026, VS Code, Rider | CMake |
| **7** | **AI / ML Engineer** | Python, Mojo, Rust | VS Code, PyCharm, Cursor | VenvStudio, uv, Conda, Streamlit, FastAPI |
| **8** | **Custom Setup** | *You choose* | *You choose* | *You choose* |
| **9** | **INSTALL EVERYTHING** | *All 18 languages* | *All 17 IDEs* | *All 38 frameworks* |

> **Note:** Option 9 will warn you about estimated time (~45-90 min), disk usage (~30-50 GB), and system load before proceeding. Requires typing `YES` in uppercase to confirm.

---

## How It Works

```
 ┌─────────────────────────────────────────────────────────┐
 │  1. Select profile(s) or custom setup                   │
 │  2. Pick programming languages                          │
 │  3. Choose version for each language                    │
 │  4. Select IDEs and editors                             │
 │  5. Pick developer tools                                │
 │  6. Choose frameworks, libraries and package managers   │
 │  7. Review installation plan                            │
 │  8. Confirm -> CodeReady installs everything            │
 │  9. Summary: succeeded / failed / log file              │
 └─────────────────────────────────────────────────────────┘
```

### Installation Strategy

| Platform | Primary | Fallback | Special |
|----------|---------|----------|---------|
| **Windows** | winget | Chocolatey | MSI/EXE direct download |
| **macOS** | Homebrew | Cask for GUI apps | Xcode CLI tools |
| **Linux** | apt / dnf / pacman / zypper | snap | Official installers |

Special installers are used where appropriate: `nvm` for Node.js, `rustup` for Rust, `SDKMAN` for Kotlin, official binaries for Go and Zig.

---

## Project Structure

```
CodeReady/
├── codeready.bat       # Windows launcher (auto-elevates to Admin)
├── codeready.ps1       # Windows PowerShell script
├── codeready.sh        # Linux/macOS bash script
└── README.md
```

---

## Requirements

| Platform | Requirements |
|----------|-------------|
| **Windows** | Windows 10/11, Administrator privileges, Internet connection |
| **macOS** | macOS 12+, Internet connection |
| **Linux** | Ubuntu 20.04+ / Debian 11+ / Fedora 36+ / Arch / openSUSE, sudo access, Internet |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| PowerShell encoding errors | Script uses pure ASCII — ensure file is saved as UTF-8 without BOM |
| Permission denied (Linux) | Run `chmod +x codeready.sh` first |
| Package not found | Some packages vary by OS. Check `~/codeready_install.log` for details |
| PATH not updated | Restart your terminal or PC after installation |
| Mojo on Windows | Mojo requires WSL. Install WSL 2 first, then `pip install mojo` inside WSL |

---

## Contributing

Found a bug? Want to add a new language or framework? Pull requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-language`)
3. Commit your changes (`git commit -m 'Add support for Haskell'`)
4. Push to the branch (`git push origin feature/new-language`)
5. Open a Pull Request

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>Made with care for developers who value their time.</b><br/>
  <sub>If CodeReady saved you time, consider giving it a star on GitHub!</sub>
</p>
