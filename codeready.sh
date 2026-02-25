#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║                   CodeReady v1.0.0                               ║
# ║       Developer Environment Setup Tool (Linux/macOS)             ║
# ║       https://github.com/user/codeready                         ║
# ╚══════════════════════════════════════════════════════════════════╝

set -euo pipefail

VERSION="1.0.0"
LOG_FILE="$HOME/codeready_install.log"
CONFIG_FILE="$HOME/codeready_config.json"
INSTALLED_ITEMS=()
FAILED_ITEMS=()

# ─── Detect OS ─────────────────────────────────────────────────────
detect_os() {
    OS_TYPE=""
    PKG_MANAGER=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        PKG_MANAGER="brew"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        case "$ID" in
            ubuntu|debian|linuxmint|pop)
                OS_TYPE="debian"
                PKG_MANAGER="apt"
                ;;
            fedora)
                OS_TYPE="fedora"
                PKG_MANAGER="dnf"
                ;;
            centos|rhel|rocky|alma)
                OS_TYPE="rhel"
                PKG_MANAGER="dnf"
                ;;
            arch|manjaro|endeavouros)
                OS_TYPE="arch"
                PKG_MANAGER="pacman"
                ;;
            opensuse*|sles)
                OS_TYPE="suse"
                PKG_MANAGER="zypper"
                ;;
            *)
                OS_TYPE="linux"
                PKG_MANAGER="unknown"
                ;;
        esac
    else
        echo "Unsupported operating system."
        exit 1
    fi
    
    echo "$OS_TYPE detected (package manager: $PKG_MANAGER)"
}

# ─── Colors & UI ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m' # No Color
BOLD='\033[1m'

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
   ██████╗ ██████╗ ██████╗ ███████╗██████╗ ███████╗ █████╗ ██████╗ ██╗   ██╗
  ██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
  ██║     ██║   ██║██║  ██║█████╗  ██████╔╝█████╗  ███████║██║  ██║ ╚████╔╝
  ██║     ██║   ██║██║  ██║██╔══╝  ██╔══██╗██╔══╝  ██╔══██║██║  ██║  ╚██╔╝
  ╚██████╗╚██████╔╝██████╔╝███████╗██║  ██║███████╗██║  ██║██████╔╝   ██║
   ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝    ╚═╝
EOF
    echo -e "                                                              v${VERSION}${NC}"
    echo -e "  ${GRAY}Developer Environment Setup Tool - Linux/macOS Edition${NC}"
    echo -e "  ${GRAY}═══════════════════════════════════════════════════${NC}"
    echo ""
}

print_step()    { echo -e "  ${YELLOW}[►]${NC} $1"; }
print_success() { echo -e "  ${GREEN}[✓]${NC} $1"; echo "[OK] $1" >> "$LOG_FILE"; }
print_fail()    { echo -e "  ${RED}[✗]${NC} $1"; echo "[FAIL] $1" >> "$LOG_FILE"; }
print_info()    { echo -e "  ${CYAN}[i]${NC} ${GRAY}$1${NC}"; }

print_section() {
    echo ""
    echo -e "  ${YELLOW}┌──────────────────────────────────────────────────┐${NC}"
    printf "  ${YELLOW}│  %-48s │${NC}\n" "$1"
    echo -e "  ${YELLOW}└──────────────────────────────────────────────────┘${NC}"
    echo ""
}

# ─── Package Manager Setup ─────────────────────────────────────────
ensure_homebrew() {
    print_step "Checking Homebrew..."
    if command -v brew &>/dev/null; then
        print_success "Homebrew is already installed."
        return 0
    fi
    print_step "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for current session
    if [[ "$OS_TYPE" == "macos" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
    else
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv 2>/dev/null)"
    fi
    print_success "Homebrew installed."
}

ensure_snap() {
    if command -v snap &>/dev/null; then
        return 0
    fi
    case "$PKG_MANAGER" in
        apt)  sudo apt install -y snapd ;;
        dnf)  sudo dnf install -y snapd ;;
    esac
}

