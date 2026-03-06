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
- [x] **Skip already installed** — `skip_installed` checks before every install, no redundant re-installs
- [x] **Safe repo install** — `safe_repo_install` + `cleanup_repo` — failed installs clean up broken repos automatically
- [x] **Flatpak first, snap last** — IDE install priority: apt repo → flatpak → snap (en son)
- [x] **Scoop (Windows)** — added as secondary package manager (winget → Scoop → Chocolatey)
- [x] **MacPorts (macOS)** — detected and available as fallback alongside Homebrew
- [x] **Nix (cross-platform)** — detected as fallback on Linux and macOS
- [x] **Docker Debian fix** — auto-detect debian vs ubuntu, trixie/sid fallback to bookworm
- [x] **Windows IDE detection** — file path checks for Notepad++, Android Studio, JetBrains IDEs
- [x] **Silent error handling** — no red error messages for missing commands in scan
- [x] **Version display** — shows actual version numbers instead of "installed OK"

### Known Issues (to fix next)

- [ ] **Windows scan too slow** — scanning 72+ commands takes too long. Need parallel scan or file-path-only detection for non-PATH apps
- [ ] **JetBrains IDEs** — don't try `--version` (they launch GUI), use only file path detection
- [ ] **Parallel scanning** — run detections in background jobs, collect results
- [ ] **Cache scan results** — save to `~/.codeready/scan-cache.json`, re-scan only if older than 1 hour

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

## 📦 v2.2 — Frameworks & TUI Expansion (Next Up)

### New Frameworks by Ecosystem

**JavaScript / TypeScript:**
- [ ] Svelte / SvelteKit (already partial)
- [ ] Remix (already partial)
- [ ] Hono — ultra-fast web framework
- [ ] Elysia — Bun-native web framework
- [ ] Turborepo — monorepo build system
- [ ] Prisma — database ORM

**Go:**
- [ ] Gin — HTTP web framework
- [ ] Fiber — Express-inspired web framework
- [ ] Echo — high-performance web framework
- [ ] Cobra — CLI application framework

**Rust:**
- [ ] Actix Web — high-performance web framework
- [ ] Axum — modular web framework (Tokio)
- [ ] Rocket — web framework with macros
- [ ] Bevy — game engine (ECS-based)
- [ ] Leptos — full-stack web framework (WASM)

**Java / Kotlin / JVM:**
- [ ] Spring Boot — enterprise web framework
- [ ] Quarkus — cloud-native Java framework
- [ ] Micronaut — microservices framework
- [ ] Ktor — Kotlin async web framework
- [ ] Gradle — build tool (already via SDKMAN)

**PHP:**
- [ ] Laravel — full-stack web framework
- [ ] Symfony — enterprise PHP framework
- [ ] Composer (already partial — ensure global)

**Ruby:**
- [ ] Ruby on Rails — full-stack web framework
- [ ] Bundler — dependency manager
- [ ] Sinatra — lightweight web framework

**Elixir:**
- [ ] Phoenix — real-time web framework
- [ ] Mix — build tool (comes with Elixir)
- [ ] Nerves — embedded/IoT framework

**Python (additions):**
- [ ] Celery — async task queue
- [ ] Pytest — testing framework
- [ ] Ruff — ultra-fast linter
- [ ] Black — code formatter
- [ ] Jupyter Notebook / Lab

**Haskell:**
- [ ] Cabal — package manager
- [ ] Stack — build tool
- [ ] Yesod — web framework

**OCaml:**
- [ ] opam — package manager (already in installer)
- [ ] Dune — build system

### TUI / Terminal Beautification Tools

**Prompt Engines:**
- [ ] Starship — cross-platform prompt
- [ ] Oh My Posh — Windows/cross-platform prompt

**Shell Plugins:**
- [ ] Oh My Zsh — zsh framework + plugins
- [ ] zsh-autosuggestions
- [ ] zsh-syntax-highlighting
- [ ] Fish shell + Fisher plugin manager
- [ ] PSReadLine config (Windows)
- [ ] posh-git (Windows)
- [ ] Terminal-Icons (Windows)

**Nerd Fonts:**
- [ ] FiraCode Nerd Font
- [ ] JetBrains Mono Nerd Font
- [ ] Hack Nerd Font
- [ ] CascadiaCode Nerd Font
- [ ] MesloLGS Nerd Font

