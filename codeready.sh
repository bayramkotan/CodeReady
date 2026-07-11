#!/usr/bin/env bash
# ================================================================
# CodeReady v2.2.0
# Developer Environment Setup Tool (Linux/macOS)
# https://github.com/bayramkotan/CodeReady
# ================================================================
set -uo pipefail

# Requires bash 4+ for associative arrays (definitions.sh)
if ((BASH_VERSINFO[0] < 4)); then
    echo "CodeReady requires bash 4 or newer." >&2
    echo "On macOS: brew install bash" >&2
    exit 1
fi

VERSION="2.3.0"
LOG_FILE="$HOME/codeready_install.log"
INSTALLED=()
FAILED=()
HAS_MACPORTS=0
HAS_NIX=0
HAS_FLATPAK=0

# --- Load package definitions -----------------------------------
# definitions.sh sits next to codeready.sh in the repo root
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if [[ -f "$SCRIPT_DIR/definitions.sh" ]]; then
    # shellcheck source=definitions.sh
    source "$SCRIPT_DIR/definitions.sh"
else
    echo "ERROR: definitions.sh not found next to codeready.sh" >&2
    echo "Expected at: $SCRIPT_DIR/definitions.sh" >&2
    exit 1
fi

# --- Detect OS --------------------------------------------------
detect_os() {
    OS_TYPE=""; PKG=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"; PKG="brew"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint|pop|elementary|zorin|kali|raspbian|pardus) OS_TYPE="debian"; PKG="apt" ;;
            fedora)                      OS_TYPE="fedora"; PKG="dnf" ;;
            centos|rhel|rocky|alma)      OS_TYPE="rhel";   PKG="dnf" ;;
            arch|manjaro|endeavouros|cachyos|garuda|artix|arcolinux) OS_TYPE="arch"; PKG="pacman" ;;
            opensuse*|sles)              OS_TYPE="suse";   PKG="zypper" ;;
            void)                        OS_TYPE="void";   PKG="xbps" ;;
            alpine)                      OS_TYPE="alpine"; PKG="apk" ;;
            *)
                # Fallback: check ID_LIKE for parent distro
                case "${ID_LIKE:-}" in
                    *arch*)   OS_TYPE="arch";   PKG="pacman" ;;
                    *debian*) OS_TYPE="debian"; PKG="apt" ;;
                    *fedora*|*rhel*) OS_TYPE="fedora"; PKG="dnf" ;;
                    *suse*)   OS_TYPE="suse";   PKG="zypper" ;;
                    *)        OS_TYPE="linux";  PKG="unknown" ;;
                esac
                ;;
        esac
    else
        echo "Unsupported OS"; exit 1
    fi
    echo "  Detected: $OS_TYPE (package manager: $PKG)"
}

# --- UI Helpers -------------------------------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; GRAY='\033[0;90m'; NC='\033[0m'; BOLD='\033[1m'

print_banner() {
    clear
    echo ""
    echo -e "${CYAN}   ####  #####  ####  ###### ####  ###### #####  ####  #   #${NC}"
    echo -e "${CYAN}  #      #   #  #   # #      #   # #      #   #  #   #  # #${NC}"
    echo -e "${CYAN}  #      #   #  #   # ####   ####  ####   #####  #   #   #${NC}"
    echo -e "${CYAN}  #      #   #  #   # #      #  #  #      #   #  #   #   #${NC}"
    echo -e "${CYAN}   ####  #####  ####  ###### #   # ###### #   #  ####    #${NC}"
    echo ""
    echo -e "                                                     ${BOLD}v${VERSION}${NC}"
    echo -e "  ${GRAY}Developer Environment Setup Tool - Linux/macOS${NC}"
    echo -e "  ${GRAY}================================================${NC}"
    echo ""
}

step()    { echo -e "  ${YELLOW}[>]${NC} $1"; }
ok()      { echo -e "  ${GREEN}[+]${NC} $1"; echo "[OK] $1" >> "$LOG_FILE"; INSTALLED+=("$1"); }
fail()    { echo -e "  ${RED}[-]${NC} $1"; echo "[FAIL] $1" >> "$LOG_FILE"; FAILED+=("$1"); }
info()    { echo -e "  ${CYAN}[i]${NC} ${GRAY}$1${NC}"; }
warn()    { echo -e "  ${YELLOW}[!]${NC} ${YELLOW}$1${NC}"; echo "[WARN] $1" >> "$LOG_FILE"; }
section() { echo ""; echo -e "  ${YELLOW}=== $1 ===${NC}"; echo ""; }

# --- Package Manager Setup --------------------------------------
ensure_brew() {
    step "Checking Homebrew..."
    if command -v brew &>/dev/null; then ok "Homebrew ready."; return 0; fi
    echo ""
    read -rp "  [?] Homebrew is not installed. Install it? (Y/n): " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
        info "Skipped Homebrew installation."
        return 1
    fi
    step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || /home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
    ok "Homebrew installed."
}

ensure_macports() {
    step "Checking MacPorts..."
    if command -v port &>/dev/null; then ok "MacPorts ready."; HAS_MACPORTS=1; return 0; fi
    info "MacPorts not installed. Using Homebrew as primary."
    echo ""
    read -rp "  [?] Install MacPorts as secondary? (y/N): " answer
    if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
        info "Visit https://www.macports.org/install.php — MacPorts requires manual download."
    fi
    HAS_MACPORTS=0
}

ensure_nix() {
    step "Checking Nix..."
    if command -v nix &>/dev/null; then ok "Nix ready."; HAS_NIX=1; return 0; fi
    echo ""
    read -rp "  [?] Nix is not installed. Install it? (Y/n): " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
        info "Skipped Nix installation."
        HAS_NIX=0
        return 1
    fi
    step "Installing Nix..."
    sh <(curl -L https://nixos.org/nix/install) --daemon &>>"$LOG_FILE" 2>&1
    if command -v nix &>/dev/null; then
        ok "Nix installed."
        HAS_NIX=1
    else
        info "Nix install may require a shell restart."
        HAS_NIX=0
    fi
}

ensure_flatpak() {
    step "Checking Flatpak..."
    if command -v flatpak &>/dev/null; then ok "Flatpak ready."; HAS_FLATPAK=1; return 0; fi
    echo ""
    read -rp "  [?] Flatpak is not installed. Install it? (Y/n): " answer
    if [[ "$answer" == "n" || "$answer" == "N" ]]; then
        info "Skipped Flatpak installation."
        HAS_FLATPAK=0
        return 1
    fi
    step "Installing Flatpak..."
    case "$PKG" in
        apt)    sudo apt install -y flatpak &>>"$LOG_FILE" ;;
        dnf)    sudo dnf install -y flatpak &>>"$LOG_FILE" ;;
        pacman) sudo pacman -S --noconfirm flatpak &>>"$LOG_FILE" ;;
        zypper) sudo zypper install -y flatpak &>>"$LOG_FILE" ;;
        *)      info "Please install Flatpak manually for your distro."; HAS_FLATPAK=0; return 1 ;;
    esac
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo &>>"$LOG_FILE" 2>&1
    ok "Flatpak installed."
    HAS_FLATPAK=1
}

AUR_HELPER=""
ensure_aur_helper() {
    # Only for Arch-based distros
    [[ "$PKG" != "pacman" ]] && return 0

    step "Checking AUR helper..."
    if command -v paru &>/dev/null; then
        ok "paru ready."
        AUR_HELPER="paru"
        return 0
    fi
    if command -v yay &>/dev/null; then
        ok "yay ready."
        AUR_HELPER="yay"
        return 0
    fi

    echo ""
    echo "  [?] No AUR helper found (yay/paru)."
    echo "      AUR is needed for some packages (Flutter, etc.)"
    echo "      [1] Install paru (recommended)"
    echo "      [2] Install yay"
    echo "      [3] Skip"
    read -rp "  Choose [1/2/3]: " aur_choice

    case "$aur_choice" in
        1)
            step "Installing paru..."
            local tmp_dir=$(mktemp -d)
            sudo pacman -S --needed --noconfirm base-devel git &>>"$LOG_FILE"
            git clone https://aur.archlinux.org/paru.git "$tmp_dir/paru" &>>"$LOG_FILE"
            (cd "$tmp_dir/paru" && makepkg -si --noconfirm) &>>"$LOG_FILE" 2>&1
            rm -rf "$tmp_dir"
            if command -v paru &>/dev/null; then
                ok "paru installed."
                AUR_HELPER="paru"
            else
                fail "paru installation failed."
            fi
            ;;
        2)
            step "Installing yay..."
            local tmp_dir=$(mktemp -d)
            sudo pacman -S --needed --noconfirm base-devel git &>>"$LOG_FILE"
            git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay" &>>"$LOG_FILE"
            (cd "$tmp_dir/yay" && makepkg -si --noconfirm) &>>"$LOG_FILE" 2>&1
            rm -rf "$tmp_dir"
            if command -v yay &>/dev/null; then
                ok "yay installed."
                AUR_HELPER="yay"
            else
                fail "yay installation failed."
            fi
            ;;
        *)
            info "Skipped AUR helper. Some packages may not be available."
            AUR_HELPER=""
            ;;
    esac
}

# Helper: install from AUR (uses paru/yay)
aur_install() {
    local name="$1" pkg="$2"
    if [[ -z "$AUR_HELPER" ]]; then
        info "$name requires AUR. No AUR helper available."
        fail "$name (needs AUR)"
        return 1
    fi
    step "Installing $name via AUR ($AUR_HELPER)..."
    if $AUR_HELPER -S --noconfirm "$pkg" &>>"$LOG_FILE" 2>&1; then
        ok "$name installed via AUR."
    else
        fail "$name AUR install failed."
    fi
}

update_pkg() {
    step "Updating package manager..."
    case "$PKG" in
        apt)    sudo apt update -y &>>"$LOG_FILE" ;;
        dnf)    sudo dnf update -y &>>"$LOG_FILE" ;;
        pacman) sudo pacman -Syu --noconfirm &>>"$LOG_FILE" ;;
        zypper) sudo zypper refresh &>>"$LOG_FILE" ;;
        brew)   brew update &>>"$LOG_FILE" ;;
    esac
}

# Helper: try nix as fallback
nix_install() {
    local name="$1" pkg="$2"
    if [[ $HAS_NIX -eq 1 ]]; then
        step "Installing $name via Nix..."
        nix-env -iA nixpkgs."$pkg" &>>"$LOG_FILE" 2>&1 && ok "$name installed via Nix." && return 0
    fi
    return 1
}

# --- Generic installer ------------------------------------------
pkg_install() {
    local name="$1"; shift
    step "Installing $name..."
    if eval "$@" &>>"$LOG_FILE" 2>&1; then
        ok "$name installed."
        return 0
    else
        fail "$name"
        return 1
    fi
}

# --- Map-based installers (see definitions.sh) ------------------
# Install via native package manager using PKG_MAP / BREW_MAP lookup.
# Returns 0 on success, 1 if no mapping found (caller should fall back).
install_native() {
    local key="$1" display_name="$2"

    if [[ "$PKG" == "brew" ]]; then
        local brew_arg="${BREW_MAP[$key]:-}"
        [[ -z "$brew_arg" ]] && return 1
        pkg_install "$display_name" "brew install $brew_arg"
        return $?
    fi

    local pkgs="${PKG_MAP[${key}:${PKG}]:-}"
    [[ -z "$pkgs" ]] && return 1

    case "$PKG" in
        apt)    pkg_install "$display_name" "sudo apt install -y $pkgs" ;;
        dnf)    pkg_install "$display_name" "sudo dnf install -y $pkgs" ;;
        pacman) pkg_install "$display_name" "sudo pacman -S --noconfirm $pkgs" ;;
        zypper) pkg_install "$display_name" "sudo zypper install -y $pkgs" ;;
        apk)    pkg_install "$display_name" "sudo apk add $pkgs" ;;
        xbps)   pkg_install "$display_name" "sudo xbps-install -y $pkgs" ;;
        *)      return 1 ;;
    esac
    return $?
}

flatpak_install() {
    local name="$1" flatpak_id="$2"
    command -v flatpak &>/dev/null || return 1
    pkg_install "$name" "flatpak install -y flathub $flatpak_id"
}

snap_install() {
    local name="$1" snap_name="$2"
    command -v snap &>/dev/null || return 1
    pkg_install "$name" "sudo snap install $snap_name --classic"
}

# Fallback chain: AUR (Arch only) -> Flatpak -> Snap -> manual notice.
# Priority per project rule: pacman -> AUR -> flatpak -> snap.
try_fallback_install() {
    local key="$1" name="$2"

    # AUR: only on Arch-based systems
    if [[ "$PKG" == "pacman" && -n "${AUR_MAP[$key]:-}" ]]; then
        aur_install "$name" "${AUR_MAP[$key]}" && return 0
    fi

    # Flatpak
    if [[ -n "${FLATPAK_MAP[$key]:-}" ]]; then
        flatpak_install "$name" "${FLATPAK_MAP[$key]}" && return 0
    fi

    # Snap (last resort per project rule)
    if [[ -n "${SNAP_MAP[$key]:-}" ]]; then
        snap_install "$name" "${SNAP_MAP[$key]}" && return 0
    fi

    warn "$name: no install method available for $PKG"
    fail "$name (unsupported on $OS_TYPE)"
    return 1
}

# Convenience wrapper: try native, then fallback chain.
# Use this for simple packages where the entire install can be table-driven.
install_from_map() {
    local key="$1" display_name="$2"
    install_native "$key" "$display_name" && return 0
    try_fallback_install "$key" "$display_name"
}

# Check if a command already exists — skip if installed
is_cmd() { command -v "$1" &>/dev/null; }

# ================================================================
# UNINSTALL HELPERS
# ================================================================

# Generic uninstaller (symmetric to pkg_install)
pkg_uninstall() {
    local name="$1"; shift
    step "Removing $name..."
    if eval "$@" &>>"$LOG_FILE" 2>&1; then
        ok "$name removed."
        return 0
    else
        fail "$name (removal)"
        return 1
    fi
}

# Uninstall via native package manager using PKG_MAP / BREW_MAP lookup.
# Returns 0 on success, 1 if no mapping found.
uninstall_native() {
    local key="$1" display_name="$2"

    if [[ "$PKG" == "brew" ]]; then
        local brew_arg="${BREW_MAP[$key]:-}"
        [[ -z "$brew_arg" ]] && return 1
        # brew uninstall doesn't take --cask/formula flags the same way
        # but "brew uninstall <name>" works for both. Strip the --cask flag.
        local name_only="${brew_arg#--cask }"
        pkg_uninstall "$display_name" "brew uninstall $name_only"
        return $?
    fi

    local pkgs="${PKG_MAP[${key}:${PKG}]:-}"
    [[ -z "$pkgs" ]] && return 1

    case "$PKG" in
        apt)    pkg_uninstall "$display_name" "sudo apt remove -y $pkgs" ;;
        dnf)    pkg_uninstall "$display_name" "sudo dnf remove -y $pkgs" ;;
        pacman) pkg_uninstall "$display_name" "sudo pacman -Rns --noconfirm $pkgs" ;;
        zypper) pkg_uninstall "$display_name" "sudo zypper remove -y $pkgs" ;;
        apk)    pkg_uninstall "$display_name" "sudo apk del $pkgs" ;;
        xbps)   pkg_uninstall "$display_name" "sudo xbps-remove -y $pkgs" ;;
        *)      return 1 ;;
    esac
    return $?
}

