<p align="center">
  <img src="https://img.shields.io/badge/CodeReady-v2.1.0-00d4ff?style=for-the-badge&labelColor=0a0a0a" alt="Version" />
  <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

<h1 align="center">CodeReady</h1>

<p align="center">
  <b>The ultimate developer environment setup tool.</b><br/>
  Scans your system. Detects what you have. Installs what you need. Zero guesswork.
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> &bull;
  <a href="#-system-scan">System Scan</a> &bull;
  <a href="#-features">Features</a> &bull;
  <a href="#-supported-software">Supported Software</a> &bull;
  <a href="#-profiles">Profiles</a> &bull;
  <a href="#-how-it-works">How It Works</a>
</p>

---

## Why CodeReady?

Setting up a new development machine is painful. You spend hours downloading compilers, configuring IDEs, installing package managers, and getting frameworks working. **CodeReady automates all of it** with a single interactive script.

- **System scan first** — detects what's already installed and shows upgrade recommendations
- **Version selection** — choose between multiple versions for each language (latest, LTS, older)
- **Multi-profile support** — combine Web Dev + Data Science + AI/ML in one go
- **Cross-platform** — same experience on Windows, macOS, and Linux
- **109+ packages** — languages, IDEs, tools, frameworks, all in one place
- **Auto shell reload** — installed tools work immediately, no terminal restart needed

---

## System Scan

CodeReady scans your system **before** installing anything. It detects every language, IDE, tool, and package manager already on your machine, compares versions, and shows you exactly what's outdated.

```
=== System Scan ===
  Scanning your system for installed software...

  Languages and Runtimes:
    Python            3.x.x       ⬆ upgrade available
    Node.js           2x.x.x      ✓ up to date
    Java (JDK)        —  not installed
    Go                1.x.x       ⬆ upgrade available
    Rust              1.x.x       ✓
    ...

  IDEs and Editors:
    VS Code           x.xx        ✓
    Neovim            —  not installed

  Developer Tools:
    Git               x.xx.x      ✓
    Docker            —  not installed

  Package Managers:
    npm               x.x.x       ✓
    uv                —  not installed

  ────────────────────────────────────────
  ✓ 8 installed  |  — 5 not found

  Continue to profile selection? (Y/n):
```

After the scan, you proceed to profile selection where CodeReady installs only what's missing or outdated.

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
| **System Scan** | Detects installed software and versions before installing anything |
| **Upgrade Detection** | Compares your versions with latest — shows what needs updating |
| **Interactive Menus** | Number-based selection with multi-select support |
| **Version Selection** | Pick specific versions for each language (latest, LTS, or older) |
| **8 Quick Profiles** | Pre-configured setups for common developer roles |
| **Multi-Profile** | Select `1 3 7` to combine Web Dev + Data Science + AI/ML |
| **Install Everything** | Option 9 installs all 109+ packages (with safety warnings) |
| **Smart Deduplication** | Combining profiles never installs the same package twice |
| **Auto Package Manager** | Detects and installs winget/Chocolatey (Win) or Homebrew/apt/dnf/pacman (Unix) |
| **Auto Shell Reload** | Sources `.bashrc`/`.zshrc` after install — tools work immediately |
| **Failure Resilience** | Failed installs don't block remaining items |
| **Installation Log** | Full log saved to `~/codeready_install.log` |
| **Pure ASCII** | No encoding issues on any terminal or locale |

---

## Supported Software

### Programming Languages and Runtimes — 39 languages

