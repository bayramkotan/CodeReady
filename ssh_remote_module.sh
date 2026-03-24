#!/usr/bin/env bash
# ============================================================================
# CodeReady v2.2 — SSH Remote Execution Module
# Add these functions to codeready.sh
# ============================================================================

# --- Remote Configuration ----------------------------------------------------
REMOTE_MODE=false
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PORT=22
REMOTE_KEY=""
REMOTE_PASS=""
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o ServerAliveInterval=30"

# --- Remote Target Selection -------------------------------------------------
# Call this at startup, before main menu
select_target() {
    echo ""
    echo -e "${CYAN}━━━ Target Machine ━━━${NC}"
    echo -e "  ${GREEN}1)${NC} This machine (localhost) ${DIM}← default${NC}"
    echo -e "  ${GREEN}2)${NC} Remote machine (SSH)"
    echo ""
    read -rp "Select target [1]: " target_choice
    target_choice="${target_choice:-1}"

    case "$target_choice" in
        1)
            REMOTE_MODE=false
            log_ok "Target: localhost"
            ;;
        2)
            REMOTE_MODE=true
            configure_remote
            ;;
        *)
            REMOTE_MODE=false
            log_ok "Target: localhost"
            ;;
    esac
}

# --- Remote Configuration Wizard ---------------------------------------------
configure_remote() {
    echo ""
    echo -e "${CYAN}━━━ Remote SSH Configuration ━━━${NC}"
    echo ""

    # Check for saved hosts
    local config_dir="$HOME/.codeready"
    local hosts_file="$config_dir/remote-hosts.json"

    if [ -f "$hosts_file" ] && command -v python3 &>/dev/null; then
        local saved_hosts
        saved_hosts=$(python3 -c "
import json
with open('$hosts_file') as f:
    hosts = json.load(f)
for i, h in enumerate(hosts, 1):
    label = h.get('label', h['host'])
    print(f'  {i}) {label} ({h[\"user\"]}@{h[\"host\"]}:{h.get(\"port\", 22)})')
print(f'  {len(hosts)+1}) New connection')
" 2>/dev/null)

        if [ -n "$saved_hosts" ]; then
            echo -e "  ${YELLOW}Saved hosts:${NC}"
            echo "$saved_hosts"
            echo ""
            local host_count
            host_count=$(python3 -c "import json; print(len(json.load(open('$hosts_file'))))" 2>/dev/null)
            read -rp "  Select host [${host_count:+1-$host_count or }new]: " host_choice

            if [[ "$host_choice" =~ ^[0-9]+$ ]] && [ "$host_choice" -le "${host_count:-0}" ] 2>/dev/null; then
                # Load saved host
                eval "$(python3 -c "
import json
with open('$hosts_file') as f:
    h = json.load(f)[$((host_choice - 1))]
print(f'REMOTE_HOST=\"{h[\"host\"]}\"')
print(f'REMOTE_USER=\"{h[\"user\"]}\"')
print(f'REMOTE_PORT={h.get(\"port\", 22)}')
print(f'REMOTE_KEY=\"{h.get(\"key\", \"\")}\"')
" 2>/dev/null)"
                log_ok "Loaded: $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
                test_remote_connection
                return
            fi
        fi
    fi

    # New connection
    read -rp "  Hostname or IP: " REMOTE_HOST
    if [ -z "$REMOTE_HOST" ]; then
        log_err "No hostname provided, falling back to localhost"
        REMOTE_MODE=false
        return 1
    fi

    read -rp "  Username [$(whoami)]: " REMOTE_USER
    REMOTE_USER="${REMOTE_USER:-$(whoami)}"

    read -rp "  Port [22]: " REMOTE_PORT
    REMOTE_PORT="${REMOTE_PORT:-22}"

    echo ""
    echo -e "  ${CYAN}Authentication:${NC}"
    echo -e "    ${GREEN}1)${NC} SSH key (default)"
    echo -e "    ${GREEN}2)${NC} SSH agent (ssh-agent)"
    echo -e "    ${GREEN}3)${NC} Password"
    read -rp "  Auth method [1]: " auth_choice
    auth_choice="${auth_choice:-1}"

    case "$auth_choice" in
        1)
            local default_key="$HOME/.ssh/id_rsa"
            [ -f "$HOME/.ssh/id_ed25519" ] && default_key="$HOME/.ssh/id_ed25519"
            read -rp "  Key path [$default_key]: " REMOTE_KEY
            REMOTE_KEY="${REMOTE_KEY:-$default_key}"
            if [ ! -f "$REMOTE_KEY" ]; then
                log_err "Key file not found: $REMOTE_KEY"
                return 1
            fi
            SSH_OPTS="$SSH_OPTS -i $REMOTE_KEY"
            ;;
        2)
            # ssh-agent — no extra config needed
            if [ -z "$SSH_AUTH_SOCK" ]; then
                log_warn "ssh-agent not running. Start it with: eval \$(ssh-agent) && ssh-add"
            fi
            ;;
        3)
            if ! command -v sshpass &>/dev/null; then
                log_info "Installing sshpass for password auth..."
                pkg_install sshpass
            fi
            read -srp "  Password: " REMOTE_PASS
            echo ""
            ;;
    esac

    test_remote_connection

    # Offer to save
    if [ $? -eq 0 ]; then
        read -rp "  Save this host for future use? [Y/n]: " save_ans
        save_ans="${save_ans:-Y}"
        if [[ "$save_ans" =~ ^[Yy]$ ]]; then
            read -rp "  Label (e.g. 'dev-server'): " host_label
            save_remote_host "$host_label"
        fi
    fi
}