update_package_manager() {
    print_step "Updating package manager..."
    case "$PKG_MANAGER" in
        apt)    sudo apt update -y && sudo apt upgrade -y ;;
        dnf)    sudo dnf update -y ;;
        pacman) sudo pacman -Syu --noconfirm ;;
        zypper) sudo zypper refresh && sudo zypper update -y ;;
        brew)   brew update ;;
    esac
    print_success "Package manager updated."
}

# ─── Generic Installer ─────────────────────────────────────────────
install_package() {
    local name="$1"
    shift
    # Remaining args: platform-specific install commands
    
    print_step "Installing $name..."
    
    if eval "$@" &>>"$LOG_FILE" 2>&1; then
        print_success "$name installed successfully."
        INSTALLED_ITEMS+=("$name")
        return 0
    else
        print_fail "Failed to install $name."
        FAILED_ITEMS+=("$name")
        return 1
    fi
}

# ─── Language Installers ───────────────────────────────────────────
install_python() {
    case "$PKG_MANAGER" in
        brew)   install_package "Python" "brew install python@3.12" ;;
        apt)    install_package "Python" "sudo apt install -y python3 python3-pip python3-venv" ;;
        dnf)    install_package "Python" "sudo dnf install -y python3 python3-pip" ;;
        pacman) install_package "Python" "sudo pacman -S --noconfirm python python-pip" ;;
        zypper) install_package "Python" "sudo zypper install -y python3 python3-pip" ;;
    esac
}

install_nodejs() {
    # Use nvm for better version management
    print_step "Installing Node.js via nvm..."
    if ! command -v nvm &>/dev/null && [[ ! -d "$HOME/.nvm" ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash &>>"$LOG_FILE"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    fi
    
    if command -v nvm &>/dev/null || [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        [ -s "$HOME/.nvm/nvm.sh" ] && . "$HOME/.nvm/nvm.sh"
        nvm install --lts &>>"$LOG_FILE" 2>&1
        nvm use --lts &>>"$LOG_FILE" 2>&1
        print_success "Node.js LTS installed via nvm."
        INSTALLED_ITEMS+=("Node.js")
    else
        # Fallback to package manager
        case "$PKG_MANAGER" in
            brew)   install_package "Node.js" "brew install node" ;;
            apt)    install_package "Node.js" "sudo apt install -y nodejs npm" ;;
            dnf)    install_package "Node.js" "sudo dnf install -y nodejs npm" ;;
            pacman) install_package "Node.js" "sudo pacman -S --noconfirm nodejs npm" ;;
        esac
    fi
}

install_java() {
    case "$PKG_MANAGER" in
        brew)   install_package "Java (JDK 21)" "brew install --cask temurin@21" ;;
        apt)    install_package "Java (JDK 21)" "sudo apt install -y temurin-21-jdk || sudo apt install -y openjdk-21-jdk" ;;
        dnf)    install_package "Java (JDK 21)" "sudo dnf install -y java-21-openjdk-devel" ;;
        pacman) install_package "Java (JDK 21)" "sudo pacman -S --noconfirm jdk-openjdk" ;;
        zypper) install_package "Java (JDK 21)" "sudo zypper install -y java-21-openjdk-devel" ;;
    esac
}

install_csharp() {
    case "$PKG_MANAGER" in
        brew)   install_package "C# / .NET SDK" "brew install dotnet-sdk" ;;
        apt)
            install_package "C# / .NET SDK" "sudo apt install -y dotnet-sdk-8.0 || (wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh && chmod +x /tmp/dotnet-install.sh && /tmp/dotnet-install.sh --channel 8.0)"
            ;;
        dnf)    install_package "C# / .NET SDK" "sudo dnf install -y dotnet-sdk-8.0" ;;
        pacman) install_package "C# / .NET SDK" "sudo pacman -S --noconfirm dotnet-sdk" ;;
    esac
}

