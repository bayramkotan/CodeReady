// CodeReady GUI — Shared Scanner Logic
// Used by both Tauri (main.rs) and Web Server (web_server.rs)

use serde::{Deserialize, Serialize};
use std::process::Command;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanItem {
    pub name: String,
    pub category: String,
    pub version: Option<String>,
    pub installed: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanResult {
    pub items: Vec<ScanItem>,
    pub total: usize,
    pub installed_count: usize,
    pub missing_count: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstallRequest {
    pub name: String,
    pub method: String,
    pub package_id: String,
}

#[allow(dead_code)]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstallProgress {
    pub name: String,
    pub status: String,
    pub message: String,
    pub percent: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProfileDef {
    pub id: u8,
    pub name: String,
    pub name_tr: String,
    pub languages: Vec<String>,
    pub ides: Vec<String>,
    pub frameworks: Vec<String>,
    pub tools: Vec<String>,
}

/// Safe CLI whitelist — languages & runtimes
const SAFE_VERSION_CMDS: &[(&str, &str, &[&str])] = &[
    ("Python",       "python",    &["--version"]),
    ("Node.js",      "node",      &["--version"]),
    ("Java (JDK)",   "java",      &["--version"]),
    ("C/C++ (GCC)",  "gcc",       &["--version"]),
    ("Go",           "go",        &["version"]),
    ("Rust",         "rustc",     &["--version"]),
    ("PHP",          "php",       &["--version"]),
    ("Ruby",         "ruby",      &["--version"]),
    ("Kotlin",       "kotlin",    &["-version"]),
    ("Swift",        "swift",     &["--version"]),
    ("Dart",         "dart",      &["--version"]),
    ("TypeScript",   "tsc",       &["--version"]),
    ("R",            "Rscript",   &["--version"]),
    ("Lua",          "lua",       &["-v"]),
    ("Perl",         "perl",      &["--version"]),
    ("Julia",        "julia",     &["--version"]),
    ("Scala",        "scala",     &["--version"]),
    ("Elixir",       "elixir",    &["--version"]),
    ("Zig",          "zig",       &["version"]),
    ("Nim",          "nim",       &["--version"]),
    ("Haskell",      "ghc",       &["--version"]),
    ("OCaml",        "ocaml",     &["--version"]),
    ("D",            "dmd",       &["--version"]),
    ("V",            "v",         &["version"]),
    ("Gleam",        "gleam",     &["--version"]),
    ("Groovy",       "groovy",    &["--version"]),
    ("Erlang",       "erl",       &["+V"]),
    (".NET SDK",     "dotnet",    &["--version"]),
];

/// IDEs — check via which/where
const IDE_CMDS: &[(&str, &str)] = &[
    ("VS Code",       "code"),
    ("VSCodium",      "codium"),
    ("Cursor",        "cursor"),
    ("Zed",           "zed"),
    ("Windsurf",      "windsurf"),
    ("Sublime Text",  "subl"),
    ("Vim",           "vim"),
    ("Neovim",        "nvim"),
    ("GNU Emacs",     "emacs"),
    ("Android Studio","studio"),
];

/// Tools & Package Managers — check via which/where + --version
const TOOL_CMDS: &[(&str, &str, &[&str])] = &[
    ("Git",          "git",       &["--version"]),
    ("Docker",       "docker",    &["--version"]),
    ("kubectl",      "kubectl",   &["version", "--client", "--short"]),
    ("Helm",         "helm",      &["version", "--short"]),
    ("Terraform",    "terraform", &["--version"]),
    ("npm",          "npm",       &["--version"]),
    ("Yarn",         "yarn",      &["--version"]),
    ("pnpm",         "pnpm",      &["--version"]),
    ("Bun",          "bun",       &["--version"]),
    ("pipx",         "pipx",      &["--version"]),
    ("uv",           "uv",        &["--version"]),
    ("Poetry",       "poetry",    &["--version"]),
    ("Conda",        "conda",     &["--version"]),
];

/// Package Managers (system-level) — check via which/where
const PKG_MANAGER_CMDS: &[(&str, &str, &[&str])] = &[
    ("Scoop",        "scoop",     &["--version"]),
    ("Chocolatey",   "choco",     &["--version"]),
    ("Homebrew",     "brew",      &["--version"]),
    ("Flatpak",      "flatpak",   &["--version"]),
    ("Nix",          "nix",       &["--version"]),
    ("Snap",         "snap",      &["version"]),
    ("winget",       "winget",    &["--version"]),
];

/// Frameworks — npm globals to check
const NPM_FRAMEWORKS: &[(&str, &str)] = &[
    ("React",         "create-react-app"),
    ("Next.js",       "create-next-app"),
    ("Vue",           "@vue/cli"),
    ("Nuxt",          "nuxi"),
    ("Angular",       "@angular/cli"),
    ("Svelte",        "create-svelte"),
    ("Vite",          "create-vite"),
    ("Astro",         "create-astro"),
    ("Remix",         "create-remix"),
    ("Express",       "express-generator"),
    ("NestJS",        "@nestjs/cli"),
    ("Tailwind",      "tailwindcss"),
    ("React Native",  "react-native-cli"),
    ("Expo",          "expo-cli"),
    ("Ionic",         "@ionic/cli"),
    ("Electron",      "electron"),
];

/// Frameworks — pip packages to check
const PIP_FRAMEWORKS: &[(&str, &str)] = &[
    ("Django",        "django"),
    ("Flask",         "flask"),
    ("FastAPI",       "fastapi"),
    ("Streamlit",     "streamlit"),
    ("VenvStudio",    "VenvStudio"),
];

// ─── Version detection ───────────────────────────────────────────

/// Commands that are PowerShell functions, not executables
const PS_FUNCTION_CMDS: &[&str] = &["scoop"];

fn get_version(cmd: &str, args: &[&str]) -> Option<String> {
    // First try direct execution
    let output = Command::new(cmd).args(args)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .output();

    let output = match output {
        Ok(o) if o.status.success() => o,
        Ok(o) => {
            // Check stderr for tools that output version there (java, rustc)
            let stderr = String::from_utf8_lossy(&o.stderr).to_string();
            if !stderr.trim().is_empty() && (stderr.contains("version") || stderr.contains("Version")) {
                o
            } else {
                return try_fallback(cmd, args);
            }
        }
        Err(_) => {
            return try_fallback(cmd, args);
        }
    };

    parse_version_output(&output)
}

#[cfg(target_os = "windows")]
fn try_fallback(cmd: &str, args: &[&str]) -> Option<String> {
    let full_cmd = if args.is_empty() {
        cmd.to_string()
    } else {
        format!("{} {}", cmd, args.join(" "))
    };

    // Try cmd /c (for .bat/.cmd files like choco)
    if let Ok(o) = Command::new("cmd")
        .args(["/c", &full_cmd])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .output()
    {
        if o.status.success() {
            return parse_version_output(&o);
        }
    }

    // Try powershell ONLY for known PS functions (scoop)
    if PS_FUNCTION_CMDS.contains(&cmd) {
        if let Ok(o) = Command::new("powershell")
            .args(["-NoProfile", "-NonInteractive", "-Command", &full_cmd])
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .output()
        {
            if o.status.success() {
                return parse_version_output(&o);
            }
        }
    }

    None
}

#[cfg(not(target_os = "windows"))]
fn try_fallback(_cmd: &str, _args: &[&str]) -> Option<String> {
    None
}

fn parse_version_output(output: &std::process::Output) -> Option<String> {
    let raw = if output.status.success() {
        String::from_utf8_lossy(&output.stdout).to_string()
    } else {
        String::from_utf8_lossy(&output.stderr).to_string()
    };
    let line = raw.lines().next().unwrap_or("").trim().to_string();
    if line.is_empty() { return None; }

    // Extract version number using regex-like approach: find first N.N.N or N.N pattern
    let version = extract_semver(&line).unwrap_or_else(|| {
        // Fallback: strip known prefixes and take first word
        line.replace("Python ", "")
            .replace("java version \"", "").replace("\"", "")
            .replace("openjdk version \"", "")
            .replace("go version go", "")
            .replace("rustc ", "")
            .replace("ruby ", "")
            .replace("Dart SDK version: ", "")
            .replace("Chocolatey ", "")
            .replace("Scoop ", "")
            .replace("Homebrew ", "")
            .replace("nix (Nix) ", "")
            .replace("flatpak ", "")
            .replace("uv ", "")
            .replace("poetry (version ", "").replace(")", "")
            .replace("conda ", "")
            .replace("pnpm ", "")
            .replace("helm: ", "")
            .replace("Terraform ", "")
            .replace("Current stable version of Scoop:", "")
            .trim()
            .split_whitespace()
            .next()
            .unwrap_or(&line)
            .trim_start_matches('v')
            .to_string()
    });

    if version.is_empty() { return None; }
    // Final sanity check: version should start with a digit
    if version.chars().next().map_or(true, |c| !c.is_ascii_digit()) {
        // If no digit found, just return "found" to indicate it exists
        return Some("found".to_string());
    }
    Some(version)
}

/// Extract semver-like version (N.N.N or N.N) from a string
fn extract_semver(s: &str) -> Option<String> {
    let chars: Vec<char> = s.chars().collect();
    let len = chars.len();
    let mut i = 0;
    while i < len {
        // Find start of a digit sequence
        if chars[i].is_ascii_digit() {
            let start = i;
            // Try to match N.N.N or N.N
            let mut dots = 0;
            let mut j = i;
            while j < len && (chars[j].is_ascii_digit() || (chars[j] == '.' && j + 1 < len && chars[j + 1].is_ascii_digit())) {
                if chars[j] == '.' { dots += 1; }
                j += 1;
            }
            if dots >= 1 {
                let candidate: String = chars[start..j].iter().collect();
                // Must have at least one dot and start with digit
                if candidate.contains('.') && candidate.chars().next().map_or(false, |c| c.is_ascii_digit()) {
                    return Some(candidate);
                }
            }
        }
        i += 1;
    }
    None
}

/// Check if a command exists — only used as last resort for known edge cases
/// NOT used for general tool detection (too many false positives on Windows)
fn _cmd_exists_basic(cmd: &str) -> bool {
    which::which(cmd).is_ok()
}

/// Get list of globally installed npm packages (cached for performance)
fn get_npm_globals() -> Vec<String> {
    // Windows: npm is a .cmd file — must run via cmd /c
    #[cfg(target_os = "windows")]
    let output = Command::new("cmd")
        .args(["/c", "npm", "list", "-g", "--depth=0", "--json"])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .output();

    #[cfg(not(target_os = "windows"))]
    let output = Command::new("npm")
        .args(["list", "-g", "--depth=0", "--json"])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .output();

    match output {
        Ok(o) if o.status.success() => {
            let json_str = String::from_utf8_lossy(&o.stdout);
            // Parse JSON to get dependency names
            if let Ok(val) = serde_json::from_str::<serde_json::Value>(&json_str) {
                if let Some(deps) = val.get("dependencies").and_then(|d| d.as_object()) {
                    return deps.keys().map(|k| k.to_lowercase()).collect();
                }
            }
            Vec::new()
        }
        _ => Vec::new(),
    }
}

/// Get list of installed pip packages (cached for performance)
fn get_pip_packages() -> Vec<String> {
    // Windows: pip/pip3 may be .exe but let's be safe with cmd /c
    #[cfg(target_os = "windows")]
    let output = Command::new("cmd")
        .args(["/c", "pip3", "list", "--format=columns"])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .output();

    #[cfg(not(target_os = "windows"))]
    let output = Command::new("pip3")
        .args(["list", "--format=columns"])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .output();

    // Fallback to pip if pip3 not found
    let output = match output {
        Ok(o) if o.status.success() => o,
        _ => {
            #[cfg(target_os = "windows")]
            let fallback = Command::new("cmd")
                .args(["/c", "pip", "list", "--format=columns"])
                .stdout(std::process::Stdio::piped())
                .stderr(std::process::Stdio::null())
                .output();

            #[cfg(not(target_os = "windows"))]
            let fallback = Command::new("pip")
                .args(["list", "--format=columns"])
                .stdout(std::process::Stdio::piped())
                .stderr(std::process::Stdio::null())
                .output();

            match fallback {
                Ok(o) => o,
                Err(_) => return Vec::new(),
            }
        }
    };

    if !output.status.success() { return Vec::new(); }

    let stdout = String::from_utf8_lossy(&output.stdout);
    stdout.lines()
        .skip(2) // skip header + separator
        .filter_map(|line| line.split_whitespace().next())
        .map(|name| name.to_lowercase())
        .collect()
}

// ─── Main scan ───────────────────────────────────────────────────

/// Try to scan using the terminal script (ps1 or sh) with --scan-json
/// Returns None if script not found or fails
fn scan_via_script() -> Option<ScanResult> {
    #[cfg(target_os = "windows")]
    let output = {
        // Find codeready.ps1 — check relative paths from exe location
        let script_paths = vec![
            std::env::current_exe().ok()?.parent()?.parent()?.parent()?.join("codeready.ps1"),  // gui/src-tauri/target -> root
            std::env::current_exe().ok()?.parent()?.parent()?.parent()?.parent()?.join("codeready.ps1"),
            std::path::PathBuf::from("../../codeready.ps1"),
            std::path::PathBuf::from("../../../codeready.ps1"),
        ];
        let script = script_paths.iter().find(|p| p.exists())?;
        eprintln!("[scanner] Using script: {}", script.display());
        Command::new("powershell")
            .args(["-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File", &script.to_string_lossy(), "--scan-json"])
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .output()
            .ok()?
    };

    #[cfg(not(target_os = "windows"))]
    let output = {
        let script_paths = vec![
            std::env::current_exe().ok()?.parent()?.parent()?.parent()?.join("codeready.sh"),
            std::env::current_exe().ok()?.parent()?.parent()?.parent()?.parent()?.join("codeready.sh"),
            std::path::PathBuf::from("../../codeready.sh"),
            std::path::PathBuf::from("../../../codeready.sh"),
        ];
        let script = script_paths.iter().find(|p| p.exists())?;
        eprintln!("[scanner] Using script: {}", script.display());
        Command::new("bash")
            .args([&script.to_string_lossy().to_string(), "--scan-json"])
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::piped())
            .output()
            .ok()?
    };

    if !output.status.success() {
        eprintln!("[scanner] Script failed: {}", String::from_utf8_lossy(&output.stderr));
        return None;
    }

    let json_str = String::from_utf8_lossy(&output.stdout);
    eprintln!("[scanner] Script returned {} bytes", json_str.len());
    serde_json::from_str::<ScanResult>(&json_str).ok()
}

pub fn scan_system_sync() -> ScanResult {
    // Strategy: try script first (single source of truth), fallback to built-in
    if let Some(result) = scan_via_script() {
        eprintln!("[scanner] Using script scan result: {}/{} installed", result.installed_count, result.total);
        return result;
    }
    eprintln!("[scanner] Script not available, using built-in scan");

    // ─── FALLBACK: built-in scan (same as before) ─────────────
    let mut items: Vec<ScanItem> = Vec::new();

    // 1. Languages & runtimes
    for (name, cmd, args) in SAFE_VERSION_CMDS {
        let version = get_version(cmd, args);
        let installed = version.is_some();
        items.push(ScanItem {
            name: name.to_string(),
            category: "language".to_string(),
            version,
            installed,
        });
    }

    // 2. IDEs via which
    for (name, cmd) in IDE_CMDS {
        let installed = which::which(cmd).is_ok();
        items.push(ScanItem {
            name: name.to_string(),
            category: "ide".to_string(),
            version: if installed { Some("found".to_string()) } else { None },
            installed,
        });
    }

    // 3. Frameworks — check npm globals + pip packages
    let npm_globals = get_npm_globals();
    let pip_packages = get_pip_packages();

    for (name, npm_pkg) in NPM_FRAMEWORKS {
        let installed = npm_globals.iter().any(|p| p == &npm_pkg.to_lowercase());
        items.push(ScanItem {
            name: name.to_string(),
            category: "framework".to_string(),
            version: if installed { Some("found".to_string()) } else { None },
            installed,
        });
    }

    for (name, pip_pkg) in PIP_FRAMEWORKS {
        // Skip if already added via npm
        if items.iter().any(|i| i.name == *name) { continue; }
        let installed = pip_packages.iter().any(|p| p == &pip_pkg.to_lowercase());
        items.push(ScanItem {
            name: name.to_string(),
            category: "framework".to_string(),
            version: if installed { Some("found".to_string()) } else { None },
            installed,
        });
    }

    // Blazor check — dotnet installed = Blazor available
    let dotnet_installed = items.iter().any(|i| i.name == ".NET SDK" && i.installed);
    items.push(ScanItem {
        name: "Blazor".to_string(),
        category: "framework".to_string(),
        version: if dotnet_installed { Some("via .NET".to_string()) } else { None },
        installed: dotnet_installed,
    });

    // Bootstrap — npm check
    let bootstrap_installed = npm_globals.iter().any(|p| p == "bootstrap");
    items.push(ScanItem {
        name: "Bootstrap".to_string(),
        category: "framework".to_string(),
        version: if bootstrap_installed { Some("found".to_string()) } else { None },
        installed: bootstrap_installed,
    });

    // 4. Tools & package managers — only trust get_version result
    for (name, cmd, args) in TOOL_CMDS {
        let version = get_version(cmd, args);
        let installed = version.is_some();
        items.push(ScanItem {
            name: name.to_string(),
            category: "tool".to_string(),
            version,
            installed,
        });
    }

    // 5. System package managers — only trust get_version result
    for (name, cmd, args) in PKG_MANAGER_CMDS {
        let version = get_version(cmd, args);
        let installed = version.is_some();
        items.push(ScanItem {
            name: name.to_string(),
            category: "pkgmanager".to_string(),
            version,
            installed,
        });
    }

    let total = items.len();
    let installed_count = items.iter().filter(|i| i.installed).count();
    let missing_count = total - installed_count;

    ScanResult { items, total, installed_count, missing_count }
}

pub fn run_install(request: &InstallRequest) -> Result<String, String> {
    let result = match request.method.as_str() {
        "winget" => Command::new("winget")
            .args(["install", "-e", "--id", &request.package_id, "--silent", "--accept-source-agreements", "--accept-package-agreements"])
            .output(),
        "scoop" => {
            #[cfg(target_os = "windows")]
            { Command::new("powershell").args(["-NoProfile", "-NonInteractive", "-Command", &format!("scoop install {}", request.package_id)]).output() }
            #[cfg(not(target_os = "windows"))]
            { Command::new("scoop").args(["install", &request.package_id]).output() }
        }
        "choco" => {
            #[cfg(target_os = "windows")]
            { Command::new("cmd").args(["/c", "choco", "install", &request.package_id, "-y"]).output() }
            #[cfg(not(target_os = "windows"))]
            { Command::new("choco").args(["install", &request.package_id, "-y"]).output() }
        }
        "pip" => {
            #[cfg(target_os = "windows")]
            { Command::new("cmd").args(["/c", "pip3", "install", "--break-system-packages", &request.package_id]).output() }
            #[cfg(not(target_os = "windows"))]
            { Command::new("pip3").args(["install", "--break-system-packages", &request.package_id]).output() }
        }
        "pip-local" => {
            // Install to current directory / venv (no -g, no --break-system-packages)
            #[cfg(target_os = "windows")]
            { Command::new("cmd").args(["/c", "pip3", "install", &request.package_id]).output() }
            #[cfg(not(target_os = "windows"))]
            { Command::new("pip3").args(["install", "--user", &request.package_id]).output() }
        }
        "npm" => {
            #[cfg(target_os = "windows")]
            { Command::new("cmd").args(["/c", "npm", "install", "-g", &request.package_id]).output() }
            #[cfg(not(target_os = "windows"))]
            { Command::new("npm").args(["install", "-g", &request.package_id]).output() }
        }
        "npm-local" => {
            // Install to current directory (no -g flag)
            #[cfg(target_os = "windows")]
            { Command::new("cmd").args(["/c", "npm", "install", &request.package_id]).output() }
            #[cfg(not(target_os = "windows"))]
            { Command::new("npm").args(["install", &request.package_id]).output() }
        }
        "apt" => Command::new("sudo").args(["apt", "install", "-y", &request.package_id]).output(),
        "brew" => Command::new("brew").args(["install", &request.package_id]).output(),
        _ => return Err(format!("Unknown method: {}", request.method)),
    };

    let scope_label = if request.method.ends_with("-local") { " (local)" } else { " (global)" };

    // Refresh PATH so next scan detects newly installed binaries
    refresh_env_path();

    match result {
        Ok(output) if output.status.success() => Ok(format!("{} installed successfully{}.", request.name, scope_label)),
        Ok(output) => Err(format!("Install failed: {}", String::from_utf8_lossy(&output.stderr))),
        Err(e) => Err(format!("Failed to run installer: {}", e)),
    }
}

/// Refresh the current process PATH from the system registry (Windows) or shell profiles (Unix)
fn refresh_env_path() {
    #[cfg(target_os = "windows")]
    {
        // Read latest Machine + User PATH from registry and update current process
        if let Ok(output) = Command::new("powershell")
            .args(["-NoProfile", "-NonInteractive", "-Command",
                "[System.Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path','User')"])
            .stdout(std::process::Stdio::piped())
            .stderr(std::process::Stdio::null())
            .output()
        {
            if output.status.success() {
                let new_path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                if !new_path.is_empty() {
                    std::env::set_var("PATH", &new_path);
                    eprintln!("[scanner] PATH refreshed ({} chars)", new_path.len());
                }
            }
        }
    }

    #[cfg(not(target_os = "windows"))]
    {
        // Source common profile files and extract PATH
        let shells = [
            ("bash", "-c", "source ~/.bashrc 2>/dev/null; source ~/.profile 2>/dev/null; echo $PATH"),
            ("zsh", "-c", "source ~/.zshrc 2>/dev/null; echo $PATH"),
        ];
        for (sh, flag, cmd) in &shells {
            if let Ok(output) = Command::new(sh)
                .args([flag, cmd])
                .stdout(std::process::Stdio::piped())
                .stderr(std::process::Stdio::null())
                .output()
            {
                if output.status.success() {
                    let new_path = String::from_utf8_lossy(&output.stdout).trim().to_string();
                    if !new_path.is_empty() && new_path.contains('/') {
                        std::env::set_var("PATH", &new_path);
                        eprintln!("[scanner] PATH refreshed via {}", sh);
                        break;
                    }
                }
            }
        }
    }
}

pub fn get_os() -> String {
    #[cfg(target_os = "windows")]
    return "windows".to_string();
    #[cfg(target_os = "macos")]
    return "macos".to_string();
    #[cfg(target_os = "linux")]
    return "linux".to_string();
}

pub fn get_profiles() -> Vec<ProfileDef> {
    vec![
        ProfileDef { id: 1,  name: "Web Frontend".into(),       name_tr: "Web Frontend".into(),       languages: vec!["Node.js".into(), "TypeScript".into()], ides: vec!["VS Code".into()], frameworks: vec!["React".into(), "Vue".into(), "Vite".into(), "Tailwind".into()], tools: vec!["npm".into(), "Yarn".into(), "pnpm".into()] },
        ProfileDef { id: 2,  name: "Web Full Stack".into(),     name_tr: "Web Full Stack".into(),     languages: vec!["Node.js".into(), "TypeScript".into(), "Python".into()], ides: vec!["VS Code".into()], frameworks: vec!["React".into(), "Next.js".into(), "Express".into(), "Django".into(), "Tailwind".into()], tools: vec!["npm".into(), "Docker".into(), "Git".into()] },
        ProfileDef { id: 3,  name: "Mobile".into(),             name_tr: "Mobil".into(),              languages: vec!["Dart".into(), "Kotlin".into(), "Swift".into()], ides: vec!["VS Code".into(), "Android Studio".into()], frameworks: vec!["Flutter".into(), "React Native".into(), "Expo".into()], tools: vec!["npm".into()] },
        ProfileDef { id: 4,  name: "Data Scientist".into(),     name_tr: "Veri Bilimci".into(),       languages: vec!["Python".into(), "R".into(), "Julia".into()], ides: vec!["VS Code".into(), "PyCharm".into()], frameworks: vec!["Streamlit".into()], tools: vec!["VenvStudio".into(), "uv".into(), "Conda".into()] },
        ProfileDef { id: 5,  name: "AI/ML Engineer".into(),     name_tr: "AI/ML Muhendisi".into(),    languages: vec!["Python".into(), "Mojo".into()], ides: vec!["VS Code".into(), "PyCharm".into()], frameworks: vec!["FastAPI".into(), "Streamlit".into()], tools: vec!["VenvStudio".into(), "uv".into(), "Conda".into(), "Docker".into()] },
        ProfileDef { id: 6,  name: "Systems Programmer".into(), name_tr: "Sistem Programcisi".into(), languages: vec!["Rust".into(), "C/C++ (GCC)".into(), "Zig".into()], ides: vec!["VS Code".into(), "Neovim".into(), "CLion".into()], frameworks: vec![], tools: vec!["Docker".into(), "Git".into()] },
        ProfileDef { id: 7,  name: "Full Stack .NET".into(),    name_tr: "Full Stack .NET".into(),    languages: vec![".NET SDK".into(), "TypeScript".into()], ides: vec!["Visual Studio".into(), "VS Code".into(), "Rider".into()], frameworks: vec!["Blazor".into(), "React".into()], tools: vec!["npm".into(), "Docker".into()] },
        ProfileDef { id: 8,  name: "Game Developer".into(),     name_tr: "Oyun Gelistirici".into(),   languages: vec![".NET SDK".into(), "C/C++ (GCC)".into(), "Rust".into()], ides: vec!["Visual Studio".into(), "VS Code".into(), "Rider".into()], frameworks: vec![], tools: vec!["Git".into()] },
        ProfileDef { id: 9,  name: "DevOps/Cloud".into(),       name_tr: "DevOps/Bulut".into(),       languages: vec!["Python".into(), "Go".into()], ides: vec!["VS Code".into()], frameworks: vec!["Terraform".into()], tools: vec!["Docker".into(), "kubectl".into(), "Helm".into()] },
        ProfileDef { id: 10, name: "Blockchain/Web3".into(),    name_tr: "Blockchain/Web3".into(),    languages: vec!["Node.js".into(), "Rust".into(), "Solidity".into()], ides: vec!["VS Code".into()], frameworks: vec!["React".into(), "Next.js".into()], tools: vec!["npm".into(), "Docker".into()] },
        ProfileDef { id: 11, name: "Embedded/IoT".into(),       name_tr: "Gomulu/IoT".into(),         languages: vec!["C/C++ (GCC)".into(), "Rust".into(), "Python".into()], ides: vec!["VS Code".into(), "CLion".into()], frameworks: vec![], tools: vec!["Docker".into(), "Git".into()] },
        ProfileDef { id: 12, name: "Scientific Computing".into(),name_tr: "Bilimsel Hesaplama".into(),languages: vec!["Python".into(), "Julia".into(), "R".into(), "Fortran".into()], ides: vec!["VS Code".into()], frameworks: vec![], tools: vec!["VenvStudio".into(), "Conda".into()] },
        ProfileDef { id: 13, name: "Functional".into(),         name_tr: "Fonksiyonel".into(),        languages: vec!["Haskell".into(), "Elixir".into(), "Erlang".into(), "OCaml".into(), "Scala".into()], ides: vec!["VS Code".into(), "Neovim".into()], frameworks: vec![], tools: vec!["Git".into()] },
        ProfileDef { id: 14, name: "JVM Ecosystem".into(),      name_tr: "JVM Ekosistemi".into(),     languages: vec!["Java (JDK)".into(), "Kotlin".into(), "Scala".into(), "Groovy".into()], ides: vec!["IntelliJ IDEA".into(), "VS Code".into()], frameworks: vec![], tools: vec!["Docker".into(), "Git".into()] },
        ProfileDef { id: 15, name: "Minimalist/Terminal".into(), name_tr: "Minimalist/Terminal".into(),languages: vec!["Python".into(), "Node.js".into(), "Go".into(), "Rust".into()], ides: vec!["Neovim".into(), "Vim".into()], frameworks: vec![], tools: vec!["Git".into()] },
    ]
}
