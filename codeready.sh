#!/usr/bin/env bash
# ================================================================
# CodeReady v2.0.0
# Developer Environment Setup Tool (Linux/macOS)
# https://github.com/bayramkotan/CodeReady
# ================================================================
set -uo pipefail

VERSION="2.0.0"
LOG_FILE="$HOME/codeready_install.log"
INSTALLED=()
FAILED=()

# --- Detect OS --------------------------------------------------
detect_os() {
    OS_TYPE=""; PKG=""
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"; PKG="brew"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint|pop) OS_TYPE="debian"; PKG="apt" ;;
            fedora)                      OS_TYPE="fedora"; PKG="dnf" ;;
            centos|rhel|rocky|alma)      OS_TYPE="rhel";   PKG="dnf" ;;
            arch|manjaro|endeavouros)    OS_TYPE="arch";   PKG="pacman" ;;
            opensuse*|sles)              OS_TYPE="suse";   PKG="zypper" ;;
            *)                           OS_TYPE="linux";  PKG="unknown" ;;
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
section() { echo ""; echo -e "  ${YELLOW}=== $1 ===${NC}"; echo ""; }

# --- Package Manager Setup --------------------------------------
ensure_brew() {
    step "Checking Homebrew..."
    if command -v brew &>/dev/null; then ok "Homebrew ready."; return 0; fi
    step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null || /home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
    ok "Homebrew installed."
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

# --- Generic installer ------------------------------------------
pkg_install() {
    local name="$1"; shift
    step "Installing $name..."
    if eval "$@" &>>"$LOG_FILE" 2>&1; then
        ok "$name installed."
    else
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
    case "$PKG" in
        brew)   pkg_install "C/C++ ($variant)" "brew install gcc llvm cmake" ;;
        apt)    pkg_install "C/C++ (GCC/G++)" "sudo apt install -y build-essential gcc g++ gdb cmake" ;;
        dnf)    pkg_install "C/C++ (GCC/G++)" "sudo dnf install -y gcc gcc-c++ gdb cmake make" ;;
        pacman) pkg_install "C/C++ (GCC/G++)" "sudo pacman -S --noconfirm base-devel gcc gdb cmake" ;;
        zypper) pkg_install "C/C++ (GCC/G++)" "sudo zypper install -y gcc gcc-c++ gdb cmake make" ;;
    esac
}

install_go() {
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
    local ver="${1:-8.4}"
    case "$PKG" in
        brew)   pkg_install "PHP $ver" "brew install php@$ver composer || brew install php composer" ;;
        apt)    pkg_install "PHP $ver" "sudo apt install -y php${ver} php${ver}-cli php-common php-mbstring php-xml composer || sudo apt install -y php php-cli composer" ;;
        dnf)    pkg_install "PHP" "sudo dnf install -y php php-cli php-common composer" ;;
        pacman) pkg_install "PHP" "sudo pacman -S --noconfirm php composer" ;;
    esac
}

install_ruby() {
    local ver="${1:-3.3}"
    case "$PKG" in
        brew)   pkg_install "Ruby $ver" "brew install ruby@$ver || brew install ruby" ;;
        apt)    pkg_install "Ruby" "sudo apt install -y ruby ruby-dev rubygems" ;;
        dnf)    pkg_install "Ruby" "sudo dnf install -y ruby ruby-devel rubygems" ;;
        pacman) pkg_install "Ruby" "sudo pacman -S --noconfirm ruby rubygems" ;;
    esac
}

install_kotlin() {
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
    local variant="${1:-flutter}"
    case "$PKG" in
        brew)
            if [[ "$variant" == "flutter" ]]; then
                pkg_install "Flutter (includes Dart)" "brew install --cask flutter"
            else
                pkg_install "Dart SDK" "brew install dart-sdk"
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
    case "$PKG" in
        brew) if command -v swift &>/dev/null; then ok "Swift available (via Xcode)."; else info "Install Xcode: xcode-select --install"; fail "Swift"; fi ;;
        apt)  pkg_install "Swift" "sudo apt install -y swift || (curl -fsSL https://swift.org/install.sh | bash)" ;;
        *)    info "Swift: visit https://swift.org/getting-started/"; fail "Swift (manual)" ;;
    esac
}