install_cpp() {
    case "$PKG_MANAGER" in
        brew)   install_package "C/C++ (Clang/GCC)" "brew install gcc llvm cmake" ;;
        apt)    install_package "C/C++ (GCC/G++)" "sudo apt install -y build-essential gcc g++ gdb cmake" ;;
        dnf)    install_package "C/C++ (GCC/G++)" "sudo dnf install -y gcc gcc-c++ gdb cmake make" ;;
        pacman) install_package "C/C++ (GCC/G++)" "sudo pacman -S --noconfirm base-devel gcc gdb cmake" ;;
        zypper) install_package "C/C++ (GCC/G++)" "sudo zypper install -y gcc gcc-c++ gdb cmake make" ;;
    esac
}

install_go() {
    case "$PKG_MANAGER" in
        brew)   install_package "Go" "brew install go" ;;
        *)
            print_step "Installing Go from official binary..."
            local GO_VERSION="1.22.5"
            local ARCH
            ARCH=$(uname -m)
            case "$ARCH" in
                x86_64)  ARCH="amd64" ;;
                aarch64|arm64) ARCH="arm64" ;;
            esac
            curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -o /tmp/go.tar.gz
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf /tmp/go.tar.gz
            echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.bashrc"
            echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.zshrc" 2>/dev/null || true
            export PATH=$PATH:/usr/local/go/bin
            rm /tmp/go.tar.gz
            print_success "Go ${GO_VERSION} installed."
            INSTALLED_ITEMS+=("Go")
            ;;
    esac
}

install_rust() {
    print_step "Installing Rust via rustup..."
    if command -v rustup &>/dev/null; then
        print_success "Rust is already installed."
        INSTALLED_ITEMS+=("Rust")
        return 0
    fi
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y &>>"$LOG_FILE"
    source "$HOME/.cargo/env" 2>/dev/null || true
    print_success "Rust installed via rustup."
    INSTALLED_ITEMS+=("Rust")
}

install_php() {
    case "$PKG_MANAGER" in
        brew)   install_package "PHP" "brew install php composer" ;;
        apt)    install_package "PHP" "sudo apt install -y php php-cli php-common php-mbstring php-xml composer" ;;
        dnf)    install_package "PHP" "sudo dnf install -y php php-cli php-common php-mbstring php-xml composer" ;;
        pacman) install_package "PHP" "sudo pacman -S --noconfirm php composer" ;;
    esac
}

install_ruby() {
    case "$PKG_MANAGER" in
        brew)   install_package "Ruby" "brew install ruby" ;;
        apt)    install_package "Ruby" "sudo apt install -y ruby ruby-dev rubygems" ;;
        dnf)    install_package "Ruby" "sudo dnf install -y ruby ruby-devel rubygems" ;;
        pacman) install_package "Ruby" "sudo pacman -S --noconfirm ruby rubygems" ;;
    esac
}

install_kotlin() {
    case "$PKG_MANAGER" in
        brew) install_package "Kotlin" "brew install kotlin" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "Kotlin" "sudo snap install kotlin --classic"
            else
                print_step "Installing Kotlin via SDKMAN..."
                curl -s "https://get.sdkman.io" | bash &>>"$LOG_FILE"
                source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
                sdk install kotlin &>>"$LOG_FILE" 2>&1
                print_success "Kotlin installed via SDKMAN."
                INSTALLED_ITEMS+=("Kotlin")
            fi
            ;;
    esac
}

install_dart() {
    case "$PKG_MANAGER" in
        brew) install_package "Dart & Flutter" "brew install --cask flutter" ;;
        apt)
            print_step "Installing Flutter (includes Dart)..."
            if command -v snap &>/dev/null; then
                install_package "Dart & Flutter" "sudo snap install flutter --classic"
            else
                install_package "Dart SDK" "sudo apt install -y apt-transport-https && sudo sh -c 'wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -' && sudo sh -c 'wget -qO- https://storage.googleapis.com/download.dartlang.org/linux/debian/dart_stable.list > /etc/apt/sources.list.d/dart_stable.list' && sudo apt update && sudo apt install -y dart"
            fi
            ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "Dart & Flutter" "sudo snap install flutter --classic"
            else
                print_fail "Please install Flutter manually from https://flutter.dev"
                FAILED_ITEMS+=("Dart & Flutter")
            fi
            ;;
    esac
}

