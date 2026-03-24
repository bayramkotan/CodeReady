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

fn get_version(cmd: &str, args: &[&str]) -> Option<String> {
    let output = Command::new(cmd).args(args)
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::piped())
        .output().ok()?;
    let raw = if output.status.success() {
        String::from_utf8_lossy(&output.stdout).to_string()
    } else {
        String::from_utf8_lossy(&output.stderr).to_string()
    };
    let line = raw.lines().next().unwrap_or("").trim().to_string();
    if line.is_empty() { return None; }
    let version = line
        .replace("Python ", "")
        .replace("java version \"", "").replace("\"", "")
        .replace("openjdk version \"", "")
        .replace("go version go", "")
        .replace("rustc ", "")
        .replace("ruby ", "")
        .replace("Dart SDK version: ", "")
        .replace("v", "")
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
        .trim()
        .split_whitespace()
        .next()
        .unwrap_or(&line)
        .to_string();
    Some(version)
}

/// Get list of globally installed npm packages (cached for performance)
fn get_npm_globals() -> Vec<String> {
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
    let output = Command::new("pip3")
        .args(["list", "--format=columns"])
        .stdout(std::process::Stdio::piped())
        .stderr(std::process::Stdio::null())
        .output();

    // Fallback to pip if pip3 not found
    let output = match output {
        Ok(o) if o.status.success() => o,
        _ => {
            match Command::new("pip")
                .args(["list", "--format=columns"])
                .stdout(std::process::Stdio::piped())
                .stderr(std::process::Stdio::null())
                .output()
            {
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

pub fn scan_system_sync() -> ScanResult {
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

    // 4. Tools & package managers
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

    // 5. System package managers
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
            .args(["install", "-e", "--id", &request.package_id, "--accept-source-agreements", "--accept-package-agreements"])
            .output(),
        "scoop" => Command::new("scoop").args(["install", &request.package_id]).output(),
        "choco" => Command::new("choco").args(["install", &request.package_id, "-y"]).output(),
        "pip" => Command::new("pip3").args(["install", "--break-system-packages", &request.package_id]).output(),
        "npm" => Command::new("npm").args(["install", "-g", &request.package_id]).output(),
        "apt" => Command::new("sudo").args(["apt", "install", "-y", &request.package_id]).output(),
        "brew" => Command::new("brew").args(["install", &request.package_id]).output(),
        _ => return Err(format!("Unknown method: {}", request.method)),
    };

    match result {
        Ok(output) if output.status.success() => Ok(format!("{} installed successfully.", request.name)),
        Ok(output) => Err(format!("Install failed: {}", String::from_utf8_lossy(&output.stderr))),
        Err(e) => Err(format!("Failed to run installer: {}", e)),
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