# Try native uninstall; if not installed via native, tell user other sources
# to check (flatpak/snap/AUR). Uninstall does not auto-cascade like install
# because we cannot always tell which source the package came from.
uninstall_from_map() {
    local key="$1" display_name="$2"

    if uninstall_native "$key" "$display_name"; then
        return 0
    fi

    # Not in native map — inform user of alternate sources
    local alternates=()
    [[ -n "${FLATPAK_MAP[$key]:-}" ]] && alternates+=("flatpak uninstall ${FLATPAK_MAP[$key]}")
    [[ -n "${SNAP_MAP[$key]:-}"    ]] && alternates+=("sudo snap remove ${SNAP_MAP[$key]}")
    [[ -n "${AUR_MAP[$key]:-}"     ]] && alternates+=("<aur-helper> -R ${AUR_MAP[$key]}")

    if ((${#alternates[@]} > 0)); then
        warn "$display_name not in native package map for $PKG."
        info "If installed via alternate source, try:"
        for cmd in "${alternates[@]}"; do
            info "  $cmd"
        done
    else
        warn "$display_name: no known removal method for $PKG."
    fi
    fail "$display_name (no native mapping)"
    return 1
}

# Interactive removal of user-space config directories (~/.cargo, ~/.nvm, etc.)
# Reads CONFIG_MAP[$key], expands $HOME, prompts once before touching anything.
remove_user_configs() {
    local key="$1" display_name="$2"
    local raw="${CONFIG_MAP[$key]:-}"
    [[ -z "$raw" ]] && return 0

    # Expand $HOME in the config paths (raw is single-quoted in the map)
    local expanded_paths=()
    local p
    for p in $raw; do
        expanded_paths+=("${p/\$HOME/$HOME}")
    done

    # Filter to only paths that actually exist
    local existing=()
    for p in "${expanded_paths[@]}"; do
        [[ -e "$p" ]] && existing+=("$p")
    done

    if ((${#existing[@]} == 0)); then
        return 0
    fi

    echo "" >&2
    echo -e "  ${YELLOW}Config files found for $display_name:${NC}" >&2
    for p in "${existing[@]}"; do
        echo -e "    ${GRAY}- $p${NC}" >&2
    done
    echo "" >&2
    read -rp "  Remove these config files too? [y/N]: " cfg_choice
    if [[ "$cfg_choice" == "y" || "$cfg_choice" == "Y" ]]; then
        for p in "${existing[@]}"; do
            step "Removing $p..."
            if [[ "$p" == /usr/* || "$p" == /opt/* || "$p" == /etc/* ]]; then
                sudo rm -rf "$p" &>>"$LOG_FILE" && ok "Removed $p" || fail "Remove $p"
            else
                rm -rf "$p" &>>"$LOG_FILE" && ok "Removed $p" || fail "Remove $p"
            fi
        done
    else
        info "Config files kept."
    fi
}

skip_installed() {
    local name="$1" cmd="$2"
    if is_cmd "$cmd"; then
        ok "$name is already installed. Skipping."
        INSTALLED+=("$name (already installed)")
        return 0
    fi
    return 1
}

# Safe apt repo add — tracks what we add so we can clean up on failure
ADDED_REPOS=()
ADDED_KEYRINGS=()

safe_add_repo() {
    local list_file="$1" repo_line="$2" keyring="$3" key_url="$4"
    # Add GPG key
    if [[ -n "$key_url" && -n "$keyring" ]]; then
        curl -fsSL "$key_url" 2>>"$LOG_FILE" | sudo gpg --dearmor -o "$keyring" 2>>"$LOG_FILE"
        sudo chmod a+r "$keyring"
        ADDED_KEYRINGS+=("$keyring")
    fi
    # Add repo
    echo "$repo_line" | sudo tee "$list_file" > /dev/null
    ADDED_REPOS+=("$list_file")
    sudo apt update &>>"$LOG_FILE" 2>&1
}

# Remove repo and keyring if install failed — don't leave broken repos
cleanup_repo() {
    local list_file="$1" keyring="$2"
    [[ -f "$list_file" ]] && sudo rm -f "$list_file" 2>/dev/null
    [[ -f "$keyring" ]] && sudo rm -f "$keyring" 2>/dev/null
    sudo apt update &>>"$LOG_FILE" 2>&1
}

# Safe install via apt repo: add repo, try install, cleanup if fails
safe_repo_install() {
    local name="$1" list_file="$2" repo_line="$3" keyring="$4" key_url="$5" pkg_name="$6"
    step "Installing $name via official repo..."
    safe_add_repo "$list_file" "$repo_line" "$keyring" "$key_url"
    if sudo apt install -y "$pkg_name" &>>"$LOG_FILE" 2>&1; then
        ok "$name installed."
    else
        warn "Failed to install $name — cleaning up broken repo..."
        cleanup_repo "$list_file" "$keyring"
        fail "$name"
    fi
}

# --- Number menu ------------------------------------------------
number_menu() {
    local title="$1"; shift
    local -n _items=$1; shift
    local -n _result=$1

    section "$title"
    local i=1
    for item in "${_items[@]}"; do
        printf "  ${CYAN}[%2d]${NC} %s\n" "$i" "$item"
        ((i++))
    done
    echo ""
    echo -e "  ${GRAY}Enter numbers separated by spaces, 'a' for all, 'n' for none${NC}"
    read -rp "  Selection: " sel
    _result=()
    if [[ "$sel" == "a" || "$sel" == "A" ]]; then
        for ((j=0; j<${#_items[@]}; j++)); do _result+=("$j"); done
        return
    fi
    [[ "$sel" == "n" || "$sel" == "N" ]] && return
    for num in $sel; do
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#_items[@]} )); then
            _result+=("$((num-1))")
        fi
    done
}

version_menu() {
    local lang_name="$1"; shift
    local -a labels=("$@")
    echo "" >&2
    echo -e "  ${CYAN}$lang_name - Select version:${NC}" >&2
    for ((i=0; i<${#labels[@]}; i++)); do
        local tag=""
        [[ $i -eq 0 ]] && tag=" (latest)"
        echo "    [$((i+1))] ${labels[$i]}$tag" >&2
    done
    read -rp "    Version (default=1): " choice
    [[ -z "$choice" ]] && choice=1
    echo "$((choice-1))"
}

# ================================================================
# LANGUAGE INSTALLERS (version-aware)
# ================================================================

install_python() {
    local ver="${1:-3.14}"
    skip_installed "Python $ver" "python3" && return
    case "$PKG" in
        brew)   pkg_install "Python $ver" "brew install python@$ver" ;;
        apt)    pkg_install "Python $ver" "sudo apt install -y python${ver} python3-pip python3-venv || sudo apt install -y python3 python3-pip python3-venv" ;;
        dnf)    pkg_install "Python $ver" "sudo dnf install -y python${ver} || sudo dnf install -y python3 python3-pip" ;;
        pacman) pkg_install "Python" "sudo pacman -S --noconfirm python python-pip" ;;
        zypper) pkg_install "Python" "sudo zypper install -y python3 python3-pip" ;;
    esac
}

install_nodejs() {
    local ver="${1:-24}"
    if is_cmd node; then ok "Node.js is already installed. Skipping."; INSTALLED+=("Node.js (already installed)"); return; fi
    step "Installing Node.js $ver via nvm..."
    if [[ ! -d "$HOME/.nvm" ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash &>>"$LOG_FILE"
    fi
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    if command -v nvm &>/dev/null; then
        nvm install "$ver" &>>"$LOG_FILE" 2>&1
        nvm use "$ver" &>>"$LOG_FILE" 2>&1
        ok "Node.js $ver installed via nvm."
    else
        case "$PKG" in
            brew) pkg_install "Node.js" "brew install node" ;;
            *)    pkg_install "Node.js" "sudo $PKG install -y nodejs npm" ;;
        esac
    fi
}

install_java() {
    skip_installed "JDK" "java" && return
    local ver="${1:-25}"
    case "$PKG" in
        brew)   pkg_install "JDK $ver" "brew install --cask temurin@$ver || brew install --cask temurin" ;;
        apt)    pkg_install "JDK $ver" "sudo apt install -y temurin-${ver}-jdk || sudo apt install -y openjdk-${ver}-jdk || sudo apt install -y default-jdk" ;;
        dnf)    pkg_install "JDK $ver" "sudo dnf install -y java-${ver}-openjdk-devel || sudo dnf install -y java-latest-openjdk-devel" ;;
        pacman) pkg_install "JDK" "sudo pacman -S --noconfirm jdk-openjdk" ;;
        zypper) pkg_install "JDK" "sudo zypper install -y java-${ver}-openjdk-devel || sudo zypper install -y java-latest-openjdk-devel" ;;
    esac
}

install_csharp() {
    skip_installed ".NET SDK" "dotnet" && return
    local ver="${1:-9}"
    case "$PKG" in
        brew)   pkg_install ".NET $ver SDK" "brew install dotnet-sdk" ;;
        apt)    pkg_install ".NET $ver SDK" "sudo apt install -y dotnet-sdk-${ver}.0 || (curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel ${ver}.0)" ;;
        dnf)    pkg_install ".NET $ver SDK" "sudo dnf install -y dotnet-sdk-${ver}.0" ;;
        pacman) pkg_install ".NET SDK" "sudo pacman -S --noconfirm dotnet-sdk" ;;
    esac
}

install_cpp() {
    local variant="${1:-gcc}"
    install_from_map "cpp" "C/C++ ($variant)"
}

install_go() {
    skip_installed "Go" "go" && return
    local ver="${1:-1.23}"
    case "$PKG" in
        brew) pkg_install "Go $ver" "brew install go" ;;
        *)
            local ARCH; ARCH=$(uname -m)
            case "$ARCH" in x86_64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; esac
            step "Installing Go ${ver} from official binary..."
            curl -fsSL "https://go.dev/dl/go${ver}.5.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz 2>>"$LOG_FILE" || \
            curl -fsSL "https://go.dev/dl/go${ver}.0.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz 2>>"$LOG_FILE"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf /tmp/go.tar.gz
            grep -q '/usr/local/go/bin' "$HOME/.bashrc" || echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
            grep -q '/usr/local/go/bin' "$HOME/.zshrc" 2>/dev/null || echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.zshrc" 2>/dev/null
            export PATH=$PATH:/usr/local/go/bin
            rm -f /tmp/go.tar.gz
            ok "Go $ver installed."
            ;;
    esac
}

install_rust() {
    step "Installing Rust via rustup..."
    if command -v rustup &>/dev/null; then ok "Rust already installed."; return; fi
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>>"$LOG_FILE"
    source "$HOME/.cargo/env" 2>/dev/null || true
    ok "Rust installed."
}

install_php() {
    skip_installed "PHP" "php" && return
    local ver="${1:-8.4}"
    case "$PKG" in
        brew)   pkg_install "PHP $ver" "brew install php@$ver composer || brew install php composer" ;;
        apt)    pkg_install "PHP $ver" "sudo apt install -y php${ver} php${ver}-cli php-common php-mbstring php-xml composer || sudo apt install -y php php-cli composer" ;;
        dnf)    pkg_install "PHP" "sudo dnf install -y php php-cli php-common composer" ;;
        pacman) pkg_install "PHP" "sudo pacman -S --noconfirm php composer" ;;
    esac
}

install_ruby() {
    skip_installed "Ruby" "ruby" && return
    local ver="${1:-3.3}"
    case "$PKG" in
        brew)   pkg_install "Ruby $ver" "brew install ruby@$ver || brew install ruby" ;;
        apt)    pkg_install "Ruby" "sudo apt install -y ruby ruby-dev rubygems" ;;
        dnf)    pkg_install "Ruby" "sudo dnf install -y ruby ruby-devel rubygems" ;;
        pacman) pkg_install "Ruby" "sudo pacman -S --noconfirm ruby rubygems" ;;
    esac
}

install_kotlin() {
    skip_installed "Kotlin" "kotlin" && return
    case "$PKG" in
        brew) pkg_install "Kotlin" "brew install kotlin" ;;
        *)    if command -v snap &>/dev/null; then
                  pkg_install "Kotlin" "sudo snap install kotlin --classic"
              else
                  step "Installing Kotlin via SDKMAN..."
                  curl -s "https://get.sdkman.io" | bash &>>"$LOG_FILE"
                  source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null
                  sdk install kotlin &>>"$LOG_FILE" 2>&1 && ok "Kotlin installed." || fail "Kotlin"
              fi ;;
    esac
}

install_dart() {
    skip_installed "Dart/Flutter" "flutter" && return
    local variant="${1:-flutter}"
    case "$PKG" in
        brew)
            if [[ "$variant" == "flutter" ]]; then
                pkg_install "Flutter (includes Dart)" "brew install --cask flutter"
            else
                pkg_install "Dart SDK" "brew install dart-sdk"
            fi ;;
        pacman)
            # Flutter not in official repos — use AUR
            if [[ -n "$AUR_HELPER" ]]; then
                aur_install "Flutter" "flutter"
            elif command -v snap &>/dev/null; then
                pkg_install "Flutter" "sudo snap install flutter --classic"
            else
                info "Flutter needs AUR helper (paru/yay) or snap. Run script again and install AUR helper."
                fail "Dart/Flutter (needs AUR)"
            fi ;;
        *)
            if command -v snap &>/dev/null; then
                pkg_install "Flutter" "sudo snap install flutter --classic"
            else
                info "Download Flutter from: https://flutter.dev"
                fail "Dart/Flutter (manual)"
            fi ;;
    esac
}

install_swift() {
    skip_installed "Swift" "swift" && return
    case "$PKG" in
        brew) if command -v swift &>/dev/null; then ok "Swift available (via Xcode)."; else info "Install Xcode: xcode-select --install"; fail "Swift"; fi ;;
        apt)  pkg_install "Swift" "sudo apt install -y swift || (curl -fsSL https://swift.org/install.sh | bash)" ;;
        *)    info "Swift: visit https://swift.org/getting-started/"; fail "Swift (manual)" ;;
    esac
}

install_zig() {
    skip_installed "Zig" "zig" && return
    # brew / pacman: direct native install via map
    if [[ "$PKG" == "brew" || "$PKG" == "pacman" ]]; then
        install_from_map "zig" "Zig"
        return
    fi
    # apt / dnf: try native (map) first, fall back to official tarball
    if [[ "$PKG" == "dnf" ]] && install_native "zig" "Zig"; then
        return
    fi
    if [[ "$PKG" == "apt" ]] && command -v snap &>/dev/null; then
        pkg_install "Zig" "sudo snap install zig --classic --beta"
        return
    fi
    step "Installing Zig from official binary..."
    local ARCH; ARCH=$(uname -m)
    case "$ARCH" in x86_64) ARCH="x86_64" ;; aarch64|arm64) ARCH="aarch64" ;; esac
    curl -fsSL "https://ziglang.org/download/0.13.0/zig-linux-${ARCH}-0.13.0.tar.xz" -o /tmp/zig.tar.xz 2>>"$LOG_FILE"
    sudo tar -C /usr/local -xf /tmp/zig.tar.xz
    sudo ln -sf /usr/local/zig-linux-*/zig /usr/local/bin/zig
    rm -f /tmp/zig.tar.xz
    ok "Zig installed."
}

install_mojo() {
    step "Installing Mojo..."
    if [[ "$OS_TYPE" == "macos" ]] || [[ "$OS_TYPE" != "macos" ]]; then
        if command -v pip3 &>/dev/null || command -v pip &>/dev/null; then
            pkg_install "Mojo" "pip3 install mojo --break-system-packages 2>/dev/null || pip install mojo --break-system-packages 2>/dev/null || pip3 install mojo || pip install mojo"
        else
            info "Mojo: pip install mojo (requires Python)"
            info "More info: https://www.modular.com/mojo"
            fail "Mojo (requires pip)"
        fi
    fi
}

install_wasm() {
    local variant="${1:-wasmtime}"
    case "$PKG" in
        brew)
            if [[ "$variant" == "wasmtime" ]]; then
                pkg_install "Wasmtime" "brew install wasmtime"
            else
                pkg_install "Wasmer" "brew install wasmer"
            fi ;;
        *)
            if [[ "$variant" == "wasmtime" ]]; then
                step "Installing Wasmtime..."
                curl https://wasmtime.dev/install.sh -sSf | bash &>>"$LOG_FILE" && ok "Wasmtime installed." || fail "Wasmtime"
            else
                step "Installing Wasmer..."
                curl https://get.wasmer.io -sSfL | sh &>>"$LOG_FILE" && ok "Wasmer installed." || fail "Wasmer"
            fi ;;
    esac
}

install_typescript() {
    skip_installed "TypeScript" "tsc" && return
    step "Installing TypeScript globally via npm..."
    if command -v npm &>/dev/null; then
        npm install -g typescript ts-node &>>"$LOG_FILE" 2>&1 && ok "TypeScript installed." || fail "TypeScript"
    else
        info "TypeScript requires Node.js/npm. Install Node.js first."
        fail "TypeScript (needs npm)"
    fi
}

install_elixir() {
    skip_installed "Elixir" "elixir" && return
    install_from_map "elixir" "Elixir"
}

install_scala() {
    skip_installed "Scala" "scala" && return
    case "$PKG" in
        brew) pkg_install "Scala" "brew install scala" ;;
        *)    if command -v cs &>/dev/null || command -v coursier &>/dev/null; then
                  pkg_install "Scala" "cs install scala3"
              else
                  step "Installing Scala via coursier..."
                  curl -fL "https://github.com/coursier/launchers/raw/master/cs-x86_64-pc-linux.gz" | gzip -d > /tmp/cs && chmod +x /tmp/cs && /tmp/cs setup -y &>>"$LOG_FILE"
                  ok "Scala installed via coursier."
              fi ;;
    esac
}

install_julia() {
    step "Installing Julia via juliaup..."
    if command -v julia &>/dev/null; then ok "Julia already installed."; return; fi
    case "$PKG" in
        brew) pkg_install "Julia" "brew install julia" ;;
        *)
            curl -fsSL https://install.julialang.org | sh -s -- -y &>>"$LOG_FILE" 2>&1
            if command -v juliaup &>/dev/null; then
                ok "Julia installed via juliaup."
            elif command -v snap &>/dev/null; then
                pkg_install "Julia" "sudo snap install julia --classic"
            else
                fail "Julia (visit https://julialang.org/downloads/)"
            fi ;;
    esac
}

# --- NEW LANGUAGES (v2.1) ---

install_r() {
    skip_installed "R" "R" && return
    install_from_map "r" "R"
}

install_lua() {
    skip_installed "Lua" "lua" && return
    install_from_map "lua" "Lua"
}

install_haskell() {
    step "Installing Haskell via GHCup..."
    if command -v ghc &>/dev/null; then ok "Haskell already installed."; return; fi
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh &>>"$LOG_FILE" 2>&1
    [ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" 2>/dev/null
    ok "Haskell (GHC + Cabal + Stack) installed via GHCup."
}

install_perl() {
    skip_installed "Perl" "perl" && return
    install_from_map "perl" "Perl"
}

install_erlang() {
    skip_installed "Erlang" "erl" && return
    install_from_map "erlang" "Erlang"
}

install_ocaml() {
    skip_installed "OCaml" "ocaml" && return
    step "Installing OCaml via opam..."
    case "$PKG" in
        brew)   pkg_install "OCaml" "brew install ocaml opam" ;;
        *)
            if command -v opam &>/dev/null; then ok "OCaml (opam) already installed."; return; fi
            case "$PKG" in
                apt)    sudo apt install -y opam &>>"$LOG_FILE" ;;
                dnf)    sudo dnf install -y opam &>>"$LOG_FILE" ;;
                pacman) sudo pacman -S --noconfirm opam &>>"$LOG_FILE" ;;
            esac
            opam init -y &>>"$LOG_FILE" 2>&1
            ok "OCaml installed via opam." ;;
    esac
}

