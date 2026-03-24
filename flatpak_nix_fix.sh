#!/usr/bin/env bash
# ============================================================================
# CodeReady v2.1 — Flatpak & Nix Auto-Install Fix
# Add these functions to codeready.sh (after detect_os / pkg manager section)
# ============================================================================

# --- Flatpak Auto-Install ---------------------------------------------------
install_flatpak() {
    if command -v flatpak &>/dev/null; then
        log_ok "Flatpak already installed: $(flatpak --version 2>/dev/null)"
        return 0
    fi

    echo ""
    echo -e "${CYAN}[?] Flatpak is not installed. Install it?${NC}"
    echo -e "    Flatpak enables sandboxed app installs (VS Code, Postman, etc.)"
    read -rp "    Install Flatpak? [Y/n]: " ans
    ans="${ans:-Y}"
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        log_warn "Flatpak skipped — some IDEs may not be installable"
        return 1
    fi

    log_info "Installing Flatpak..."
    case "$PKG_MANAGER" in
        apt)
            sudo apt-get update -qq
            sudo apt-get install -y flatpak
            ;;
        dnf)
            sudo dnf install -y flatpak
            ;;
        pacman)
            sudo pacman -S --noconfirm flatpak
            ;;
        zypper)
            sudo zypper install -y flatpak
            ;;
        *)
            log_warn "Cannot auto-install Flatpak on this system (unknown pkg manager: $PKG_MANAGER)"
            return 1
            ;;
    esac

    if command -v flatpak &>/dev/null; then
        # Add Flathub repo if not present
        if ! flatpak remotes 2>/dev/null | grep -q "flathub"; then
            log_info "Adding Flathub repository..."
            flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        fi
        log_ok "Flatpak installed successfully"
        return 0
    else
        log_err "Flatpak installation failed"
        return 1
    fi
}

# --- Nix Auto-Install --------------------------------------------------------
install_nix() {
    if command -v nix &>/dev/null; then
        log_ok "Nix already installed: $(nix --version 2>/dev/null)"
        return 0
    fi

    echo ""
    echo -e "${CYAN}[?] Nix package manager is not installed. Install it?${NC}"
    echo -e "    Nix provides reproducible builds and 80,000+ packages"
    echo -e "    Install is user-level only — does not affect system packages"
    read -rp "    Install Nix? [Y/n]: " ans
    ans="${ans:-Y}"
    if [[ ! "$ans" =~ ^[Yy]$ ]]; then
        log_warn "Nix skipped"
        return 1
    fi

    log_info "Installing Nix (multi-user daemon mode)..."

    # Detect if running in Docker/container (no systemd)
    if [ -f /.dockerenv ] || grep -qsE "(docker|lxc|containerd)" /proc/1/cgroup 2>/dev/null; then
        log_info "Container detected — installing Nix in single-user mode..."
        sh <(curl -L https://nixos.org/nix/install) --no-daemon
    else
        sh <(curl -L https://nixos.org/nix/install) --daemon --yes
    fi

    # Source nix profile
    if [ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    elif [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    fi

    if command -v nix &>/dev/null; then
        log_ok "Nix installed successfully"
        return 0
    else
        log_warn "Nix installed but not in PATH — restart your shell or run: . ~/.nix-profile/etc/profile.d/nix.sh"
        return 1
    fi
}

# --- Offer Missing Package Managers ------------------------------------------
# Call this after detect_os() and before main menu
offer_package_managers() {
    local HAS_FLATPAK=false
    local HAS_NIX=false

    command -v flatpak &>/dev/null && HAS_FLATPAK=true
    command -v nix &>/dev/null && HAS_NIX=true

    # Only offer on Linux (macOS uses brew, Windows uses winget/scoop/choco)
    if [[ "$OS_TYPE" != "linux" ]]; then
        return 0
    fi

    if ! $HAS_FLATPAK || ! $HAS_NIX; then
        echo ""
        echo -e "${YELLOW}━━━ Optional Package Managers ━━━${NC}"
    fi

    if ! $HAS_FLATPAK; then
        install_flatpak
    fi

    if ! $HAS_NIX; then
        install_nix
    fi
}

# --- Updated flatpak_or_snap() with auto-install ----------------------------
# Replace existing flatpak_or_snap() with this version
flatpak_or_snap() {
    local flatpak_id="$1"
    local snap_id="$2"
    local name="$3"

    # Try flatpak first — auto-install if missing
    if ! command -v flatpak &>/dev/null; then
        log_info "Flatpak not available, attempting install..."
        install_flatpak
    fi

    if command -v flatpak &>/dev/null; then
        log_info "Installing $name via Flatpak..."
        if flatpak install -y flathub "$flatpak_id" 2>/dev/null; then
            log_ok "$name installed via Flatpak"
            return 0
        else
            log_warn "Flatpak install failed for $name"
        fi
    fi

    # Snap as last resort
    if [ -n "$snap_id" ] && command -v snap &>/dev/null; then
        log_info "Trying snap as fallback for $name..."
        if sudo snap install "$snap_id" --classic 2>/dev/null; then
            log_ok "$name installed via snap"
            return 0
        fi
    fi

    log_err "Could not install $name (no Flatpak or snap available)"
    return 1
}