install_zig() {
    case "$PKG" in
        brew)   pkg_install "Zig" "brew install zig" ;;
        apt)    if command -v snap &>/dev/null; then
                    pkg_install "Zig" "sudo snap install zig --classic --beta"
                else
                    step "Installing Zig from official binary..."
                    local ARCH; ARCH=$(uname -m)
                    case "$ARCH" in x86_64) ARCH="x86_64" ;; aarch64|arm64) ARCH="aarch64" ;; esac
                    curl -fsSL "https://ziglang.org/download/0.13.0/zig-linux-${ARCH}-0.13.0.tar.xz" -o /tmp/zig.tar.xz 2>>"$LOG_FILE"
                    sudo tar -C /usr/local -xf /tmp/zig.tar.xz
                    sudo ln -sf /usr/local/zig-linux-*/zig /usr/local/bin/zig
                    rm -f /tmp/zig.tar.xz
                    ok "Zig installed."
                fi ;;
        pacman) pkg_install "Zig" "sudo pacman -S --noconfirm zig" ;;
        dnf)    pkg_install "Zig" "sudo dnf install -y zig || (curl -fsSL https://ziglang.org/download/0.13.0/zig-linux-x86_64-0.13.0.tar.xz -o /tmp/zig.tar.xz && sudo tar -C /usr/local -xf /tmp/zig.tar.xz && sudo ln -sf /usr/local/zig-linux-*/zig /usr/local/bin/zig)" ;;
    esac
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
    step "Installing TypeScript globally via npm..."
    if command -v npm &>/dev/null; then
        npm install -g typescript ts-node &>>"$LOG_FILE" 2>&1 && ok "TypeScript installed." || fail "TypeScript"
    else
        info "TypeScript requires Node.js/npm. Install Node.js first."
        fail "TypeScript (needs npm)"
    fi
}

install_elixir() {
    case "$PKG" in
        brew)   pkg_install "Elixir" "brew install elixir" ;;
        apt)    pkg_install "Elixir" "sudo apt install -y elixir" ;;
        dnf)    pkg_install "Elixir" "sudo dnf install -y elixir" ;;
        pacman) pkg_install "Elixir" "sudo pacman -S --noconfirm elixir" ;;
    esac
}

install_scala() {
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
    case "$PKG" in
        brew)   pkg_install "R" "brew install r" ;;
        apt)    pkg_install "R" "sudo apt install -y r-base r-base-dev" ;;
        dnf)    pkg_install "R" "sudo dnf install -y R" ;;
        pacman) pkg_install "R" "sudo pacman -S --noconfirm r" ;;
        zypper) pkg_install "R" "sudo zypper install -y R-base R-base-devel" ;;
    esac
}

install_lua() {
    case "$PKG" in
        brew)   pkg_install "Lua" "brew install lua luarocks" ;;
        apt)    pkg_install "Lua" "sudo apt install -y lua5.4 liblua5.4-dev luarocks" ;;
        dnf)    pkg_install "Lua" "sudo dnf install -y lua lua-devel luarocks" ;;
        pacman) pkg_install "Lua" "sudo pacman -S --noconfirm lua luarocks" ;;
    esac
}

install_haskell() {
    step "Installing Haskell via GHCup..."
    if command -v ghc &>/dev/null; then ok "Haskell already installed."; return; fi
    curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 sh &>>"$LOG_FILE" 2>&1
    [ -f "$HOME/.ghcup/env" ] && source "$HOME/.ghcup/env" 2>/dev/null
    ok "Haskell (GHC + Cabal + Stack) installed via GHCup."
}

install_perl() {
    case "$PKG" in
        brew)   pkg_install "Perl" "brew install perl" ;;
        apt)    pkg_install "Perl" "sudo apt install -y perl cpanminus" ;;
        dnf)    pkg_install "Perl" "sudo dnf install -y perl perl-App-cpanminus" ;;
        pacman) pkg_install "Perl" "sudo pacman -S --noconfirm perl cpanminus" ;;
    esac
}

install_erlang() {
    case "$PKG" in
        brew)   pkg_install "Erlang" "brew install erlang" ;;
        apt)    pkg_install "Erlang" "sudo apt install -y erlang" ;;
        dnf)    pkg_install "Erlang" "sudo dnf install -y erlang" ;;
        pacman) pkg_install "Erlang" "sudo pacman -S --noconfirm erlang" ;;
    esac
}