install_fortran() {
    skip_installed "Fortran" "gfortran" && return
    install_from_map "fortran" "Fortran (GFortran)"
}

install_d() {
    skip_installed "D" "ldc2" && return
    install_native "d" "D (LDC)" && return
    info "D language: visit https://dlang.org/install.html"
    fail "D (manual)"
}

install_nim() {
    step "Installing Nim via choosenim..."
    if command -v nim &>/dev/null; then ok "Nim already installed."; return; fi
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y &>>"$LOG_FILE" 2>&1
    export PATH="$HOME/.nimble/bin:$PATH"
    ok "Nim installed via choosenim."
}

install_crystal() {
    skip_installed "Crystal" "crystal" && return
    # apt has no native crystal package — use the official install script
    if [[ "$PKG" == "apt" ]]; then
        step "Installing Crystal..."
        curl -fsSL https://crystal-lang.org/install.sh | sudo bash &>>"$LOG_FILE" 2>&1
        ok "Crystal installed."
        return
    fi
    install_native "crystal" "Crystal" && return
    info "Crystal: visit https://crystal-lang.org/install/"
    fail "Crystal (manual)"
}

install_v() {
    step "Installing V language..."
    if command -v v &>/dev/null; then ok "V already installed."; return; fi
    case "$PKG" in
        brew) pkg_install "V" "brew install vlang" ;;
        *)
            git clone --depth 1 https://github.com/vlang/v /tmp/vlang &>>"$LOG_FILE" 2>&1
            cd /tmp/vlang && make &>>"$LOG_FILE" 2>&1
            sudo mv /tmp/vlang/v /usr/local/bin/v 2>/dev/null
            cd - &>/dev/null
            ok "V language installed." ;;
    esac
}

install_gleam() {
    skip_installed "Gleam" "gleam" && return
    case "$PKG" in
        brew) pkg_install "Gleam" "brew install gleam" ;;
        *)
            step "Installing Gleam..."
            curl -fsSL https://gleam.run/install.sh | sh &>>"$LOG_FILE" 2>&1
            ok "Gleam installed." ;;
    esac
}

install_carbon() {
    info "Carbon is in early development (experimental). Visit: https://github.com/carbon-language/carbon-lang"
    info "You can explore via Compiler Explorer: https://carbon.compiler-explorer.com"
    fail "Carbon (experimental, no installer yet)"
}

install_solidity() {
    skip_installed "Solidity" "solcjs" && return
    step "Installing Solidity compiler (solc)..."
    if command -v npm &>/dev/null; then
        npm install -g solc &>>"$LOG_FILE" 2>&1 && ok "Solidity (solcjs) installed via npm." || fail "Solidity"
    else
        case "$PKG" in
            brew) pkg_install "Solidity" "brew install solidity" ;;
            *)    if command -v snap &>/dev/null; then
                      pkg_install "Solidity" "sudo snap install solc"
                  else
                      info "Solidity: npm install -g solc (needs Node.js)"; fail "Solidity (needs npm)"
                  fi ;;
        esac
    fi
}

install_groovy() {
    skip_installed "Groovy" "groovy" && return
    case "$PKG" in
        brew) pkg_install "Groovy" "brew install groovy" ;;
        *)    if command -v sdk &>/dev/null || [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
                  [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && source "$HOME/.sdkman/bin/sdkman-init.sh"
                  sdk install groovy &>>"$LOG_FILE" 2>&1 && ok "Groovy installed via SDKMAN." || fail "Groovy"
              else
                  step "Installing Groovy via SDKMAN..."
                  curl -s "https://get.sdkman.io" | bash &>>"$LOG_FILE"
                  source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null
                  sdk install groovy &>>"$LOG_FILE" 2>&1 && ok "Groovy installed." || fail "Groovy"
              fi ;;
    esac
}

install_ada() {
    skip_installed "Ada" "gnat" && return
    install_native "ada" "Ada (GNAT)" && return
    info "Ada: visit https://www.adacore.com/download"
    fail "Ada (manual)"
}

install_cobol() {
    skip_installed "COBOL" "cobc" && return
    install_native "cobol" "COBOL (GnuCOBOL)" && return
    info "COBOL: visit https://gnucobol.sourceforge.io"
    fail "COBOL (manual)"
}

install_lisp() {
    skip_installed "Common Lisp" "sbcl" && return
    install_from_map "lisp" "Common Lisp (SBCL)"
}

install_racket() {
    skip_installed "Racket" "racket" && return
    install_from_map "racket" "Racket"
}

install_objc() {
    if [[ "$PKG" == "brew" ]]; then
        info "Objective-C available via Xcode: xcode-select --install"
        if command -v clang &>/dev/null; then ok "Objective-C (Clang) available."; else fail "Objective-C"; fi
        return
    fi
    install_native "objc" "Objective-C (GNUstep)" && return
    info "Objective-C: use Xcode (macOS) or GNUstep (Linux)"
    fail "Objective-C (manual)"
}

# ================================================================
# IDE INSTALLERS (skip if installed, flatpak > apt/repo > snap)
# ================================================================

# Helper: try flatpak first, then snap as last resort
flatpak_or_snap() {
    local name="$1" flatpak_id="$2" snap_name="$3"
    if command -v flatpak &>/dev/null; then
        pkg_install "$name" "flatpak install -y flathub $flatpak_id"
    elif command -v snap &>/dev/null; then
        pkg_install "$name" "sudo snap install $snap_name --classic"
    else
        info "Download $name manually."; fail "$name (manual)"
    fi
}

install_ide() {
    local key="$1"
    case "$key" in
        vscode)
            skip_installed "VS Code" "code" && return
            case "$PKG" in
                brew) pkg_install "VS Code" "brew install --cask visual-studio-code" ;;
                apt)
                    safe_repo_install "VS Code" \
                        "/etc/apt/sources.list.d/vscode.list" \
                        "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" \
                        "/usr/share/keyrings/microsoft-archive-keyring.gpg" \
                        "https://packages.microsoft.com/keys/microsoft.asc" \
                        "code" ;;
                dnf)
                    step "Installing VS Code via Microsoft repo..."
                    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>>"$LOG_FILE"
                    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
                    if sudo dnf install -y code &>>"$LOG_FILE"; then ok "VS Code installed."
                    else sudo rm -f /etc/yum.repos.d/vscode.repo 2>/dev/null; fail "VS Code"; fi ;;
                *) flatpak_or_snap "VS Code" "com.visualstudio.code" "code" ;;
            esac ;;
        vscodium)
            skip_installed "VSCodium" "codium" && return
            case "$PKG" in
                brew) pkg_install "VSCodium" "brew install --cask vscodium" ;;
                apt)
                    step "Installing VSCodium via repo..."
                    curl -fsSL https://gitlab.com/nicedoc/vscodium/-/raw/master/install.sh | sudo bash &>>"$LOG_FILE" 2>&1
                    sudo apt update &>>"$LOG_FILE" && sudo apt install -y codium &>>"$LOG_FILE" && ok "VSCodium installed." || fail "VSCodium" ;;
                *) flatpak_or_snap "VSCodium" "com.vscodium.codium" "codium" ;;
            esac ;;
        vs2026) info "Visual Studio is Windows-only. Use VS Code or Rider." ;;
        intellij)   skip_installed "IntelliJ IDEA" "idea" && return
                    install_from_map "intellij"  "IntelliJ IDEA" ;;
        pycharm)    skip_installed "PyCharm" "pycharm" && return
                    install_from_map "pycharm"   "PyCharm" ;;
        webstorm)   skip_installed "WebStorm" "webstorm" && return
                    install_from_map "webstorm"  "WebStorm" ;;
        goland)     skip_installed "GoLand" "goland" && return
                    install_from_map "goland"    "GoLand" ;;
        clion)      skip_installed "CLion" "clion" && return
                    install_from_map "clion"     "CLion" ;;
        rider)      skip_installed "Rider" "rider" && return
                    install_from_map "rider"     "Rider" ;;
        rustrover)  skip_installed "RustRover" "rustrover" && return
                    install_from_map "rustrover" "RustRover" ;;
        eclipse)    skip_installed "Eclipse" "eclipse" && return
                    install_from_map "eclipse"   "Eclipse" ;;
        android)    skip_installed "Android Studio" "studio" && return
                    install_from_map "android"   "Android Studio" ;;
        sublime)
            skip_installed "Sublime Text" "subl" && return
            # apt: use official signed repo (requires custom keyring)
            if [[ "$PKG" == "apt" ]]; then
                safe_repo_install "Sublime Text" \
                    "/etc/apt/sources.list.d/sublime-text.list" \
                    "deb [arch=amd64 signed-by=/usr/share/keyrings/sublimehq-archive-keyring.gpg] https://download.sublimetext.com/ apt/stable/" \
                    "/usr/share/keyrings/sublimehq-archive-keyring.gpg" \
                    "https://download.sublimetext.com/sublimehq-pub.gpg" \
                    "sublime-text"
            else
                install_from_map "sublime" "Sublime Text"
            fi ;;
        vim)        skip_installed "Neovim" "nvim" && return
                    install_from_map "neovim" "Neovim" ;;
        classicvim) skip_installed "Vim" "vim" && return
                    install_from_map "vim" "Vim" ;;
        emacs)      skip_installed "GNU Emacs" "emacs" && return
                    install_from_map "emacs" "GNU Emacs" ;;
        antigravity)
            skip_installed "Antigravity" "antigravity" && return
            if install_native "antigravity" "Antigravity"; then :
            else info "Download Antigravity: https://antigravity.app"; fail "Antigravity (manual)"
            fi ;;
        netbeans)   skip_installed "NetBeans" "netbeans" && return
                    install_from_map "netbeans" "NetBeans" ;;
        fleet)      skip_installed "Fleet" "fleet" && return
                    install_from_map "fleet" "JetBrains Fleet" ;;
        notepadpp)  info "Notepad++ is Windows-only." ;;
        cursor)
            skip_installed "Cursor" "cursor" && return
            # AUR fallback for Arch users (was manual-only before)
            if install_from_map "cursor" "Cursor"; then :
            else info "Download Cursor: https://cursor.sh"; fi ;;
        windsurf)
            skip_installed "Windsurf" "windsurf" && return
            if install_from_map "windsurf" "Windsurf"; then :
            else info "Download Windsurf: https://codeium.com/windsurf"; fi ;;
        zed)
            skip_installed "Zed" "zed" && return
            # brew / Arch (AUR): use map. Everything else: official install script.
            if [[ "$PKG" == "brew" ]] || [[ "$PKG" == "pacman" && -n "${AUR_MAP[zed]:-}" ]]; then
                install_from_map "zed" "Zed"
            else
                step "Installing Zed..."
                curl -fsSL https://zed.dev/install.sh | sh &>>"$LOG_FILE" && ok "Zed installed." || fail "Zed"
            fi ;;
        *) fail "Unknown IDE: $key" ;;
    esac
}

