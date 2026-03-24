# ============================================================================
# CodeReady Roadmap — v2.2 Patch (add these items)
# ============================================================================

# --- In v2.1 Known Issues section, mark as FIXED: ---
# - [x] **Flatpak/Nix auto-install** — FIXED: `install_flatpak()` and `install_nix()` functions added,
#        `offer_package_managers()` runs after detect_os(), `flatpak_or_snap()` auto-installs Flatpak if missing

# --- In v2.2 section, add new subsection: ---

### SSH Remote Execution (NEW)

**Terminal Scripts:**
- [ ] **Target selection at startup** — `[1] This machine (localhost)  [2] Remote machine (SSH)` — localhost default
- [ ] **SSH configuration wizard** — hostname, user, port, auth (key/agent/password)
- [ ] **Saved hosts** — `~/.codeready/remote-hosts.json` with label, reuse on next run
- [ ] **Remote bootstrap** — scp `codeready.sh` to `/tmp/codeready.XXXXX/` on remote, chmod +x
- [ ] **Remote scan** — `ssh user@host "sudo bash /tmp/.../codeready.sh --scan"` with live output
- [ ] **Remote install** — `ssh user@host "sudo bash /tmp/.../codeready.sh --install 'items'"` with live output
- [ ] **Remote profile** — `ssh user@host "sudo bash /tmp/.../codeready.sh --profile N"` with live output
- [ ] **CLI flags** — `--remote HOST`, `--remote-user`, `--remote-port`, `--remote-key`, `--local-only`
- [ ] **Banner shows target** — "TARGET: user@host:port / Mode: SSH Remote" or "TARGET: localhost / Mode: Local"
- [ ] **Auto cleanup** — `rm -rf /tmp/codeready.XXXXX/` after execution
- [ ] **sshpass fallback** — auto-install sshpass if password auth selected

**PowerShell (PS1):**
- [ ] **Same target selection** — uses Windows built-in ssh.exe (OpenSSH) or plink (PuTTY) fallback
- [ ] **Remote always runs codeready.sh** — PS1 copies .sh to Linux remote (remote is always Linux/macOS)
- [ ] **CLI params** — `-Remote`, `-RemoteUser`, `-RemotePort`, `-RemoteKey`, `-Scan`, `-Install`, `-Profile`
- [ ] **Saved hosts** — `%USERPROFILE%\.codeready\remote-hosts.json`

**GUI (Tauri + Web):**
- [ ] **HostSelector component** — dropdown in TitleBar: "localhost" + saved hosts + "Add remote..."
- [ ] **Add Remote Host modal** — label, host, user, port, auth type (key/agent/password), key path
- [ ] **Connection status** — green dot = connected, yellow pulse = connecting, disconnect on switch
- [ ] **Rust SSH backend** — `scanner_remote.rs` using `ssh2` crate, same bootstrap/exec pattern
- [ ] **Tauri commands** — `ssh_connect`, `ssh_disconnect`, `ssh_scan`, `ssh_install`, `ssh_profile`
- [ ] **Actix-web routes** — POST `/api/ssh/connect`, `/api/ssh/scan`, `/api/ssh/install`, `/api/ssh/profile`
- [ ] **useApi SSH extension** — auto-detects Tauri vs REST for all SSH endpoints
- [ ] **EN/TR i18n** — all remote strings translated
- [ ] **Live output streaming** — same TerminalPanel, prefixed with `[remote]` marker
- [ ] **Host management** — save, edit, remove saved hosts via GUI

### Flatpak & Nix Auto-Install (FIXED)

- [x] **`install_flatpak()`** — detects missing Flatpak, asks user, installs via apt/dnf/pacman/zypper, adds Flathub repo
- [x] **`install_nix()`** — detects missing Nix, asks user, installs daemon mode (or single-user in Docker)
- [x] **`offer_package_managers()`** — called after `detect_os()`, offers Flatpak + Nix on Linux only
- [x] **`flatpak_or_snap()` updated** — auto-calls `install_flatpak()` before giving up, then tries snap as last resort

# --- In File Structure, add: ---
# gui/src/components/HostSelector.jsx   # Target selector dropdown + add modal
# gui/src-tauri/src/scanner_remote.rs   # SSH connection manager (ssh2 crate)

# --- In Key Decisions Made, add: ---
# - **Remote = always codeready.sh** — even from PS1 on Windows, remote target runs .sh (Linux/macOS only)
# - **SSH from PS1 uses ssh.exe** — Windows 10+ built-in OpenSSH, plink as fallback
# - **Saved hosts in JSON** — `~/.codeready/remote-hosts.json`, same format for terminal + GUI
# - **Remote bootstrap pattern** — scp script → mktemp → execute → stream output → cleanup
# - **ssh2 crate for GUI** — Rust-native SSH (no shelling out), same session for scan/install/profile
# - **Flatpak > Nix > snap** — Flatpak offered first, Nix second, snap always last resort
# - **Auto-install Flatpak** — `flatpak_or_snap()` installs Flatpak on-demand before falling back to snap
