// ============================================================================
// CodeReady GUI — Remote SSH Module (scanner_remote.rs)
// Add to gui/src-tauri/src/
// Requires: ssh2 = "0.9" in Cargo.toml
// ============================================================================

use ssh2::Session;
use std::io::Read;
use std::net::TcpStream;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;

/// Remote host configuration
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct RemoteHost {
    pub label: String,
    pub host: String,
    pub user: String,
    pub port: u16,
    pub auth: AuthMethod,
}

#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(tag = "type")]
pub enum AuthMethod {
    #[serde(rename = "key")]
    Key { path: String },
    #[serde(rename = "agent")]
    Agent,
    #[serde(rename = "password")]
    Password { password: String },
}

/// Result from a remote command execution
#[derive(Debug, Clone, serde::Serialize)]
pub struct RemoteExecResult {
    pub stdout: String,
    pub stderr: String,
    pub exit_code: i32,
    pub success: bool,
}

/// SSH connection manager
pub struct SshManager {
    session: Session,
    host: RemoteHost,
}

impl SshManager {
    /// Connect to a remote host
    pub fn connect(host: &RemoteHost) -> Result<Self, String> {
        let addr = format!("{}:{}", host.host, host.port);
        let tcp = TcpStream::connect(&addr)
            .map_err(|e| format!("TCP connection failed to {}: {}", addr, e))?;

        tcp.set_read_timeout(Some(std::time::Duration::from_secs(10)))
            .ok();

        let mut session = Session::new()
            .map_err(|e| format!("Failed to create SSH session: {}", e))?;

        session.set_tcp_stream(tcp);
        session.handshake()
            .map_err(|e| format!("SSH handshake failed: {}", e))?;

        // Authenticate
        match &host.auth {
            AuthMethod::Key { path } => {
                let key_path = PathBuf::from(shellexpand::tilde(path).to_string());
                session.userauth_pubkey_file(
                    &host.user,
                    None,
                    &key_path,
                    None,
                ).map_err(|e| format!("Key auth failed: {}", e))?;
            }
            AuthMethod::Agent => {
                let mut agent = session.agent()
                    .map_err(|e| format!("SSH agent init failed: {}", e))?;
                agent.connect()
                    .map_err(|e| format!("SSH agent connect failed: {}", e))?;
                agent.list_identities()
                    .map_err(|e| format!("SSH agent list failed: {}", e))?;

                let identities: Vec<_> = agent.identities().unwrap_or_default();
                let mut authed = false;
                for id in &identities {
                    if agent.userauth(&host.user, id).is_ok() {
                        authed = true;
                        break;
                    }
                }
                if !authed {
                    return Err("SSH agent auth failed — no matching key".to_string());
                }
            }
            AuthMethod::Password { password } => {
                session.userauth_password(&host.user, password)
                    .map_err(|e| format!("Password auth failed: {}", e))?;
            }
        }

        if !session.authenticated() {
            return Err("Authentication failed".to_string());
        }

        Ok(SshManager {
            session,
            host: host.clone(),
        })
    }

    /// Test the connection
    pub fn test_connection(&self) -> Result<String, String> {
        let result = self.exec("echo CodeReady-OK && uname -s")?;
        if result.stdout.contains("CodeReady-OK") {
            let os = if result.stdout.contains("Darwin") {
                "macOS"
            } else {
                "Linux"
            };
            Ok(os.to_string())
        } else {
            Err("Connection test failed".to_string())
        }
    }

    /// Execute a command on the remote machine
    pub fn exec(&self, cmd: &str) -> Result<RemoteExecResult, String> {
        let mut channel = self.session.channel_session()
            .map_err(|e| format!("Channel open failed: {}", e))?;

        channel.exec(cmd)
            .map_err(|e| format!("Exec failed: {}", e))?;

        let mut stdout = String::new();
        channel.read_to_string(&mut stdout)
            .map_err(|e| format!("Read stdout failed: {}", e))?;

        let mut stderr = String::new();
        channel.stderr().read_to_string(&mut stderr)
            .map_err(|e| format!("Read stderr failed: {}", e))?;

        channel.wait_close()
            .map_err(|e| format!("Channel close failed: {}", e))?;

        let exit_code = channel.exit_status()
            .unwrap_or(-1);

        Ok(RemoteExecResult {
            stdout,
            stderr,
            exit_code,
            success: exit_code == 0,
        })
    }

    /// Upload codeready.sh to remote /tmp
    pub fn bootstrap(&self, script_content: &str) -> Result<String, String> {
        // Create temp dir
        let result = self.exec("mktemp -d /tmp/codeready.XXXXXX")?;
        let remote_tmp = result.stdout.trim().to_string();

        if remote_tmp.is_empty() {
            return Err("Failed to create temp dir on remote".to_string());
        }

        // Upload script via SCP
        let script_bytes = script_content.as_bytes();
        let remote_path = format!("{}/codeready.sh", remote_tmp);

        let mut remote_file = self.session.scp_send(
            std::path::Path::new(&remote_path),
            0o755,
            script_bytes.len() as u64,
            None,
        ).map_err(|e| format!("SCP upload failed: {}", e))?;

        use std::io::Write;
        remote_file.write_all(script_bytes)
            .map_err(|e| format!("SCP write failed: {}", e))?;

        // Close SCP channel
        remote_file.send_eof()
            .map_err(|e| format!("SCP EOF failed: {}", e))?;
        remote_file.wait_eof()
            .map_err(|e| format!("SCP wait EOF failed: {}", e))?;
        remote_file.close()
            .map_err(|e| format!("SCP close failed: {}", e))?;
        remote_file.wait_close()
            .map_err(|e| format!("SCP wait close failed: {}", e))?;

        Ok(remote_tmp)
    }