install_ocaml() {
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
    case "$PKG" in
        brew)   pkg_install "Fortran (GFortran)" "brew install gcc" ;;
        apt)    pkg_install "Fortran (GFortran)" "sudo apt install -y gfortran" ;;
        dnf)    pkg_install "Fortran (GFortran)" "sudo dnf install -y gcc-gfortran" ;;
        pacman) pkg_install "Fortran (GFortran)" "sudo pacman -S --noconfirm gcc-fortran" ;;
        zypper) pkg_install "Fortran (GFortran)" "sudo zypper install -y gcc-fortran" ;;
    esac
}

install_d() {
    case "$PKG" in
        brew)   pkg_install "D (LDC)" "brew install ldc dub" ;;
        apt)    pkg_install "D (LDC)" "sudo apt install -y ldc dub" ;;
        dnf)    pkg_install "D (LDC)" "sudo dnf install -y ldc dub" ;;
        pacman) pkg_install "D (LDC)" "sudo pacman -S --noconfirm ldc dub" ;;
        *)      info "D language: visit https://dlang.org/install.html"; fail "D (manual)" ;;
    esac
}

install_nim() {
    step "Installing Nim via choosenim..."
    if command -v nim &>/dev/null; then ok "Nim already installed."; return; fi
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh -s -- -y &>>"$LOG_FILE" 2>&1
    export PATH="$HOME/.nimble/bin:$PATH"
    ok "Nim installed via choosenim."
}

install_crystal() {
    case "$PKG" in
        brew)   pkg_install "Crystal" "brew install crystal" ;;
        apt)    step "Installing Crystal..."
                curl -fsSL https://crystal-lang.org/install.sh | sudo bash &>>"$LOG_FILE" 2>&1
                ok "Crystal installed." ;;
        pacman) pkg_install "Crystal" "sudo pacman -S --noconfirm crystal shards" ;;
        *)      info "Crystal: visit https://crystal-lang.org/install/"; fail "Crystal (manual)" ;;
    esac
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
    case "$PKG" in
        brew)   pkg_install "Ada (GNAT)" "brew install gnat" ;;
        apt)    pkg_install "Ada (GNAT)" "sudo apt install -y gnat" ;;
        dnf)    pkg_install "Ada (GNAT)" "sudo dnf install -y gcc-gnat" ;;
        pacman) pkg_install "Ada (GNAT)" "sudo pacman -S --noconfirm gcc-ada" ;;
        *)      info "Ada: visit https://www.adacore.com/download"; fail "Ada (manual)" ;;
    esac
}

install_cobol() {
    case "$PKG" in
        brew)   pkg_install "COBOL (GnuCOBOL)" "brew install gnucobol" ;;
        apt)    pkg_install "COBOL (GnuCOBOL)" "sudo apt install -y gnucobol" ;;
        dnf)    pkg_install "COBOL (GnuCOBOL)" "sudo dnf install -y gnucobol" ;;
        pacman) pkg_install "COBOL (GnuCOBOL)" "sudo pacman -S --noconfirm gnucobol" ;;
        *)      info "COBOL: visit https://gnucobol.sourceforge.io"; fail "COBOL (manual)" ;;
    esac
}

install_lisp() {
    case "$PKG" in
        brew)   pkg_install "Common Lisp (SBCL)" "brew install sbcl" ;;
        apt)    pkg_install "Common Lisp (SBCL)" "sudo apt install -y sbcl" ;;
        dnf)    pkg_install "Common Lisp (SBCL)" "sudo dnf install -y sbcl" ;;
        pacman) pkg_install "Common Lisp (SBCL)" "sudo pacman -S --noconfirm sbcl" ;;
    esac
}

install_racket() {
    case "$PKG" in
        brew)   pkg_install "Racket" "brew install racket" ;;
        apt)    pkg_install "Racket" "sudo apt install -y racket" ;;
        dnf)    pkg_install "Racket" "sudo dnf install -y racket" ;;
        pacman) pkg_install "Racket" "sudo pacman -S --noconfirm racket" ;;
    esac
}