install_swift() {
    case "$PKG_MANAGER" in
        brew)
            # Swift comes with Xcode on macOS
            print_step "Installing Swift..."
            if command -v swift &>/dev/null; then
                print_success "Swift is already available (via Xcode)."
                INSTALLED_ITEMS+=("Swift")
            else
                print_info "Please install Xcode from the App Store for Swift support."
                print_info "Or install: xcode-select --install"
                FAILED_ITEMS+=("Swift")
            fi
            ;;
        apt)
            install_package "Swift" "sudo apt install -y swift || (curl -fsSL https://swift.org/install.sh | bash)"
            ;;
        *)
            print_info "Swift on Linux: visit https://swift.org/getting-started/"
            FAILED_ITEMS+=("Swift")
            ;;
    esac
}

# ─── IDE Installers ────────────────────────────────────────────────
install_vscode() {
    case "$PKG_MANAGER" in
        brew) install_package "VS Code" "brew install --cask visual-studio-code" ;;
        apt)
            install_package "VS Code" "sudo snap install code --classic || (wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /tmp/packages.microsoft.gpg && sudo install -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg && echo 'deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main' | sudo tee /etc/apt/sources.list.d/vscode.list && sudo apt update && sudo apt install -y code)"
            ;;
        dnf) install_package "VS Code" "sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc && echo -e '[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc' | sudo tee /etc/yum.repos.d/vscode.repo && sudo dnf install -y code" ;;
        pacman) install_package "VS Code" "sudo pacman -S --noconfirm code || yay -S --noconfirm visual-studio-code-bin" ;;
    esac
}

install_intellij() {
    case "$PKG_MANAGER" in
        brew) install_package "IntelliJ IDEA Community" "brew install --cask intellij-idea-ce" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "IntelliJ IDEA Community" "sudo snap install intellij-idea-community --classic"
            else
                print_info "Download IntelliJ IDEA from: https://www.jetbrains.com/idea/download/"
                FAILED_ITEMS+=("IntelliJ IDEA Community")
            fi
            ;;
    esac
}

install_pycharm() {
    case "$PKG_MANAGER" in
        brew) install_package "PyCharm Community" "brew install --cask pycharm-ce" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "PyCharm Community" "sudo snap install pycharm-community --classic"
            else
                print_info "Download PyCharm from: https://www.jetbrains.com/pycharm/download/"
                FAILED_ITEMS+=("PyCharm Community")
            fi
            ;;
    esac
}

install_webstorm() {
    case "$PKG_MANAGER" in
        brew) install_package "WebStorm" "brew install --cask webstorm" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "WebStorm" "sudo snap install webstorm --classic"
            else
                print_info "Download WebStorm from: https://www.jetbrains.com/webstorm/download/"
                FAILED_ITEMS+=("WebStorm")
            fi
            ;;
    esac
}

install_goland() {
    case "$PKG_MANAGER" in
        brew) install_package "GoLand" "brew install --cask goland" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "GoLand" "sudo snap install goland --classic"
            else
                print_info "Download GoLand from: https://www.jetbrains.com/go/download/"
                FAILED_ITEMS+=("GoLand")
            fi
            ;;
    esac
}

install_clion() {
    case "$PKG_MANAGER" in
        brew) install_package "CLion" "brew install --cask clion" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "CLion" "sudo snap install clion --classic"
            else
                print_info "Download CLion from: https://www.jetbrains.com/clion/download/"
                FAILED_ITEMS+=("CLion")
            fi
            ;;
    esac
}

