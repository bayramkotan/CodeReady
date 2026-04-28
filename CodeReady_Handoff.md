# CodeReady Handoff

> **Project:** CodeReady — Developer Environment Setup Tool
> **Author:** Bayram Kotan (bayramkotan)
> **Last Updated:** 12 April 2026
> **GitHub:** https://github.com/bayramkotan/CodeReady

---

## Project Paths

| Machine | OS | Shell | CodeReady Path | Notes |
|---------|-----|-------|---------------|-------|
| Windows (primary) | Windows 11 | PowerShell | `C:\Github\CodeReady` | Main dev machine |
| CachyOS #1 | CachyOS (Arch) | Fish | `~/Desktop/GitHub/CodeReady` | Turkish locale, fish shell |
| CachyOS #2 | CachyOS (Arch) | Bash | `~/Github/CodeReady` | English locale, bash shell |
| Pardus | Pardus (Debian) | Bash | `~/Masaüstü/GitHub/CodeReady` | Turkish locale |

**Handoff Path:** `C:\Users\bayram\Yandex.Disk\GitHub_Handoff_Files\CodeReady\CodeReady_Handoff.md`

---

## Project Overview

CodeReady is a cross-platform developer environment setup tool that scans, installs, and configures programming languages, IDEs, frameworks, tools, and more — with a single interactive script.

**Scripts:** `codeready.ps1` (Windows) + `codeready.sh` (Linux/macOS) + `codeready.bat` (Windows launcher)
**GUI:** Tauri v2 + React + Vite + Tailwind + Actix-web (dual mode: native + web on :3500)

---

## Current State (v2.2.0)

### What Works
- **39 programming languages** — Python, Node.js, Java, C#, C/C++, Go, Rust, PHP, Ruby, Kotlin, Swift, Dart/Flutter, TypeScript, R, Lua, Haskell, Perl, Erlang, OCaml, Fortran, D, Nim, Crystal, V, Gleam, Carbon, Solidity, Groovy, Ada, COBOL, Lisp, Racket, Objective-C, Julia, Scala, Elixir, Mojo, Zig, WebAssembly
- **23 IDEs/Editors** — VS Code, VSCodium, Antigravity, Cursor, Zed, Windsurf, Visual Studio, Sublime Text, Vim, Neovim, GNU Emacs, Notepad++, IntelliJ, PyCharm, WebStorm, GoLand, CLion, Rider, RustRover, JetBrains Fleet, Eclipse, NetBeans, Android Studio
- **38+ frameworks** — React, Next.js, Vue, Nuxt, Angular, Svelte, Vite, Astro, Remix, Express, NestJS, Django, Flask, FastAPI, Streamlit, Tailwind, Bootstrap, React Native, Expo, Ionic, Electron, Tauri, cargo-watch, wasm-pack, Blazor, .NET MAUI, Terraform, kubectl, Helm + VenvStudio, uv, Poetry, pipx, Conda, npm, Yarn, pnpm, Bun
- **15 profiles** — Web Frontend, Web Full Stack, Mobile, Data Scientist, AI/ML, Systems Programmer, Full Stack .NET, Game Developer, DevOps/Cloud, Blockchain/Web3, Embedded/IoT, Scientific Computing, Functional, JVM Ecosystem, Minimalist/Terminal
- **GUI+Terminal sync** — scanner.rs calls ps1/sh `--scan-json`, same scan engine for both
- **Silent install** — winget `--silent` flag, no GUI popups on Windows
- **PATH refresh** — `refresh_env_path()` after every install, no service restart needed
- **Local/Global install toggle** — frameworks/tools can be installed locally or globally
- **Package manager auto-detect** — Flatpak/Nix (Linux), Homebrew (Mac), winget/Scoop/Chocolatey (Win) — asks before installing
- **CachyOS + Pardus + 20+ distros** — `detect_os()` with `ID_LIKE` fallback
- **SSH Remote designed** — module drafted, needs integration
- **EN/TR i18n** — GUI has useI18n hook

### Known Issues
- **Nix install doesn't persist** — installs but not found on next run, needs PATH fix or daemon restart
- **useApi.js needs scope param** — `smartInstall(name, scope)` — manual 1-line edit needed
- **SSH not integrated** — scanner_remote.rs drafted but not wired

---

## File Structure

