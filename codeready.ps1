#Requires -RunAsAdministrator
# ================================================================
# CodeReady v2.0.0
# Developer Environment Setup Tool (Windows)
# https://github.com/bayramkotan/CodeReady
# ================================================================

$ErrorActionPreference = "Continue"
$script:Version = "2.0.0"
$script:LogFile = "$env:USERPROFILE\codeready_install.log"
$script:InstalledItems = @()
$script:FailedItems = @()

# --- Colors and UI ----------------------------------------------
function Write-Banner {
    Clear-Host
    $banner = @"

     CCCCC   OOO   DDDD   EEEEE  RRRR   EEEEE   AAA   DDDD   Y   Y
    C       O   O  D   D  E      R   R  E      A   A  D   D   Y Y
    C       O   O  D   D  EEE    RRRR   EEE    AAAAA  D   D    Y
    C       O   O  D   D  E      R  R   E      A   A  D   D    Y
     CCCCC   OOO   DDDD   EEEEE  R   R  EEEEE  A   A  DDDD     Y
                                                        v$script:Version
"@
    Write-Host $banner -ForegroundColor Cyan
    Write-Host "  Developer Environment Setup Tool - Windows Edition" -ForegroundColor DarkCyan
    Write-Host "  ===================================================" -ForegroundColor DarkGray
    Write-Host ""
}

function Write-Step($msg)    { Write-Host "  [>] " -NoNewline -ForegroundColor Yellow; Write-Host $msg }
function Write-Success($msg) { Write-Host "  [+] " -NoNewline -ForegroundColor Green;  Write-Host $msg; Add-Content -Path $script:LogFile -Value ("[OK] " + $msg) }
function Write-Fail($msg)    { Write-Host "  [-] " -NoNewline -ForegroundColor Red;    Write-Host $msg; Add-Content -Path $script:LogFile -Value ("[FAIL] " + $msg) }
function Write-Info($msg)    { Write-Host "  [i] " -NoNewline -ForegroundColor DarkCyan; Write-Host $msg -ForegroundColor Gray }
function Write-SectionHeader($title) { Write-Host ""; Write-Host "  === $title ===" -ForegroundColor DarkYellow; Write-Host "" }

# --- Package Manager Setup --------------------------------------
function Ensure-WinGet {
    Write-Step "Checking winget..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Success "winget is already installed."
        return $true
    }
    Write-Step "Installing winget..."
    try {
        $progressPreference = "silentlyContinue"
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile "$env:TEMP\winget.msixbundle"
        Add-AppxPackage -Path "$env:TEMP\winget.msixbundle"
        Write-Success "winget installed."
        return $true
    } catch {
        Write-Fail "Could not install winget: $_"
        return $false
    }
}

function Ensure-Chocolatey {
    Write-Step "Checking Chocolatey..."
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Success "Chocolatey is already installed."
        return $true
    }
    Write-Step "Installing Chocolatey..."
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        $url = "https://community.chocolatey.org/install.ps1"
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($url))
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Success "Chocolatey installed."
        return $true
    } catch {
        Write-Fail "Could not install Chocolatey: $_"
        return $false
    }
}

# --- Installation Helpers ---------------------------------------
function Install-WithWinGet($id, $name) {
    Write-Step "Installing $name..."
    try {
        $result = winget install --id $id --accept-source-agreements --accept-package-agreements --silent 2>&1
        if ($LASTEXITCODE -eq 0 -or $result -match "already installed") {
            Write-Success "$name installed successfully."
            $script:InstalledItems += $name
            return $true
        } else {
            Write-Fail "Failed to install $name via winget."
            $script:FailedItems += $name
            return $false
        }
    } catch {
        Write-Fail "Error installing ${name}: $_"
        $script:FailedItems += $name
        return $false
    }
}

function Install-WithChoco($pkg, $name) {
    Write-Step "Installing $name..."
    try {
        choco install $pkg -y --no-progress 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$name installed successfully."
            $script:InstalledItems += $name
            return $true
        } else {
            Write-Fail "Failed to install $name via Chocolatey."
            $script:FailedItems += $name
            return $false
        }
    } catch {
        Write-Fail "Error installing ${name}: $_"
        $script:FailedItems += $name
        return $false
    }
}

function Install-Item($wingetId, $chocoId, $name) {
    if ($wingetId -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        return Install-WithWinGet $wingetId $name
    }
    elseif ($chocoId -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        return Install-WithChoco $chocoId $name
    }
    else {
        Write-Fail "No installation method for $name"
        $script:FailedItems += $name
        return $false
    }
}