install_objc() {
    case "$PKG" in
        brew) info "Objective-C available via Xcode: xcode-select --install"
              if command -v clang &>/dev/null; then ok "Objective-C (Clang) available."; else fail "Objective-C"; fi ;;
        apt)  pkg_install "Objective-C (GNUstep)" "sudo apt install -y gobjc gnustep-devel" ;;
        dnf)  pkg_install "Objective-C (GNUstep)" "sudo dnf install -y gcc-objc gnustep-base-devel" ;;
        *)    info "Objective-C: use Xcode (macOS) or GNUstep (Linux)"; fail "Objective-C (manual)" ;;
    esac
}

# ================================================================
# IDE INSTALLERS
# ================================================================
install_ide() {
    local key="$1"
    case "$key" in
        vscode)
            case "$PKG" in
                brew) pkg_install "VS Code" "brew install --cask visual-studio-code" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "VS Code" "sudo snap install code --classic"
                      else info "Download VS Code: https://code.visualstudio.com"; fail "VS Code (manual)"; fi ;;
            esac ;;
        vs2026)     info "Visual Studio 2026 is Windows-only. Use VS Code or Rider." ;;
        intellij)
            case "$PKG" in
                brew) pkg_install "IntelliJ IDEA" "brew install --cask intellij-idea-ce" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "IntelliJ IDEA" "sudo snap install intellij-idea-community --classic"
                      else info "Download: https://www.jetbrains.com/idea/download/"; fail "IntelliJ (manual)"; fi ;;
            esac ;;
        pycharm)
            case "$PKG" in
                brew) pkg_install "PyCharm" "brew install --cask pycharm-ce" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "PyCharm" "sudo snap install pycharm-community --classic"
                      else fail "PyCharm (manual)"; fi ;;
            esac ;;
        webstorm)
            case "$PKG" in
                brew) pkg_install "WebStorm" "brew install --cask webstorm" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "WebStorm" "sudo snap install webstorm --classic"; else fail "WebStorm (manual)"; fi ;;
            esac ;;
        goland)
            case "$PKG" in
                brew) pkg_install "GoLand" "brew install --cask goland" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "GoLand" "sudo snap install goland --classic"; else fail "GoLand (manual)"; fi ;;
            esac ;;
        clion)
            case "$PKG" in
                brew) pkg_install "CLion" "brew install --cask clion" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "CLion" "sudo snap install clion --classic"; else fail "CLion (manual)"; fi ;;
            esac ;;
        rider)
            case "$PKG" in
                brew) pkg_install "Rider" "brew install --cask rider" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "Rider" "sudo snap install rider --classic"; else fail "Rider (manual)"; fi ;;
            esac ;;
        rustrover)
            case "$PKG" in
                brew) pkg_install "RustRover" "brew install --cask rustrover" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "RustRover" "sudo snap install rustrover --classic"; else fail "RustRover (manual)"; fi ;;
            esac ;;
        eclipse)
            case "$PKG" in
                brew) pkg_install "Eclipse" "brew install --cask eclipse-jee" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "Eclipse" "sudo snap install eclipse --classic"; else fail "Eclipse (manual)"; fi ;;
            esac ;;
        android)
            case "$PKG" in
                brew) pkg_install "Android Studio" "brew install --cask android-studio" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "Android Studio" "sudo snap install android-studio --classic"; else fail "Android Studio (manual)"; fi ;;
            esac ;;
        sublime)
            case "$PKG" in
                brew) pkg_install "Sublime Text" "brew install --cask sublime-text" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "Sublime Text" "sudo snap install sublime-text --classic"; else fail "Sublime Text (manual)"; fi ;;
            esac ;;
        vim)
            case "$PKG" in
                brew)   pkg_install "Neovim" "brew install neovim" ;;
                apt)    pkg_install "Neovim" "sudo apt install -y neovim" ;;
                dnf)    pkg_install "Neovim" "sudo dnf install -y neovim" ;;
                pacman) pkg_install "Neovim" "sudo pacman -S --noconfirm neovim" ;;
                zypper) pkg_install "Neovim" "sudo zypper install -y neovim" ;;
            esac ;;
        classicvim)
            case "$PKG" in
                brew)   pkg_install "Vim" "brew install vim" ;;
                apt)    pkg_install "Vim" "sudo apt install -y vim" ;;
                dnf)    pkg_install "Vim" "sudo dnf install -y vim-enhanced" ;;
                pacman) pkg_install "Vim" "sudo pacman -S --noconfirm vim" ;;
                zypper) pkg_install "Vim" "sudo zypper install -y vim" ;;
            esac ;;
        vscodium)
            case "$PKG" in
                brew) pkg_install "VSCodium" "brew install --cask vscodium" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "VSCodium" "sudo snap install codium --classic"
                      else info "Download VSCodium: https://vscodium.com"; fail "VSCodium (manual)"; fi ;;
            esac ;;
        antigravity)
            case "$PKG" in
                brew) pkg_install "Antigravity" "brew install --cask antigravity" ;;
                *)    info "Download Antigravity: https://antigravity.app"; fail "Antigravity (manual)" ;;
            esac ;;
        emacs)
            case "$PKG" in
                brew)   pkg_install "GNU Emacs" "brew install --cask emacs" ;;
                apt)    pkg_install "GNU Emacs" "sudo apt install -y emacs" ;;
                dnf)    pkg_install "GNU Emacs" "sudo dnf install -y emacs" ;;
                pacman) pkg_install "GNU Emacs" "sudo pacman -S --noconfirm emacs" ;;
                zypper) pkg_install "GNU Emacs" "sudo zypper install -y emacs" ;;
            esac ;;
        netbeans)
            case "$PKG" in
                brew) pkg_install "NetBeans" "brew install --cask netbeans" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "NetBeans" "sudo snap install netbeans --classic"
                      else info "Download NetBeans: https://netbeans.apache.org"; fail "NetBeans (manual)"; fi ;;
            esac ;;
        fleet)
            case "$PKG" in
                brew) pkg_install "JetBrains Fleet" "brew install --cask jetbrains-fleet" ;;
                *)    info "Download Fleet: https://www.jetbrains.com/fleet/"; fail "Fleet (manual)" ;;
            esac ;;
        notepadpp)  info "Notepad++ is Windows-only." ;;
        cursor)
            case "$PKG" in
                brew) pkg_install "Cursor" "brew install --cask cursor" ;;
                *)    info "Download Cursor: https://cursor.sh"; fail "Cursor (manual)" ;;
            esac ;;
        windsurf)
            case "$PKG" in
                brew) pkg_install "Windsurf" "brew install --cask windsurf" ;;
                *)    info "Download Windsurf: https://codeium.com/windsurf"; fail "Windsurf (manual)" ;;
            esac ;;
        zed)
            case "$PKG" in
                brew) pkg_install "Zed" "brew install --cask zed" ;;
                *)    step "Installing Zed..."
                      curl -fsSL https://zed.dev/install.sh | sh &>>"$LOG_FILE" && ok "Zed installed." || fail "Zed" ;;
            esac ;;
        *) fail "Unknown IDE: $key" ;;
    esac
}