**Terminal Color Schemes:**
- [ ] Catppuccin (Latte, Frappe, Macchiato, Mocha)
- [ ] Dracula
- [ ] Nord
- [ ] Gruvbox (Light, Dark)
- [ ] One Dark
- [ ] Tokyo Night
- [ ] Solarized (Light, Dark)

**Terminal Emulator Config:**
- [ ] Windows Terminal settings.json — font, color scheme, opacity
- [ ] Alacritty config generator
- [ ] Kitty config generator
- [ ] iTerm2 profile import (macOS)

### Modern CLI Tools

- [ ] bat — cat with syntax highlighting
- [ ] eza / exa — modern ls replacement
- [ ] fd — modern find replacement
- [ ] ripgrep (rg) — modern grep replacement
- [ ] fzf — fuzzy finder
- [ ] zoxide — smarter cd
- [ ] delta — better git diff
- [ ] lazygit — terminal git UI
- [ ] lazydocker — terminal docker UI
- [ ] htop / btop — system monitor
- [ ] tldr — simplified man pages
- [ ] jq — JSON processor
- [ ] yq — YAML processor
- [ ] httpie — modern curl alternative

---

## 🎨 v2.3 — Terminal Beautification / Shell UX

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

## 📡 v2.4 — Live Version Intelligence

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

## 📋 v2.5 — Configuration, Cache & Portable Profiles

### Config & Cache System (`~/.codeready/`)

- [ ] **`~/.codeready/` directory** — central config location
- [ ] **`scan-cache.json`** — scan results cached, re-scan only if > 1 hour old or `--rescan` flag
  ```json
  {
    "scanned_at": "2026-03-06T14:30:00Z",
    "os": "windows",
    "languages": {
      "python": {"installed": true, "version": "3.14.0", "path": "C:\\Python314\\python.exe"},
      "nodejs": {"installed": true, "version": "24.14.0", "path": "C:\\Users\\user\\.nvm\\..."},
      "go": {"installed": false}
    },
    "ides": {
      "vscode": {"installed": true, "version": "1.109.5", "path": "C:\\Users\\user\\AppData\\Local\\Programs\\..."},
      "notepadpp": {"installed": true, "path": "C:\\Program Files\\Notepad++\\notepad++.exe"}
    },
    "tools": { "git": {"installed": true, "version": "2.53.0"} },
    "frameworks": { "npm": {"installed": true, "version": "11.9.0"} }
  }
  ```
- [ ] **`install-manifest.json`** — what CodeReady installed, when, how
  ```json
  {
    "installed_at": "2026-03-06T14:35:00Z",
    "profile": "2",
    "items": [
      {"name": "nodejs", "version": "24", "method": "nvm", "timestamp": "..."},
      {"name": "vscode", "version": "1.109.5", "method": "winget", "id": "Microsoft.VisualStudioCode"}
    ]
  }
  ```
- [ ] **`config.json`** — user preferences
  ```json
  {
    "default_profile": "2",
    "package_manager_priority": ["winget", "scoop", "choco"],
    "skip_scan": false,
    "auto_fix": true,
    "theme": "default"
  }
  ```

### Portable Profile (`codeready-profile.json`)

- [ ] **Export** — `codeready --export` saves current selections to `codeready-profile.json`
- [ ] **Import** — `codeready --import codeready-profile.json` installs everything from file
- [ ] **Git-friendly** — commit to repo, whole team gets same dev environment
- [ ] **Clone workflow:**
  ```bash
  # Machine A: export
  ./codeready.sh --export
  git add codeready-profile.json && git commit -m "dev environment" && git push

  # Machine B: import
  git pull
  ./codeready.sh --import codeready-profile.json
  ```
- [ ] **Profile format:**
  ```json
  {
    "name": "My Full Stack Setup",
    "created": "2026-03-06",
    "created_on": "windows",
    "languages": ["nodejs", "python", "typescript"],
    "language_versions": {"nodejs": "24", "python": "3.14"},
    "ides": ["vscode", "cursor"],
    "tools": ["git", "docker"],
    "frameworks": ["react", "nextjs", "tailwind", "django", "fastapi"],
    "custom_packages": {"winget": ["SomeApp.Id"], "brew": ["some-pkg"]}
  }
  ```
- [ ] **Diff profiles** — `codeready --diff profile-a.json profile-b.json`
- [ ] **Merge profiles** — `codeready --merge profile-a.json profile-b.json > combined.json`

