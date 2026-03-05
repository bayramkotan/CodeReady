# CodeReady Roadmap

> This is a living document. Features are prioritized by impact and complexity.
> Last updated: 5 March 2026

---

## ✅ v2.1 — Smart Defaults (Current Release)

### Auto-Configuration Mode

- [x] **System scan on startup** — detect already installed languages, IDEs, tools and their versions
- [x] **Show current environment report** — before any install, show what's already on the system
- [x] **Auto-suggest upgrades** — compare installed versions with latest, recommend updates
- [x] **39 languages supported** — added R, Lua, Haskell, Perl, Erlang, OCaml, Fortran, D, Nim, Crystal, V, Gleam, Carbon, Solidity, Groovy, Ada, COBOL, Lisp, Racket, Objective-C
- [x] **23 IDEs/Editors** — added VSCodium, Antigravity, Vim, GNU Emacs, NetBeans, JetBrains Fleet
- [x] **15 profiles** — added DevOps/Cloud, Blockchain/Web3, Embedded/IoT, Scientific Computing, Functional, JVM Ecosystem, Minimalist/Terminal
- [x] **System scan detects all 23 IDEs** — full IDE detection in scan report
- [ ] **One-click accept** — user just hits Enter to accept all recommendations
- [ ] **Skip already installed** — never reinstall something that's already at latest version
- [ ] **Version check via API** — query GitHub releases, pypi, npm registry for actual latest versions instead of hardcoded version lists

### Uninstall Mode

- [ ] **`--uninstall` flag** — run script in reverse to cleanly remove installed software
- [ ] **Track what was installed** — save manifest to `~/.codeready/installed.json` during install
- [ ] **Selective uninstall** — interactive menu to pick which items to remove
- [ ] **Dependency awareness** — warn if removing Node.js while React/Next.js depend on it
- [ ] **Clean PATH entries** — remove additions made to .bashrc/.zshrc/.profile

### Source Shell Config Fix

- [x] **Auto-detect shell** — bash, zsh and source the correct config
- [x] **Auto-reload after install** — sources .bashrc/.zshrc/.profile so tools work immediately
- [ ] **Fish shell support** — fish uses different syntax for PATH (`set -gx`)

---

## 🎨 v2.2 — Terminal Beautification / Shell UX (Next Up)

Kullanıcının terminalini güzelleştir. VenvStudio'daki CLI/TUI Tools yaklaşımının CodeReady versiyonu.

### Prompt Engines

**Starship:**
- [ ] **Install Starship** — cross-platform prompt (curl installer / brew / winget)
- [ ] **Auto-detect shell** — bash/zsh/fish/pwsh detection
- [ ] **Auto-configure shell** — eval "$(starship init bash)" satırını .bashrc'ye ekle
- [ ] **Preset selection** — Nerd Font Symbols, Bracketed, Plain Text, Pastel Powerline, Tokyo Night, Gruvbox Rainbow
- [ ] **starship.toml generator** — kullanıcının seçtiği modüller ile config oluştur
- [ ] **Test in terminal** — "Press Enter to preview your prompt" — geçici shell açıp göster
- [ ] **Backup existing config** — mevcut .bashrc/.zshrc'yi .bak ile yedekle

**Oh My Posh:**
- [ ] **Install Oh My Posh** — brew / winget / manual
- [ ] **Theme browser** — mevcut temaları listele, seçtir
- [ ] **Auto-configure shell** — PowerShell profile veya bashrc'ye ekle
- [ ] **Theme preview description** — her tema için kısa açıklama göster

### Nerd Fonts

- [ ] **Font installer** — popüler Nerd Font'ları kur (FiraCode, JetBrains Mono, Hack, CascadiaCode, MesloLGS)
- [ ] **Detect installed fonts** — sistemdeki mevcut Nerd Font'ları kontrol et
- [ ] **Font preview** — her font için örnek karakter seti göster (→ ✓ ✗ ⚡  )
- [ ] **Multi-select** — birden fazla font kurulabilsin
- [ ] **Windows Terminal integration** — font ayarını settings.json'a otomatik yaz
- [ ] **iTerm2 / macOS Terminal** — macOS'ta font ayarı rehberi

### Shell Enhancements

**Zsh Plugins (Linux/macOS):**
- [ ] **Oh My Zsh installer** — otomatik kur
- [ ] **zsh-autosuggestions** — komut önerileri
- [ ] **zsh-syntax-highlighting** — komutları renklendir
- [ ] **Plugin preset** — "Developer Pack" (autosuggestions + syntax + completions)