install_rider() {
    case "$PKG_MANAGER" in
        brew) install_package "Rider" "brew install --cask rider" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "Rider" "sudo snap install rider --classic"
            else
                print_info "Download Rider from: https://www.jetbrains.com/rider/download/"
                FAILED_ITEMS+=("Rider")
            fi
            ;;
    esac
}

install_eclipse() {
    case "$PKG_MANAGER" in
        brew) install_package "Eclipse IDE" "brew install --cask eclipse-jee" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "Eclipse IDE" "sudo snap install eclipse --classic"
            else
                print_info "Download Eclipse from: https://www.eclipse.org/downloads/"
                FAILED_ITEMS+=("Eclipse IDE")
            fi
            ;;
    esac
}

install_android_studio() {
    case "$PKG_MANAGER" in
        brew) install_package "Android Studio" "brew install --cask android-studio" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "Android Studio" "sudo snap install android-studio --classic"
            else
                print_info "Download Android Studio from: https://developer.android.com/studio"
                FAILED_ITEMS+=("Android Studio")
            fi
            ;;
    esac
}

install_sublime() {
    case "$PKG_MANAGER" in
        brew) install_package "Sublime Text" "brew install --cask sublime-text" ;;
        apt)
            install_package "Sublime Text" "sudo snap install sublime-text --classic || (wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add - && echo 'deb https://download.sublimetext.com/ apt/stable/' | sudo tee /etc/apt/sources.list.d/sublime-text.list && sudo apt update && sudo apt install -y sublime-text)"
            ;;
        dnf) install_package "Sublime Text" "sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg && sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo && sudo dnf install -y sublime-text" ;;
        pacman) install_package "Sublime Text" "sudo pacman -S --noconfirm sublime-text-4 || yay -S --noconfirm sublime-text-4" ;;
    esac
}

install_vim() {
    case "$PKG_MANAGER" in
        brew)   install_package "Neovim" "brew install neovim" ;;
        apt)    install_package "Neovim" "sudo apt install -y neovim" ;;
        dnf)    install_package "Neovim" "sudo dnf install -y neovim" ;;
        pacman) install_package "Neovim" "sudo pacman -S --noconfirm neovim" ;;
        zypper) install_package "Neovim" "sudo zypper install -y neovim" ;;
    esac
}

install_vs2022() {
    print_info "Visual Studio 2022 is Windows-only. Skipping on $OS_TYPE."
    print_info "Consider using VS Code or Rider as alternatives."
}

install_notepadpp() {
    print_info "Notepad++ is Windows-only. Skipping on $OS_TYPE."
    print_info "Consider using Sublime Text or VS Code as alternatives."
}

install_cursor() {
    case "$PKG_MANAGER" in
        brew) install_package "Cursor" "brew install --cask cursor" ;;
        *)
            print_info "Download Cursor from: https://cursor.sh"
            FAILED_ITEMS+=("Cursor")
            ;;
    esac
}

# ─── Tool Installers ──────────────────────────────────────────────
install_git() {
    case "$PKG_MANAGER" in
        brew)   install_package "Git" "brew install git" ;;
        apt)    install_package "Git" "sudo apt install -y git" ;;
        dnf)    install_package "Git" "sudo dnf install -y git" ;;
        pacman) install_package "Git" "sudo pacman -S --noconfirm git" ;;
        zypper) install_package "Git" "sudo zypper install -y git" ;;
    esac
}

install_docker() {
    case "$PKG_MANAGER" in
        brew) install_package "Docker Desktop" "brew install --cask docker" ;;
        apt)
            install_package "Docker" "sudo apt install -y ca-certificates curl && sudo install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && sudo chmod a+r /etc/apt/keyrings/docker.asc && echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \$(. /etc/os-release && echo \$VERSION_CODENAME) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && sudo usermod -aG docker \$USER"
            ;;
        dnf) install_package "Docker" "sudo dnf install -y docker && sudo systemctl enable --now docker && sudo usermod -aG docker \$USER" ;;
        pacman) install_package "Docker" "sudo pacman -S --noconfirm docker docker-compose && sudo systemctl enable --now docker && sudo usermod -aG docker \$USER" ;;
    esac
}