    /// Run scan on remote machine
    pub fn remote_scan(&self, script_content: &str) -> Result<RemoteExecResult, String> {
        let remote_tmp = self.bootstrap(script_content)?;
        let result = self.exec(&format!("sudo bash {}/codeready.sh --scan", remote_tmp));
        let _ = self.exec(&format!("rm -rf {}", remote_tmp));
        result
    }

    /// Install items on remote machine
    pub fn remote_install(&self, script_content: &str, items: &str) -> Result<RemoteExecResult, String> {
        let remote_tmp = self.bootstrap(script_content)?;
        let result = self.exec(&format!("sudo bash {}/codeready.sh --install '{}'", remote_tmp, items));
        let _ = self.exec(&format!("rm -rf {}", remote_tmp));
        result
    }

    /// Apply profile on remote machine
    pub fn remote_profile(&self, script_content: &str, profile_num: u32) -> Result<RemoteExecResult, String> {
        let remote_tmp = self.bootstrap(script_content)?;
        let result = self.exec(&format!("sudo bash {}/codeready.sh --profile {}", remote_tmp, profile_num));
        let _ = self.exec(&format!("rm -rf {}", remote_tmp));
        result
    }

    /// Cleanup
    pub fn disconnect(self) {
        let _ = self.session.disconnect(None, "CodeReady done", None);
    }
}

// ============================================================================
// Tauri Commands — add to main.rs
// ============================================================================

/// Shared SSH manager state
pub type SshState = Arc<Mutex<Option<SshManager>>>;

/// Tauri command: Connect to remote host
#[tauri::command]
pub async fn ssh_connect(
    state: tauri::State<'_, SshState>,
    host: RemoteHost,
) -> Result<String, String> {
    let manager = SshManager::connect(&host)?;
    let os = manager.test_connection()?;
    *state.lock().await = Some(manager);
    Ok(os)
}

/// Tauri command: Disconnect
#[tauri::command]
pub async fn ssh_disconnect(state: tauri::State<'_, SshState>) -> Result<(), String> {
    let mut lock = state.lock().await;
    if let Some(manager) = lock.take() {
        manager.disconnect();
    }
    Ok(())
}

/// Tauri command: Remote scan
#[tauri::command]
pub async fn ssh_scan(
    state: tauri::State<'_, SshState>,
    script_content: String,
) -> Result<RemoteExecResult, String> {
    let lock = state.lock().await;
    match lock.as_ref() {
        Some(manager) => manager.remote_scan(&script_content),
        None => Err("Not connected to remote host".to_string()),
    }
}

/// Tauri command: Remote install
#[tauri::command]
pub async fn ssh_install(
    state: tauri::State<'_, SshState>,
    script_content: String,
    items: String,
) -> Result<RemoteExecResult, String> {
    let lock = state.lock().await;
    match lock.as_ref() {
        Some(manager) => manager.remote_install(&script_content, &items),
        None => Err("Not connected to remote host".to_string()),
    }
}

/// Tauri command: Remote profile
#[tauri::command]
pub async fn ssh_profile(
    state: tauri::State<'_, SshState>,
    script_content: String,
    profile_num: u32,
) -> Result<RemoteExecResult, String> {
    let lock = state.lock().await;
    match lock.as_ref() {
        Some(manager) => manager.remote_profile(&script_content, profile_num),
        None => Err("Not connected to remote host".to_string()),
    }
}

// ============================================================================
// Actix-web Routes — add to web_server.rs
// ============================================================================

/*
Add these routes to the Actix-web server for web mode:

POST /api/ssh/connect     { host, user, port, auth }  → { os, status }
POST /api/ssh/disconnect  {}                           → { status }
POST /api/ssh/scan        { script_content }           → { stdout, stderr, exit_code }
POST /api/ssh/install     { script_content, items }    → { stdout, stderr, exit_code }
POST /api/ssh/profile     { script_content, profile }  → { stdout, stderr, exit_code }
GET  /api/ssh/hosts       {}                           → [{ label, host, user, port }]
POST /api/ssh/hosts/save  { label, host, user, port }  → { status }
DELETE /api/ssh/hosts/:id {}                            → { status }

The web_server.rs should use the same SshManager struct above.
Store the SshManager in Actix web::Data<Arc<Mutex<Option<SshManager>>>>.
*/

// ============================================================================
// Cargo.toml additions
// ============================================================================

/*
[dependencies]
ssh2 = "0.9"
shellexpand = "3"

# If ssh2 fails to build on Windows, use:
# ssh2 = { version = "0.9", features = ["vendored-openssl"] }
*/