# --- Test Remote Connection --------------------------------------------------
test_remote_connection() {
    log_info "Testing SSH connection to $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT..."

    local ssh_cmd
    ssh_cmd=$(build_ssh_cmd)

    if $ssh_cmd "echo 'CodeReady SSH OK'" 2>/dev/null | grep -q "CodeReady SSH OK"; then
        log_ok "SSH connection successful"

        # Detect remote OS
        local remote_os
        remote_os=$($ssh_cmd "uname -s 2>/dev/null" 2>/dev/null)
        log_info "Remote OS: $remote_os"

        if [ "$remote_os" != "Linux" ] && [ "$remote_os" != "Darwin" ]; then
            log_warn "Remote is $remote_os — only Linux and macOS are supported for remote setup"
            return 1
        fi

        return 0
    else
        log_err "SSH connection failed. Check credentials and try again."
        REMOTE_MODE=false
        return 1
    fi
}

# --- Build SSH Command -------------------------------------------------------
build_ssh_cmd() {
    local cmd="ssh $SSH_OPTS -p $REMOTE_PORT"

    if [ -n "$REMOTE_PASS" ]; then
        cmd="sshpass -p '$REMOTE_PASS' $cmd"
    fi

    echo "$cmd $REMOTE_USER@$REMOTE_HOST"
}

# --- Build SCP Command -------------------------------------------------------
build_scp_cmd() {
    local cmd="scp $SSH_OPTS -P $REMOTE_PORT"

    if [ -n "$REMOTE_PASS" ]; then
        cmd="sshpass -p '$REMOTE_PASS' $cmd"
    fi

    echo "$cmd"
}