# --- Interactive Menu -------------------------------------------
function Show-NumberMenu($title, $items) {
    Write-SectionHeader $title

    for ($i = 0; $i -lt $items.Count; $i++) {
        $num = ($i + 1).ToString().PadLeft(2)
        Write-Host "  [$num] $($items[$i])" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "  Enter numbers separated by spaces, 'a' for all, 'n' for none" -ForegroundColor DarkGray
    $selection = Read-Host "  Selection"

    if ($selection -eq "a" -or $selection -eq "A") { return @(0..($items.Count - 1)) }
    if ($selection -eq "n" -or $selection -eq "N") { return @() }

    $result = @()
    foreach ($num in $selection.Split(" ", [StringSplitOptions]::RemoveEmptyEntries)) {
        $n = 0
        if ([int]::TryParse($num, [ref]$n)) {
            if ($n -ge 1 -and $n -le $items.Count) { $result += ($n - 1) }
        }
    }
    return $result
}

function Show-VersionMenu($langName, $versions) {
    Write-Host ""
    Write-Host "  $langName - Select version:" -ForegroundColor Cyan
    for ($i = 0; $i -lt $versions.Count; $i++) {
        $tag = ""
        if ($i -eq 0) { $tag = " (latest)" }
        Write-Host "    [$($i+1)] $($versions[$i].Label)$tag" -ForegroundColor White
    }
    $choice = Read-Host "    Version (default=1)"
    if (-not $choice -or $choice -eq "") { $choice = "1" }
    $idx = [int]$choice - 1
    if ($idx -lt 0 -or $idx -ge $versions.Count) { $idx = 0 }
    return $versions[$idx]
}

# ================================================================
# LANGUAGE DEFINITIONS (with version choices)
# ================================================================
function Get-Languages {
    return @(
        @{
            Key="python"; Name="Python"; Desc="General purpose, AI/ML, scripting"
            Versions=@(
                @{ Label="Python 3.14"; WinGet="Python.Python.3.14"; Choco="python314" },
                @{ Label="Python 3.13"; WinGet="Python.Python.3.13"; Choco="python313" },
                @{ Label="Python 3.12"; WinGet="Python.Python.3.12"; Choco="python312" },
                @{ Label="Python 3.11"; WinGet="Python.Python.3.11"; Choco="python311" }
            )
        },
        @{
            Key="nodejs"; Name="Node.js"; Desc="JavaScript/TypeScript runtime"
            Versions=@(
                @{ Label="Node.js 24 LTS"; WinGet="OpenJS.NodeJS.LTS"; Choco="nodejs-lts" },
                @{ Label="Node.js 25 (Current)"; WinGet="OpenJS.NodeJS"; Choco="nodejs" },
                @{ Label="Node.js 22 LTS"; WinGet="OpenJS.NodeJS.22"; Choco="nodejs.install --version=22" },
                @{ Label="Node.js 20 LTS"; WinGet="OpenJS.NodeJS.20"; Choco="nodejs.install --version=20" }
            )
        },
        @{
            Key="java"; Name="Java (JDK)"; Desc="Enterprise, Android, cross-platform"
            Versions=@(
                @{ Label="JDK 25 (Latest)"; WinGet="EclipseAdoptium.Temurin.25.JDK"; Choco="temurin25" },
                @{ Label="JDK 23 (LTS)"; WinGet="EclipseAdoptium.Temurin.23.JDK"; Choco="temurin23" },
                @{ Label="JDK 21 (LTS)"; WinGet="EclipseAdoptium.Temurin.21.JDK"; Choco="temurin21" },
                @{ Label="JDK 17 (LTS)"; WinGet="EclipseAdoptium.Temurin.17.JDK"; Choco="temurin17" }
            )
        },
        @{
            Key="csharp"; Name="C# / .NET SDK"; Desc="Microsoft ecosystem, web, desktop, games"
            Versions=@(
                @{ Label=".NET 9 (Latest)"; WinGet="Microsoft.DotNet.SDK.9"; Choco="dotnet-sdk" },
                @{ Label=".NET 8 (LTS)"; WinGet="Microsoft.DotNet.SDK.8"; Choco="dotnet-8.0-sdk" },
                @{ Label=".NET 7"; WinGet="Microsoft.DotNet.SDK.7"; Choco="dotnet-7.0-sdk" },
                @{ Label=".NET 6 (LTS)"; WinGet="Microsoft.DotNet.SDK.6"; Choco="dotnet-6.0-sdk" }
            )
        },
        @{
            Key="cpp"; Name="C/C++"; Desc="Systems programming, performance-critical"
            Versions=@(
                @{ Label="MinGW-w64 (GCC latest)"; WinGet=""; Choco="mingw" },
                @{ Label="LLVM/Clang (latest)"; WinGet="LLVM.LLVM"; Choco="llvm" },
                @{ Label="MSVC Build Tools 2026"; WinGet="Microsoft.VisualStudio.2026.BuildTools"; Choco="" }
            )
        },
        @{
            Key="go"; Name="Go (Golang)"; Desc="Cloud, networking, microservices"
            Versions=@(
                @{ Label="Go 1.23 (Latest)"; WinGet="GoLang.Go"; Choco="golang" },
                @{ Label="Go 1.22"; WinGet="GoLang.Go.1.22"; Choco="golang --version=1.22" },
                @{ Label="Go 1.21"; WinGet="GoLang.Go.1.21"; Choco="golang --version=1.21" }
            )
        },
        @{
            Key="rust"; Name="Rust"; Desc="Systems programming, memory safety"
            Versions=@(
                @{ Label="Rust (latest via rustup)"; WinGet="Rustlang.Rustup"; Choco="rustup.install" }
            )
        },
        @{
            Key="php"; Name="PHP"; Desc="Web development, CMS, server-side"
            Versions=@(
                @{ Label="PHP 8.4 (Latest)"; WinGet=""; Choco="php --version=8.4" },
                @{ Label="PHP 8.3"; WinGet=""; Choco="php --version=8.3" },
                @{ Label="PHP 8.2"; WinGet=""; Choco="php --version=8.2" }
            )
        },
        @{
            Key="ruby"; Name="Ruby"; Desc="Web development, scripting, DevOps"
            Versions=@(
                @{ Label="Ruby 3.3 (Latest)"; WinGet="RubyInstallerTeam.Ruby.3.3"; Choco="ruby" },
                @{ Label="Ruby 3.2"; WinGet="RubyInstallerTeam.Ruby.3.2"; Choco="ruby --version=3.2" },
                @{ Label="Ruby 3.1"; WinGet="RubyInstallerTeam.Ruby.3.1"; Choco="ruby --version=3.1" }
            )
        },
        @{
            Key="kotlin"; Name="Kotlin"; Desc="Android, JVM, multiplatform"
            Versions=@(
                @{ Label="Kotlin (latest)"; WinGet=""; Choco="kotlin" }
            )
        },
        @{
            Key="dart"; Name="Dart and Flutter"; Desc="Mobile, web, desktop UI"
            Versions=@(
                @{ Label="Flutter (latest, includes Dart)"; WinGet="Google.Flutter"; Choco="flutter" },
                @{ Label="Dart SDK only"; WinGet=""; Choco="dart-sdk" }
            )
        },
        @{
            Key="swift"; Name="Swift"; Desc="Apple ecosystem, server-side"
            Versions=@(
                @{ Label="Swift (latest)"; WinGet="Swift.Toolchain"; Choco="" }
            )
        },
        @{
            Key="zig"; Name="Zig"; Desc="Next-gen systems programming, C/C++ interop"
            Versions=@(
                @{ Label="Zig 0.13 (Latest stable)"; WinGet="zig.zig"; Choco="zig" },
                @{ Label="Zig 0.12"; WinGet=""; Choco="zig --version=0.12" }
            )
        },
        @{
            Key="mojo"; Name="Mojo"; Desc="AI/GPU programming, Python superset (Linux/macOS + WSL)"
            Versions=@(
                @{ Label="Mojo (latest via pip in WSL)"; WinGet=""; Choco="" }
            )
        },
        @{
            Key="wasm"; Name="WebAssembly (WASI)"; Desc="Portable binary format, edge/browser"
            Versions=@(
                @{ Label="Wasmtime (latest)"; WinGet="BytecodeAlliance.Wasmtime"; Choco="wasmtime" },
                @{ Label="Wasmer (latest)"; WinGet="Wasmer.Wasmer"; Choco="wasmer" }
            )
        },
        @{
            Key="typescript"; Name="TypeScript"; Desc="Typed JavaScript, enterprise web"
            Versions=@(
                @{ Label="TypeScript (latest via npm)"; WinGet=""; Choco="" }
            )
        },
        @{
            Key="elixir"; Name="Elixir"; Desc="Functional, concurrent, fault-tolerant"
            Versions=@(
                @{ Label="Elixir (latest)"; WinGet="ElixirLang.Elixir"; Choco="elixir" }
            )
        },
        @{
            Key="scala"; Name="Scala"; Desc="JVM functional/OOP hybrid"
            Versions=@(
                @{ Label="Scala 3 (latest)"; WinGet=""; Choco="scala" }
            )
        },
        @{
            Key="julia"; Name="Julia"; Desc="High-performance scientific computing"
            Versions=@(
                @{ Label="Julia 1.12 (Latest)"; WinGet="Julialang.Julia"; Choco="julia" },
                @{ Label="Julia 1.10 (LTS)"; WinGet="Julialang.Julia.LTS"; Choco="julia --version=1.10" }
            )
        }
    )
}

# ================================================================
# IDE DEFINITIONS (always latest version)
# ================================================================
function Get-IDEs {
    return @(
        @{ Key="vscode";    Name="VS Code";                    Desc="Lightweight, extensible, multi-language";    WinGet="Microsoft.VisualStudioCode";              Choco="vscode" },
        @{ Key="vs2026";    Name="Visual Studio 2026 Community"; Desc="Full-featured IDE for .NET, C++ (v18)";   WinGet="Microsoft.VisualStudio.2026.Community";    Choco="visualstudio2026community" },
        @{ Key="intellij";  Name="IntelliJ IDEA Community";    Desc="Java, Kotlin, JVM languages";               WinGet="JetBrains.IntelliJIDEA.Community";         Choco="intellijidea-community" },
        @{ Key="pycharm";   Name="PyCharm Community";          Desc="Python IDE with debugging and testing";      WinGet="JetBrains.PyCharm.Community";              Choco="pycharm-community" },
        @{ Key="webstorm";  Name="WebStorm";                   Desc="JavaScript/TypeScript IDE (paid)";           WinGet="JetBrains.WebStorm";                       Choco="webstorm" },
        @{ Key="goland";    Name="GoLand";                     Desc="Go IDE by JetBrains (paid)";                 WinGet="JetBrains.GoLand";                         Choco="goland" },
        @{ Key="clion";     Name="CLion";                      Desc="C/C++ IDE by JetBrains (paid)";              WinGet="JetBrains.CLion";                          Choco="clion" },
        @{ Key="rider";     Name="Rider";                      Desc=".NET IDE by JetBrains (paid)";               WinGet="JetBrains.Rider";                          Choco="jetbrains-rider" },
        @{ Key="rustrover"; Name="RustRover";                  Desc="Rust IDE by JetBrains";                      WinGet="JetBrains.RustRover";                      Choco="rustrover" },
        @{ Key="eclipse";   Name="Eclipse IDE";                Desc="Java, C/C++, PHP, multi-language";           WinGet="EclipseFoundation.EclipseIDE";             Choco="eclipse" },
        @{ Key="android";   Name="Android Studio";             Desc="Official Android development IDE";           WinGet="Google.AndroidStudio";                     Choco="androidstudio" },
        @{ Key="sublime";   Name="Sublime Text";               Desc="Fast, lightweight code editor";              WinGet="SublimeHQ.SublimeText.4";                  Choco="sublimetext4" },
        @{ Key="vim";       Name="Neovim";                     Desc="Terminal-based editor for power users";      WinGet="Neovim.Neovim";                            Choco="neovim" },
        @{ Key="notepadpp"; Name="Notepad++";                  Desc="Lightweight Windows code editor";            WinGet="Notepad++.Notepad++";                      Choco="notepadplusplus" },
        @{ Key="cursor";    Name="Cursor";                     Desc="AI-powered code editor";                     WinGet="Anysphere.Cursor";                         Choco="" },
        @{ Key="windsurf";  Name="Windsurf";                   Desc="AI-powered IDE by Codeium";                  WinGet="Codeium.Windsurf";                         Choco="" },
        @{ Key="zed";       Name="Zed";                        Desc="High-performance editor written in Rust";    WinGet="Zed.Zed";                                  Choco="" }
    )
}

# ================================================================
# TOOLS DEFINITIONS
# ================================================================
function Get-Tools {
    return @(
        @{ Key="git";       Name="Git";               Desc="Version control system";          WinGet="Git.Git";                  Choco="git" },
        @{ Key="docker";    Name="Docker Desktop";     Desc="Containerization platform";       WinGet="Docker.DockerDesktop";     Choco="docker-desktop" },
        @{ Key="postman";   Name="Postman";            Desc="API testing and development";     WinGet="Postman.Postman";          Choco="postman" },
        @{ Key="wsl";       Name="WSL 2 (Ubuntu)";     Desc="Linux subsystem for Windows";     WinGet="";                         Choco="" },
        @{ Key="terminal";  Name="Windows Terminal";    Desc="Modern terminal application";     WinGet="Microsoft.WindowsTerminal"; Choco="microsoft-windows-terminal" },
        @{ Key="cmake";     Name="CMake";              Desc="Cross-platform build system";     WinGet="Kitware.CMake";            Choco="cmake" },
        @{ Key="gh";        Name="GitHub CLI";         Desc="GitHub from command line";        WinGet="GitHub.cli";               Choco="gh" },
        @{ Key="nvm";       Name="NVM for Windows";    Desc="Node version manager";            WinGet="CoreyButler.NVMforWindows"; Choco="nvm" },
        @{ Key="pyenv";     Name="pyenv-win";          Desc="Python version manager";          WinGet="";                         Choco="pyenv-win" }
    )
}

# ================================================================
# FRAMEWORKS, PACKAGE MANAGERS, LIBRARIES
# ================================================================
function Get-Frameworks {
    return @(
        # --- JS/TS Package Managers ---
        @{ Key="npm";       Name="npm (latest)";       Desc="Node.js default package manager";    Type="npm"; Cmd="npm install -g npm@latest" },
        @{ Key="yarn";      Name="Yarn";               Desc="Fast, reliable JS package manager";  Type="npm"; Cmd="npm install -g yarn" },
        @{ Key="pnpm";      Name="pnpm";               Desc="Fast, disk-efficient JS pkg manager"; Type="npm"; Cmd="npm install -g pnpm" },
        @{ Key="bun";       Name="Bun";                Desc="Ultra-fast JS runtime and pkg manager"; Type="winget"; WinGet="Oven-sh.Bun"; Choco="bun" },

        # --- Python Package Managers ---
        @{ Key="uv";        Name="uv";                 Desc="Ultra-fast Python package manager (Rust)"; Type="pip"; Cmd="pip install uv --break-system-packages 2>$null; pip install uv" },
        @{ Key="poetry";    Name="Poetry";             Desc="Python dependency management";       Type="pip"; Cmd="pip install poetry --break-system-packages 2>$null; pip install poetry" },
        @{ Key="pipx";      Name="pipx";               Desc="Install Python CLI tools in isolation"; Type="pip"; Cmd="pip install pipx --break-system-packages 2>$null; pip install pipx" },
        @{ Key="conda";     Name="Miniconda";          Desc="Python/R data science pkg manager";  Type="winget"; WinGet="Anaconda.Miniconda3"; Choco="miniconda3" },
        @{ Key="venvstudio"; Name="VenvStudio";        Desc="GUI virtual environment manager (PySide6) by bayramkotan"; Type="pip"; Cmd="pip install VenvStudio --break-system-packages 2>$null; pip install VenvStudio" },

        # --- JS/TS Frameworks ---
        @{ Key="react";     Name="React (create-react-app)"; Desc="Facebook UI library";          Type="npm"; Cmd="npm install -g create-react-app" },
        @{ Key="nextjs";    Name="Next.js (create-next-app)"; Desc="React fullstack framework";   Type="npm"; Cmd="npm install -g create-next-app" },
        @{ Key="vue";       Name="Vue CLI";            Desc="Progressive JS framework";           Type="npm"; Cmd="npm install -g @vue/cli" },
        @{ Key="nuxt";      Name="Nuxt (nuxi)";       Desc="Vue fullstack framework";            Type="npm"; Cmd="npm install -g nuxi" },
        @{ Key="angular";   Name="Angular CLI";        Desc="Google enterprise web framework";    Type="npm"; Cmd="npm install -g @angular/cli" },
        @{ Key="svelte";    Name="SvelteKit";          Desc="Lightweight reactive framework";     Type="npm"; Cmd="npm install -g create-svelte" },
        @{ Key="vite";      Name="Vite";               Desc="Next-gen frontend build tool";       Type="npm"; Cmd="npm install -g create-vite" },
        @{ Key="astro";     Name="Astro";              Desc="Content-focused web framework";      Type="npm"; Cmd="npm install -g create-astro" },
        @{ Key="express";   Name="Express.js";         Desc="Minimal Node.js web framework";      Type="npm"; Cmd="npm install -g express-generator" },
        @{ Key="nest";      Name="NestJS CLI";         Desc="Progressive Node.js framework";      Type="npm"; Cmd="npm install -g @nestjs/cli" },
        @{ Key="remix";     Name="Remix";              Desc="Full stack web framework";           Type="npm"; Cmd="npm install -g create-remix" },

        # --- Python Frameworks ---
        @{ Key="django";    Name="Django";             Desc="Python web framework";               Type="pip"; Cmd="pip install django --break-system-packages 2>$null; pip install django" },
        @{ Key="flask";     Name="Flask";              Desc="Lightweight Python web framework";   Type="pip"; Cmd="pip install flask --break-system-packages 2>$null; pip install flask" },
        @{ Key="fastapi";   Name="FastAPI";            Desc="Modern async Python API framework";  Type="pip"; Cmd="pip install fastapi uvicorn --break-system-packages 2>$null; pip install fastapi uvicorn" },
        @{ Key="streamlit"; Name="Streamlit";          Desc="Python data app framework";          Type="pip"; Cmd="pip install streamlit --break-system-packages 2>$null; pip install streamlit" },

        # --- CSS/UI Frameworks ---
        @{ Key="tailwind";  Name="Tailwind CSS";       Desc="Utility-first CSS framework";        Type="npm"; Cmd="npm install -g tailwindcss" },
        @{ Key="bootstrap"; Name="Bootstrap";          Desc="Popular CSS framework";              Type="npm"; Cmd="npm install -g bootstrap" },

        # --- Mobile/Cross-platform ---
        @{ Key="reactnative"; Name="React Native CLI"; Desc="Cross-platform mobile framework";    Type="npm"; Cmd="npm install -g react-native-cli" },
        @{ Key="expo";      Name="Expo CLI";           Desc="React Native toolchain";             Type="npm"; Cmd="npm install -g expo-cli" },
        @{ Key="ionic";     Name="Ionic CLI";          Desc="Cross-platform mobile framework";    Type="npm"; Cmd="npm install -g @ionic/cli" },
        @{ Key="electron";  Name="Electron Forge";     Desc="Desktop apps with web tech";         Type="npm"; Cmd="npm install -g @electron-forge/cli" },
        @{ Key="tauri";     Name="Tauri CLI";          Desc="Lightweight desktop apps (Rust)";    Type="npm"; Cmd="npm install -g @tauri-apps/cli" },

        # --- Rust Ecosystem ---
        @{ Key="cargo-watch"; Name="cargo-watch";      Desc="Auto-rebuild Rust on file changes";  Type="cargo"; Cmd="cargo install cargo-watch" },
        @{ Key="wasm-pack"; Name="wasm-pack";          Desc="Rust to WebAssembly toolchain";      Type="cargo"; Cmd="cargo install wasm-pack" },

        # --- .NET Ecosystem ---
        @{ Key="blazor";    Name="Blazor (via .NET)";  Desc="C# web UI framework (included in .NET SDK)"; Type="info"; Cmd="" },
        @{ Key="maui";      Name=".NET MAUI";          Desc="Cross-platform .NET UI (install via VS workload)"; Type="info"; Cmd="" },

        # --- DevOps/Infra ---
        @{ Key="terraform";  Name="Terraform";         Desc="Infrastructure as code";             Type="winget"; WinGet="Hashicorp.Terraform"; Choco="terraform" },
        @{ Key="kubectl";    Name="kubectl";           Desc="Kubernetes CLI";                     Type="winget"; WinGet="Kubernetes.kubectl"; Choco="kubernetes-cli" },
        @{ Key="helm";       Name="Helm";              Desc="Kubernetes package manager";         Type="winget"; WinGet="Helm.Helm"; Choco="kubernetes-helm" }
    )
}

# --- Framework installer ----------------------------------------
function Install-Framework($fw) {
    $name = $fw.Name
    Write-Step "Installing $name..."
    try {
        switch ($fw.Type) {
            "npm" {
                if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
                    Write-Fail "$name requires npm (Node.js). Install Node.js first."
                    return
                }
                Invoke-Expression $fw.Cmd 2>&1 | Out-Null
            }
            "pip" {
                if (-not (Get-Command pip -ErrorAction SilentlyContinue) -and -not (Get-Command pip3 -ErrorAction SilentlyContinue)) {
                    Write-Fail "$name requires pip (Python). Install Python first."
                    return
                }
                Invoke-Expression $fw.Cmd 2>&1 | Out-Null
            }
            "cargo" {
                if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
                    Write-Fail "$name requires cargo (Rust). Install Rust first."
                    return
                }
                Invoke-Expression $fw.Cmd 2>&1 | Out-Null
            }
            "winget" {
                Install-Item $fw.WinGet $fw.Choco $name
                return
            }
            "info" {
                Write-Info "$name - $($fw.Desc)"
                return
            }
        }
        if ($LASTEXITCODE -eq 0 -or $?) {
            Write-Success "$name installed."
            $script:InstalledItems += $name
        } else {
            Write-Fail "$name installation may have issues."
            $script:FailedItems += $name
        }
    } catch {
        Write-Fail "Error installing ${name}: $_"
        $script:FailedItems += $name
    }
}

