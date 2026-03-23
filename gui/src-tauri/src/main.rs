// CodeReady GUI — Rust Backend (Tauri v2)
// Handles system scanning, installation, and version detection

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use serde::{Deserialize, Serialize};
use std::process::Command;
use tauri::Manager;

// ─── Data Structures ─────────────────────────────────────────────

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScanItem {
    pub name: String,
    pub category: String,       // "language", "ide", "framework", "tool"
    pub version: Option<String>, // None = not installed
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
    pub method: String, // "winget", "scoop", "choco", "apt", "brew", "pip"
    pub package_id: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstallProgress {
    pub name: String,
    pub status: String, // "starting", "downloading", "installing", "done", "failed"
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

// ─── Version Detection ───────────────────────────────────────────

/// Safe CLI whitelist — only these get --version executed
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
    ("Git",          "git",       &["--version"]),
    ("Docker",       "docker",    &["--version"]),
    ("kubectl",      "kubectl",   &["version", "--client", "--short"]),
];

fn get_version(cmd: &str, args: &[&str]) -> Option<String> {
    let output = Command::new(cmd)
        .args(args)
        .output()
        .ok()?;

    let raw = if output.status.success() {
        String::from_utf8_lossy(&output.stdout).to_string()
    } else {
        String::from_utf8_lossy(&output.stderr).to_string()
    };

    let line = raw.lines().next().unwrap_or("").trim().to_string();
    if line.is_empty() { return None; }

    // Extract version number from common patterns
    let version = line
        .replace("Python ", "")
        .replace("java version \"", "").replace("\"", "")
        .replace("openjdk version \"", "")
        .replace("go version go", "")
        .replace("rustc ", "")
        .replace("ruby ", "")
        .replace("Dart SDK version: ", "")
        .replace("v", "")
        .trim()
        .split_whitespace()
        .next()
        .unwrap_or(&line)
        .to_string();

    Some(version)
}

// ─── JetBrains IDE Detection (file path only, never --version) ───

#[cfg(target_os = "windows")]
fn detect_jetbrains_ides() -> Vec<ScanItem> {
    use std::path::PathBuf;

    let ide_checks: Vec<(&str, Vec<PathBuf>)> = vec![
        ("IntelliJ IDEA", vec![
            PathBuf::from(std::env::var("PROGRAMFILES").unwrap_or_default()).join("JetBrains"),
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("Programs/IntelliJ IDEA"),
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("JetBrains/Toolbox/apps/IDEA"),
        ]),
        ("PyCharm", vec![
            PathBuf::from(std::env::var("PROGRAMFILES").unwrap_or_default()).join("JetBrains"),
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("Programs/PyCharm"),
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("JetBrains/Toolbox/apps/PyCharm"),
        ]),
        ("WebStorm", vec![
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("JetBrains/Toolbox/apps/WebStorm"),
        ]),
        ("GoLand", vec![
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("JetBrains/Toolbox/apps/GoLand"),
        ]),
        ("CLion", vec![
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("JetBrains/Toolbox/apps/CLion"),
        ]),
        ("Rider", vec![
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("JetBrains/Toolbox/apps/Rider"),
        ]),
        ("RustRover", vec![
            PathBuf::from(std::env::var("LOCALAPPDATA").unwrap_or_default()).join("JetBrains/Toolbox/apps/RustRover"),
        ]),
    ];

    let mut results = Vec::new();
    for (name, paths) in &ide_checks {
        let found = paths.iter().any(|p| p.exists());
        results.push(ScanItem {
            name: name.to_string(),
            category: "ide".to_string(),
            version: if found { Some("found".to_string()) } else { None },
            installed: found,
        });
    }
    results
}

#[cfg(not(target_os = "windows"))]
fn detect_jetbrains_ides() -> Vec<ScanItem> {
    Vec::new() // Linux/macOS: detected via which + flatpak
}

// ─── IDE Detection via which/where ───────────────────────────────

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

fn detect_ide_cmds() -> Vec<ScanItem> {
    IDE_CMDS.iter().map(|(name, cmd)| {
        let installed = which::which(cmd).is_ok();
        ScanItem {
            name: name.to_string(),
            category: "ide".to_string(),
            version: if installed { Some("found".to_string()) } else { None },
            installed,
        }
    }).collect()
}

// ─── Tauri Commands ──────────────────────────────────────────────

#[tauri::command]
async fn scan_system(app: tauri::AppHandle) -> Result<ScanResult, String> {
    let mut items: Vec<ScanItem> = Vec::new();

    // Scan languages/runtimes
    for (name, cmd, args) in SAFE_VERSION_CMDS {
        let version = get_version(cmd, args);
        let installed = version.is_some();

        let item = ScanItem {
            name: name.to_string(),
            category: "language".to_string(),
            version: version.clone(),
            installed,
        };

        // Emit progress event
        let status = if installed {
            format!("[+] {} {} found", name, version.as_deref().unwrap_or(""))
        } else {
            format!("[-] {} not found", name)
        };
        let _ = app.emit("scan-progress", &status);

        items.push(item);
    }

    // Scan IDEs (command-based)
    let ide_items = detect_ide_cmds();
    for item in &ide_items {
        let status = if item.installed {
            format!("[+] {} found", item.name)
        } else {
            format!("[-] {} not found", item.name)
        };
        let _ = app.emit("scan-progress", &status);
    }
    items.extend(ide_items);

    // Scan JetBrains IDEs (file path)
    let jb_items = detect_jetbrains_ides();
    for item in &jb_items {
        let status = if item.installed {
            format!("[+] {} found", item.name)
        } else {
            format!("[-] {} not found", item.name)
        };
        let _ = app.emit("scan-progress", &status);
    }
    items.extend(jb_items);

    let total = items.len();
    let installed_count = items.iter().filter(|i| i.installed).count();
    let missing_count = total - installed_count;

    let _ = app.emit("scan-progress", &format!("[✓] Scan complete. {}/{} installed.", installed_count, total));

    Ok(ScanResult {
        items,
        total,
        installed_count,
        missing_count,
    })
}

#[tauri::command]
async fn install_item(app: tauri::AppHandle, request: InstallRequest) -> Result<String, String> {
    let _ = app.emit("install-progress", InstallProgress {
        name: request.name.clone(),
        status: "starting".to_string(),
        message: format!("Installing {}...", request.name),
        percent: 0,
    });

    let result = match request.method.as_str() {
        "winget" => {
            Command::new("winget")
                .args(["install", "-e", "--id", &request.package_id, "--accept-source-agreements", "--accept-package-agreements"])
                .output()
        }
        "scoop" => {
            Command::new("scoop")
                .args(["install", &request.package_id])
                .output()
        }
        "choco" => {
            Command::new("choco")
                .args(["install", &request.package_id, "-y"])
                .output()
        }
        "pip" => {
            Command::new("pip3")
                .args(["install", "--break-system-packages", &request.package_id])
                .output()
        }
        "npm" => {
            Command::new("npm")
                .args(["install", "-g", &request.package_id])
                .output()
        }
        "apt" => {
            Command::new("sudo")
                .args(["apt", "install", "-y", &request.package_id])
                .output()
        }
        "brew" => {
            Command::new("brew")
                .args(["install", &request.package_id])
                .output()
        }
        _ => return Err(format!("Unknown install method: {}", request.method)),
    };

    match result {
        Ok(output) => {
            if output.status.success() {
                let _ = app.emit("install-progress", InstallProgress {
                    name: request.name.clone(),
                    status: "done".to_string(),
                    message: format!("{} installed successfully.", request.name),
                    percent: 100,
                });
                Ok(format!("{} installed successfully.", request.name))
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr).to_string();
                let _ = app.emit("install-progress", InstallProgress {
                    name: request.name.clone(),
                    status: "failed".to_string(),
                    message: format!("Failed to install {}: {}", request.name, stderr),
                    percent: 0,
                });
                Err(format!("Install failed: {}", stderr))
            }
        }
        Err(e) => {
            let _ = app.emit("install-progress", InstallProgress {
                name: request.name.clone(),
                status: "failed".to_string(),
                message: format!("Failed to run installer: {}", e),
                percent: 0,
            });
            Err(format!("Failed to run installer: {}", e))
        }
    }
}