### Scan Performance (using cache)

- [ ] **First run** — full scan, save to `scan-cache.json`
- [ ] **Subsequent runs** — read from cache, finish in < 1 second
- [ ] **`--rescan` flag** — force fresh scan
- [ ] **Smart invalidation** — if PATH changed or new software detected, auto-rescan
- [ ] **Windows optimization** — JetBrains IDEs: file path only, no `--version` (they launch GUI)
- [ ] **Parallel scan (Linux/macOS)** — run detections in background with `&`, collect results

---

## 🔄 v2.6 — Update Manager

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

## 🩺 v2.7 — Problem Solver / Diagnostics Engine

An intelligent troubleshooting system that diagnoses and fixes common development environment issues automatically.

### `--doctor` Command

- [ ] **`codeready --doctor`** — run full system diagnostics
- [ ] **Exit codes** — 0 = all good, 1 = warnings, 2 = critical issues
- [ ] **Colored report** — green/yellow/red per check
- [ ] **`--doctor --fix`** — auto-fix safe issues
- [ ] **`--doctor --fix --dry-run`** — show what would be fixed without doing it

### PATH & Environment Checks

- [ ] **Duplicate PATH entries** — detect and offer to clean
- [ ] **Broken PATH entries** — directories that don't exist
- [ ] **Conflicting versions** — multiple Python/Node/Java on PATH, which one wins?
- [ ] **Wrong version active** — `python` points to 2.x instead of 3.x
- [ ] **Missing PATH** — installed but not on PATH (e.g., Go installed but `/usr/local/go/bin` missing)
- [ ] **Shell config conflicts** — .bashrc vs .bash_profile vs .profile loading order

### Package Manager Health

- [ ] **Broken apt/dnf repos** — detect and offer to remove
- [ ] **Stale package cache** — `apt update` not run in > 7 days
- [ ] **Orphaned packages** — installed deps no longer needed
- [ ] **GPG key expiry** — repo signing keys about to expire
- [ ] **Conflicting package managers** — same tool installed via brew AND apt
- [ ] **winget source health** — check if winget sources reachable
- [ ] **Scoop bucket issues** — outdated or broken buckets

### Language-Specific Diagnostics

**Python:**
- [ ] pip vs pip3 confusion — which pip goes with which python?
- [ ] Broken virtual environments — missing interpreters
- [ ] System vs user packages — `--break-system-packages` needed?
- [ ] Conda vs pip conflicts
- [ ] Missing build tools — `gcc`, `python-dev` for compilation

**Node.js:**
- [ ] nvm vs system Node — which is active?
- [ ] Global npm permissions — EACCES errors
- [ ] Multiple lockfile conflicts (npm + yarn + pnpm)

**Java:**
- [ ] JAVA_HOME not set or wrong version
- [ ] Multiple JDKs — which is active?

**Rust:**
- [ ] rustup vs system rust conflicts
- [ ] Missing linker (`cc` not found)

**Docker:**
- [ ] Daemon not running
- [ ] User not in docker group
- [ ] Broken Docker repo — auto-detect and fix

**Git:**
- [ ] No user.name/email configured
- [ ] SSH key missing
- [ ] Credential helper not set

### System Checks

- [ ] Disk space — warn if < 5GB free
- [ ] RAM — warn if < 2GB available
- [ ] Internet connectivity — github.com, pypi.org, npmjs.org reachable?
- [ ] DNS resolution issues
- [ ] Firewall/proxy blocking package downloads
- [ ] SSL certificate issues
- [ ] File permissions — `/usr/local/bin`, `~/.config` ownership

### IDE Health

- [ ] VS Code broken extensions
- [ ] VS Code conflicting settings.json
- [ ] Neovim broken plugins

### Auto-Fix Categories

- [ ] **Safe fixes** — auto-apply (PATH cleanup, missing config, broken repos)
- [ ] **Risky fixes** — ask user first (version switching, package removal)
- [ ] **Manual fixes** — show instructions only (OS-level, permission changes)
- [ ] **Fix log** — `~/.codeready/doctor-fixes.log`
- [ ] **Rollback** — undo all auto-fixes if something goes wrong

### Knowledge Base

- [ ] Error pattern database — common errors mapped to solutions
- [ ] Web search fallback — suggest Stack Overflow / GitHub issues
- [ ] Community fixes — load patterns from GitHub repo
- [ ] OS-specific checks and fixes per platform

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