install_postman() {
    case "$PKG_MANAGER" in
        brew) install_package "Postman" "brew install --cask postman" ;;
        *)
            if command -v snap &>/dev/null; then
                install_package "Postman" "sudo snap install postman"
            else
                print_info "Download Postman from: https://www.postman.com/downloads/"
                FAILED_ITEMS+=("Postman")
            fi
            ;;
    esac
}

install_cmake() {
    case "$PKG_MANAGER" in
        brew)   install_package "CMake" "brew install cmake" ;;
        apt)    install_package "CMake" "sudo apt install -y cmake" ;;
        dnf)    install_package "CMake" "sudo dnf install -y cmake" ;;
        pacman) install_package "CMake" "sudo pacman -S --noconfirm cmake" ;;
    esac
}

install_gh() {
    case "$PKG_MANAGER" in
        brew)   install_package "GitHub CLI" "brew install gh" ;;
        apt)    install_package "GitHub CLI" "sudo apt install -y gh || (curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && echo 'deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main' | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null && sudo apt update && sudo apt install -y gh)" ;;
        dnf)    install_package "GitHub CLI" "sudo dnf install -y gh" ;;
        pacman) install_package "GitHub CLI" "sudo pacman -S --noconfirm github-cli" ;;
    esac
}

install_terminal() {
    print_info "Windows Terminal is Windows-only. Skipping."
}

install_wsl() {
    print_info "WSL is Windows-only. Skipping."
}

# ─── Menu System ───────────────────────────────────────────────────
show_multiselect_menu() {
    local title="$1"
    shift
    local -n _items=$1
    shift
    local -n _result=$1

    print_section "$title"
    
    local i=1
    local keys=()
    for key in "${!_items[@]}"; do
        keys+=("$key")
        echo -e "  ${CYAN}[$i]${NC} ${_items[$key]}"
        ((i++))
    done
    
    echo ""
    echo -e "  ${GRAY}Enter numbers separated by spaces (e.g., 1 3 5)${NC}"
    echo -e "  ${GRAY}Enter 'a' for all, 'n' for none${NC}"
    echo ""
    read -rp "  Your selection: " selection
    
    _result=()
    
    if [[ "$selection" == "a" || "$selection" == "A" ]]; then
        _result=("${keys[@]}")
        return
    fi
    
    if [[ "$selection" == "n" || "$selection" == "N" ]]; then
        return
    fi
    
    for num in $selection; do
        if [[ "$num" =~ ^[0-9]+$ ]] && (( num >= 1 && num <= ${#keys[@]} )); then
            _result+=("${keys[$((num-1))]}")
        fi
    done
}

# ─── Profile System ───────────────────────────────────────────────
show_profile_menu() {
    print_section "Quick Setup Profiles"
    echo -e "  ${BOLD}[1]${NC} Web Developer      ${GRAY}- Node.js, Python, PHP + VS Code, Sublime${NC}"
    echo -e "  ${BOLD}[2]${NC} Mobile Developer   ${GRAY}- Java, Kotlin, Dart + Android Studio, VS Code${NC}"
    echo -e "  ${BOLD}[3]${NC} Data Scientist     ${GRAY}- Python + VS Code, PyCharm${NC}"
    echo -e "  ${BOLD}[4]${NC} Systems Programmer ${GRAY}- C/C++, Rust, Go + VS Code, CLion, Vim${NC}"
    echo -e "  ${BOLD}[5]${NC} Full Stack .NET    ${GRAY}- C#/.NET, Node.js + VS Code, Rider${NC}"
    echo -e "  ${BOLD}[6]${NC} Game Developer     ${GRAY}- C/C++, C# + VS Code${NC}"
    echo -e "  ${BOLD}[7]${NC} Custom Setup       ${GRAY}- Choose your own languages & IDEs${NC}"
    echo ""
    read -rp "  Select profile (1-7): " choice
    echo "$choice"
}

# ─── Dispatcher ────────────────────────────────────────────────────
install_language() {
    case "$1" in
        python)  install_python ;;
        nodejs)  install_nodejs ;;
        java)    install_java ;;
        csharp)  install_csharp ;;
        cpp)     install_cpp ;;
        go)      install_go ;;
        rust)    install_rust ;;
        php)     install_php ;;
        ruby)    install_ruby ;;
        kotlin)  install_kotlin ;;
        dart)    install_dart ;;
        swift)   install_swift ;;
        *) print_fail "Unknown language: $1" ;;
    esac
}