#[tauri::command]
fn get_profiles() -> Vec<ProfileDef> {
    vec![
        ProfileDef {
            id: 1,
            name: "Web Frontend".into(),
            name_tr: "Web Frontend".into(),
            languages: vec!["Node.js".into(), "TypeScript".into()],
            ides: vec!["VS Code".into()],
            frameworks: vec!["React".into(), "Vue".into(), "Vite".into(), "Tailwind".into()],
            tools: vec!["npm".into(), "Yarn".into(), "pnpm".into()],
        },
        ProfileDef {
            id: 2,
            name: "Web Full Stack".into(),
            name_tr: "Web Full Stack".into(),
            languages: vec!["Node.js".into(), "TypeScript".into(), "Python".into()],
            ides: vec!["VS Code".into()],
            frameworks: vec!["React".into(), "Next.js".into(), "Express".into(), "Django".into(), "Tailwind".into()],
            tools: vec!["npm".into(), "Docker".into(), "Git".into()],
        },
        ProfileDef {
            id: 3,
            name: "Mobile".into(),
            name_tr: "Mobil".into(),
            languages: vec!["Dart".into(), "Kotlin".into(), "Swift".into()],
            ides: vec!["VS Code".into(), "Android Studio".into()],
            frameworks: vec!["Flutter".into(), "React Native".into(), "Expo".into()],
            tools: vec!["npm".into()],
        },
        ProfileDef {
            id: 4,
            name: "Data Scientist".into(),
            name_tr: "Veri Bilimci".into(),
            languages: vec!["Python".into(), "R".into(), "Julia".into()],
            ides: vec!["VS Code".into(), "PyCharm".into()],
            frameworks: vec!["Streamlit".into()],
            tools: vec!["VenvStudio".into(), "uv".into(), "Conda".into()],
        },
        ProfileDef {
            id: 5,
            name: "AI/ML Engineer".into(),
            name_tr: "AI/ML Muhendisi".into(),
            languages: vec!["Python".into(), "Mojo".into()],
            ides: vec!["VS Code".into(), "PyCharm".into()],
            frameworks: vec!["FastAPI".into(), "Streamlit".into()],
            tools: vec!["VenvStudio".into(), "uv".into(), "Conda".into(), "Docker".into()],
        },
        ProfileDef {
            id: 6,
            name: "Systems Programmer".into(),
            name_tr: "Sistem Programcisi".into(),
            languages: vec!["Rust".into(), "C/C++ (GCC)".into(), "Zig".into()],
            ides: vec!["VS Code".into(), "Neovim".into(), "CLion".into()],
            frameworks: vec![],
            tools: vec!["Docker".into(), "Git".into()],
        },
        ProfileDef {
            id: 7,
            name: "Full Stack .NET".into(),
            name_tr: "Full Stack .NET".into(),
            languages: vec![".NET SDK".into(), "TypeScript".into()],
            ides: vec!["Visual Studio".into(), "VS Code".into(), "Rider".into()],
            frameworks: vec!["Blazor".into(), "React".into()],
            tools: vec!["npm".into(), "Docker".into()],
        },
        ProfileDef {
            id: 8,
            name: "Game Developer".into(),
            name_tr: "Oyun Gelistirici".into(),
            languages: vec![".NET SDK".into(), "C/C++ (GCC)".into(), "Rust".into()],
            ides: vec!["Visual Studio".into(), "VS Code".into(), "Rider".into()],
            frameworks: vec![],
            tools: vec!["Git".into()],
        },
        ProfileDef {
            id: 9,
            name: "DevOps/Cloud".into(),
            name_tr: "DevOps/Bulut".into(),
            languages: vec!["Python".into(), "Go".into()],
            ides: vec!["VS Code".into()],
            frameworks: vec!["Terraform".into()],
            tools: vec!["Docker".into(), "kubectl".into(), "Helm".into()],
        },
        ProfileDef {
            id: 10,
            name: "Blockchain/Web3".into(),
            name_tr: "Blockchain/Web3".into(),
            languages: vec!["Node.js".into(), "Rust".into(), "Solidity".into()],
            ides: vec!["VS Code".into()],
            frameworks: vec!["React".into(), "Next.js".into()],
            tools: vec!["npm".into(), "Docker".into()],
        },
        ProfileDef {
            id: 11,
            name: "Embedded/IoT".into(),
            name_tr: "Gomulu/IoT".into(),
            languages: vec!["C/C++ (GCC)".into(), "Rust".into(), "Python".into()],
            ides: vec!["VS Code".into(), "CLion".into()],
            frameworks: vec![],
            tools: vec!["Docker".into(), "Git".into()],
        },
        ProfileDef {
            id: 12,
            name: "Scientific Computing".into(),
            name_tr: "Bilimsel Hesaplama".into(),
            languages: vec!["Python".into(), "Julia".into(), "R".into(), "Fortran".into()],
            ides: vec!["VS Code".into()],
            frameworks: vec![],
            tools: vec!["VenvStudio".into(), "Conda".into()],
        },
        ProfileDef {
            id: 13,
            name: "Functional".into(),
            name_tr: "Fonksiyonel".into(),
            languages: vec!["Haskell".into(), "Elixir".into(), "Erlang".into(), "OCaml".into(), "Scala".into()],
            ides: vec!["VS Code".into(), "Neovim".into()],
            frameworks: vec![],
            tools: vec!["Git".into()],
        },
        ProfileDef {
            id: 14,
            name: "JVM Ecosystem".into(),
            name_tr: "JVM Ekosistemi".into(),
            languages: vec!["Java (JDK)".into(), "Kotlin".into(), "Scala".into(), "Groovy".into()],
            ides: vec!["IntelliJ IDEA".into(), "VS Code".into()],
            frameworks: vec![],
            tools: vec!["Docker".into(), "Git".into()],
        },
        ProfileDef {
            id: 15,
            name: "Minimalist/Terminal".into(),
            name_tr: "Minimalist/Terminal".into(),
            languages: vec!["Python".into(), "Node.js".into(), "Go".into(), "Rust".into()],
            ides: vec!["Neovim".into(), "Vim".into()],
            frameworks: vec![],
            tools: vec!["Git".into()],
        },
    ]
}

#[tauri::command]
fn get_os_info() -> String {
    #[cfg(target_os = "windows")]
    return "windows".to_string();
    #[cfg(target_os = "macos")]
    return "macos".to_string();
    #[cfg(target_os = "linux")]
    return "linux".to_string();
}

// ─── Main ────────────────────────────────────────────────────────

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .invoke_handler(tauri::generate_handler![
            scan_system,
            install_item,
            get_profiles,
            get_os_info,
        ])
        .run(tauri::generate_context!())
        .expect("error while running CodeReady");
}