# ================================================================
# TOOL INSTALLERS
# ================================================================
install_tool() {
    local key="$1"
    case "$key" in
        git)        skip_installed "Git" "git" && return
                    install_from_map "git" "Git" ;;
        docker)
            skip_installed "Docker" "docker" && return
            case "$PKG" in
                brew) pkg_install "Docker" "brew install --cask docker" ;;
                apt)
                    step "Installing Docker..."
                    sudo apt install -y ca-certificates curl &>>"$LOG_FILE"
                    sudo install -m 0755 -d /etc/apt/keyrings
                    local DISTRO CODENAME
                    if grep -qi "debian" /etc/os-release; then DISTRO="debian"; else DISTRO="ubuntu"; fi
                    CODENAME=$(. /etc/os-release && echo "$VERSION_CODENAME")
                    if [[ "$DISTRO" == "debian" && ("$CODENAME" == "trixie" || "$CODENAME" == "sid" || -z "$CODENAME") ]]; then
                        CODENAME="bookworm"
                    fi
                    local docker_keyring="/etc/apt/keyrings/docker.asc"
                    local docker_list="/etc/apt/sources.list.d/docker.list"
                    curl -fsSL "https://download.docker.com/linux/${DISTRO}/gpg" -o "$docker_keyring" 2>>"$LOG_FILE"
                    sudo chmod a+r "$docker_keyring"
                    echo "deb [arch=$(dpkg --print-architecture) signed-by=${docker_keyring}] https://download.docker.com/linux/${DISTRO} ${CODENAME} stable" | sudo tee "$docker_list" > /dev/null
                    sudo apt update &>>"$LOG_FILE" 2>&1
                    if sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>>"$LOG_FILE" 2>&1; then
                        sudo usermod -aG docker "$USER" 2>/dev/null
                        ok "Docker installed."
                    else
                        warn "Docker install failed — cleaning up repo to prevent system issues..."
                        cleanup_repo "$docker_list" "$docker_keyring"
                        fail "Docker"
                    fi
                    ;;
                dnf)  pkg_install "Docker" "sudo dnf install -y docker && sudo systemctl enable --now docker && sudo usermod -aG docker \$USER" ;;
                pacman) pkg_install "Docker" "sudo pacman -S --noconfirm docker docker-compose && sudo systemctl enable --now docker && sudo usermod -aG docker \$USER" ;;
            esac ;;
        postman)    skip_installed "Postman" "postman" && return
                    install_from_map "postman" "Postman" ;;
        cmake)      skip_installed "CMake" "cmake" && return
                    install_from_map "cmake" "CMake" ;;
        gh)
            # apt: keep custom Microsoft-style repo fallback. Everything else: map.
            if [[ "$PKG" == "apt" ]]; then
                pkg_install "GitHub CLI" "sudo apt install -y gh || (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt update && sudo apt install -y gh)"
            else
                install_from_map "gh" "GitHub CLI"
            fi ;;
        nvm)    info "nvm is installed automatically with Node.js selection." ;;
        pyenv)
            step "Installing pyenv..."
            curl https://pyenv.run | bash &>>"$LOG_FILE" && ok "pyenv installed." || fail "pyenv"
            ;;
        wsl)    info "WSL is Windows-only." ;;
        terminal) info "Windows Terminal is Windows-only." ;;
        *) fail "Unknown tool: $key" ;;
    esac
}

# ================================================================
# FRAMEWORK / LIBRARY INSTALLERS
# ================================================================
install_framework() {
    local key="$1"
    case "$key" in
        # JS/TS Package Managers
        npm)        step "Updating npm..."; npm install -g npm@latest &>>"$LOG_FILE" && ok "npm updated." || fail "npm" ;;
        yarn)       step "Installing Yarn..."; npm install -g yarn &>>"$LOG_FILE" && ok "Yarn installed." || fail "Yarn" ;;
        pnpm)       step "Installing pnpm..."; npm install -g pnpm &>>"$LOG_FILE" && ok "pnpm installed." || fail "pnpm" ;;
        bun)
            step "Installing Bun..."
            case "$PKG" in
                brew) brew install oven-sh/bun/bun &>>"$LOG_FILE" && ok "Bun installed." || fail "Bun" ;;
                *)    curl -fsSL https://bun.sh/install | bash &>>"$LOG_FILE" && ok "Bun installed." || fail "Bun" ;;
            esac ;;

        # Python Package Managers
        uv)         step "Installing uv..."; (pip3 install --break-system-packages uv 2>/dev/null || pip install --break-system-packages uv 2>/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh) &>>"$LOG_FILE" 2>&1 && ok "uv installed." || fail "uv" ;;
        poetry)     step "Installing Poetry..."; (curl -sSL https://install.python-poetry.org | python3 -) &>>"$LOG_FILE" 2>&1 && ok "Poetry installed." || fail "Poetry" ;;
        pipx)       step "Installing pipx..."; (pip3 install --break-system-packages --user pipx 2>/dev/null || pip install --break-system-packages --user pipx) &>>"$LOG_FILE" 2>&1 && ok "pipx installed." || fail "pipx" ;;
        conda)
            step "Installing Miniconda..."
            case "$PKG" in
                brew) brew install --cask miniconda &>>"$LOG_FILE" && ok "Miniconda installed." || fail "Miniconda" ;;
                *)
                    local ARCH; ARCH=$(uname -m)
                    local OS_STR="Linux"
                    [[ "$OS_TYPE" == "macos" ]] && OS_STR="MacOSX"
                    curl -fsSL "https://repo.anaconda.com/miniconda/Miniconda3-latest-${OS_STR}-${ARCH}.sh" -o /tmp/miniconda.sh &>>"$LOG_FILE"
                    bash /tmp/miniconda.sh -b -p "$HOME/miniconda3" &>>"$LOG_FILE" && ok "Miniconda installed." || fail "Miniconda"
                    rm -f /tmp/miniconda.sh ;;
            esac ;;
        venvstudio) step "Installing VenvStudio..."; (pip3 install --break-system-packages VenvStudio 2>/dev/null || pip install --break-system-packages VenvStudio) &>>"$LOG_FILE" 2>&1 && ok "VenvStudio installed." || fail "VenvStudio" ;;

        # JS/TS Frameworks
        react)      step "Installing React (create-react-app)..."; npm install -g create-react-app &>>"$LOG_FILE" && ok "React CLI installed." || fail "React" ;;
        nextjs)     step "Installing Next.js (create-next-app)..."; npm install -g create-next-app &>>"$LOG_FILE" && ok "Next.js CLI installed." || fail "Next.js" ;;
        vue)        step "Installing Vue CLI..."; npm install -g @vue/cli &>>"$LOG_FILE" && ok "Vue CLI installed." || fail "Vue CLI" ;;
        nuxt)       step "Installing Nuxt (nuxi)..."; npm install -g nuxi &>>"$LOG_FILE" && ok "Nuxt CLI installed." || fail "Nuxt" ;;
        angular)    step "Installing Angular CLI..."; npm install -g @angular/cli &>>"$LOG_FILE" && ok "Angular CLI installed." || fail "Angular CLI" ;;
        svelte)     step "Installing SvelteKit..."; npm install -g create-svelte &>>"$LOG_FILE" && ok "SvelteKit installed." || fail "SvelteKit" ;;
        vite)       step "Installing Vite..."; npm install -g create-vite &>>"$LOG_FILE" && ok "Vite installed." || fail "Vite" ;;
        astro)      step "Installing Astro..."; npm install -g create-astro &>>"$LOG_FILE" && ok "Astro installed." || fail "Astro" ;;
        express)    step "Installing Express.js..."; npm install -g express-generator &>>"$LOG_FILE" && ok "Express.js installed." || fail "Express.js" ;;
        nest)       step "Installing NestJS CLI..."; npm install -g @nestjs/cli &>>"$LOG_FILE" && ok "NestJS installed." || fail "NestJS" ;;
        remix)      step "Installing Remix..."; npm install -g create-remix &>>"$LOG_FILE" && ok "Remix installed." || fail "Remix" ;;

        # Python Frameworks
        django)     step "Installing Django..."; (pip3 install --break-system-packages django 2>/dev/null || pip install --break-system-packages django) &>>"$LOG_FILE" 2>&1 && ok "Django installed." || fail "Django" ;;
        flask)      step "Installing Flask..."; (pip3 install --break-system-packages flask 2>/dev/null || pip install --break-system-packages flask) &>>"$LOG_FILE" 2>&1 && ok "Flask installed." || fail "Flask" ;;
        fastapi)    step "Installing FastAPI..."; (pip3 install --break-system-packages fastapi uvicorn 2>/dev/null || pip install --break-system-packages fastapi uvicorn) &>>"$LOG_FILE" 2>&1 && ok "FastAPI installed." || fail "FastAPI" ;;
        streamlit)  step "Installing Streamlit..."; (pip3 install --break-system-packages streamlit 2>/dev/null || pip install --break-system-packages streamlit) &>>"$LOG_FILE" 2>&1 && ok "Streamlit installed." || fail "Streamlit" ;;

        # CSS/UI
        tailwind)   step "Installing Tailwind CSS..."; npm install -g tailwindcss &>>"$LOG_FILE" && ok "Tailwind CSS installed." || fail "Tailwind CSS" ;;
        bootstrap)  step "Installing Bootstrap..."; npm install -g bootstrap &>>"$LOG_FILE" && ok "Bootstrap installed." || fail "Bootstrap" ;;

        # Mobile/Cross-platform
        reactnative) step "Installing React Native CLI..."; npm install -g react-native-cli &>>"$LOG_FILE" && ok "React Native CLI installed." || fail "React Native" ;;
        expo)       step "Installing Expo CLI..."; npm install -g expo-cli &>>"$LOG_FILE" && ok "Expo CLI installed." || fail "Expo" ;;
        ionic)      step "Installing Ionic CLI..."; npm install -g @ionic/cli &>>"$LOG_FILE" && ok "Ionic CLI installed." || fail "Ionic" ;;
        electron)   step "Installing Electron Forge..."; npm install -g @electron-forge/cli &>>"$LOG_FILE" && ok "Electron Forge installed." || fail "Electron" ;;
        tauri)      step "Installing Tauri CLI..."; npm install -g @tauri-apps/cli &>>"$LOG_FILE" && ok "Tauri CLI installed." || fail "Tauri" ;;

        # Rust Ecosystem
        cargo-watch) step "Installing cargo-watch..."; cargo install cargo-watch &>>"$LOG_FILE" 2>&1 && ok "cargo-watch installed." || fail "cargo-watch" ;;
        wasm-pack)  step "Installing wasm-pack..."; cargo install wasm-pack &>>"$LOG_FILE" 2>&1 && ok "wasm-pack installed." || fail "wasm-pack" ;;

        # .NET info
        blazor)     info "Blazor is included in .NET SDK - use: dotnet new blazor" ;;
        maui)       info ".NET MAUI - install via: dotnet workload install maui" ;;

        # DevOps/Infra
        terraform)
            case "$PKG" in
                brew) pkg_install "Terraform" "brew install terraform" ;;
                *)    pkg_install "Terraform" "sudo snap install terraform --classic 2>/dev/null || (curl -fsSL https://releases.hashicorp.com/terraform/1.9.0/terraform_1.9.0_linux_amd64.zip -o /tmp/tf.zip && sudo unzip -o /tmp/tf.zip -d /usr/local/bin/)" ;;
            esac ;;
        kubectl)
            case "$PKG" in
                brew) pkg_install "kubectl" "brew install kubectl" ;;
                *)    pkg_install "kubectl" "sudo snap install kubectl --classic 2>/dev/null || (curl -LO 'https://dl.k8s.io/release/\$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl' && sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl)" ;;
            esac ;;
        helm)
            case "$PKG" in
                brew) pkg_install "Helm" "brew install helm" ;;
                *)    pkg_install "Helm" "sudo snap install helm --classic 2>/dev/null || (curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash)" ;;
            esac ;;

        *) fail "Unknown framework: $key" ;;
    esac
}

# ================================================================
# UNINSTALL FUNCTIONS
# ================================================================

# --- Complex uninstallers for external installers ---------------

uninstall_rust() {
    if ! is_cmd rustc && ! is_cmd rustup && [[ ! -d "$HOME/.cargo" && ! -d "$HOME/.rustup" ]]; then
        info "Rust not installed."
        return
    fi
    # rustup ships its own self-uninstall which cleans ~/.cargo and ~/.rustup
    if is_cmd rustup; then
        step "Removing Rust via rustup..."
        rustup self uninstall -y &>>"$LOG_FILE" && ok "Rust removed." || fail "Rust (rustup self uninstall)"
        # rustup already removes ~/.cargo and ~/.rustup, so config prompt not needed
        return
    fi
    # No rustup — fall back to native uninstall + config prompt
    uninstall_native "rust" "Rust"
    remove_user_configs "rust" "Rust"
}

uninstall_nodejs() {
    if ! is_cmd node && [[ ! -d "$HOME/.nvm" ]]; then
        info "Node.js not installed."
        return
    fi
    # NVM-based uninstall
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        step "Removing Node.js via nvm..."
        # nvm has no self-uninstall — just remove its directory
        rm -rf "$HOME/.nvm" &>>"$LOG_FILE" && ok "nvm removed."
        # Also remove nvm lines from shell rc files
        for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
            [[ -f "$rc" ]] && sed -i '/NVM_DIR\|nvm.sh\|bash_completion/d' "$rc" 2>>"$LOG_FILE"
        done
        info "nvm lines removed from shell rc files."
    fi
    # Try native uninstall as well (some distros install node via pkg manager)
    if is_cmd node && [[ -z "${NVM_DIR:-}" ]]; then
        # PKG_MAP doesn't have "nodejs" but distros install as "nodejs" or "node"
        case "$PKG" in
            apt)    pkg_uninstall "Node.js" "sudo apt remove -y nodejs npm" ;;
            dnf)    pkg_uninstall "Node.js" "sudo dnf remove -y nodejs npm" ;;
            pacman) pkg_uninstall "Node.js" "sudo pacman -Rns --noconfirm nodejs npm" ;;
            zypper) pkg_uninstall "Node.js" "sudo zypper remove -y nodejs npm" ;;
            brew)   pkg_uninstall "Node.js" "brew uninstall node" ;;
        esac
    fi
    remove_user_configs "nodejs" "Node.js"
}