**Fish Shell:**
- [ ] **Fish installer** — apt/brew/dnf
- [ ] **Fisher plugin manager** — otomatik kur
- [ ] **Popular plugins** — z (directory jumping), fzf, autopair

**PowerShell (Windows):**
- [ ] **PSReadLine config** — syntax highlighting, predictive IntelliSense
- [ ] **Terminal-Icons** — dosya/klasör ikonları (Nerd Font gerekli)
- [ ] **z module** — directory jumping
- [ ] **posh-git** — git status in prompt

### Terminal Emulator Config

- [ ] **Windows Terminal** — color scheme selection (Catppuccin, Dracula, Nord, Gruvbox, One Dark)
- [ ] **Windows Terminal** — font, opacity, acrylic/mica background ayarları
- [ ] **iTerm2 profiles** — macOS'ta renk şeması import
- [ ] **Alacritty config** — alacritty.toml generator
- [ ] **Kitty config** — kitty.conf generator

### Color Scheme Presets

- [ ] **Catppuccin** (Latte, Frappe, Macchiato, Mocha)
- [ ] **Dracula**
- [ ] **Nord**
- [ ] **Gruvbox** (Light, Dark)
- [ ] **One Dark**
- [ ] **Tokyo Night**
- [ ] **Solarized** (Light, Dark)
- [ ] **Auto-apply** — seçilen tema terminale + prompt engine'e birlikte uygulansın

### Interactive Preview

- [ ] **Before/After** — "Your terminal now" vs "Your terminal after" karşılaştırma
- [ ] **Quick preview** — geçici shell açıp tüm ayarları uygula, beğenirse kalıcı yap
- [ ] **Rollback** — "Undo all changes" — yedekten geri yükle

---

## 📡 v2.3 — Live Version Intelligence

### Dynamic Version Discovery

Stop hardcoding versions. Query real sources at runtime.

- [ ] **Python** — check python.org/downloads or pypi for latest stable
- [ ] **Node.js** — query nodejs.org/dist/index.json for LTS and Current
- [ ] **Java** — query Adoptium API for available JDK versions
- [ ] **Go** — parse go.dev/dl for latest releases
- [ ] **Rust** — rustup always gets latest, but show which version that is
- [ ] **.NET** — query dotnet.microsoft.com releases API
- [ ] **Zig** — query GitHub releases API
- [ ] **Cache results** — save version info to `~/.codeready/versions-cache.json` with TTL (24h)
- [ ] **Offline fallback** — use hardcoded versions when no internet available

### Smart Recommendations

- [ ] **"Recommended" vs "All versions"** — default shows only recommended (latest stable + latest LTS), advanced shows all
- [ ] **EOL warnings** — flag versions approaching end-of-life
  ```
  Python 3.9 — ⚠️ EOL October 2025, not recommended
  Python 3.12 — ✓ Supported until October 2028
  ```
- [ ] **Compatibility checks** — warn about known issues (e.g., Mojo requires Python 3.10+)

---

## 📋 v2.4 — Configuration Profiles and Export

### Save and Restore Environments

- [ ] **Export config** — save entire selection to `codeready-config.yaml`
  ```yaml
  name: "My Web Dev Setup"
  created: "2026-03-01"
  languages:
    - name: nodejs
      version: "24"
    - name: python
      version: "3.14"
  ides:
    - vscode
    - cursor
  tools:
    - git
    - docker
  frameworks:
    - react
    - tailwind
    - venvstudio
  ```
- [ ] **Import config** — `./codeready.sh --config my-setup.yaml` for instant replay
- [ ] **Team sharing** — commit config file to team repo, everyone gets same environment
- [ ] **Config templates on GitHub** — community-contributed configs for different stacks
- [ ] **Diff configs** — compare two configs to see what's different

### Environment Health Check

- [ ] **`--check` flag** — verify all installed tools are working and on PATH
- [ ] **`--doctor` flag** — diagnose and fix common issues (broken symlinks, missing PATH entries, corrupted installs)
- [ ] **Periodic health check reminder** — optional: run check monthly

---

## 🔄 v2.5 — Update Manager

### Keep Everything Fresh

- [ ] **`--update` flag** — check all installed tools for newer versions
- [ ] **Update report** — show what can be updated before doing anything
  ```
  Updates available:
    Node.js 24.0.0 → 24.1.0 (minor, safe)
    Python 3.14.0 → 3.14.1 (patch, safe)
    VS Code 1.96 → 1.98 (minor, safe)
    React 19.0 → 20.0 (MAJOR — review changelog)
  
  [A] Update all safe  [S] Select individually  [C] Cancel
  ```