# --- Save Remote Host --------------------------------------------------------
save_remote_host() {
    local label="${1:-$REMOTE_HOST}"
    local config_dir="$HOME/.codeready"
    local hosts_file="$config_dir/remote-hosts.json"

    mkdir -p "$config_dir"

    python3 -c "
import json, os
hosts_file = '$hosts_file'
hosts = []
if os.path.exists(hosts_file):
    with open(hosts_file) as f:
        hosts = json.load(f)

# Remove duplicate
hosts = [h for h in hosts if not (h['host'] == '$REMOTE_HOST' and h['user'] == '$REMOTE_USER' and h.get('port', 22) == $REMOTE_PORT)]

hosts.append({
    'label': '$label',
    'host': '$REMOTE_HOST',
    'user': '$REMOTE_USER',
    'port': $REMOTE_PORT,
    'key': '$REMOTE_KEY'
})

with open(hosts_file, 'w') as f:
    json.dump(hosts, f, indent=2)
" 2>/dev/null

    log_ok "Host saved: $label → $REMOTE_USER@$REMOTE_HOST:$REMOTE_PORT"
}

# --- Remote Bootstrap --------------------------------------------------------
# Copies codeready.sh to remote and prepares it for execution
remote_bootstrap() {
    local ssh_cmd scp_cmd
    ssh_cmd=$(build_ssh_cmd)
    scp_cmd=$(build_scp_cmd)

    log_info "Bootstrapping remote machine..."

    # 1. Create temp dir on remote
    local remote_tmp
    remote_tmp=$($ssh_cmd "mktemp -d /tmp/codeready.XXXXXX" 2>/dev/null)
    if [ -z "$remote_tmp" ]; then
        log_err "Failed to create temp directory on remote"
        return 1
    fi
    log_info "Remote temp dir: $remote_tmp"

    # 2. Copy codeready.sh to remote
    local script_path
    script_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

    log_info "Copying codeready.sh to remote..."
    if ! $scp_cmd "$script_path" "$REMOTE_USER@$REMOTE_HOST:$remote_tmp/codeready.sh" 2>/dev/null; then
        log_err "Failed to copy script to remote"
        return 1
    fi

    # 3. Make executable
    $ssh_cmd "chmod +x $remote_tmp/codeready.sh" 2>/dev/null

    log_ok "Bootstrap complete — script ready at $remote_tmp/codeready.sh"
    echo "$remote_tmp"
}

# --- Remote Execute ----------------------------------------------------------
# Runs a command on the remote machine with live output streaming
remote_exec() {
    local cmd="$1"
    local ssh_cmd
    ssh_cmd=$(build_ssh_cmd)

    # Stream stdout/stderr live to local terminal
    $ssh_cmd -t "$cmd" 2>&1
    return $?
}

# --- Remote Scan -------------------------------------------------------------
remote_scan() {
    local remote_tmp
    remote_tmp=$(remote_bootstrap)
    [ $? -ne 0 ] && return 1

    log_info "Running system scan on $REMOTE_HOST..."
    echo -e "${DIM}━━━ Remote scan output ━━━${NC}"
    remote_exec "sudo bash $remote_tmp/codeready.sh --scan"
    local rc=$?
    echo -e "${DIM}━━━ End remote output ━━━${NC}"

    # Cleanup
    remote_exec "rm -rf $remote_tmp" 2>/dev/null

    return $rc
}

# --- Remote Install ----------------------------------------------------------
# Installs selected items on remote machine
remote_install() {
    local items="$1"  # comma-separated list or "all"
    local remote_tmp
    remote_tmp=$(remote_bootstrap)
    [ $? -ne 0 ] && return 1

    log_info "Installing on $REMOTE_HOST: $items"
    echo -e "${DIM}━━━ Remote install output ━━━${NC}"
    remote_exec "sudo bash $remote_tmp/codeready.sh --install '$items'"
    local rc=$?
    echo -e "${DIM}━━━ End remote output ━━━${NC}"

    # Cleanup
    remote_exec "rm -rf $remote_tmp" 2>/dev/null

    return $rc
}