uninstall_kotlin() {
    if ! is_cmd kotlin && [[ ! -d "$HOME/.sdkman" ]]; then
        info "Kotlin not installed."
        return
    fi
    # SDKMAN-based uninstall
    if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && is_cmd sdk 2>/dev/null; then
        step "Removing Kotlin via SDKMAN..."
        # shellcheck disable=SC1091
        source "$HOME/.sdkman/bin/sdkman-init.sh"
        sdk uninstall kotlin &>>"$LOG_FILE" && ok "Kotlin removed via SDKMAN."
    fi
    # Native fallback
    case "$PKG" in
        brew)   is_cmd kotlin && pkg_uninstall "Kotlin" "brew uninstall kotlin" ;;
        pacman) is_cmd kotlin && pkg_uninstall "Kotlin" "sudo pacman -Rns --noconfirm kotlin" ;;
    esac
    # Ask about full SDKMAN removal (which also affects Groovy, Scala, etc.)
    if [[ -d "$HOME/.sdkman" ]]; then
        echo "" >&2
        echo -e "  ${YELLOW}SDKMAN directory exists: $HOME/.sdkman${NC}" >&2
        echo -e "  ${GRAY}(Warning: this is shared with Groovy, Scala, Java-via-SDKMAN)${NC}" >&2
        read -rp "  Remove entire SDKMAN? [y/N]: " sdk_choice
        if [[ "$sdk_choice" == "y" || "$sdk_choice" == "Y" ]]; then
            rm -rf "$HOME/.sdkman" && ok "SDKMAN removed."
            for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                [[ -f "$rc" ]] && sed -i '/SDKMAN_DIR\|sdkman-init.sh/d' "$rc" 2>>"$LOG_FILE"
            done
        fi
    fi
}

uninstall_java() {
    if ! is_cmd java && [[ ! -d "$HOME/.jenv" ]]; then
        info "Java not installed."
        return
    fi
    # jenv cleanup
    if [[ -d "$HOME/.jenv" ]]; then
        step "Removing jenv..."
        rm -rf "$HOME/.jenv"
        for rc in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
            [[ -f "$rc" ]] && sed -i '/jenv/d' "$rc" 2>>"$LOG_FILE"
        done
        ok "jenv removed."
    fi
    # Native JDK uninstall — try common package names per distro
    case "$PKG" in
        apt)
            local java_pkgs
            java_pkgs=$(dpkg -l 'openjdk-*-jdk' 2>/dev/null | awk '/^ii/ {print $2}' | tr '\n' ' ')
            [[ -n "$java_pkgs" ]] && pkg_uninstall "Java (JDK)" "sudo apt remove -y $java_pkgs"
            ;;
        dnf)
            pkg_uninstall "Java (JDK)" "sudo dnf remove -y 'java-*-openjdk-devel' 'java-*-openjdk'"
            ;;
        pacman)
            local jdk_pkgs
            jdk_pkgs=$(pacman -Qq 2>/dev/null | grep -E '^jdk-?[0-9]+-openjdk$|^jre-?[0-9]+-openjdk$' | tr '\n' ' ')
            [[ -n "$jdk_pkgs" ]] && pkg_uninstall "Java (JDK)" "sudo pacman -Rns --noconfirm $jdk_pkgs"
            ;;
        zypper)
            pkg_uninstall "Java (JDK)" "sudo zypper remove -y 'java-*-openjdk-devel' 'java-*-openjdk'"
            ;;
        brew)
            is_cmd java && pkg_uninstall "Java (JDK)" "brew uninstall --cask temurin"
            ;;
    esac
    remove_user_configs "java" "Java"
}

# --- Uninstall dispatcher ---------------------------------------
# Routes a package key to the right uninstall function.
# For simple map-based packages, uses uninstall_from_map + config prompt.
# For complex packages, delegates to a dedicated uninstall_* function.
uninstall_package() {
    local key="$1" display_name="${2:-$1}"

    case "$key" in
        # --- Complex external installers (Phase 1: implemented) ---
        rust)     uninstall_rust ;;
        nodejs)   uninstall_nodejs ;;
        kotlin)   uninstall_kotlin ;;
        java)     uninstall_java ;;

        # --- Complex external installers (Phase 2: deferred) ---
        python|php|ruby|go|dart|swift|julia|haskell|scala|nim|v|gleam|typescript|zig|mojo|wasm|solidity|groovy|carbon|csharp)
            warn "$display_name uninstall not yet implemented (Phase 2)."
            info "Manual removal hints:"
            case "$key" in
                python)  info "  pyenv: rm -rf ~/.pyenv; system Python: $PKG remove python3" ;;
                go)      info "  rm -rf /usr/local/go ~/go; then $PKG remove go" ;;
                haskell) info "  ghcup nuke; or rm -rf ~/.ghcup ~/.cabal ~/.stack" ;;
                julia)   info "  juliaup self uninstall" ;;
                scala)   info "  cs uninstall scala; rm -rf ~/.sbt ~/.coursier" ;;
                nim)     info "  rm -rf ~/.choosenim ~/.nimble" ;;
                dart)    info "  $PKG remove dart; rm -rf ~/.pub-cache ~/.dart-tool" ;;
                swift)   info "  rm -rf /opt/swift or /usr/local/swift" ;;
                typescript) info "  npm uninstall -g typescript" ;;
                *)       info "  Check installer docs for $display_name" ;;
            esac
            ;;

        # --- Simple map-based packages (native uninstall) ---
        *)
            uninstall_from_map "$key" "$display_name"
            # Prompt for config removal if CONFIG_MAP has entry
            [[ -n "${CONFIG_MAP[$key]:-}" ]] && remove_user_configs "$key" "$display_name"
            ;;
    esac
}

# --- Detect whether a key's package is currently installed ------
# Maps a package key to a detection command and returns 0 if installed.
# Simple probe — used only by uninstall menu.
_installed_marker() {
    local key="$1"
    local cmd
    case "$key" in
        # Languages
        python)      cmd="python3" ;;
        nodejs)      cmd="node" ;;
        java)        cmd="java" ;;
        csharp)      cmd="dotnet" ;;
        cpp)         cmd="gcc" ;;
        go)          cmd="go" ;;
        rust)        cmd="rustc" ;;
        php)         cmd="php" ;;
        ruby)        cmd="ruby" ;;
        kotlin)      cmd="kotlin" ;;
        dart)        cmd="dart" ;;
        swift)       cmd="swift" ;;
        zig)         cmd="zig" ;;
        typescript)  cmd="tsc" ;;
        elixir)      cmd="elixir" ;;
        scala)       cmd="scala" ;;
        julia)       cmd="julia" ;;
        r)           cmd="R" ;;
        lua)         cmd="lua" ;;
        haskell)     cmd="ghc" ;;
        perl)        cmd="perl" ;;
        erlang)      cmd="erl" ;;
        ocaml)       cmd="ocaml" ;;
        fortran)     cmd="gfortran" ;;
        d)           cmd="ldc2" ;;
        nim)         cmd="nim" ;;
        crystal)     cmd="crystal" ;;
        v)           cmd="v" ;;
        gleam)       cmd="gleam" ;;
        solidity)    cmd="solc" ;;
        groovy)      cmd="groovy" ;;
        ada)         cmd="gnat" ;;
        cobol)       cmd="cobc" ;;
        lisp)        cmd="sbcl" ;;
        racket)      cmd="racket" ;;
        objc)        is_cmd gobjc || is_cmd clang; return $? ;;
        mojo|wasm|carbon) return 1 ;;  # No single detection command
        # IDEs
        vscode)      cmd="code" ;;
        vscodium)    cmd="codium" ;;
        cursor)      cmd="cursor" ;;
        zed)         cmd="zed" ;;
        sublime)     cmd="subl" ;;
        vim)         cmd="nvim" ;;
        classicvim)  cmd="vim" ;;
        emacs)       cmd="emacs" ;;
        windsurf)    cmd="windsurf" ;;
        antigravity) cmd="antigravity" ;;
        intellij)    is_cmd idea || is_cmd intellij-idea-community; return $? ;;
        pycharm)     cmd="pycharm" ;;
        webstorm)    cmd="webstorm" ;;
        goland)      cmd="goland" ;;
        clion)       cmd="clion" ;;
        rider)       cmd="rider" ;;
        rustrover)   cmd="rustrover" ;;
        fleet)       cmd="fleet" ;;
        eclipse)     cmd="eclipse" ;;
        netbeans)    cmd="netbeans" ;;
        android)     cmd="studio" ;;
        notepadpp)   return 1 ;;  # Windows only
        # Tools
        git)         cmd="git" ;;
        docker)      cmd="docker" ;;
        postman)     cmd="postman" ;;
        cmake)       cmd="cmake" ;;
        gh)          cmd="gh" ;;
        pyenv)       cmd="pyenv" ;;
        *)           cmd="$key" ;;
    esac
    is_cmd "$cmd"
}