```
C:\Github\CodeReady\
├── codeready.bat           # Windows launcher (auto-elevates to Admin)
├── codeready.ps1           # Windows PowerShell (~1370 lines + --scan-json)
├── codeready.sh            # Linux/macOS bash (~1930 lines + --scan-json + CachyOS)
├── codeready_todo.md       # Roadmap
├── README.md               # GitHub README
└── gui/                    # Tauri v2 + Web dual-mode GUI
    ├── package.json         # v2.2.0
    ├── src/
    │   ├── main.jsx
    │   ├── App.jsx          # Main orchestrator, installing state, missingPkgManagers
    │   ├── styles/global.css # Dark theme #111113, Inter 15px
    │   ├── hooks/
    │   │   ├── useI18n.js   # EN/TR language hook
    │   │   └── useApi.js    # Auto-detects Tauri vs REST API
    │   ├── i18n/translations.js  # EN/TR + scope + pkgAlert strings
    │   └── components/
    │       ├── TitleBar.jsx      # Styled dropdown, localhost/SSH indicator, EN/TR toggle
    │       ├── TerminalPanel.jsx # 13px mono font, w-96, colored log lines
    │       ├── ScanView.jsx      # Local/Global toggle, install disable, pkg manager alert
    │       └── ProfilesView.jsx  # 14px cards, blue highlight
    └── src-tauri/
        ├── Cargo.toml
        ├── src/
        │   ├── main.rs          # Tauri binary
        │   ├── web_server.rs    # Actix-web REST on :3500 + scope support
        │   ├── scanner.rs       # scan_via_script() → fallback built-in, PATH refresh, silent install
        │   ├── scanner_remote.rs # SSH (drafted, not integrated)
        │   └── definitions.rs   # 97 package defs
```

---

## Key Technical Details

### GUI+Terminal Sync (--scan-json)
- `codeready.ps1 --scan-json` → JSON scan output (no Admin required)
- `codeready.sh --scan-json` → JSON scan output
- `scanner.rs` `scan_via_script()` calls the appropriate script, parses JSON
- If script fails → falls back to built-in Rust scan
- `#Requires -RunAsAdministrator` removed from ps1 top — Admin check only in `Main()`

### detect_os() — Supported Distros
```
ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian|pardus → apt
fedora → dnf
centos|rhel|rocky|alma → dnf
arch|manjaro|endeavouros|cachyos|garuda|artix|arcolinux → pacman
opensuse*|sles → zypper
void → xbps
alpine → apk
Fallback: ID_LIKE=arch→pacman, debian→apt, fedora→dnf, suse→zypper
```

### Install Methods in scanner.rs
- `winget` — with `--silent` flag
- `scoop` — via `powershell -Command` on Windows
- `choco` — via `cmd /c` on Windows
- `npm` / `npm-local` — global (`-g`) vs project-local
- `pip` / `pip-local` — global (`--break-system-packages`) vs `--user`
- `apt` — with `sudo`
- `brew` — direct

### PATH Refresh
After every install, `refresh_env_path()` reads latest PATH:
- Windows: reads Machine+User PATH from registry via PowerShell
- Linux: sources `~/.bashrc` / `~/.zshrc` and extracts $PATH

---

## Shell Configs (runserver)

### What runserver Does (all platforms)
1. Auto-detects CodeReady path (Desktop / Masaüstü / Github)
2. Auto-installs npm + cargo if missing (pacman/apt/dnf/zypper/brew/rustup)
3. `npm install` if node_modules missing
4. Smart frontend build (only if src/ newer than dist/)
5. `sudo -v` pre-authenticates
6. Opens browser after 2 sec (`xdg-open`)
7. Runs server with sudo for global installs

### Windows — PowerShell $PROFILE
Existing `runserver` function in `$PROFILE`. Does frontend build check + cargo run.

### CachyOS (Fish) — ~/.config/fish/config.fish
```fish
# === CodeReady ===
# Path auto-detect: Desktop / Masaüstü / Github
# __codeready_ensure_deps: installs npm (pacman) + cargo (rustup) if missing
# runserver: build + sudo cargo run + xdg-open browser
# cr: sudo ./codeready.sh
# cr-scan: --scan-json | python3 -m json.tool
```

### Pardus / CachyOS Bash — ~/.bashrc
```bash
# === CodeReady ===
# Same as Fish but bash syntax
# __codeready_ensure_deps: installs npm (apt/pacman) + cargo (rustup)
# runserver: build + sudo $HOME/.cargo/bin/cargo run + xdg-open browser
# cr / cr-scan aliases
```

---

## Key Decisions
- **Flatpak > snap** — snap is always last resort
- **VenvStudio first** — before uv and Conda in Python package managers
- **GUI calls terminal scripts** — scanner.rs → ps1/sh --scan-json (single source of truth)
- **Pure ASCII in PS1** — no Unicode
- **JetBrains: file path only** — never run --version on GUI apps
- **winget --silent** — no installer GUI popups
- **sudo runserver** — server runs as root for global install capability
- **No #Requires -RunAsAdministrator** — removed from ps1 top, scan-json works without admin
- **ID_LIKE fallback** — unknown distros checked against parent distro
- **AUR helper: paru > yay** — paru recommended, yay as alternative. Auto-install offered on Arch-based distros. Flutter and other AUR-only packages use `aur_install()` function
- **Package manager priority (Arch):** pacman → AUR (paru/yay) → flatpak → snap