# ================================================================
# TOOL INSTALLERS
# ================================================================
install_tool() {
    local key="$1"
    case "$key" in
        git)
            case "$PKG" in
                brew) pkg_install "Git" "brew install git" ;;
                apt)  pkg_install "Git" "sudo apt install -y git" ;;
                dnf)  pkg_install "Git" "sudo dnf install -y git" ;;
                pacman) pkg_install "Git" "sudo pacman -S --noconfirm git" ;;
                zypper) pkg_install "Git" "sudo zypper install -y git" ;;
            esac ;;
        docker)
            case "$PKG" in
                brew) pkg_install "Docker" "brew install --cask docker" ;;
                apt)  pkg_install "Docker" "sudo apt install -y ca-certificates curl && sudo install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && sudo chmod a+r /etc/apt/keyrings/docker.asc && echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \$VERSION_CODENAME) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && sudo usermod -aG docker \$USER" ;;
                dnf)  pkg_install "Docker" "sudo dnf install -y docker && sudo systemctl enable --now docker && sudo usermod -aG docker \$USER" ;;
                pacman) pkg_install "Docker" "sudo pacman -S --noconfirm docker docker-compose && sudo systemctl enable --now docker && sudo usermod -aG docker \$USER" ;;
            esac ;;
        postman)
            case "$PKG" in
                brew) pkg_install "Postman" "brew install --cask postman" ;;
                *)    if command -v snap &>/dev/null; then pkg_install "Postman" "sudo snap install postman"; else fail "Postman (manual)"; fi ;;
            esac ;;
        cmake)
            case "$PKG" in
                brew)   pkg_install "CMake" "brew install cmake" ;;
                apt)    pkg_install "CMake" "sudo apt install -y cmake" ;;
                dnf)    pkg_install "CMake" "sudo dnf install -y cmake" ;;
                pacman) pkg_install "CMake" "sudo pacman -S --noconfirm cmake" ;;
            esac ;;
        gh)
            case "$PKG" in
                brew)   pkg_install "GitHub CLI" "brew install gh" ;;
                apt)    pkg_install "GitHub CLI" "sudo apt install -y gh || (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt update && sudo apt install -y gh)" ;;
                dnf)    pkg_install "GitHub CLI" "sudo dnf install -y gh" ;;
                pacman) pkg_install "GitHub CLI" "sudo pacman -S --noconfirm github-cli" ;;
            esac ;;
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
        uv)         step "Installing uv..."; (pip3 install uv 2>/dev/null || pip install uv 2>/dev/null || curl -LsSf https://astral.sh/uv/install.sh | sh) &>>"$LOG_FILE" 2>&1 && ok "uv installed." || fail "uv" ;;
        poetry)     step "Installing Poetry..."; (curl -sSL https://install.python-poetry.org | python3 -) &>>"$LOG_FILE" 2>&1 && ok "Poetry installed." || fail "Poetry" ;;
        pipx)       step "Installing pipx..."; (pip3 install --user pipx 2>/dev/null || pip install --user pipx) &>>"$LOG_FILE" 2>&1 && ok "pipx installed." || fail "pipx" ;;
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
        venvstudio) step "Installing VenvStudio..."; (pip3 install VenvStudio 2>/dev/null || pip install VenvStudio) &>>"$LOG_FILE" 2>&1 && ok "VenvStudio installed." || fail "VenvStudio" ;;

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
        django)     step "Installing Django..."; (pip3 install django 2>/dev/null || pip install django) &>>"$LOG_FILE" 2>&1 && ok "Django installed." || fail "Django" ;;
        flask)      step "Installing Flask..."; (pip3 install flask 2>/dev/null || pip install flask) &>>"$LOG_FILE" 2>&1 && ok "Flask installed." || fail "Flask" ;;
        fastapi)    step "Installing FastAPI..."; (pip3 install fastapi uvicorn 2>/dev/null || pip install fastapi uvicorn) &>>"$LOG_FILE" 2>&1 && ok "FastAPI installed." || fail "FastAPI" ;;
        streamlit)  step "Installing Streamlit..."; (pip3 install streamlit 2>/dev/null || pip install streamlit) &>>"$LOG_FILE" 2>&1 && ok "Streamlit installed." || fail "Streamlit" ;;

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
# PROFILES
# ================================================================
show_profile_menu() {
    section "Quick Setup Profiles" >&2
    echo -e "  ${BOLD}[1]${NC} Web Developer      ${GRAY}- Node.js, Python, PHP, TypeScript + VS Code, Sublime${NC}" >&2
    echo -e "  ${BOLD}[2]${NC} Mobile Developer   ${GRAY}- Java, Kotlin, Dart + Android Studio, VS Code${NC}" >&2
    echo -e "  ${BOLD}[3]${NC} Data Scientist     ${GRAY}- Python, Mojo + VS Code, PyCharm${NC}" >&2
    echo -e "  ${BOLD}[4]${NC} Systems Programmer ${GRAY}- C/C++, Rust, Zig, Go + VS Code, CLion, Neovim${NC}" >&2
    echo -e "  ${BOLD}[5]${NC} Full Stack .NET    ${GRAY}- C#/.NET, Node.js, TypeScript + VS Code, Rider${NC}" >&2
    echo -e "  ${BOLD}[6]${NC} Game Developer     ${GRAY}- C/C++, C# + VS Code, Rider${NC}" >&2
    echo -e "  ${BOLD}[7]${NC} AI / ML Engineer   ${GRAY}- Python, Mojo, Rust + VS Code, PyCharm, Cursor${NC}" >&2
    echo "" >&2
    echo -e "  ${BOLD}[8]${NC} Custom Setup       ${GRAY}- Choose your own${NC}" >&2
    echo -e "  ${RED}[9] INSTALL EVERYTHING ${GRAY}- All languages, IDEs, tools, frameworks${NC}" >&2
    echo "" >&2
    echo -e "  ${GRAY}You can select multiple profiles separated by spaces (e.g. 1 3 7)${NC}" >&2
    echo "" >&2
    read -rp "  Select profile(s): " choice
    echo "$choice"
}