# --- Remote Profile ----------------------------------------------------------
remote_apply_profile() {
    local profile_num="$1"
    local remote_tmp
    remote_tmp=$(remote_bootstrap)
    [ $? -ne 0 ] && return 1

    log_info "Applying profile $profile_num on $REMOTE_HOST..."
    echo -e "${DIM}━━━ Remote profile output ━━━${NC}"
    remote_exec "sudo bash $remote_tmp/codeready.sh --profile $profile_num"
    local rc=$?
    echo -e "${DIM}━━━ End remote output ━━━${NC}"

    # Cleanup
    remote_exec "rm -rf $remote_tmp" 2>/dev/null

    return $rc
}

# --- Remote-Aware Wrapper Functions ------------------------------------------
# These replace direct calls in the main menu logic

run_scan() {
    if $REMOTE_MODE; then
        remote_scan
    else
        do_scan  # existing local scan function
    fi
}

run_install() {
    local items="$1"
    if $REMOTE_MODE; then
        remote_install "$items"
    else
        do_install "$items"  # existing local install function
    fi
}

run_profile() {
    local profile_num="$1"
    if $REMOTE_MODE; then
        remote_apply_profile "$profile_num"
    else
        do_apply_profile "$profile_num"  # existing local profile function
    fi
}

# --- CLI Flags for Remote Mode -----------------------------------------------
# Add these to the argument parser at the top of codeready.sh
#
# --remote HOST        Set remote target (enables SSH mode)
# --remote-user USER   SSH username (default: current user)
# --remote-port PORT   SSH port (default: 22)
# --remote-key PATH    SSH private key path
# --scan               Run scan only (for remote headless use)
# --install ITEMS      Install items (comma-separated)
# --profile NUM        Apply profile number
# --local-only         Force localhost (skip target selection)
#
# Example usage:
#   ./codeready.sh --remote 192.168.1.50 --remote-user deploy --profile 5
#   ./codeready.sh --remote myserver.com --scan
#   ./codeready.sh --remote dev-box --remote-key ~/.ssh/id_ed25519 --install "python,nodejs,vscode"

parse_remote_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --remote)
                REMOTE_MODE=true
                REMOTE_HOST="$2"
                shift 2
                ;;
            --remote-user)
                REMOTE_USER="$2"
                shift 2
                ;;
            --remote-port)
                REMOTE_PORT="$2"
                shift 2
                ;;
            --remote-key)
                REMOTE_KEY="$2"
                SSH_OPTS="$SSH_OPTS -i $2"
                shift 2
                ;;
            --scan)
                ACTION="scan"
                shift
                ;;
            --install)
                ACTION="install"
                INSTALL_ITEMS="$2"
                shift 2
                ;;
            --profile)
                ACTION="profile"
                PROFILE_NUM="$2"
                shift 2
                ;;
            --local-only)
                REMOTE_MODE=false
                shift
                ;;
            *)
                shift
                ;;
        esac
    done

    # Default user if remote mode enabled but no user specified
    if $REMOTE_MODE && [ -z "$REMOTE_USER" ]; then
        REMOTE_USER="$(whoami)"
    fi

    # If remote mode via CLI, test connection and run action
    if $REMOTE_MODE && [ -n "$ACTION" ]; then
        test_remote_connection || exit 1
        case "$ACTION" in
            scan)    remote_scan ;;
            install) remote_install "$INSTALL_ITEMS" ;;
            profile) remote_apply_profile "$PROFILE_NUM" ;;
        esac
        exit $?
    fi
}

# --- Updated Main Menu Banner ------------------------------------------------
# Replace existing banner with target-aware version
show_banner() {
    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}  ${GREEN}CodeReady${NC} — Developer Environment Setup    v2.2.0  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
    if $REMOTE_MODE; then
        echo -e "${CYAN}║${NC}  ${YELLOW}TARGET: ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PORT}${NC}"
        printf "${CYAN}║${NC}  %-52s${CYAN}║${NC}\n" "Mode: SSH Remote"
    else
        echo -e "${CYAN}║${NC}  ${GREEN}TARGET: localhost${NC}"
        printf "${CYAN}║${NC}  %-52s${CYAN}║${NC}\n" "Mode: Local"
    fi
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
}