# ================================================================
# PROFILES
# ================================================================
function Show-ProfileMenu {
    Write-SectionHeader "Quick Setup Profiles"
    Write-Host "  [1] Web Developer      - Node.js, Python, PHP, TypeScript + VS Code, Sublime" -ForegroundColor White
    Write-Host "  [2] Mobile Developer   - Java, Kotlin, Dart + Android Studio, VS Code" -ForegroundColor White
    Write-Host "  [3] Data Scientist     - Python, Mojo + VS Code, PyCharm" -ForegroundColor White
    Write-Host "  [4] Systems Programmer - C/C++, Rust, Zig, Go + VS Code, CLion, Neovim" -ForegroundColor White
    Write-Host "  [5] Full Stack .NET    - C#/.NET, Node.js, TypeScript + VS 2026, VS Code" -ForegroundColor White
    Write-Host "  [6] Game Developer     - C/C++, C# + VS 2026, VS Code, Rider" -ForegroundColor White
    Write-Host "  [7] AI / ML Engineer   - Python, Mojo, Rust + VS Code, PyCharm, Cursor" -ForegroundColor White
    Write-Host ""
    Write-Host "  [8] Custom Setup       - Choose your own languages, versions, and IDEs" -ForegroundColor Yellow
    Write-Host "  [9] INSTALL EVERYTHING - All languages, IDEs, tools, frameworks" -ForegroundColor Red
    Write-Host ""
    Write-Host "  You can select multiple profiles separated by spaces (e.g. 1 3 7)" -ForegroundColor DarkGray
    Write-Host ""
    return (Read-Host "  Select profile(s)")
}

