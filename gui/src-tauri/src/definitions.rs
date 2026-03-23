// CodeReady GUI — Package Definitions
// Maps display names to install IDs for each package manager

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PackageDef {
    pub name: String,
    pub category: String,
    pub winget: String,
    pub choco: String,
    pub apt: String,
    pub brew: String,
    pub pip: String,
    pub npm: String,
}

impl PackageDef {
    fn new(name: &str, cat: &str, winget: &str, choco: &str, apt: &str, brew: &str, pip: &str, npm: &str) -> Self {
        Self {
            name: name.into(), category: cat.into(),
            winget: winget.into(), choco: choco.into(),
            apt: apt.into(), brew: brew.into(),
            pip: pip.into(), npm: npm.into(),
        }
    }

    /// Pick best install method for the current OS
    pub fn best_method(&self, os: &str) -> Option<(&str, &str)> {
        match os {
            "windows" => {
                if !self.winget.is_empty() { return Some(("winget", &self.winget)); }
                if !self.choco.is_empty() { return Some(("choco", &self.choco)); }
                if !self.npm.is_empty() { return Some(("npm", &self.npm)); }
                if !self.pip.is_empty() { return Some(("pip", &self.pip)); }
                None
            }
            "linux" => {
                if !self.apt.is_empty() { return Some(("apt", &self.apt)); }
                if !self.pip.is_empty() { return Some(("pip", &self.pip)); }
                if !self.npm.is_empty() { return Some(("npm", &self.npm)); }
                if !self.brew.is_empty() { return Some(("brew", &self.brew)); }
                None
            }
            "macos" => {
                if !self.brew.is_empty() { return Some(("brew", &self.brew)); }
                if !self.pip.is_empty() { return Some(("pip", &self.pip)); }
                if !self.npm.is_empty() { return Some(("npm", &self.npm)); }
                None
            }
            _ => None,
        }
    }
}