| Language | Version Selection | Win | Mac | Linux | Notes |
|----------|-------------------|:---:|:---:|:-----:|-------|
| **Python** | Multiple versions (latest + older) | ✅ | ✅ | ✅ | Via system pkg or official installer |
| **Node.js** | LTS + Current versions | ✅ | ✅ | ✅ | Via nvm (preferred) |
| **Java (JDK)** | Latest + LTS versions | ✅ | ✅ | ✅ | Eclipse Temurin / OpenJDK |
| **C# / .NET** | Latest + LTS versions | ✅ | ✅ | ✅ | Microsoft .NET SDK |
| **C / C++** | GCC, Clang/LLVM, MSVC | ✅ | ✅ | ✅ | MinGW on Windows |
| **Go** | Multiple recent versions | ✅ | ✅ | ✅ | Official binary |
| **Rust** | Always latest via rustup | ✅ | ✅ | ✅ | Managed by rustup |
| **PHP** | Multiple recent versions | ✅ | ✅ | ✅ | Includes Composer |
| **Ruby** | Multiple recent versions | ✅ | ✅ | ✅ | |
| **Kotlin** | Latest | ✅ | ✅ | ✅ | Via SDKMAN or snap |
| **Dart / Flutter** | Latest | ✅ | ✅ | ✅ | Flutter includes Dart |
| **Swift** | Latest | ✅ | ✅ | ⚠️ | macOS via Xcode, Linux partial |
| **TypeScript** | Latest (via npm) | ✅ | ✅ | ✅ | Requires Node.js |
| **R** | Latest | ✅ | ✅ | ✅ | Statistics, data science |
| **Lua** | Latest | ✅ | ✅ | ✅ | Scripting, game engines, embedded |
| **Perl** | Latest | ✅ | ✅ | ✅ | Text processing, sysadmin |
| **Julia** | Latest + LTS | ✅ | ✅ | ✅ | Scientific computing |
| **Scala** | Latest | ✅ | ✅ | ✅ | JVM functional/OOP |
| **Groovy** | Latest | ✅ | ✅ | ✅ | JVM scripting, Gradle builds |
| **Elixir** | Latest | ✅ | ✅ | ✅ | Functional, concurrent, BEAM VM |
| **Erlang** | Latest | ✅ | ✅ | ✅ | Telecom, distributed systems |
| **Haskell** | Latest via GHCup | ✅ | ✅ | ✅ | Pure functional, fintech |
| **OCaml** | Latest via opam | ✅ | ✅ | ✅ | Fintech, compilers |
| **Common Lisp** | Latest (SBCL) | ✅ | ✅ | ✅ | AI, symbolic computing |
| **Racket** | Latest | ✅ | ✅ | ✅ | PL research, education |
| **Zig** | Multiple recent versions | ✅ | ✅ | ✅ | Next-gen systems language |
| **Nim** | Latest via choosenim | ✅ | ✅ | ✅ | Python-like syntax, compiled |
| **Crystal** | Latest | ✅ | ✅ | ✅ | Ruby-like, compiled, fast |
| **V** | Latest | ✅ | ✅ | ✅ | Simple systems language |
| **D** | Latest (LDC) | ✅ | ✅ | ✅ | Systems programming |
| **Gleam** | Latest | ✅ | ✅ | ✅ | Type-safe BEAM language |
| **Mojo** | Latest | WSL | ✅ | ✅ | AI/GPU programming by Modular |
| **Carbon** | Experimental | ⚠️ | ⚠️ | ⚠️ | Google's C++ successor (no installer) |
| **Solidity** | Latest (solcjs) | ✅ | ✅ | ✅ | Ethereum smart contracts |
| **Fortran** | Latest (GFortran) | ✅ | ✅ | ✅ | Scientific computing, HPC |
| **Ada** | Latest (GNAT) | ✅ | ✅ | ✅ | Safety-critical, aerospace |
| **COBOL** | Latest (GnuCOBOL) | ✅ | ✅ | ✅ | Banking, legacy systems |
| **Objective-C** | Via Clang/GNUstep | ✅ | ✅ | ✅ | Legacy Apple development |
| **WebAssembly** | Wasmtime / Wasmer | ✅ | ✅ | ✅ | WASI runtimes |

> **Version selection** is available for Python, Node.js, Java, .NET, Go, PHP, Ruby, Zig, and Julia. You pick your preferred version during setup. Other languages install the latest stable release.

### IDEs and Editors — 23 editors

| IDE | License | Win | Mac | Linux |
|-----|---------|:---:|:---:|:-----:|
| **VS Code** | Free | ✅ | ✅ | ✅ |
| **VSCodium** | Free | ✅ | ✅ | ✅ |
| **Antigravity** | Free | ✅ | ✅ | ✅ |
| **Cursor** | Freemium | ✅ | ✅ | ✅ |
| **Zed** | Free | ✅ | ✅ | ✅ |
| **Windsurf** | Free | ✅ | ✅ | ✅ |
| **Visual Studio** Community | Free | ✅ | — | — |
| **Sublime Text** | Freemium | ✅ | ✅ | ✅ |
| **Vim** | Free | ✅ | ✅ | ✅ |
| **Neovim** | Free | ✅ | ✅ | ✅ |
| **GNU Emacs** | Free | ✅ | ✅ | ✅ |
| **Notepad++** | Free | ✅ | — | — |
| **IntelliJ IDEA** Community | Free | ✅ | ✅ | ✅ |
| **PyCharm** Community | Free | ✅ | ✅ | ✅ |
| **WebStorm** | Paid | ✅ | ✅ | ✅ |
| **GoLand** | Paid | ✅ | ✅ | ✅ |
| **CLion** | Paid | ✅ | ✅ | ✅ |
| **Rider** | Paid | ✅ | ✅ | ✅ |
| **RustRover** | Free | ✅ | ✅ | ✅ |
| **JetBrains Fleet** | Free | ✅ | ✅ | ✅ |
| **Eclipse IDE** | Free | ✅ | ✅ | ✅ |
| **Apache NetBeans** | Free | ✅ | ✅ | ✅ |
| **Android Studio** | Free | ✅ | ✅ | ✅ |

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