# ================================================================
# SYSTEM SCAN - Auto-detect installed software and versions
# ================================================================
get_cmd_version() {
    local cmd="$1" flag="${2:---version}"
    if command -v "$cmd" &>/dev/null; then
        local ver
        ver=$("$cmd" $flag 2>&1 | head -1 | grep -oP '\d+\.\d+[\.\d]*' | head -1)
        [[ -n "$ver" ]] && echo "$ver" || echo "installed"
    else
        echo ""
    fi
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
        elif [[ "$recommended" == "latest" || "$recommended" == "—" ]]; then
            echo -e "    ${GREEN}${padded}${NC}  ${GREEN}${current}${NC}  ${GREEN}✓${NC}"
        elif [[ "$current" == "$recommended"* ]]; then
            echo -e "    ${GREEN}${padded}${NC}  ${GREEN}${current}${NC}  ${GREEN}✓ up to date${NC}"
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
    if [[ "$OS_TYPE" == "macos" ]]; then ensure_brew; else update_pkg; fi

    # System scan - show what's installed
    system_scan

    # Language, IDE, Tool keys
    local LANG_KEYS=("python" "nodejs" "java" "csharp" "cpp" "go" "rust" "php" "ruby" "kotlin" "dart" "swift" "zig" "mojo" "wasm" "typescript" "elixir" "scala" "julia" "r" "lua" "haskell" "perl" "erlang" "ocaml" "fortran" "d" "nim" "crystal" "v" "gleam" "carbon" "solidity" "groovy" "ada" "cobol" "lisp" "racket" "objc")
    local LANG_LABELS=("Python - General purpose, AI/ML" "Node.js - JavaScript/TypeScript runtime" "Java (JDK) - Enterprise, Android" "C# / .NET SDK - Microsoft ecosystem" "C/C++ - Systems programming" "Go - Cloud, microservices" "Rust - Memory safety, systems" "PHP - Web, CMS" "Ruby - Web, scripting" "Kotlin - Android, JVM" "Dart/Flutter - Mobile, web UI" "Swift - Apple ecosystem" "Zig - Next-gen systems, C interop" "Mojo - AI/GPU programming" "WebAssembly (WASI) - Portable binary" "TypeScript - Typed JavaScript" "Elixir - Functional, concurrent" "Scala - JVM functional/OOP" "Julia - Scientific computing" "R - Statistics, data science" "Lua - Scripting, game engines" "Haskell - Pure functional, fintech" "Perl - Text processing, sysadmin" "Erlang - Telecom, distributed systems" "OCaml - Fintech, compilers" "Fortran - Scientific computing, HPC" "D - Systems programming, C++ alt" "Nim - Python-like syntax, compiled" "Crystal - Ruby-like, compiled" "V - Simple systems language" "Gleam - Type-safe BEAM language" "Carbon - Experimental C++ successor" "Solidity - Ethereum smart contracts" "Groovy - JVM scripting, Gradle" "Ada - Safety-critical systems" "COBOL - Banking, legacy systems" "Common Lisp (SBCL) - AI, macros" "Racket - PL research, education" "Objective-C - Legacy Apple dev")

    local IDE_KEYS=("vscode" "vscodium" "antigravity" "cursor" "zed" "windsurf" "sublime" "classicvim" "vim" "emacs" "notepadpp" "intellij" "pycharm" "webstorm" "goland" "clion" "rider" "rustrover" "fleet" "eclipse" "netbeans" "android")
    local IDE_LABELS=("VS Code - Lightweight, extensible" "VSCodium - VS Code without telemetry" "Antigravity - AI-native code editor" "Cursor - AI-powered code editor" "Zed - High-performance editor" "Windsurf - AI-powered IDE" "Sublime Text - Fast, lightweight" "Vim - Classic terminal editor" "Neovim - Modern terminal editor" "GNU Emacs - Extensible text editor" "Notepad++ - Windows code editor" "IntelliJ IDEA Community - Java, Kotlin" "PyCharm Community - Python IDE" "WebStorm - JS/TS IDE (paid)" "GoLand - Go IDE (paid)" "CLion - C/C++ IDE (paid)" "Rider - .NET IDE (paid)" "RustRover - Rust IDE" "JetBrains Fleet - Lightweight multi-lang" "Eclipse IDE - Java, multi-language" "Apache NetBeans - Java, PHP, HTML5" "Android Studio - Android development")

    local TOOL_KEYS=("git" "docker" "postman" "cmake" "gh" "pyenv")
    local TOOL_LABELS=("Git - Version control" "Docker - Containers" "Postman - API testing" "CMake - Build system" "GitHub CLI - GitHub from terminal" "pyenv - Python version manager")

    local FW_KEYS=("npm" "yarn" "pnpm" "bun" "venvstudio" "uv" "poetry" "pipx" "conda" "react" "nextjs" "vue" "nuxt" "angular" "svelte" "vite" "astro" "express" "nest" "remix" "django" "flask" "fastapi" "streamlit" "tailwind" "bootstrap" "reactnative" "expo" "ionic" "electron" "tauri" "cargo-watch" "wasm-pack" "blazor" "maui" "terraform" "kubectl" "helm")
    local FW_LABELS=("npm (latest) - Node default pkg manager" "Yarn - Fast JS pkg manager" "pnpm - Disk-efficient JS pkg manager" "Bun - Ultra-fast JS runtime" "VenvStudio - GUI venv manager (PySide6)" "uv - Ultra-fast Python pkg manager (Rust)" "Poetry - Python dependency mgmt" "pipx - Isolated Python CLI tools" "Miniconda - Python/R data science" "React (create-react-app) - Facebook UI" "Next.js - React fullstack framework" "Vue CLI - Progressive JS framework" "Nuxt (nuxi) - Vue fullstack framework" "Angular CLI - Google enterprise web" "SvelteKit - Lightweight reactive" "Vite - Next-gen build tool" "Astro - Content-focused web framework" "Express.js - Minimal Node.js web" "NestJS CLI - Progressive Node.js" "Remix - Full stack web framework" "Django - Python web framework" "Flask - Lightweight Python web" "FastAPI - Modern async Python API" "Streamlit - Python data app" "Tailwind CSS - Utility-first CSS" "Bootstrap - Popular CSS framework" "React Native CLI - Cross-platform mobile" "Expo CLI - React Native toolchain" "Ionic CLI - Cross-platform mobile" "Electron Forge - Desktop apps (web tech)" "Tauri CLI - Lightweight desktop (Rust)" "cargo-watch - Rust auto-rebuild" "wasm-pack - Rust to WebAssembly" "Blazor - C# web UI (in .NET SDK)" ".NET MAUI - Cross-platform .NET UI" "Terraform - Infrastructure as code" "kubectl - Kubernetes CLI" "Helm - Kubernetes pkg manager")

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
            1) add_unique sel_langs "nodejs" "python" "php" "typescript"; add_unique sel_ides "vscode" "sublime"; add_unique sel_tools "git" "docker" "postman"; add_unique sel_fws "yarn" "pnpm" "vite" "react" "tailwind" "express" ;;
            2) add_unique sel_langs "java" "kotlin" "dart"; add_unique sel_ides "android" "vscode"; add_unique sel_tools "git"; add_unique sel_fws "reactnative" "expo" ;;
            3) add_unique sel_langs "python" "julia" "mojo"; add_unique sel_ides "vscode" "pycharm"; add_unique sel_tools "git" "docker"; add_unique sel_fws "venvstudio" "uv" "conda" "streamlit" "fastapi" ;;
            4) add_unique sel_langs "cpp" "rust" "zig" "go"; add_unique sel_ides "vscode" "clion" "vim"; add_unique sel_tools "git" "cmake"; add_unique sel_fws "cargo-watch" "wasm-pack" ;;
            5) add_unique sel_langs "csharp" "nodejs" "typescript"; add_unique sel_ides "vscode" "rider"; add_unique sel_tools "git" "docker" "postman"; add_unique sel_fws "yarn" "vite" "react" "nextjs" ;;
            6) add_unique sel_langs "cpp" "csharp"; add_unique sel_ides "vscode" "rider"; add_unique sel_tools "git" "cmake" ;;
            7) add_unique sel_langs "python" "julia" "mojo" "rust"; add_unique sel_ides "vscode" "pycharm" "cursor"; add_unique sel_tools "git" "docker"; add_unique sel_fws "venvstudio" "uv" "conda" "streamlit" "fastapi" ;;
            8) is_custom=1 ;;
            9) is_all=1 ;;
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

main "$@"