# ================================================================
# SPECIAL INSTALLERS
# ================================================================
function Install-WSL {
    Write-Step "Installing WSL 2 with Ubuntu..."
    try {
        wsl --install -d Ubuntu 2>&1 | Out-Null
        Write-Success "WSL 2 (Ubuntu) initiated. Reboot may be required."
        $script:InstalledItems += "WSL 2 (Ubuntu)"
    } catch {
        Write-Fail "Failed to install WSL: $_"
        $script:FailedItems += "WSL 2 (Ubuntu)"
    }
}

function Install-TypeScript {
    Write-Step "Installing TypeScript globally via npm..."
    try {
        npm install -g typescript ts-node 2>&1 | Out-Null
        Write-Success "TypeScript installed globally."
        $script:InstalledItems += "TypeScript"
    } catch {
        Write-Fail "TypeScript install failed. Make sure Node.js is installed first."
        $script:FailedItems += "TypeScript"
    }
}

function Install-Mojo {
    Write-Info "Mojo requires Linux/macOS or WSL on Windows."
    Write-Info "To install in WSL: pip install mojo"
    Write-Info "More info: https://www.modular.com/mojo"
    $script:FailedItems += "Mojo (manual - WSL required)"
}

# ================================================================
# SUMMARY
# ================================================================
function Show-Summary {
    Write-SectionHeader "Installation Summary"

    if ($script:InstalledItems.Count -gt 0) {
        Write-Host "  Successfully installed ($($script:InstalledItems.Count)):" -ForegroundColor Green
        foreach ($item in $script:InstalledItems) { Write-Host "    + $item" -ForegroundColor Green }
    }

    if ($script:FailedItems.Count -gt 0) {
        Write-Host ""
        Write-Host "  Failed / Manual ($($script:FailedItems.Count)):" -ForegroundColor Red
        foreach ($item in $script:FailedItems) { Write-Host "    - $item" -ForegroundColor Red }
    }

    Write-Host ""
    Write-Host "  Total: $($script:InstalledItems.Count) succeeded, $($script:FailedItems.Count) failed" -ForegroundColor Cyan
    Write-Host "  Log: $script:LogFile" -ForegroundColor DarkGray
    Write-Host ""
    if ($script:InstalledItems.Count -gt 0) {
        Write-Host "  WARNING: Restart your terminal/PC for PATH changes." -ForegroundColor Yellow
    }
}