pub fn get_all_packages() -> Vec<PackageDef> {
    vec![
        // ── Languages & Runtimes ─────────────────────────────────────
        PackageDef::new("Python",       "language", "Python.Python.3.14",               "python314",            "python3",          "python",       "", ""),
        PackageDef::new("Node.js",      "language", "OpenJS.NodeJS.LTS",                "nodejs-lts",           "nodejs",           "node",         "", ""),
        PackageDef::new("Java (JDK)",   "language", "EclipseAdoptium.Temurin.25.JDK",   "temurin25",            "default-jdk",      "openjdk",      "", ""),
        PackageDef::new(".NET SDK",     "language", "Microsoft.DotNet.SDK.9",           "dotnet-sdk",           "dotnet-sdk-9.0",   "dotnet",       "", ""),
        PackageDef::new("C/C++ (GCC)",  "language", "",                                 "mingw",                "build-essential",  "gcc",          "", ""),
        PackageDef::new("Go",           "language", "GoLang.Go",                        "golang",               "golang-go",        "go",           "", ""),
        PackageDef::new("Rust",         "language", "Rustlang.Rustup",                  "rustup.install",       "rustup",           "rustup",       "", ""),
        PackageDef::new("PHP",          "language", "",                                 "php",                  "php",              "php",          "", ""),
        PackageDef::new("Ruby",         "language", "RubyInstallerTeam.Ruby.3.3",       "ruby",                 "ruby-full",        "ruby",         "", ""),
        PackageDef::new("Kotlin",       "language", "",                                 "kotlin",               "kotlin",           "kotlin",       "", ""),
        PackageDef::new("Dart",         "language", "",                                 "dart-sdk",             "",                 "dart",         "", ""),
        PackageDef::new("Flutter",      "language", "Google.Flutter",                   "flutter",              "",                 "flutter",      "", ""),
        PackageDef::new("Swift",        "language", "Swift.Toolchain",                  "",                     "swift",            "swift",        "", ""),
        PackageDef::new("TypeScript",   "language", "",                                 "",                     "",                 "",             "", "typescript"),
        PackageDef::new("R",            "language", "RProject.R",                       "r.project",            "r-base",           "r",            "", ""),
        PackageDef::new("Lua",          "language", "",                                 "lua",                  "lua5.4",           "lua",          "", ""),
        PackageDef::new("Haskell",      "language", "",                                 "ghc",                  "ghc",              "ghc",          "", ""),
        PackageDef::new("Perl",         "language", "StrawberryPerl.StrawberryPerl",    "strawberryperl",       "perl",             "perl",         "", ""),
        PackageDef::new("Erlang",       "language", "Ericsson.ErlangOTP",               "erlang",               "erlang",           "erlang",       "", ""),
        PackageDef::new("OCaml",        "language", "",                                 "ocaml",                "ocaml",            "ocaml",        "", ""),
        PackageDef::new("Fortran",      "language", "",                                 "mingw",                "gfortran",         "gcc",          "", ""),
        PackageDef::new("D",            "language", "ldc-developers.LDC",               "ldc",                  "ldc",              "ldc",          "", ""),
        PackageDef::new("Nim",          "language", "",                                 "nim",                  "",                 "nim",          "", ""),
        PackageDef::new("Crystal",      "language", "",                                 "crystal",              "crystal",          "crystal",      "", ""),
        PackageDef::new("V",            "language", "",                                 "vlang",                "",                 "vlang",        "", ""),
        PackageDef::new("Gleam",        "language", "",                                 "gleam",                "",                 "gleam",        "", ""),
        PackageDef::new("Solidity",     "language", "",                                 "",                     "",                 "",             "", "solc"),
        PackageDef::new("Groovy",       "language", "",                                 "groovy",               "groovy",           "groovy",       "", ""),
        PackageDef::new("Elixir",       "language", "ElixirLang.Elixir",                "elixir",               "elixir",           "elixir",       "", ""),
        PackageDef::new("Scala",        "language", "",                                 "scala",                "scala",            "scala",        "", ""),
        PackageDef::new("Julia",        "language", "Julialang.Julia",                  "julia",                "",                 "julia",        "", ""),
        PackageDef::new("Zig",          "language", "zig.zig",                          "zig",                  "",                 "zig",          "", ""),
        PackageDef::new("Mojo",         "language", "",                                 "",                     "",                 "",             "mojo", ""),
        PackageDef::new("WebAssembly",  "language", "BytecodeAlliance.Wasmtime",        "wasmtime",             "",                 "wasmtime",     "", ""),

        // ── IDEs & Editors ───────────────────────────────────────────
        PackageDef::new("VS Code",                  "ide", "Microsoft.VisualStudioCode",          "vscode",               "code",                 "visual-studio-code",   "", ""),
        PackageDef::new("VSCodium",                 "ide", "VSCodium.VSCodium",                   "vscodium",             "",                     "vscodium",             "", ""),
        PackageDef::new("Cursor",                   "ide", "Anysphere.Cursor",                    "",                     "",                     "",                     "", ""),
        PackageDef::new("Zed",                      "ide", "Zed.Zed",                             "",                     "",                     "zed",                  "", ""),
        PackageDef::new("Windsurf",                 "ide", "Codeium.Windsurf",                    "",                     "",                     "",                     "", ""),
        PackageDef::new("Visual Studio",            "ide", "Microsoft.VisualStudio.2026.Community","visualstudio2026community","",                 "",                     "", ""),
        PackageDef::new("Sublime Text",             "ide", "SublimeHQ.SublimeText.4",             "sublimetext4",         "sublime-text",         "sublime-text",         "", ""),
        PackageDef::new("Vim",                      "ide", "vim.vim",                             "vim",                  "vim",                  "vim",                  "", ""),
        PackageDef::new("Neovim",                   "ide", "Neovim.Neovim",                       "neovim",               "neovim",               "neovim",               "", ""),
        PackageDef::new("GNU Emacs",                "ide", "GNU.Emacs",                           "emacs",                "emacs",                "emacs",                "", ""),
        PackageDef::new("Notepad++",                "ide", "Notepad++.Notepad++",                 "notepadplusplus",      "",                     "",                     "", ""),
        PackageDef::new("IntelliJ IDEA",            "ide", "JetBrains.IntelliJIDEA.Community",    "intellijidea-community","",                    "intellij-idea-ce",     "", ""),
        PackageDef::new("PyCharm",                  "ide", "JetBrains.PyCharm.Community",         "pycharm-community",    "",                     "pycharm-ce",           "", ""),
        PackageDef::new("WebStorm",                 "ide", "JetBrains.WebStorm",                  "webstorm",             "",                     "webstorm",             "", ""),
        PackageDef::new("GoLand",                   "ide", "JetBrains.GoLand",                    "goland",               "",                     "goland",               "", ""),
        PackageDef::new("CLion",                    "ide", "JetBrains.CLion",                     "clion",                "",                     "clion",                "", ""),
        PackageDef::new("Rider",                    "ide", "JetBrains.Rider",                     "jetbrains-rider",      "",                     "rider",                "", ""),
        PackageDef::new("RustRover",                "ide", "JetBrains.RustRover",                 "rustrover",            "",                     "rustrover",            "", ""),
        PackageDef::new("JetBrains Fleet",          "ide", "JetBrains.Fleet",                     "",                     "",                     "",                     "", ""),
        PackageDef::new("Eclipse",                  "ide", "EclipseFoundation.EclipseIDE",        "eclipse",              "eclipse",              "eclipse-ide",          "", ""),
        PackageDef::new("Apache NetBeans",          "ide", "Apache.NetBeans",                     "netbeans",             "netbeans",             "netbeans",             "", ""),
        PackageDef::new("Android Studio",           "ide", "Google.AndroidStudio",                "androidstudio",        "",                     "android-studio",       "", ""),

        // ── Frameworks ───────────────────────────────────────────────
        PackageDef::new("React",          "framework", "", "", "", "", "", "create-react-app"),
        PackageDef::new("Next.js",        "framework", "", "", "", "", "", "create-next-app"),
        PackageDef::new("Vue",            "framework", "", "", "", "", "", "@vue/cli"),
        PackageDef::new("Nuxt",           "framework", "", "", "", "", "", "nuxi"),
        PackageDef::new("Angular",        "framework", "", "", "", "", "", "@angular/cli"),
        PackageDef::new("Svelte",         "framework", "", "", "", "", "", "create-svelte"),
        PackageDef::new("Vite",           "framework", "", "", "", "", "", "create-vite"),
        PackageDef::new("Astro",          "framework", "", "", "", "", "", "create-astro"),
        PackageDef::new("Remix",          "framework", "", "", "", "", "", "create-remix"),
        PackageDef::new("Express",        "framework", "", "", "", "", "", "express-generator"),
        PackageDef::new("NestJS",         "framework", "", "", "", "", "", "@nestjs/cli"),
        PackageDef::new("Django",         "framework", "", "", "", "", "django", ""),
        PackageDef::new("Flask",          "framework", "", "", "", "", "flask", ""),
        PackageDef::new("FastAPI",        "framework", "", "", "", "", "fastapi uvicorn", ""),
        PackageDef::new("Streamlit",      "framework", "", "", "", "", "streamlit", ""),
        PackageDef::new("Tailwind",       "framework", "", "", "", "", "", "tailwindcss"),
        PackageDef::new("Bootstrap",      "framework", "", "", "", "", "", "bootstrap"),
        PackageDef::new("React Native",   "framework", "", "", "", "", "", "react-native-cli"),
        PackageDef::new("Expo",           "framework", "", "", "", "", "", "expo-cli"),
        PackageDef::new("Ionic",          "framework", "", "", "", "", "", "@ionic/cli"),
        PackageDef::new("Electron",       "framework", "", "", "", "", "", "electron"),
        PackageDef::new("Blazor",         "framework", "Microsoft.DotNet.SDK.9", "dotnet-sdk", "dotnet-sdk-9.0", "dotnet", "", ""),

        // ── Tools & Package Managers ─────────────────────────────────
        PackageDef::new("VenvStudio",     "tool", "", "", "", "", "VenvStudio", ""),
        PackageDef::new("uv",            "tool", "", "", "", "", "uv", ""),
        PackageDef::new("Poetry",        "tool", "", "", "", "", "", ""),  // curl installer
        PackageDef::new("pipx",          "tool", "", "", "", "", "pipx", ""),
        PackageDef::new("Conda",         "tool", "", "", "", "", "", ""),  // custom installer
        PackageDef::new("npm",           "tool", "OpenJS.NodeJS.LTS", "nodejs-lts", "nodejs", "node", "", ""),
        PackageDef::new("Yarn",          "tool", "", "", "", "", "", "yarn"),
        PackageDef::new("pnpm",          "tool", "", "", "", "", "", "pnpm"),
        PackageDef::new("Bun",           "tool", "", "", "", "", "", ""),  // curl installer
        PackageDef::new("Git",           "tool", "Git.Git", "git", "git", "git", "", ""),
        PackageDef::new("Docker",        "tool", "Docker.DockerDesktop", "docker-desktop", "docker.io", "docker", "", ""),
        PackageDef::new("kubectl",       "tool", "Kubernetes.kubectl", "kubernetes-cli", "", "kubectl", "", ""),
        PackageDef::new("Helm",          "tool", "Helm.Helm", "kubernetes-helm", "", "helm", "", ""),
        PackageDef::new("Terraform",     "tool", "Hashicorp.Terraform", "terraform", "", "terraform", "", ""),
    ]
}