---

## Git Commands

```powershell
cd C:\Github\CodeReady
git add .
git commit -m "message"
git push
```

---

## Roadmap

| Version | Title | Status |
|---------|-------|--------|
| v2.2 | Frameworks, GUI sync, CachyOS | ✅ Current |
| v2.3 | Uninstall, admin-free mode, .bashrc aliases, ARM/Silicon | Next |
| v2.4 | Dynamic version from config.json | Planned |
| v2.5 | Profile JSON export/import | Planned |
| v2.6 | Update Manager | Planned |
| v3.0 | Platform Evolution, Docker, CI/CD | Planned |

### TODO Items
| # | Item | Priority | Status |
|---|------|----------|--------|
| 1 | **CRITICAL: pkg_install multi-distro** — codeready.sh install functions currently only use `apt`. Must support `pacman -S` (Arch/CachyOS), `dnf install` (Fedora/RHEL), `zypper install` (openSUSE), `brew install` (macOS) for ALL languages, IDEs, tools. Every `apt install` call needs a `case "$PKG"` wrapper. | **Critical** | Not started |
| 2 | **Flutter/Dart on Arch** — not in pacman repos, needs AUR (yay/paru) or snap/flatpak or git clone from flutter.dev SDK. Add AUR helper detection + install. | High | Not started |
| 3 | SSH remote integration | High | Designed, not wired |
| 4 | Uninstall support | High | Not started |
| 5 | Language selection at startup (EN/TR) | Medium | GUI done, terminal not |
| 6 | Docker sudo-free + Desktop | Medium | Not started |
| 7 | Profile JSON export/import | Medium | Not started |
| 8 | Dynamic version from config.json | Medium | Not started |
| 9 | Admin/sudo-free mode | High | Not started |
| 10 | Windows ARM + macOS Silicon | Low | Not started |
| 11 | Nix PATH persistence fix | Medium | Not started |
| 12 | useApi.js scope param | Low | Manual 1-line edit |
| 13 | **.bashrc cp alias conflict** — Bayram's .bashrc has `alias cp='cp -i'` which blocks scripted `cp`. Use `\cp` or `command cp` in docs/scripts. | Low | Noted |
| 14 | **OS-specific filtering** — Don't show OS-irrelevant items. Notepad++, Visual Studio = Windows only. Xcode = Mac only. Hide them on Linux. Apply to both terminal scan and GUI `definitions.rs`. | High | Not started |
| 15 | **Framework/tool conflict detection** — Warn if conflicting packages selected (e.g. Dart standalone vs Flutter which includes Dart). Prevent double-install or show dependency info. | Medium | Not started |
| 16 | **VenvStudio first in pip frameworks** — In terminal scan output and install menu, VenvStudio should appear before Django/Flask/FastAPI/Streamlit. Already first in `definitions.rs` but not in `codeready.sh`. | High | Not started |
| 17 | **Kotlin SDKMAN fix** — "Installing Kotlin via SDKMAN..." then exits without installing. SDKMAN install may need shell reload or interactive mode. Add pacman/brew fallback. | High | Not started |
| 18 | **Add Flet framework** — flet.dev, Python UI framework. Install: `pip install flet`. Add to pip frameworks in both `codeready.sh` and `definitions.rs`. | Medium | Not started |
| 19 | **Add CustomTkinter framework** — Modern Python GUI. Install: `pip install customtkinter`. Add to pip frameworks in both `codeready.sh` and `definitions.rs`. | Medium | Not started |

### Multi-Distro Install Refactor Details (TODO #1)
Current state: `codeready.sh` has individual install functions per language/IDE/tool that hardcode `apt`. Example:
```bash
# CURRENT (broken on non-Debian):
sudo apt install -y python3
# NEEDED:
case "$PKG" in
    apt)    sudo apt install -y python3 ;;
    pacman) sudo pacman -S --noconfirm python ;;
    dnf)    sudo dnf install -y python3 ;;
    zypper) sudo zypper install -y python3 ;;
    brew)   brew install python ;;
esac
```
This must be done for ALL ~100 packages. The `pkg_install()` helper function exists but not all install paths use it. Some use `safe_repo_install()` which is apt-only. Strategy: create a `definitions.sh` lookup table (like `definitions.rs`) mapping package names to per-distro install commands.