- [ ] **Semantic versioning awareness** — distinguish patch/minor/major updates
- [ ] **Changelog preview** — show brief changelog for major updates
- [ ] **Rollback support** — save previous version info, ability to downgrade if update breaks something
- [ ] **Auto-update schedule** — optional cron/task scheduler for weekly checks

---

## 🚀 v3.0 — Platform Evolution

### Docker and Container Support

- [ ] **Generate Dockerfile** — create Dockerfile from selected profile
  ```dockerfile
  FROM ubuntu:24.04
  # Auto-generated by CodeReady v3.0
  RUN apt-get update && apt-get install -y ...
  RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/...
  ```
- [ ] **Docker Compose** — multi-service dev environment with database, cache, etc.
- [ ] **Dev Container support** — generate `.devcontainer/devcontainer.json` for VS Code
- [ ] **Podman alternative** — support rootless containers

### CI/CD Integration

- [ ] **GitHub Actions workflow** — generate `.github/workflows/setup.yml` from config
- [ ] **GitLab CI** — generate `.gitlab-ci.yml` setup stage
- [ ] **Pre-commit hooks** — install and configure common hooks (lint, format, test)

### Plugin System

- [ ] **Plugin architecture** — allow community to add new languages, tools, frameworks
- [ ] **Plugin registry** — searchable catalog of community plugins
- [ ] **Plugin template** — skeleton for creating new plugins
  ```yaml
  name: haskell
  type: language
  versions:
    source: "https://www.haskell.org/ghcup/..."
  install:
    linux: "curl --proto '=https' ... | sh"
    macos: "brew install ghc"
    windows: "winget install GHCup"
  ```

### TUI (Terminal UI)

- [ ] **Interactive TUI** — replace basic menus with rich terminal interface using curses/whiptail
- [ ] **Search and filter** — type to filter packages in large lists
- [ ] **Checkbox selection** — visual checkboxes instead of number input
- [ ] **Progress bars** — real progress indication per package install
- [ ] **Split view** — show install log on one side, progress on other

---

## 🔧 v3.1 — IDE Configuration

### Post-Install Configuration

After installing IDEs, auto-configure them.

- [ ] **VS Code extensions** — install recommended extensions based on selected languages
  - Python profile: Python, Pylance, Black, Ruff
  - Web profile: ESLint, Prettier, Tailwind IntelliSense
  - Rust profile: rust-analyzer, CodeLLDB
  - Go profile: Go (official)
- [ ] **VS Code settings.json** — configure formatters, linters, themes
- [ ] **Neovim config** — install and configure popular plugin managers (lazy.nvim) with language support
- [ ] **JetBrains plugins** — install via command line plugin manager
- [ ] **Git global config** — set default branch name, pull strategy, useful aliases
- [ ] **SSH key generation** — optional GitHub/GitLab SSH key setup

### Shell Enhancement

- [ ] **Starship prompt** — install and configure with dev-friendly preset
- [ ] **Shell aliases** — add useful dev aliases (gs=git status, dc=docker compose, etc.)
- [ ] **Zsh plugins** — zsh-autosuggestions, zsh-syntax-highlighting via oh-my-zsh or zinit
- [ ] **tmux config** — basic dev-friendly tmux configuration

---

## 💭 Future Ideas (Unscheduled)

- [ ] **Web dashboard** — local web UI as alternative to terminal (Electron/Tauri app?)
- [ ] **Remote setup** — SSH into remote machine and set up environment
- [ ] **WSL bridge** — detect Windows, auto-setup WSL, configure shared paths
- [ ] **Language server management** — install and configure LSPs independently
- [ ] **Database setup** — PostgreSQL, MySQL, MongoDB, Redis with optional sample data
- [ ] **Cloud SDK** — AWS CLI, Azure CLI, gcloud CLI setup and auth
- [ ] **Dotfiles integration** — pull user's dotfiles repo and apply
- [ ] **Benchmark mode** — time installations and show optimization suggestions
- [ ] **Telemetry (opt-in)** — anonymous usage stats to prioritize popular features
- [ ] **Localization** — Turkish, German, Japanese, Chinese UI translations
- [ ] **Offline installer** — download all packages once, install on air-gapped machines

---

## Contributing

Want to tackle one of these? Fork the repo and submit a PR! Each feature should include:

1. Implementation in both `codeready.ps1` and `codeready.sh`
2. Updated README section
3. Test on at least one platform (Windows/Linux/macOS)

Priority labels: `P0` = critical, `P1` = high impact, `P2` = nice to have

---

<p align="center"><i>This roadmap evolves with the project. Check back often!</i></p>