# ================================================================
# MAIN
# ================================================================
function Main {
    Write-Banner
    "CodeReady v2 Install Log - $(Get-Date)" | Set-Content -Path $script:LogFile

    # Admin check
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Fail "Please run as Administrator!"
        return
    }

    # Package managers
    Write-SectionHeader "Package Manager Setup"
    $hasWinGet = Ensure-WinGet
    $hasChoco = Ensure-Chocolatey
    if (-not $hasWinGet -and -not $hasChoco) { Write-Fail "No package manager available."; return }

    # Load definitions
    $langs = Get-Languages
    $ides = Get-IDEs
    $tools = Get-Tools

    # Profile selection
    $profileChoice = Show-ProfileMenu

    $selectedLangs = @()
    $selectedVersions = @{}
    $selectedIDEKeys = @()
    $selectedToolKeys = @()
    $selectedFWKeys = @()

    # Helper to merge profile selections (avoids duplicates)
    function Add-ProfileItems($langList, $ideList, $toolList, $fwList) {
        foreach ($l in $langList)  { if ($selectedLangs    -notcontains $l) { $script:tmpLangs += $l } }
        foreach ($i in $ideList)   { if ($selectedIDEKeys  -notcontains $i) { $script:tmpIDEs  += $i } }
        foreach ($t in $toolList)  { if ($selectedToolKeys -notcontains $t) { $script:tmpTools += $t } }
        foreach ($f in $fwList)    { if ($selectedFWKeys   -notcontains $f) { $script:tmpFWs   += $f } }
    }

    $script:tmpLangs = @(); $script:tmpIDEs = @(); $script:tmpTools = @(); $script:tmpFWs = @()

    # Parse multiple profile choices
    $profileChoices = $profileChoice.Split(" ", [StringSplitOptions]::RemoveEmptyEntries)
    $isCustom = $false
    $isInstallAll = $false

    foreach ($pc in $profileChoices) {
        switch ($pc) {
            "1" { Add-ProfileItems @("nodejs","python","php","typescript") @("vscode","sublime") @("git","docker","postman","nvm") @("yarn","pnpm","vite","react","tailwind","express") }
            "2" { Add-ProfileItems @("java","kotlin","dart") @("android","vscode") @("git") @("reactnative","expo") }
            "3" { Add-ProfileItems @("python","julia","mojo") @("vscode","pycharm") @("git","docker") @("uv","conda","venvstudio","streamlit","fastapi") }
            "4" { Add-ProfileItems @("cpp","rust","zig","go") @("vscode","clion","vim") @("git","cmake") @("cargo-watch","wasm-pack") }
            "5" { Add-ProfileItems @("csharp","nodejs","typescript") @("vs2026","vscode") @("git","docker","postman") @("yarn","vite","react","nextjs") }
            "6" { Add-ProfileItems @("cpp","csharp") @("vs2026","vscode","rider") @("git","cmake") @() }
            "7" { Add-ProfileItems @("python","julia","mojo","rust") @("vscode","pycharm","cursor") @("git","docker") @("uv","conda","venvstudio","streamlit","fastapi") }
            "8" { $isCustom = $true }
            "9" { $isInstallAll = $true }
        }
    }

    if ($isInstallAll) {
        # INSTALL EVERYTHING
        Write-Host ""
        Write-Host "  ============================================================" -ForegroundColor Red
        Write-Host "  WARNING: You are about to install EVERYTHING!" -ForegroundColor Red
        Write-Host "  ============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "  This includes:" -ForegroundColor Yellow
        Write-Host "    - 18 programming languages and runtimes" -ForegroundColor White
        Write-Host "    - 17 IDEs and editors" -ForegroundColor White
        Write-Host "    - 9 developer tools" -ForegroundColor White
        Write-Host "    - 38 frameworks, libraries and package managers" -ForegroundColor White
        Write-Host ""
        Write-Host "  Estimated time: 45-90 minutes (depends on internet speed)" -ForegroundColor Yellow
        Write-Host "  Disk space: approximately 30-50 GB" -ForegroundColor Yellow
        Write-Host "  System load: HIGH - your PC may slow down during install" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  RECOMMENDATION: Close other programs before proceeding." -ForegroundColor Cyan
        Write-Host ""
        $confirmAll = Read-Host "  Type 'YES' (uppercase) to confirm"
        if ($confirmAll -ne "YES") { Write-Info "Cancelled. Good choice - select specific profiles instead!"; return }

        $selectedLangs = $langs | ForEach-Object { $_.Key }
        $selectedIDEKeys = $ides | ForEach-Object { $_.Key }
        $selectedToolKeys = $tools | ForEach-Object { $_.Key }
        $fws = Get-Frameworks
        $selectedFWKeys = $fws | ForEach-Object { $_.Key }
    }
    elseif ($isCustom) {
        # Custom: language selection
        $langNames = $langs | ForEach-Object { "$($_.Name) - $($_.Desc)" }
        $langIdxs = Show-NumberMenu "Select Programming Languages" $langNames
        foreach ($idx in $langIdxs) { $selectedLangs += $langs[$idx].Key }

        # Custom: IDE selection
        $ideNames = $ides | ForEach-Object { "$($_.Name) - $($_.Desc)" }
        $ideIdxs = Show-NumberMenu "Select IDEs and Editors" $ideNames
        foreach ($idx in $ideIdxs) { $selectedIDEKeys += $ides[$idx].Key }

        # Custom: tool selection
        $toolNames = $tools | ForEach-Object { "$($_.Name) - $($_.Desc)" }
        $toolIdxs = Show-NumberMenu "Select Developer Tools" $toolNames
        foreach ($idx in $toolIdxs) { $selectedToolKeys += $tools[$idx].Key }

        # Custom: framework selection
        $fws = Get-Frameworks
        $fwNames = $fws | ForEach-Object { "$($_.Name) - $($_.Desc)" }
        $fwIdxs = Show-NumberMenu "Select Frameworks, Libraries and Package Managers" $fwNames
        foreach ($idx in $fwIdxs) { $selectedFWKeys += $fws[$idx].Key }
    }
    else {
        # Merge collected profile items (deduplicated)
        $selectedLangs = $script:tmpLangs | Select-Object -Unique
        $selectedIDEKeys = $script:tmpIDEs | Select-Object -Unique
        $selectedToolKeys = $script:tmpTools | Select-Object -Unique
        $selectedFWKeys = $script:tmpFWs | Select-Object -Unique

        if ($profileChoices.Count -gt 1) {
            Write-Info "Merged $($profileChoices.Count) profiles - duplicates removed."
        }
    }

    # VERSION SELECTION for each language
    Write-SectionHeader "Version Selection"
    foreach ($langKey in $selectedLangs) {
        $langDef = $langs | Where-Object { $_.Key -eq $langKey }
        if ($langDef -and $langDef.Versions.Count -gt 1) {
            $ver = Show-VersionMenu $langDef.Name $langDef.Versions
            $selectedVersions[$langKey] = $ver
        } elseif ($langDef -and $langDef.Versions.Count -eq 1) {
            $selectedVersions[$langKey] = $langDef.Versions[0]
            Write-Info "$($langDef.Name): $($langDef.Versions[0].Label)"
        }
    }

    # Confirmation
    Write-SectionHeader "Installation Plan"
    Write-Host "  Languages:" -ForegroundColor Cyan
    foreach ($lk in $selectedLangs) {
        $ver = $selectedVersions[$lk]
        if ($ver) { Write-Host "    - $($ver.Label)" }
        else { Write-Host "    - $lk" }
    }
    Write-Host "  IDEs:" -ForegroundColor Cyan
    foreach ($ik in $selectedIDEKeys) {
        $ide = $ides | Where-Object { $_.Key -eq $ik }
        if ($ide) { Write-Host "    - $($ide.Name)" }
    }
    Write-Host "  Tools:" -ForegroundColor Cyan
    foreach ($tk in $selectedToolKeys) {
        $tool = $tools | Where-Object { $_.Key -eq $tk }
        if ($tool) { Write-Host "    - $($tool.Name)" }
    }
    if ($selectedFWKeys.Count -gt 0) {
        $fws = Get-Frameworks
        Write-Host "  Frameworks/Libraries:" -ForegroundColor Cyan
        foreach ($fk in $selectedFWKeys) {
            $fw = $fws | Where-Object { $_.Key -eq $fk }
            if ($fw) { Write-Host "    - $($fw.Name)" }
        }
    }
    Write-Host ""
    $confirm = Read-Host "  Proceed? (Y/n)"
    if ($confirm -eq "n" -or $confirm -eq "N") { Write-Info "Cancelled."; return }

    # INSTALL LANGUAGES
    Write-SectionHeader "Installing Languages and Runtimes"
    foreach ($langKey in $selectedLangs) {
        if ($langKey -eq "typescript") { Install-TypeScript; continue }
        if ($langKey -eq "mojo") { Install-Mojo; continue }

        $ver = $selectedVersions[$langKey]
        if ($ver) {
            Install-Item $ver.WinGet $ver.Choco $ver.Label
        }
    }

    # INSTALL IDEs
    Write-SectionHeader "Installing IDEs and Editors"
    foreach ($ideKey in $selectedIDEKeys) {
        $ide = $ides | Where-Object { $_.Key -eq $ideKey }
        if ($ide) { Install-Item $ide.WinGet $ide.Choco $ide.Name }
    }

    # INSTALL TOOLS
    Write-SectionHeader "Installing Developer Tools"
    foreach ($toolKey in $selectedToolKeys) {
        if ($toolKey -eq "wsl") { Install-WSL; continue }
        $tool = $tools | Where-Object { $_.Key -eq $toolKey }
        if ($tool) { Install-Item $tool.WinGet $tool.Choco $tool.Name }
    }

    # INSTALL FRAMEWORKS
    if ($selectedFWKeys.Count -gt 0) {
        Write-SectionHeader "Installing Frameworks, Libraries and Package Managers"
        $fws = Get-Frameworks
        foreach ($fwKey in $selectedFWKeys) {
            $fw = $fws | Where-Object { $_.Key -eq $fwKey }
            if ($fw) { Install-Framework $fw }
        }
    }

    # Refresh PATH
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Show-Summary
}

Main