CodeReady ships with **15 profiles** for common developer roles, grouped by category. You can select **one or multiple** profiles, or go fully custom.

```
Select profile(s): 2 5 9     <- combine multiple profiles
Select profile(s): 17        <- install EVERYTHING (with safety warnings)
```

### Popular Stacks

| # | Profile | Languages | IDEs | Frameworks and Tools |
|:-:|---------|-----------|------|--------------------|
| **1** | **Web Frontend** | Node.js, TypeScript | VS Code, Zed | Yarn, pnpm, Vite, React, Vue, Tailwind |
| **2** | **Web Full Stack** | Node.js, Python, TypeScript, PHP | VS Code, Sublime | Yarn, pnpm, Vite, React, Next.js, Express, Django, Tailwind |
| **3** | **Mobile Developer** | Java, Kotlin, Dart/Flutter, Swift | Android Studio, VS Code | React Native, Expo |
| **4** | **Data Scientist** | Python, R, Julia | VS Code, PyCharm | VenvStudio, uv, Conda, Streamlit, FastAPI |
| **5** | **AI / ML Engineer** | Python, Mojo, Rust, Julia | VS Code, PyCharm, Cursor | VenvStudio, uv, Conda, Streamlit, FastAPI |
| **6** | **Systems Programmer** | C/C++, Rust, Zig, Go | VS Code, CLion, Neovim | CMake, cargo-watch, wasm-pack |
| **7** | **Full Stack .NET** | C#/.NET, Node.js, TypeScript | Visual Studio, VS Code, Rider | Yarn, Vite, React, Next.js, Blazor |
| **8** | **Game Developer** | C/C++, C#, Lua | Visual Studio, VS Code, Rider | CMake |

### Specialized

| # | Profile | Languages | IDEs | Frameworks and Tools |
|:-:|---------|-----------|------|--------------------|
| **9** | **DevOps / Cloud** | Python, Go, Rust | VS Code, Neovim | Docker, Terraform, kubectl, Helm |
| **10** | **Blockchain / Web3** | Solidity, Rust, TypeScript | VS Code, Cursor | npm, Yarn |
| **11** | **Embedded / IoT** | C/C++, Rust, Python, Lua | VS Code, CLion, Neovim | CMake |
| **12** | **Scientific Computing** | Fortran, Python, R, Julia, Haskell | VS Code, Emacs | VenvStudio, uv, Conda |
| **13** | **Functional Programmer** | Haskell, Elixir, Erlang, OCaml, Scala, Gleam | VS Code, Emacs, Neovim | — |
| **14** | **JVM Ecosystem** | Java, Kotlin, Scala, Groovy | IntelliJ, Eclipse, NetBeans | Docker |
| **15** | **Minimalist / Terminal** | Go, Rust, Python | Neovim, Vim, Emacs | Git only |

### Other Options

| # | Option | Description |
|:-:|--------|-------------|
| **16** | **Custom Setup** | Choose your own languages, versions, IDEs, tools, and frameworks |
| **17** | **INSTALL EVERYTHING** | All 39 languages, 23 IDEs, 38 frameworks (warns about time and disk) |

> **Note:** Option 17 will warn you about estimated time, disk usage, and system load before proceeding. Requires typing `YES` in uppercase to confirm.

---

## How It Works

```
 ┌─────────────────────────────────────────────────────────┐
 │  1. System scan — detect installed software & versions  │
 │  2. Select profile(s) or custom setup                   │
 │  3. Pick programming languages                          │
 │  4. Choose version for each language                    │
 │  5. Select IDEs and editors                             │
 │  6. Pick developer tools                                │
 │  7. Choose frameworks, libraries and package managers   │
 │  8. Review installation plan                            │
 │  9. Confirm -> CodeReady installs everything            │
 │ 10. Auto-reload shell -> tools work immediately         │
 │ 11. Summary: succeeded / failed / log file              │
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
├── codeready_todo.md   # Development roadmap
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
| Command not found after install | CodeReady auto-reloads your shell, but if needed run `source ~/.bashrc` (or `~/.zshrc`) |
| Mojo on Windows | Mojo requires WSL. Install WSL 2 first, then install Mojo inside WSL |
| System scan shows wrong version | Some tools report versions differently. Check with `<tool> --version` manually |

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