# --- Interactive uninstall selection menu -----------------------
# Shows currently-installed packages and lets user pick which to remove.
show_uninstall_menu() {
    # Combine all category keys/labels for lookup
    local -a all_keys=("${LANG_KEYS[@]}" "${IDE_KEYS[@]}" "${TOOL_KEYS[@]}")
    local -a all_labels=("${LANG_LABELS[@]}" "${IDE_LABELS[@]}" "${TOOL_LABELS[@]}")

    # Filter to installed ones only
    local -a installed_keys=() installed_labels=()
    local i
    for i in "${!all_keys[@]}"; do
        if _installed_marker "${all_keys[$i]}"; then
            installed_keys+=("${all_keys[$i]}")
            installed_labels+=("${all_labels[$i]}")
        fi
    done

    if ((${#installed_keys[@]} == 0)); then
        warn "No installed packages detected. Nothing to uninstall."
        return 1
    fi

    section "Uninstall — Select Packages" >&2
    echo "" >&2
    for i in "${!installed_keys[@]}"; do
        printf "  ${BOLD}[%2d]${NC} %s\n" "$((i+1))" "${installed_labels[$i]}" >&2
    done
    echo "" >&2
    echo -e "  ${GRAY}Space-separated numbers to select multiple (e.g. 1 3 5), or empty to cancel${NC}" >&2
    echo "" >&2
    read -rp "  Uninstall which? " nums

    [[ -z "$nums" ]] && { info "Uninstall cancelled."; return 1; }

    # Confirm
    echo "" >&2
    echo -e "  ${YELLOW}The following will be uninstalled:${NC}" >&2
    local n
    for n in $nums; do
        [[ ! "$n" =~ ^[0-9]+$ ]] && continue
        local idx=$((n-1))
        (( idx < 0 || idx >= ${#installed_keys[@]} )) && continue
        echo -e "    ${GRAY}- ${installed_labels[$idx]}${NC}" >&2
    done
    echo "" >&2
    read -rp "  Proceed with uninstall? [y/N]: " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { info "Uninstall cancelled."; return 1; }
    echo "" >&2

    # Execute
    for n in $nums; do
        [[ ! "$n" =~ ^[0-9]+$ ]] && continue
        local idx=$((n-1))
        (( idx < 0 || idx >= ${#installed_keys[@]} )) && continue
        local key="${installed_keys[$idx]}"
        local label="${installed_labels[$idx]}"
        # Extract just the name (before " - ")
        local display_name="${label%% - *}"
        section "Uninstalling: $display_name" >&2
        uninstall_package "$key" "$display_name"
        echo "" >&2
    done

    return 0
}

# --- Action menu (Install/Uninstall/Exit) -----------------------
show_action_menu() {
    section "What would you like to do?" >&2
    echo "" >&2
    echo -e "  ${BOLD}[1]${NC}  Install    ${GRAY}- Set up development environment${NC}" >&2
    echo -e "  ${BOLD}[2]${NC}  Uninstall  ${GRAY}- Remove installed packages${NC}" >&2
    echo -e "  ${BOLD}[3]${NC}  Exit${NC}" >&2
    echo "" >&2
    read -rp "  Choose [1/2/3]: " action_choice
    echo "$action_choice"
}

# ================================================================
# PROFILES
# ================================================================
show_profile_menu() {
    section "Quick Setup Profiles" >&2
    echo "" >&2
    echo -e "  ${BOLD}${CYAN}--- Popular Stacks ---${NC}" >&2
    echo -e "  ${BOLD}[1]${NC}  Web Frontend        ${GRAY}- Node.js, TypeScript + VS Code, Zed + React, Vue, Tailwind, Vite${NC}" >&2
    echo -e "  ${BOLD}[2]${NC}  Web Full Stack       ${GRAY}- Node.js, Python, TypeScript + VS Code + React, Next.js, Express, Django${NC}" >&2
    echo -e "  ${BOLD}[3]${NC}  Mobile Developer     ${GRAY}- Java, Kotlin, Dart/Flutter, Swift + Android Studio, VS Code${NC}" >&2
    echo -e "  ${BOLD}[4]${NC}  Data Scientist       ${GRAY}- Python, R, Julia + VS Code, PyCharm + VenvStudio, uv, Conda, Streamlit${NC}" >&2
    echo -e "  ${BOLD}[5]${NC}  AI / ML Engineer     ${GRAY}- Python, Mojo, Rust, Julia + VS Code, PyCharm, Cursor + VenvStudio, uv, FastAPI${NC}" >&2
    echo -e "  ${BOLD}[6]${NC}  Systems Programmer   ${GRAY}- C/C++, Rust, Zig, Go + VS Code, CLion, Neovim + CMake, cargo-watch${NC}" >&2
    echo -e "  ${BOLD}[7]${NC}  Full Stack .NET      ${GRAY}- C#/.NET, Node.js, TypeScript + Visual Studio, VS Code + React, Next.js${NC}" >&2
    echo -e "  ${BOLD}[8]${NC}  Game Developer       ${GRAY}- C/C++, C#, Lua + Visual Studio, VS Code, Rider + CMake${NC}" >&2
    echo "" >&2
    echo -e "  ${BOLD}${CYAN}--- Specialized ---${NC}" >&2
    echo -e "  ${BOLD}[9]${NC}  DevOps / Cloud       ${GRAY}- Python, Go, Rust + VS Code, Neovim + Docker, Terraform, kubectl, Helm${NC}" >&2
    echo -e "  ${BOLD}[10]${NC} Blockchain / Web3    ${GRAY}- Solidity, Rust, TypeScript + VS Code, Cursor + Node.js, npm${NC}" >&2
    echo -e "  ${BOLD}[11]${NC} Embedded / IoT       ${GRAY}- C/C++, Rust, Python, Lua + VS Code, CLion, Neovim + CMake${NC}" >&2
    echo -e "  ${BOLD}[12]${NC} Scientific Computing ${GRAY}- Fortran, Python, R, Julia, Haskell + VS Code, Emacs + VenvStudio, uv${NC}" >&2
    echo -e "  ${BOLD}[13]${NC} Functional Programmer ${GRAY}- Haskell, Elixir, Erlang, OCaml, Scala, Gleam + VS Code, Emacs, Neovim${NC}" >&2
    echo -e "  ${BOLD}[14]${NC} JVM Ecosystem        ${GRAY}- Java, Kotlin, Scala, Groovy + IntelliJ, Eclipse, NetBeans${NC}" >&2
    echo -e "  ${BOLD}[15]${NC} Minimalist / Terminal ${GRAY}- Go, Rust, Python + Neovim, Vim, Emacs + Git only${NC}" >&2
    echo "" >&2
    echo -e "  ${BOLD}[16]${NC} Custom Setup         ${GRAY}- Choose your own languages, versions, and IDEs${NC}" >&2
    echo -e "  ${RED}[17] INSTALL EVERYTHING ${GRAY}- All languages, IDEs, tools, frameworks${NC}" >&2
    echo "" >&2
    echo -e "  ${GRAY}You can select multiple profiles separated by spaces (e.g. 1 5 9)${NC}" >&2
    echo "" >&2
    read -rp "  Select profile(s): " choice
    echo "$choice"
}

# ================================================================
# SYSTEM SCAN - Auto-detect installed software and versions
# ================================================================
get_cmd_version() {
    local cmd="$1" flag="${2:---version}"
    if ! command -v "$cmd" &>/dev/null; then echo ""; return; fi
    local ver
    ver=$("$cmd" $flag 2>&1 | head -3 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    [[ -n "$ver" ]] && echo "$ver" || echo "found"
}

system_scan() {
    section "System Scan"
    echo -e "  ${GRAY}Scanning your system for installed software...${NC}"
    echo ""

    # Detect languages
    local py_ver=$(get_cmd_version python3)
    [[ -z "$py_ver" ]] && py_ver=$(get_cmd_version python)
    local node_ver=""
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh" 2>/dev/null
        node_ver=$(get_cmd_version node "-v" | sed 's/^v//')
    else
        node_ver=$(get_cmd_version node "-v" | sed 's/^v//')
    fi
    local java_ver=$(java -version 2>&1 | head -1 | grep -oP '\d+[\.\d]*' | head -1)
    local dotnet_ver=$(get_cmd_version dotnet "--version")
    local gcc_ver=$(get_cmd_version gcc "--version")
    local go_ver=$(get_cmd_version go "version" | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    [[ -z "$go_ver" ]] && go_ver=$(go version 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local rust_ver=""
    [[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env" 2>/dev/null
    rust_ver=$(get_cmd_version rustc "--version")
    local php_ver=$(get_cmd_version php "--version")
    local ruby_ver=$(get_cmd_version ruby "--version")
    local kotlin_ver=$(get_cmd_version kotlin "-version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local dart_ver=$(get_cmd_version dart "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local zig_ver=$(get_cmd_version zig "version")
    local ts_ver=$(get_cmd_version tsc "--version")
    local elixir_ver=$(get_cmd_version elixir "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local scala_ver=$(get_cmd_version scala "-version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local julia_ver=$(get_cmd_version julia "--version")
    local swift_ver=$(get_cmd_version swift "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local mojo_ver=$(get_cmd_version mojo "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local flutter_ver=$(get_cmd_version flutter "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local wasmtime_ver=$(get_cmd_version wasmtime "--version")
    local wasmer_ver=$(get_cmd_version wasmer "--version")
    local r_ver=$(get_cmd_version R "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local lua_ver=$(get_cmd_version lua "-v" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local ghc_ver=$(get_cmd_version ghc "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local perl_ver=$(get_cmd_version perl "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local erlang_ver=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null | tr -d '"')
    local ocaml_ver=$(get_cmd_version ocaml "--version")
    local gfortran_ver=$(get_cmd_version gfortran "--version")
    local dmd_ver=$(get_cmd_version ldc2 "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local nim_ver=$(get_cmd_version nim "--version")
    local crystal_ver=$(get_cmd_version crystal "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local vlang_ver=$(get_cmd_version v "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local gleam_ver=$(get_cmd_version gleam "--version")
    local solc_ver=$(get_cmd_version solcjs "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local groovy_ver=$(get_cmd_version groovy "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local gnat_ver=$(get_cmd_version gnat "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local cobc_ver=$(get_cmd_version cobc "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local sbcl_ver=$(get_cmd_version sbcl "--version")
    local racket_ver=$(get_cmd_version racket "--version" 2>&1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local objc_ver="" && command -v gobjc &>/dev/null && objc_ver="installed"
    [[ -z "$objc_ver" ]] && command -v clang &>/dev/null && objc_ver="via clang"

    # Detect IDEs/Editors
    local code_ver=$(get_cmd_version code "--version" 2>/dev/null | head -1)
    local codium_ver=$(get_cmd_version codium "--version" 2>/dev/null | head -1)
    local nvim_ver=$(get_cmd_version nvim "--version")
    local vim_ver=$(get_cmd_version vim "--version" 2>&1 | grep -oP '\d+\.\d+' | head -1)
    local cursor_ver="" && command -v cursor &>/dev/null && cursor_ver="installed"
    local sublime_ver="" && command -v subl &>/dev/null && sublime_ver="installed"
    local emacs_ver=$(get_cmd_version emacs "--version")
    local zed_ver="" && command -v zed &>/dev/null && zed_ver="installed"
    local windsurf_ver="" && command -v windsurf &>/dev/null && windsurf_ver="installed"
    local antigravity_ver="" && command -v antigravity &>/dev/null && antigravity_ver="installed"
    local fleet_ver="" && command -v fleet &>/dev/null && fleet_ver="installed"
    local idea_ver="" && (command -v idea &>/dev/null || command -v intellij-idea-community &>/dev/null) && idea_ver="installed"
    local pycharm_ver="" && command -v pycharm &>/dev/null && pycharm_ver="installed"
    local webstorm_ver="" && command -v webstorm &>/dev/null && webstorm_ver="installed"
    local goland_ver="" && command -v goland &>/dev/null && goland_ver="installed"
    local clion_ver="" && command -v clion &>/dev/null && clion_ver="installed"
    local rider_ver="" && command -v rider &>/dev/null && rider_ver="installed"
    local rustrover_ver="" && command -v rustrover &>/dev/null && rustrover_ver="installed"
    local eclipse_ver="" && command -v eclipse &>/dev/null && eclipse_ver="installed"
    local netbeans_ver="" && command -v netbeans &>/dev/null && netbeans_ver="installed"
    local android_ver="" && (command -v studio &>/dev/null || command -v android-studio &>/dev/null) && android_ver="installed"
    local notepadpp_ver="" && command -v notepad++ &>/dev/null && notepadpp_ver="installed"

    # Detect tools
    local git_ver=$(get_cmd_version git "--version")
    local docker_ver=$(get_cmd_version docker "--version")
    local cmake_ver=$(get_cmd_version cmake "--version")
    local gh_ver=$(get_cmd_version gh "--version")

    # Detect package managers / frameworks
    local npm_ver=$(get_cmd_version npm "--version")
    local yarn_ver=$(get_cmd_version yarn "--version")
    local pnpm_ver=$(get_cmd_version pnpm "--version")
    local bun_ver=$(get_cmd_version bun "--version")
    local uv_ver=$(get_cmd_version uv "--version")
    local poetry_ver=$(get_cmd_version poetry "--version")
    local conda_ver=$(get_cmd_version conda "--version")
    local pip_ver=$(get_cmd_version pip3 "--version")
    [[ -z "$pip_ver" ]] && pip_ver=$(get_cmd_version pip "--version")
    local terraform_ver=$(get_cmd_version terraform "--version")
    local kubectl_ver=$(get_cmd_version kubectl "version --client --short" 2>/dev/null | grep -oP '\d+\.\d+[\.\d]*' | head -1)
    local helm_ver=$(get_cmd_version helm "version --short" 2>/dev/null | grep -oP '\d+\.\d+[\.\d]*' | head -1)

    # Latest versions (our recommendations)
    declare -A LATEST=(
        [python]="latest" [nodejs]="latest" [java]="latest" [dotnet]="latest" [gcc]="—"
        [go]="latest" [rust]="latest" [php]="latest" [ruby]="latest" [kotlin]="latest"
        [dart]="latest" [zig]="latest" [typescript]="latest" [elixir]="latest"
        [scala]="latest" [julia]="latest" [swift]="latest"
        [vscode]="latest" [nvim]="latest" [git]="latest" [docker]="latest"
        [cmake]="latest" [gh]="latest"
        [npm]="latest" [yarn]="latest" [pnpm]="latest" [bun]="latest"
        [uv]="latest" [poetry]="latest" [conda]="latest"
        [terraform]="latest" [kubectl]="latest" [helm]="latest"
    )

    # Display function
    show_item() {
        local name="$1" current="$2" recommended="$3" width=16
        local padded
        padded=$(printf "%-${width}s" "$name")
        if [[ -z "$current" ]]; then
            echo -e "    ${GRAY}${padded}${NC}  ${GRAY}—  not installed${NC}"
        elif [[ "$current" == "installed" || "$current" == "found" ]]; then
            echo -e "    ${GREEN}${padded}${NC}  ${GREEN}yes${NC}"
        elif [[ "$recommended" == "latest" || "$recommended" == "—" ]]; then
            echo -e "    ${GREEN}${padded}${NC}  ${GREEN}${current}${NC}"
        elif [[ "$current" == "$recommended"* ]]; then
            echo -e "    ${GREEN}${padded}${NC}  ${GREEN}${current}${NC}  ${GREEN}up to date${NC}"
        else
            echo -e "    ${YELLOW}${padded}${NC}  ${YELLOW}${current}${NC}  ${CYAN}⬆ ${recommended} available${NC}"
        fi
    }

    # Print scan results
    echo -e "  ${BOLD}${CYAN}Languages and Runtimes:${NC}"
    show_item "Python"     "$py_ver"     "${LATEST[python]}"
    show_item "Node.js"    "$node_ver"   "${LATEST[nodejs]}"
    show_item "Java (JDK)" "$java_ver"   "${LATEST[java]}"
    show_item ".NET SDK"   "$dotnet_ver" "${LATEST[dotnet]}"
    show_item "C/C++ (GCC)" "$gcc_ver"   "${LATEST[gcc]}"
    show_item "Go"         "$go_ver"     "${LATEST[go]}"
    show_item "Rust"       "$rust_ver"   "${LATEST[rust]}"
    show_item "PHP"        "$php_ver"    "${LATEST[php]}"
    show_item "Ruby"       "$ruby_ver"   "${LATEST[ruby]}"
    show_item "Kotlin"     "$kotlin_ver" "${LATEST[kotlin]}"
    show_item "Dart"       "$dart_ver"   "${LATEST[dart]}"
    show_item "Swift"      "$swift_ver"  "${LATEST[swift]}"
    show_item "Zig"        "$zig_ver"    "${LATEST[zig]}"
    show_item "Mojo"       "$mojo_ver"   "latest"
    show_item "TypeScript" "$ts_ver"     "${LATEST[typescript]}"
    show_item "Elixir"     "$elixir_ver" "${LATEST[elixir]}"
    show_item "Scala"      "$scala_ver"  "${LATEST[scala]}"
    show_item "Julia"      "$julia_ver"  "${LATEST[julia]}"
    local wasm_label=""
    [[ -n "$wasmtime_ver" ]] && wasm_label="wasmtime $wasmtime_ver"
    [[ -n "$wasmer_ver" ]] && wasm_label="${wasm_label:+$wasm_label, }wasmer $wasmer_ver"
    show_item "WebAssembly" "$wasm_label" "latest"
    show_item "Flutter"    "$flutter_ver" "latest"
    show_item "R"          "$r_ver"       "latest"
    show_item "Lua"        "$lua_ver"     "latest"
    show_item "Haskell"    "$ghc_ver"     "latest"
    show_item "Perl"       "$perl_ver"    "latest"
    show_item "Erlang"     "$erlang_ver"  "latest"
    show_item "OCaml"      "$ocaml_ver"   "latest"
    show_item "Fortran"    "$gfortran_ver" "latest"
    show_item "D (LDC)"    "$dmd_ver"     "latest"
    show_item "Nim"        "$nim_ver"     "latest"
    show_item "Crystal"    "$crystal_ver" "latest"
    show_item "V"          "$vlang_ver"   "latest"
    show_item "Gleam"      "$gleam_ver"   "latest"
    show_item "Solidity"   "$solc_ver"    "latest"
    show_item "Groovy"     "$groovy_ver"  "latest"
    show_item "Ada (GNAT)" "$gnat_ver"    "latest"
    show_item "COBOL"      "$cobc_ver"    "latest"
    show_item "Lisp (SBCL)" "$sbcl_ver"  "latest"
    show_item "Racket"     "$racket_ver"  "latest"
    show_item "Obj-C"      "$objc_ver"    "latest"
    echo ""

    echo -e "  ${BOLD}${CYAN}IDEs and Editors:${NC}"
    show_item "VS Code"      "$code_ver"        "latest"
    show_item "VSCodium"     "$codium_ver"      "latest"
    show_item "Antigravity"  "$antigravity_ver" "latest"
    show_item "Cursor"       "$cursor_ver"      "latest"
    show_item "Zed"          "$zed_ver"         "latest"
    show_item "Windsurf"     "$windsurf_ver"    "latest"
    show_item "Sublime"      "$sublime_ver"     "latest"
    show_item "Vim"          "$vim_ver"         "latest"
    show_item "Neovim"       "$nvim_ver"        "latest"
    show_item "GNU Emacs"    "$emacs_ver"       "latest"
    show_item "IntelliJ"     "$idea_ver"        "latest"
    show_item "PyCharm"      "$pycharm_ver"     "latest"
    show_item "WebStorm"     "$webstorm_ver"    "latest"
    show_item "GoLand"       "$goland_ver"      "latest"
    show_item "CLion"        "$clion_ver"       "latest"
    show_item "Rider"        "$rider_ver"       "latest"
    show_item "RustRover"    "$rustrover_ver"   "latest"
    show_item "Fleet"        "$fleet_ver"       "latest"
    show_item "Eclipse"      "$eclipse_ver"     "latest"
    show_item "NetBeans"     "$netbeans_ver"    "latest"
    show_item "Android St."  "$android_ver"     "latest"
    show_item "Notepad++"    "$notepadpp_ver"   "latest"
    echo ""

    echo -e "  ${BOLD}${CYAN}Developer Tools:${NC}"
    show_item "Git"        "$git_ver"    "${LATEST[git]}"
    show_item "Docker"     "$docker_ver" "${LATEST[docker]}"
    show_item "CMake"      "$cmake_ver"  "${LATEST[cmake]}"
    show_item "GitHub CLI" "$gh_ver"     "${LATEST[gh]}"
    echo ""

    echo -e "  ${BOLD}${CYAN}Package Managers:${NC}"
    show_item "npm"        "$npm_ver"    "${LATEST[npm]}"
    show_item "Yarn"       "$yarn_ver"   "${LATEST[yarn]}"
    show_item "pnpm"       "$pnpm_ver"   "${LATEST[pnpm]}"
    show_item "Bun"        "$bun_ver"    "${LATEST[bun]}"
    show_item "uv"         "$uv_ver"     "${LATEST[uv]}"
    show_item "Poetry"     "$poetry_ver" "${LATEST[poetry]}"
    show_item "Conda"      "$conda_ver"  "${LATEST[conda]}"
    show_item "Terraform"  "$terraform_ver" "${LATEST[terraform]}"
    show_item "kubectl"    "$kubectl_ver" "${LATEST[kubectl]}"
    show_item "Helm"       "$helm_ver"   "${LATEST[helm]}"
    echo ""

    # Frameworks — npm globals
    echo -e "  ${BOLD}${CYAN}Frameworks (npm global):${NC}"
    local npm_globals=""
    if command -v npm &>/dev/null; then
        npm_globals=$(npm list -g --depth=0 2>/dev/null | tail -n +2 | sed 's/.*── //' | cut -d@ -f1)
    fi

    check_npm_fw() {
        local name="$1" pkg="$2"
        local status=""
        if echo "$npm_globals" | grep -qiw "$pkg"; then
            status="found"
        fi
        show_item "$name" "$status" "latest"
    }

    check_npm_fw "React (CRA)"    "create-react-app"
    check_npm_fw "Next.js"        "create-next-app"
    check_npm_fw "Vue CLI"        "@vue/cli"
    check_npm_fw "Nuxt (nuxi)"    "nuxi"
    check_npm_fw "Angular CLI"    "@angular/cli"
    check_npm_fw "SvelteKit"      "create-svelte"
    check_npm_fw "Vite"           "create-vite"
    check_npm_fw "Astro"          "create-astro"
    check_npm_fw "Remix"          "create-remix"
    check_npm_fw "Express"        "express-generator"
    check_npm_fw "NestJS"         "@nestjs/cli"
    check_npm_fw "Tailwind CSS"   "tailwindcss"
    check_npm_fw "Bootstrap"      "bootstrap"
    check_npm_fw "React Native"   "react-native-cli"
    check_npm_fw "Expo"           "expo-cli"
    check_npm_fw "Ionic CLI"      "@ionic/cli"
    check_npm_fw "Electron"       "electron"
    echo ""

    # Frameworks — pip packages
    echo -e "  ${BOLD}${CYAN}Frameworks (pip):${NC}"
    local pip_list=""
    if command -v pip3 &>/dev/null; then
        pip_list=$(pip3 list --format=columns 2>/dev/null | tail -n +3 | awk '{print tolower($1)}')
    elif command -v pip &>/dev/null; then
        pip_list=$(pip list --format=columns 2>/dev/null | tail -n +3 | awk '{print tolower($1)}')
    fi

    check_pip_fw() {
        local name="$1" pkg="$2"
        local status=""
        if echo "$pip_list" | grep -qiw "$pkg"; then
            status="found"
        fi
        show_item "$name" "$status" "latest"
    }

    check_pip_fw "Django"      "django"
    check_pip_fw "Flask"       "flask"
    check_pip_fw "FastAPI"     "fastapi"
    check_pip_fw "Streamlit"   "streamlit"
    check_pip_fw "VenvStudio"  "venvstudio"
    echo ""

    # Blazor check
    local blazor_status=""
    [[ -n "$dotnet_ver" ]] && blazor_status="via .NET"
    show_item "Blazor" "$blazor_status" "latest"
    echo ""

    # Count stats
    local installed_count=0 update_count=0 missing_count=0
    for v in "$py_ver" "$node_ver" "$java_ver" "$dotnet_ver" "$gcc_ver" "$go_ver" "$rust_ver" "$php_ver" "$ruby_ver" "$git_ver" "$docker_ver" "$code_ver" "$npm_ver"; do
        if [[ -n "$v" ]]; then
            ((installed_count++))
        else
            ((missing_count++))
        fi
    done

    echo -e "  ${BOLD}────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}✓ ${installed_count} installed${NC}  ${GRAY}|${NC}  ${GRAY}— ${missing_count} not found${NC}"
    echo ""

    # Offer auto-upgrade
    read -rp "  Continue to profile selection? (Y/n): " scan_choice
    [[ "$scan_choice" == "n" || "$scan_choice" == "N" ]] && { info "Exited."; exit 0; }
    echo ""
}
main() {
    print_banner
    echo "CodeReady v2 Install Log - $(date)" > "$LOG_FILE"

    section "System Detection"
    detect_os

    section "Package Manager Setup"
    if [[ "$OS_TYPE" == "macos" ]]; then
        ensure_brew
        ensure_macports
        ensure_nix
    else
        update_pkg
        ensure_flatpak
        ensure_nix
        ensure_aur_helper
    fi

    # System scan - show what's installed
    system_scan

    # Language, IDE, Tool keys (defined before action selector so uninstall menu can see them)
    local LANG_KEYS=("python" "nodejs" "java" "csharp" "cpp" "go" "rust" "php" "ruby" "kotlin" "dart" "swift" "zig" "mojo" "wasm" "typescript" "elixir" "scala" "julia" "r" "lua" "haskell" "perl" "erlang" "ocaml" "fortran" "d" "nim" "crystal" "v" "gleam" "carbon" "solidity" "groovy" "ada" "cobol" "lisp" "racket" "objc")
    local LANG_LABELS=("Python - General purpose, AI/ML" "Node.js - JavaScript/TypeScript runtime" "Java (JDK) - Enterprise, Android" "C# / .NET SDK - Microsoft ecosystem" "C/C++ - Systems programming" "Go - Cloud, microservices" "Rust - Memory safety, systems" "PHP - Web, CMS" "Ruby - Web, scripting" "Kotlin - Android, JVM" "Dart/Flutter - Mobile, web UI" "Swift - Apple ecosystem" "Zig - Next-gen systems, C interop" "Mojo - AI/GPU programming" "WebAssembly (WASI) - Portable binary" "TypeScript - Typed JavaScript" "Elixir - Functional, concurrent" "Scala - JVM functional/OOP" "Julia - Scientific computing" "R - Statistics, data science" "Lua - Scripting, game engines" "Haskell - Pure functional, fintech" "Perl - Text processing, sysadmin" "Erlang - Telecom, distributed systems" "OCaml - Fintech, compilers" "Fortran - Scientific computing, HPC" "D - Systems programming, C++ alt" "Nim - Python-like syntax, compiled" "Crystal - Ruby-like, compiled" "V - Simple systems language" "Gleam - Type-safe BEAM language" "Carbon - Experimental C++ successor" "Solidity - Ethereum smart contracts" "Groovy - JVM scripting, Gradle" "Ada - Safety-critical systems" "COBOL - Banking, legacy systems" "Common Lisp (SBCL) - AI, macros" "Racket - PL research, education" "Objective-C - Legacy Apple dev")

    local IDE_KEYS=("vscode" "vscodium" "antigravity" "cursor" "zed" "windsurf" "sublime" "classicvim" "vim" "emacs" "notepadpp" "intellij" "pycharm" "webstorm" "goland" "clion" "rider" "rustrover" "fleet" "eclipse" "netbeans" "android")
    local IDE_LABELS=("VS Code - Lightweight, extensible" "VSCodium - VS Code without telemetry" "Antigravity - AI-native code editor" "Cursor - AI-powered code editor" "Zed - High-performance editor" "Windsurf - AI-powered IDE" "Sublime Text - Fast, lightweight" "Vim - Classic terminal editor" "Neovim - Modern terminal editor" "GNU Emacs - Extensible text editor" "Notepad++ - Windows code editor" "IntelliJ IDEA Community - Java, Kotlin" "PyCharm Community - Python IDE" "WebStorm - JS/TS IDE (paid)" "GoLand - Go IDE (paid)" "CLion - C/C++ IDE (paid)" "Rider - .NET IDE (paid)" "RustRover - Rust IDE" "JetBrains Fleet - Lightweight multi-lang" "Eclipse IDE - Java, multi-language" "Apache NetBeans - Java, PHP, HTML5" "Android Studio - Android development")

    local TOOL_KEYS=("git" "docker" "postman" "cmake" "gh" "pyenv")
    local TOOL_LABELS=("Git - Version control" "Docker - Containers" "Postman - API testing" "CMake - Build system" "GitHub CLI - GitHub from terminal" "pyenv - Python version manager")

    local FW_KEYS=("npm" "yarn" "pnpm" "bun" "venvstudio" "uv" "poetry" "pipx" "conda" "react" "nextjs" "vue" "nuxt" "angular" "svelte" "vite" "astro" "express" "nest" "remix" "django" "flask" "fastapi" "streamlit" "tailwind" "bootstrap" "reactnative" "expo" "ionic" "electron" "tauri" "cargo-watch" "wasm-pack" "blazor" "maui" "terraform" "kubectl" "helm")
    local FW_LABELS=("npm (latest) - Node default pkg manager" "Yarn - Fast JS pkg manager" "pnpm - Disk-efficient JS pkg manager" "Bun - Ultra-fast JS runtime" "VenvStudio - GUI venv manager (PySide6)" "uv - Ultra-fast Python pkg manager (Rust)" "Poetry - Python dependency mgmt" "pipx - Isolated Python CLI tools" "Miniconda - Python/R data science" "React (create-react-app) - Facebook UI" "Next.js - React fullstack framework" "Vue CLI - Progressive JS framework" "Nuxt (nuxi) - Vue fullstack framework" "Angular CLI - Google enterprise web" "SvelteKit - Lightweight reactive" "Vite - Next-gen build tool" "Astro - Content-focused web framework" "Express.js - Minimal Node.js web" "NestJS CLI - Progressive Node.js" "Remix - Full stack web framework" "Django - Python web framework" "Flask - Lightweight Python web" "FastAPI - Modern async Python API" "Streamlit - Python data app" "Tailwind CSS - Utility-first CSS" "Bootstrap - Popular CSS framework" "React Native CLI - Cross-platform mobile" "Expo CLI - React Native toolchain" "Ionic CLI - Cross-platform mobile" "Electron Forge - Desktop apps (web tech)" "Tauri CLI - Lightweight desktop (Rust)" "cargo-watch - Rust auto-rebuild" "wasm-pack - Rust to WebAssembly" "Blazor - C# web UI (in .NET SDK)" ".NET MAUI - Cross-platform .NET UI" "Terraform - Infrastructure as code" "kubectl - Kubernetes CLI" "Helm - Kubernetes pkg manager")

    # --- Action selector ---
    local action
    action=$(show_action_menu)
    case "$action" in
        2)
            # Uninstall flow
            show_uninstall_menu
            section "Uninstall Summary"
            echo -e "  ${GREEN}✓ ${#INSTALLED[@]} operations completed${NC}"
            [[ ${#FAILED[@]} -gt 0 ]] && echo -e "  ${RED}✗ ${#FAILED[@]} failed:${NC} ${FAILED[*]}"
            info "Log: $LOG_FILE"
            exit 0
            ;;
        3|q|Q|"")
            info "Exited."
            exit 0
            ;;
        1|*)
            # Continue with install flow (default)
            ;;
    esac

    local sel_langs=() sel_ides=() sel_tools=() sel_fws=()

    local profile
    profile=$(show_profile_menu)

    # Helper: add items avoiding duplicates
    add_unique() {
        local -n _arr=$1; shift
        for item in "$@"; do
            local found=0
            for existing in "${_arr[@]}"; do [[ "$existing" == "$item" ]] && found=1 && break; done
            [[ $found -eq 0 ]] && _arr+=("$item")
        done
    }

    local is_custom=0 is_all=0

    for pc in $profile; do
        case "$pc" in
            1)  add_unique sel_langs "nodejs" "typescript"; add_unique sel_ides "vscode" "zed"; add_unique sel_tools "git"; add_unique sel_fws "yarn" "pnpm" "vite" "react" "vue" "tailwind" ;;
            2)  add_unique sel_langs "nodejs" "python" "typescript" "php"; add_unique sel_ides "vscode" "sublime"; add_unique sel_tools "git" "docker" "postman"; add_unique sel_fws "yarn" "pnpm" "vite" "react" "nextjs" "express" "django" "tailwind" ;;
            3)  add_unique sel_langs "java" "kotlin" "dart" "swift"; add_unique sel_ides "android" "vscode"; add_unique sel_tools "git"; add_unique sel_fws "reactnative" "expo" ;;
            4)  add_unique sel_langs "python" "r" "julia"; add_unique sel_ides "vscode" "pycharm"; add_unique sel_tools "git" "docker"; add_unique sel_fws "venvstudio" "uv" "conda" "streamlit" "fastapi" ;;
            5)  add_unique sel_langs "python" "mojo" "rust" "julia"; add_unique sel_ides "vscode" "pycharm" "cursor"; add_unique sel_tools "git" "docker"; add_unique sel_fws "venvstudio" "uv" "conda" "streamlit" "fastapi" ;;
            6)  add_unique sel_langs "cpp" "rust" "zig" "go"; add_unique sel_ides "vscode" "clion" "vim"; add_unique sel_tools "git" "cmake"; add_unique sel_fws "cargo-watch" "wasm-pack" ;;
            7)  add_unique sel_langs "csharp" "nodejs" "typescript"; add_unique sel_ides "vs2026" "vscode" "rider"; add_unique sel_tools "git" "docker" "postman"; add_unique sel_fws "yarn" "vite" "react" "nextjs" "blazor" ;;
            8)  add_unique sel_langs "cpp" "csharp" "lua"; add_unique sel_ides "vs2026" "vscode" "rider"; add_unique sel_tools "git" "cmake" ;;
            9)  add_unique sel_langs "python" "go" "rust"; add_unique sel_ides "vscode" "vim"; add_unique sel_tools "git" "docker"; add_unique sel_fws "terraform" "kubectl" "helm" ;;
            10) add_unique sel_langs "solidity" "rust" "typescript" "nodejs"; add_unique sel_ides "vscode" "cursor"; add_unique sel_tools "git"; add_unique sel_fws "npm" "yarn" ;;
            11) add_unique sel_langs "cpp" "rust" "python" "lua"; add_unique sel_ides "vscode" "clion" "vim"; add_unique sel_tools "git" "cmake" ;;
            12) add_unique sel_langs "fortran" "python" "r" "julia" "haskell"; add_unique sel_ides "vscode" "emacs"; add_unique sel_tools "git"; add_unique sel_fws "venvstudio" "uv" "conda" ;;
            13) add_unique sel_langs "haskell" "elixir" "erlang" "ocaml" "scala" "gleam"; add_unique sel_ides "vscode" "emacs" "vim"; add_unique sel_tools "git" ;;
            14) add_unique sel_langs "java" "kotlin" "scala" "groovy"; add_unique sel_ides "intellij" "eclipse" "netbeans"; add_unique sel_tools "git" "docker" ;;
            15) add_unique sel_langs "go" "rust" "python"; add_unique sel_ides "vim" "classicvim" "emacs"; add_unique sel_tools "git" ;;
            16) is_custom=1 ;;
            17) is_all=1 ;;
        esac
    done

    if [[ $is_all -eq 1 ]]; then
        echo ""
        echo -e "  ${RED}============================================================${NC}"
        echo -e "  ${RED}WARNING: You are about to install EVERYTHING!${NC}"
        echo -e "  ${RED}============================================================${NC}"
        echo ""
        echo -e "  ${YELLOW}This includes:${NC}"
        echo -e "    - 39 programming languages and runtimes"
        echo -e "    - 23 IDEs and editors"
        echo -e "    - 9 developer tools"
        echo -e "    - 38 frameworks, libraries and package managers"
        echo ""
        echo -e "  ${YELLOW}Estimated time: 45-90 minutes (depends on internet speed)${NC}"
        echo -e "  ${YELLOW}Disk space: approximately 30-50 GB${NC}"
        echo -e "  ${YELLOW}System load: HIGH - your system may slow down during install${NC}"
        echo ""
        echo -e "  ${CYAN}RECOMMENDATION: Close other programs before proceeding.${NC}"
        echo ""
        read -rp "  Type 'YES' (uppercase) to confirm: " confirm_all
        if [[ "$confirm_all" != "YES" ]]; then
            info "Cancelled. Good choice - select specific profiles instead!"
            exit 0
        fi
        sel_langs=("${LANG_KEYS[@]}")
        sel_ides=("${IDE_KEYS[@]}")
        sel_tools=("${TOOL_KEYS[@]}")
        sel_fws=("${FW_KEYS[@]}")
    elif [[ $is_custom -eq 1 ]]; then
        local sel_idx=()
        number_menu "Select Programming Languages" LANG_LABELS sel_idx
        for idx in "${sel_idx[@]}"; do sel_langs+=("${LANG_KEYS[$idx]}"); done

        sel_idx=()
        number_menu "Select IDEs and Editors" IDE_LABELS sel_idx
        for idx in "${sel_idx[@]}"; do sel_ides+=("${IDE_KEYS[$idx]}"); done

        sel_idx=()
        number_menu "Select Developer Tools" TOOL_LABELS sel_idx
        for idx in "${sel_idx[@]}"; do sel_tools+=("${TOOL_KEYS[$idx]}"); done

        sel_idx=()
        number_menu "Select Frameworks, Libraries and Package Managers" FW_LABELS sel_idx
        for idx in "${sel_idx[@]}"; do sel_fws+=("${FW_KEYS[$idx]}"); done
    fi

    # Version selection for supported languages
    section "Version Selection"
    declare -A VER_CHOICE

    for lang in "${sel_langs[@]}"; do
        case "$lang" in
            python)
                local pv=("3.14" "3.13" "3.12" "3.11")
                local pi; pi=$(version_menu "Python" "Python 3.14" "Python 3.13" "Python 3.12" "Python 3.11")
                VER_CHOICE[python]="${pv[$pi]}" ;;
            nodejs)
                local nv=("24" "25" "22" "20")
                local ni; ni=$(version_menu "Node.js" "Node.js 24 LTS" "Node.js 25 (Current)" "Node.js 22 LTS" "Node.js 20 LTS")
                VER_CHOICE[nodejs]="${nv[$ni]}" ;;
            java)
                local jv=("25" "23" "21" "17")
                local ji; ji=$(version_menu "Java" "JDK 25 (Latest)" "JDK 23 (LTS)" "JDK 21 (LTS)" "JDK 17 (LTS)")
                VER_CHOICE[java]="${jv[$ji]}" ;;
            csharp)
                local cv=("9" "8" "7" "6")
                local ci; ci=$(version_menu ".NET" ".NET 9 (Latest)" ".NET 8 (LTS)" ".NET 7" ".NET 6 (LTS)")
                VER_CHOICE[csharp]="${cv[$ci]}" ;;
            go)
                local gv=("1.23" "1.22" "1.21")
                local gi; gi=$(version_menu "Go" "Go 1.23 (Latest)" "Go 1.22" "Go 1.21")
                VER_CHOICE[go]="${gv[$gi]}" ;;
            php)
                local phv=("8.4" "8.3" "8.2")
                local phi; phi=$(version_menu "PHP" "PHP 8.4 (Latest)" "PHP 8.3" "PHP 8.2")
                VER_CHOICE[php]="${phv[$phi]}" ;;
            ruby)
                local rv=("3.3" "3.2" "3.1")
                local ri; ri=$(version_menu "Ruby" "Ruby 3.3 (Latest)" "Ruby 3.2" "Ruby 3.1")
                VER_CHOICE[ruby]="${rv[$ri]}" ;;
            *) info "$lang: latest version will be installed." ;;
        esac
    done

    # Confirmation
    section "Installation Plan"
    echo -e "  ${CYAN}Languages:${NC} ${sel_langs[*]}"
    echo -e "  ${CYAN}IDEs:${NC}      ${sel_ides[*]}"
    echo -e "  ${CYAN}Tools:${NC}     ${sel_tools[*]}"
    if [[ ${#sel_fws[@]} -gt 0 ]]; then
        echo -e "  ${CYAN}Frameworks:${NC} ${sel_fws[*]}"
    fi
    echo ""
    read -rp "  Proceed? (Y/n): " confirm
    [[ "$confirm" == "n" || "$confirm" == "N" ]] && { info "Cancelled."; exit 0; }

    # Install languages
    section "Installing Languages and Runtimes"
    for lang in "${sel_langs[@]}"; do
        case "$lang" in
            python)     install_python "${VER_CHOICE[python]:-3.14}" ;;
            nodejs)     install_nodejs "${VER_CHOICE[nodejs]:-24}" ;;
            java)       install_java "${VER_CHOICE[java]:-25}" ;;
            csharp)     install_csharp "${VER_CHOICE[csharp]:-9}" ;;
            cpp)        install_cpp ;;
            go)         install_go "${VER_CHOICE[go]:-1.23}" ;;
            rust)       install_rust ;;
            php)        install_php "${VER_CHOICE[php]:-8.4}" ;;
            ruby)       install_ruby "${VER_CHOICE[ruby]:-3.3}" ;;
            kotlin)     install_kotlin ;;
            dart)       install_dart ;;
            swift)      install_swift ;;
            zig)        install_zig ;;
            mojo)       install_mojo ;;
            wasm)       install_wasm ;;
            typescript) install_typescript ;;
            elixir)     install_elixir ;;
            scala)      install_scala ;;
            julia)      install_julia ;;
            r)          install_r ;;
            lua)        install_lua ;;
            haskell)    install_haskell ;;
            perl)       install_perl ;;
            erlang)     install_erlang ;;
            ocaml)      install_ocaml ;;
            fortran)    install_fortran ;;
            d)          install_d ;;
            nim)        install_nim ;;
            crystal)    install_crystal ;;
            v)          install_v ;;
            gleam)      install_gleam ;;
            carbon)     install_carbon ;;
            solidity)   install_solidity ;;
            groovy)     install_groovy ;;
            ada)        install_ada ;;
            cobol)      install_cobol ;;
            lisp)       install_lisp ;;
            racket)     install_racket ;;
            objc)       install_objc ;;
            julia)
                local julv=("1.12" "1.10")
                local juli; juli=$(version_menu "Julia" "Julia 1.12 (Latest)" "Julia 1.10 (LTS)")
                VER_CHOICE[julia]="${julv[$juli]}" ;;
        esac
    done

    # Install IDEs
    section "Installing IDEs and Editors"
    for ide in "${sel_ides[@]}"; do install_ide "$ide"; done

    # Install tools
    section "Installing Developer Tools"
    for tool in "${sel_tools[@]}"; do install_tool "$tool"; done

    # Install frameworks
    if [[ ${#sel_fws[@]} -gt 0 ]]; then
        section "Installing Frameworks, Libraries and Package Managers"
        for fw in "${sel_fws[@]}"; do install_framework "$fw"; done
    fi

    # Summary
    section "Installation Summary"
    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}Installed (${#INSTALLED[@]}):${NC}"
        for item in "${INSTALLED[@]}"; do echo -e "    ${GREEN}+${NC} $item"; done
    fi
    if [[ ${#FAILED[@]} -gt 0 ]]; then
        echo ""
        echo -e "  ${RED}Failed / Manual (${#FAILED[@]}):${NC}"
        for item in "${FAILED[@]}"; do echo -e "    ${RED}-${NC} $item"; done
    fi
    echo ""
    echo -e "  ${CYAN}Total: ${#INSTALLED[@]} succeeded, ${#FAILED[@]} failed${NC}"
    echo -e "  ${GRAY}Log: $LOG_FILE${NC}"
    echo ""
    if [[ ${#INSTALLED[@]} -gt 0 ]]; then
        # Reload shell config so everything works immediately
        echo ""
        step "Reloading shell configuration..."
        [[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc" 2>/dev/null
        [[ -f "$HOME/.zshrc" ]] && source "$HOME/.zshrc" 2>/dev/null
        [[ -f "$HOME/.profile" ]] && source "$HOME/.profile" 2>/dev/null
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" 2>/dev/null
        [ -s "$HOME/.cargo/env" ] && . "$HOME/.cargo/env" 2>/dev/null
        [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ] && . "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null
        export PATH="$HOME/.local/bin:$PATH"
        ok "Shell configuration reloaded."
        echo ""
        echo -e "  ${YELLOW}If commands still not found, run: source ~/.bashrc${NC}"
    fi
    echo ""
}

# ================================================================
# JSON SCAN OUTPUT (for GUI integration)
# Usage: bash codeready.sh --scan-json
# ================================================================
export_scan_json() {
    local items="["
    local first=true

    add_item() {
        local name="$1" category="$2" version="$3" installed="$4"
        [[ "$first" == "true" ]] && first=false || items+=","
        if [[ -n "$version" ]]; then
            items+="{\"name\":\"$name\",\"category\":\"$category\",\"version\":\"$version\",\"installed\":$installed}"
        else
            items+="{\"name\":\"$name\",\"category\":\"$category\",\"version\":null,\"installed\":$installed}"
        fi
    }

    # Source nvm/cargo if available
    [[ -s "$HOME/.nvm/nvm.sh" ]] && source "$HOME/.nvm/nvm.sh" 2>/dev/null
    [[ -s "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env" 2>/dev/null

    # Languages
    local langs=(
        "Python|python3|--version"
        "Node.js|node|-v"
        "Java (JDK)|java|-version"
        ".NET SDK|dotnet|--version"
        "C/C++ (GCC)|gcc|--version"
        "Go|go|version"
        "Rust|rustc|--version"
        "PHP|php|--version"
        "Ruby|ruby|--version"
        "Kotlin|kotlin|-version"
        "Dart|dart|--version"
        "Swift|swift|--version"
        "TypeScript|tsc|--version"
        "R|Rscript|--version"
        "Lua|lua|-v"
        "Haskell|ghc|--version"
        "Perl|perl|--version"
        "Erlang|erl|+V"
        "OCaml|ocaml|--version"
        "Fortran|gfortran|--version"
        "D|ldc2|--version"
        "Nim|nim|--version"
        "Crystal|crystal|--version"
        "V|v|--version"
        "Gleam|gleam|--version"
        "Solidity|solcjs|--version"
        "Groovy|groovy|--version"
        "Elixir|elixir|--version"
        "Scala|scala|-version"
        "Julia|julia|--version"
        "Zig|zig|version"
        "Mojo|mojo|--version"
        "WebAssembly|wasmtime|--version"
        "Flutter|flutter|--version"
    )
    for entry in "${langs[@]}"; do
        IFS='|' read -r name cmd flag <<< "$entry"
        local ver=$(get_cmd_version "$cmd" "$flag")
        if [[ -n "$ver" ]]; then
            add_item "$name" "language" "$ver" "true"
        else
            add_item "$name" "language" "" "false"
        fi
    done

    # IDEs
    local ides=(
        "VS Code|code" "VSCodium|codium" "Cursor|cursor" "Zed|zed" "Windsurf|windsurf"
        "Sublime Text|subl" "Vim|vim" "Neovim|nvim" "GNU Emacs|emacs" "Android Studio|studio"
        "IntelliJ IDEA|idea" "PyCharm|pycharm" "WebStorm|webstorm" "GoLand|goland"
        "CLion|clion" "Rider|rider" "RustRover|rustrover" "JetBrains Fleet|fleet"
        "Eclipse|eclipse" "Apache NetBeans|netbeans" "Notepad++|notepad++"
    )
    for entry in "${ides[@]}"; do
        IFS='|' read -r name cmd <<< "$entry"
        if command -v "$cmd" &>/dev/null; then
            add_item "$name" "ide" "found" "true"
        else
            add_item "$name" "ide" "" "false"
        fi
    done

    # Frameworks — npm globals
    local npm_json=""
    if command -v npm &>/dev/null; then
        npm_json=$(npm list -g --depth=0 --json 2>/dev/null || echo "{}")
    fi
    local fw_npm=(
        "React|create-react-app" "Next.js|create-next-app" "Vue|@vue/cli" "Nuxt|nuxi"
        "Angular|@angular/cli" "Svelte|create-svelte" "Vite|create-vite" "Astro|create-astro"
        "Remix|create-remix" "Express|express-generator" "NestJS|@nestjs/cli"
        "Tailwind|tailwindcss" "Bootstrap|bootstrap" "React Native|react-native-cli"
        "Expo|expo-cli" "Ionic|@ionic/cli" "Electron|electron"
    )
    for entry in "${fw_npm[@]}"; do
        IFS='|' read -r name pkg <<< "$entry"
        if echo "$npm_json" | grep -q "\"$pkg\""; then
            add_item "$name" "framework" "found" "true"
        else
            add_item "$name" "framework" "" "false"
        fi
    done

    # Frameworks — pip
    local pip_pkgs=""
    if command -v pip3 &>/dev/null; then
        pip_pkgs=$(pip3 list --format=columns 2>/dev/null | tail -n +3 | awk '{print tolower($1)}')
    elif command -v pip &>/dev/null; then
        pip_pkgs=$(pip list --format=columns 2>/dev/null | tail -n +3 | awk '{print tolower($1)}')
    fi
    local fw_pip=("Django|django" "Flask|flask" "FastAPI|fastapi" "Streamlit|streamlit" "VenvStudio|venvstudio")
    for entry in "${fw_pip[@]}"; do
        IFS='|' read -r name pkg <<< "$entry"
        if echo "$pip_pkgs" | grep -qiw "$pkg"; then
            add_item "$name" "framework" "found" "true"
        else
            add_item "$name" "framework" "" "false"
        fi
    done

    # Blazor
    if command -v dotnet &>/dev/null; then
        add_item "Blazor" "framework" "via .NET" "true"
    else
        add_item "Blazor" "framework" "" "false"
    fi

    # Tools
    local tools=(
        "Git|git|--version" "Docker|docker|--version" "kubectl|kubectl|version --client --short"
        "Helm|helm|version --short" "Terraform|terraform|--version"
        "npm|npm|--version" "Yarn|yarn|--version" "pnpm|pnpm|--version" "Bun|bun|--version"
        "pipx|pipx|--version" "uv|uv|--version" "Poetry|poetry|--version" "Conda|conda|--version"
    )
    for entry in "${tools[@]}"; do
        IFS='|' read -r name cmd flag <<< "$entry"
        local ver=$(get_cmd_version "$cmd" "$flag")
        if [[ -n "$ver" ]]; then
            add_item "$name" "tool" "$ver" "true"
        else
            add_item "$name" "tool" "" "false"
        fi
    done

    # System package managers
    local pkgmgrs=("Homebrew|brew|--version" "Flatpak|flatpak|--version" "Nix|nix|--version" "Snap|snap|version")
    for entry in "${pkgmgrs[@]}"; do
        IFS='|' read -r name cmd flag <<< "$entry"
        local ver=$(get_cmd_version "$cmd" "$flag")
        if [[ -n "$ver" ]]; then
            add_item "$name" "pkgmanager" "$ver" "true"
        else
            add_item "$name" "pkgmanager" "" "false"
        fi
    done

    items+="]"

    # Count
    local total=$(echo "$items" | grep -o '"installed":true' | wc -l)
    local all=$(echo "$items" | grep -o '"installed":' | wc -l)
    local missing=$((all - total))

    echo "{\"items\":$items,\"total\":$all,\"installed_count\":$total,\"missing_count\":$missing}"
}

# ================================================================
# ENTRY POINT
# ================================================================
if [[ "${1:-}" == "--scan-json" ]]; then
    export_scan_json
    exit 0
fi

main "$@"