install_ide() {
    case "$1" in
        vscode)     install_vscode ;;
        vs2022)     install_vs2022 ;;
        intellij)   install_intellij ;;
        pycharm)    install_pycharm ;;
        webstorm)   install_webstorm ;;
        goland)     install_goland ;;
        clion)      install_clion ;;
        rider)      install_rider ;;
        eclipse)    install_eclipse ;;
        android)    install_android_studio ;;
        sublime)    install_sublime ;;
        vim)        install_vim ;;
        notepadpp)  install_notepadpp ;;
        cursor)     install_cursor ;;
        *) print_fail "Unknown IDE: $1" ;;
    esac
}

install_tool() {
    case "$1" in
        git)      install_git ;;
        docker)   install_docker ;;
        postman)  install_postman ;;
        wsl)      install_wsl ;;
        terminal) install_terminal ;;
        cmake)    install_cmake ;;
        gh)       install_gh ;;
        *) print_fail "Unknown tool: $1" ;;
    esac
}

# ─── Summary ───────────────────────────────────────────────────────
show_summary() {
    print_section "Installation Summary"
    
    if [[ ${#INSTALLED_ITEMS[@]} -gt 0 ]]; then
        echo -e "  ${GREEN}Successfully installed (${#INSTALLED_ITEMS[@]}):${NC}"
        for item in "${INSTALLED_ITEMS[@]}"; do
            echo -e "    ${GREEN}✓${NC} $item"
        done
    fi
    
    if [[ ${#FAILED_ITEMS[@]} -gt 0 ]]; then
        echo ""
        echo -e "  ${RED}Failed installations (${#FAILED_ITEMS[@]}):${NC}"
        for item in "${FAILED_ITEMS[@]}"; do
            echo -e "    ${RED}✗${NC} $item"
        done
    fi
    
    echo ""
    echo -e "  ${CYAN}Total: ${#INSTALLED_ITEMS[@]} succeeded, ${#FAILED_ITEMS[@]} failed${NC}"
    echo -e "  ${GRAY}Log file: $LOG_FILE${NC}"
    echo ""
    
    if [[ ${#INSTALLED_ITEMS[@]} -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠  Please restart your terminal for PATH changes to take effect.${NC}"
        echo -e "  ${GRAY}   Or run: source ~/.bashrc (or source ~/.zshrc)${NC}"
    fi
    echo ""
}

# ─── MAIN ──────────────────────────────────────────────────────────
main() {
    print_banner
    
    # Init log
    echo "CodeReady Installation Log - $(date)" > "$LOG_FILE"
    
    # Detect OS
    print_section "System Detection"
    detect_os
    
    # Setup package manager
    print_section "Package Manager Setup"
    if [[ "$OS_TYPE" == "macos" ]]; then
        ensure_homebrew
    else
        update_package_manager
        ensure_snap || true
    fi
    
    # Profile selection
    profile_choice=$(show_profile_menu)
    
    declare -a selected_langs selected_ides selected_tools
    
    case "$profile_choice" in
        1) selected_langs=(nodejs python php); selected_ides=(vscode sublime); selected_tools=(git docker postman) ;;
        2) selected_langs=(java kotlin dart); selected_ides=(android vscode); selected_tools=(git) ;;
        3) selected_langs=(python nodejs); selected_ides=(vscode pycharm); selected_tools=(git docker) ;;
        4) selected_langs=(cpp rust go); selected_ides=(vscode clion vim); selected_tools=(git cmake) ;;
        5) selected_langs=(csharp nodejs); selected_ides=(vscode rider); selected_tools=(git docker postman) ;;
        6) selected_langs=(cpp csharp); selected_ides=(vscode); selected_tools=(git cmake) ;;
        7|*)
            # Custom menu selections
            declare -A lang_menu=(
                [python]="Python - General purpose, AI/ML, scripting"
                [nodejs]="Node.js - JavaScript/TypeScript runtime"
                [java]="Java (JDK) - Enterprise, Android, cross-platform"
                [csharp]="C# / .NET SDK - Microsoft ecosystem, web, desktop"
                [cpp]="C/C++ - Systems programming, performance-critical"
                [go]="Go (Golang) - Cloud, networking, microservices"
                [rust]="Rust - Systems programming, memory safety"
                [php]="PHP - Web development, CMS, server-side"
                [ruby]="Ruby - Web development, scripting, DevOps"
                [kotlin]="Kotlin - Android, JVM, multiplatform"
                [dart]="Dart & Flutter - Mobile, web, desktop UI"
                [swift]="Swift - Apple ecosystem, server-side"
            )
            
            declare -A ide_menu=(
                [vscode]="VS Code - Lightweight, extensible, multi-language"
                [intellij]="IntelliJ IDEA Community - Java, Kotlin, JVM"
                [pycharm]="PyCharm Community - Python IDE"
                [webstorm]="WebStorm - JavaScript/TypeScript IDE (paid)"
                [goland]="GoLand - Go IDE (paid)"
                [clion]="CLion - C/C++ IDE (paid)"
                [rider]="Rider - .NET IDE (paid)"
                [eclipse]="Eclipse IDE - Java, C/C++, PHP"
                [android]="Android Studio - Official Android IDE"
                [sublime]="Sublime Text - Fast, lightweight editor"
                [vim]="Neovim - Terminal-based editor"
                [cursor]="Cursor - AI-powered code editor"
            )
            
            declare -A tool_menu=(
                [git]="Git - Version control system"
                [docker]="Docker - Containerization platform"
                [postman]="Postman - API testing & development"
                [cmake]="CMake - Cross-platform build system"
                [gh]="GitHub CLI - GitHub from command line"
            )
            
            show_multiselect_menu "Select Programming Languages" lang_menu selected_langs
            show_multiselect_menu "Select IDEs & Editors" ide_menu selected_ides
            show_multiselect_menu "Select Developer Tools" tool_menu selected_tools
            ;;
    esac
    
    # Confirmation
    print_section "Installation Plan"
    echo -e "  ${CYAN}Languages:${NC} ${selected_langs[*]}"
    echo -e "  ${CYAN}IDEs:${NC}      ${selected_ides[*]}"
    echo -e "  ${CYAN}Tools:${NC}     ${selected_tools[*]}"
    echo ""
    read -rp "  Proceed with installation? (Y/n): " confirm
    
    if [[ "$confirm" == "n" || "$confirm" == "N" ]]; then
        print_info "Installation cancelled."
        exit 0
    fi
    
    # Install Languages
    print_section "Installing Languages & Runtimes"
    for lang in "${selected_langs[@]}"; do
        install_language "$lang"
    done
    
    # Install IDEs
    print_section "Installing IDEs & Editors"
    for ide in "${selected_ides[@]}"; do
        install_ide "$ide"
    done
    
    # Install Tools
    print_section "Installing Developer Tools"
    for tool in "${selected_tools[@]}"; do
        install_tool "$tool"
    done
    
    # Summary
    show_summary
}

# Run
main "$@"
