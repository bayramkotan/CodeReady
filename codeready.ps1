#Requires -RunAsAdministrator
# ================================================================
# CodeReady v2.1.0
# Developer Environment Setup Tool (Windows)
# https://github.com/bayramkotan/CodeReady
# ================================================================

$ErrorActionPreference = "Continue"
$script:Version = "2.1.0"
$script:LogFile = "$env:USERPROFILE\codeready_install.log"
$script:InstalledItems = @()
$script:FailedItems = @()

# --- Colors and UI ----------------------------------------------
function Write-Banner {
    Clear-Host
    $banner = @"

   ####  #####  ####  ###### ####  ###### #####  ####  #   #
  #      #   #  #   # #      #   # #      #   #  #   #  # #
  #      #   #  #   # ####   ####  ####   #####  #   #   #
  #      #   #  #   # #      #  #  #      #   #  #   #   #
   ####  #####  ####  ###### #   # ###### #   #  ####    #
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

function Ensure-Scoop {
    Write-Step "Checking Scoop..."
    if (Get-Command scoop -ErrorAction SilentlyContinue) {
        Write-Success "Scoop is already installed."
        return $true
    }
    Write-Step "Installing Scoop..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri "https://get.scoop.sh" | Invoke-Expression
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","User") + ";" + [System.Environment]::GetEnvironmentVariable("Path","Machine")
        Write-Success "Scoop installed."
        return $true
    } catch {
        Write-Fail "Could not install Scoop: $_"
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

function Install-WithScoop($pkg, $name) {
    Write-Step "Installing $name via Scoop..."
    try {
        scoop install $pkg 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Success "$name installed via Scoop."
            $script:InstalledItems += $name
            return $true
        } else {
            return $false
        }
    } catch {
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

function Install-Item($wingetId, $chocoId, $name, $scoopId) {
    # Priority: winget > scoop > chocolatey
    if ($wingetId -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        return Install-WithWinGet $wingetId $name
    }
    elseif ($scoopId -and (Get-Command scoop -ErrorAction SilentlyContinue)) {
        return Install-WithScoop $scoopId $name
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
        },
        @{ Key="r"; Name="R"; Desc="Statistics, data science, bioinformatics"
            Versions=@( @{ Label="R (latest)"; WinGet="RProject.R"; Choco="r.project" } ) },
        @{ Key="lua"; Name="Lua"; Desc="Scripting, game engines, embedded"
            Versions=@( @{ Label="Lua (latest)"; WinGet=""; Choco="lua" } ) },
        @{ Key="haskell"; Name="Haskell"; Desc="Pure functional, fintech, academic"
            Versions=@( @{ Label="Haskell (GHCup)"; WinGet=""; Choco="ghc" } ) },
        @{ Key="perl"; Name="Perl"; Desc="Text processing, sysadmin, bioinformatics"
            Versions=@( @{ Label="Perl (latest)"; WinGet="StrawberryPerl.StrawberryPerl"; Choco="strawberryperl" } ) },
        @{ Key="erlang"; Name="Erlang"; Desc="Telecom, distributed, fault-tolerant"
            Versions=@( @{ Label="Erlang (latest)"; WinGet="Ericsson.ErlangOTP"; Choco="erlang" } ) },
        @{ Key="ocaml"; Name="OCaml"; Desc="Fintech, compilers, formal verification"
            Versions=@( @{ Label="OCaml (latest)"; WinGet=""; Choco="ocaml" } ) },
        @{ Key="fortran"; Name="Fortran"; Desc="Scientific computing, HPC, physics"
            Versions=@( @{ Label="GFortran (via MinGW)"; WinGet=""; Choco="mingw" } ) },
        @{ Key="d"; Name="D"; Desc="Systems programming, C++ alternative"
            Versions=@( @{ Label="D (LDC latest)"; WinGet="ldc-developers.LDC"; Choco="ldc" } ) },
        @{ Key="nim"; Name="Nim"; Desc="Python-like syntax, compiles to C"
            Versions=@( @{ Label="Nim (latest)"; WinGet=""; Choco="nim" } ) },
        @{ Key="crystal"; Name="Crystal"; Desc="Ruby-like, compiled, fast"
            Versions=@( @{ Label="Crystal (latest)"; WinGet=""; Choco="crystal" } ) },
        @{ Key="v"; Name="V"; Desc="Simple systems language (vlang)"
            Versions=@( @{ Label="V (latest)"; WinGet=""; Choco="vlang" } ) },
        @{ Key="gleam"; Name="Gleam"; Desc="Type-safe BEAM language"
            Versions=@( @{ Label="Gleam (latest)"; WinGet=""; Choco="gleam" } ) },
        @{ Key="carbon"; Name="Carbon"; Desc="Experimental C++ successor by Google"
            Versions=@( @{ Label="Carbon (experimental)"; WinGet=""; Choco="" } ) },
        @{ Key="solidity"; Name="Solidity"; Desc="Ethereum smart contract language"
            Versions=@( @{ Label="Solidity (solcjs via npm)"; WinGet=""; Choco="" } ) },
        @{ Key="groovy"; Name="Groovy"; Desc="JVM scripting, Gradle builds"
            Versions=@( @{ Label="Groovy (latest)"; WinGet=""; Choco="groovy" } ) },
        @{ Key="ada"; Name="Ada"; Desc="Safety-critical, aerospace, defense"
            Versions=@( @{ Label="Ada (GNAT)"; WinGet="AdaCore.GNAT"; Choco="gnat" } ) },
        @{ Key="cobol"; Name="COBOL"; Desc="Banking, legacy enterprise systems"
            Versions=@( @{ Label="GnuCOBOL (latest)"; WinGet=""; Choco="gnucobol" } ) },
        @{ Key="lisp"; Name="Common Lisp"; Desc="AI, macros, symbolic computation"
            Versions=@( @{ Label="SBCL (latest)"; WinGet=""; Choco="sbcl" } ) },
        @{ Key="racket"; Name="Racket"; Desc="PL research, education, DSLs"
            Versions=@( @{ Label="Racket (latest)"; WinGet="Racket.Racket"; Choco="racket" } ) },
        @{ Key="objc"; Name="Objective-C"; Desc="Legacy Apple development"
            Versions=@( @{ Label="Obj-C (via MSVC/Clang)"; WinGet=""; Choco="" } ) }
    )
}

# ================================================================
# IDE DEFINITIONS (always latest version)
# ================================================================
function Get-IDEs {
    return @(
        @{ Key="vscode";      Name="VS Code";                    Desc="Lightweight, extensible, multi-language";    WinGet="Microsoft.VisualStudioCode";              Choco="vscode" },
        @{ Key="vscodium";    Name="VSCodium";                   Desc="VS Code without telemetry";                  WinGet="VSCodium.VSCodium";                       Choco="vscodium" },
        @{ Key="antigravity"; Name="Antigravity";                Desc="AI-native code editor";                      WinGet="";                                        Choco="" },
        @{ Key="cursor";      Name="Cursor";                     Desc="AI-powered code editor";                     WinGet="Anysphere.Cursor";                        Choco="" },
        @{ Key="zed";         Name="Zed";                        Desc="High-performance editor written in Rust";    WinGet="Zed.Zed";                                 Choco="" },
        @{ Key="windsurf";    Name="Windsurf";                   Desc="AI-powered IDE by Codeium";                  WinGet="Codeium.Windsurf";                        Choco="" },
        @{ Key="vs2026";      Name="Visual Studio Community";    Desc="Full-featured IDE for .NET, C++";            WinGet="Microsoft.VisualStudio.2026.Community";   Choco="visualstudio2026community" },
        @{ Key="sublime";     Name="Sublime Text";               Desc="Fast, lightweight code editor";              WinGet="SublimeHQ.SublimeText.4";                 Choco="sublimetext4" },
        @{ Key="classicvim";  Name="Vim";                        Desc="Classic terminal text editor";               WinGet="vim.vim";                                 Choco="vim" },
        @{ Key="vim";         Name="Neovim";                     Desc="Modern terminal editor";                     WinGet="Neovim.Neovim";                           Choco="neovim" },
        @{ Key="emacs";       Name="GNU Emacs";                  Desc="Extensible, customizable text editor";       WinGet="GNU.Emacs";                               Choco="emacs" },
        @{ Key="notepadpp";   Name="Notepad++";                  Desc="Lightweight Windows code editor";            WinGet="Notepad++.Notepad++";                     Choco="notepadplusplus" },
        @{ Key="intellij";    Name="IntelliJ IDEA Community";    Desc="Java, Kotlin, JVM languages";               WinGet="JetBrains.IntelliJIDEA.Community";        Choco="intellijidea-community" },
        @{ Key="pycharm";     Name="PyCharm Community";          Desc="Python IDE with debugging and testing";      WinGet="JetBrains.PyCharm.Community";             Choco="pycharm-community" },
        @{ Key="webstorm";    Name="WebStorm";                   Desc="JavaScript/TypeScript IDE (paid)";           WinGet="JetBrains.WebStorm";                      Choco="webstorm" },
        @{ Key="goland";      Name="GoLand";                     Desc="Go IDE by JetBrains (paid)";                 WinGet="JetBrains.GoLand";                        Choco="goland" },
        @{ Key="clion";       Name="CLion";                      Desc="C/C++ IDE by JetBrains (paid)";             WinGet="JetBrains.CLion";                         Choco="clion" },
        @{ Key="rider";       Name="Rider";                      Desc=".NET IDE by JetBrains (paid)";              WinGet="JetBrains.Rider";                         Choco="jetbrains-rider" },
        @{ Key="rustrover";   Name="RustRover";                  Desc="Rust IDE by JetBrains";                      WinGet="JetBrains.RustRover";                     Choco="rustrover" },
        @{ Key="fleet";       Name="JetBrains Fleet";            Desc="Lightweight multi-language IDE";             WinGet="JetBrains.Fleet";                         Choco="" },
        @{ Key="eclipse";     Name="Eclipse IDE";                Desc="Java, C/C++, PHP, multi-language";          WinGet="EclipseFoundation.EclipseIDE";            Choco="eclipse" },
        @{ Key="netbeans";    Name="Apache NetBeans";            Desc="Java, PHP, HTML5 IDE";                       WinGet="Apache.NetBeans";                         Choco="netbeans" },
        @{ Key="android";     Name="Android Studio";             Desc="Official Android development IDE";           WinGet="Google.AndroidStudio";                    Choco="androidstudio" }
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
        @{ Key="venvstudio"; Name="VenvStudio";        Desc="GUI virtual environment manager (PySide6) by bayramkotan"; Type="pip"; Cmd="pip install VenvStudio --break-system-packages 2>$null; pip install VenvStudio" },
        @{ Key="uv";        Name="uv";                 Desc="Ultra-fast Python package manager (Rust)"; Type="pip"; Cmd="pip install uv --break-system-packages 2>$null; pip install uv" },
        @{ Key="poetry";    Name="Poetry";             Desc="Python dependency management";       Type="pip"; Cmd="pip install poetry --break-system-packages 2>$null; pip install poetry" },
        @{ Key="pipx";      Name="pipx";               Desc="Install Python CLI tools in isolation"; Type="pip"; Cmd="pip install pipx --break-system-packages 2>$null; pip install pipx" },
        @{ Key="conda";     Name="Miniconda";          Desc="Python/R data science pkg manager";  Type="winget"; WinGet="Anaconda.Miniconda3"; Choco="miniconda3" },

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
    Write-Host ""
    Write-Host "  --- Popular Stacks ---" -ForegroundColor Cyan
    Write-Host "  [1]  Web Frontend        - Node.js, TypeScript + VS Code, Zed + React, Vue, Tailwind" -ForegroundColor White
    Write-Host "  [2]  Web Full Stack       - Node.js, Python, TypeScript + VS Code + React, Next.js, Django" -ForegroundColor White
    Write-Host "  [3]  Mobile Developer     - Java, Kotlin, Dart/Flutter, Swift + Android Studio, VS Code" -ForegroundColor White
    Write-Host "  [4]  Data Scientist       - Python, R, Julia + VS Code, PyCharm + VenvStudio, uv, Conda" -ForegroundColor White
    Write-Host "  [5]  AI / ML Engineer     - Python, Mojo, Rust, Julia + VS Code, PyCharm, Cursor" -ForegroundColor White
    Write-Host "  [6]  Systems Programmer   - C/C++, Rust, Zig, Go + VS Code, CLion, Neovim + CMake" -ForegroundColor White
    Write-Host "  [7]  Full Stack .NET      - C#/.NET, Node.js, TypeScript + VS 2026, VS Code + React, Next.js" -ForegroundColor White
    Write-Host "  [8]  Game Developer       - C/C++, C#, Lua + VS 2026, VS Code, Rider + CMake" -ForegroundColor White
    Write-Host ""
    Write-Host "  --- Specialized ---" -ForegroundColor Cyan
    Write-Host "  [9]  DevOps / Cloud       - Python, Go, Rust + VS Code, Neovim + Docker, Terraform, kubectl" -ForegroundColor White
    Write-Host "  [10] Blockchain / Web3    - Solidity, Rust, TypeScript + VS Code, Cursor + npm" -ForegroundColor White
    Write-Host "  [11] Embedded / IoT       - C/C++, Rust, Python, Lua + VS Code, CLion, Neovim + CMake" -ForegroundColor White
    Write-Host "  [12] Scientific Computing - Fortran, Python, R, Julia, Haskell + VS Code, Emacs" -ForegroundColor White
    Write-Host "  [13] Functional Prog.     - Haskell, Elixir, Erlang, OCaml, Scala, Gleam + VS Code, Emacs" -ForegroundColor White
    Write-Host "  [14] JVM Ecosystem        - Java, Kotlin, Scala, Groovy + IntelliJ, Eclipse, NetBeans" -ForegroundColor White
    Write-Host "  [15] Minimalist / Terminal - Go, Rust, Python + Neovim, Vim, Emacs + Git only" -ForegroundColor White
    Write-Host ""
    Write-Host "  [16] Custom Setup         - Choose your own languages, versions, and IDEs" -ForegroundColor Yellow
    Write-Host "  [17] INSTALL EVERYTHING   - All languages, IDEs, tools, frameworks" -ForegroundColor Red
    Write-Host ""
    Write-Host "  You can select multiple profiles separated by spaces (e.g. 1 5 9)" -ForegroundColor DarkGray
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
# SYSTEM SCAN - Auto-detect installed software and versions
# ================================================================
function Get-CmdVersion($cmd, $flag) {
    if (-not $flag) { $flag = "--version" }
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) { return "" }
    # Only run --version on safe CLI tools (no GUI, no interactive shell)
    $safeCmds = @("python","node","java","dotnet","gcc","go","rustc","php","ruby","dart","zig","tsc","nim","crystal","gleam","gfortran","ldc2","cobc","gnat","sbcl","git","docker","cmake","gh","npm","yarn","pnpm","bun","uv","poetry","conda","terraform","code","codium","nvim","vim","subl","emacs","perl","ghc","ocaml","racket","lua","julia","groovy","mojo","solcjs","wasmtime","wasmer")
    if ($safeCmds -notcontains $cmd) { return "found" }
    try {
        $out = & $cmd $flag 2>&1 | Select-Object -First 3
        foreach ($line in $out) {
            $s = "$line"
            if ($s -match '(\d+\.\d+[\.\d]*)') { return $Matches[1] }
        }
        return "found"
    } catch { return "found" }
}

function Show-ScanItem($name, $current, $recommended) {
    $padded = $name.PadRight(16)
    if ([string]::IsNullOrEmpty($current)) {
        Write-Host "    $padded  " -NoNewline -ForegroundColor DarkGray
        Write-Host "- not installed" -ForegroundColor DarkGray
    }
    elseif ($current -eq "found" -or $current -eq "installed") {
        Write-Host "    $padded  " -NoNewline -ForegroundColor Green
        Write-Host "yes" -ForegroundColor Green
    }
    elseif ($recommended -eq "latest" -or $recommended -eq "-") {
        Write-Host "    $padded  " -NoNewline -ForegroundColor Green
        Write-Host "$current" -ForegroundColor Green
    }
    elseif ($current.StartsWith($recommended)) {
        Write-Host "    $padded  " -NoNewline -ForegroundColor Green
        Write-Host "$current  up to date" -ForegroundColor Green
    }
    else {
        Write-Host "    $padded  " -NoNewline -ForegroundColor Yellow
        Write-Host "$current" -NoNewline -ForegroundColor Yellow
        Write-Host "  >> $recommended available" -ForegroundColor Cyan
    }
}

function Start-SystemScan {
    Write-SectionHeader "System Scan"
    Write-Host "  Scanning your system for installed software..." -ForegroundColor DarkGray
    Write-Host ""

    # Languages
    $py = Get-CmdVersion "python" "--version"
    $node = Get-CmdVersion "node" "-v"
    if ($node) { $node = $node -replace '^v','' }
    $java = Get-CmdVersion "java" "-version"
    $dotnet = Get-CmdVersion "dotnet" "--version"
    $gcc = Get-CmdVersion "gcc" "--version"
    $goVer = Get-CmdVersion "go" "version"
    $rust = Get-CmdVersion "rustc" "--version"
    $php = Get-CmdVersion "php" "--version"
    $ruby = Get-CmdVersion "ruby" "--version"
    $kotlin = Get-CmdVersion "kotlin" "-version"
    $dart = Get-CmdVersion "dart" "--version"
    $zig = Get-CmdVersion "zig" "version"
    $ts = Get-CmdVersion "tsc" "--version"
    $swift = Get-CmdVersion "swift" "--version"
    $mojo = Get-CmdVersion "mojo" "--version"
    $flutter = Get-CmdVersion "flutter" "--version"
    $wasmtime = Get-CmdVersion "wasmtime" "--version"
    $wasmer = Get-CmdVersion "wasmer" "--version"
    $elixir = Get-CmdVersion "elixir" "--version"
    $scalaVer = Get-CmdVersion "scala" "-version"
    $juliaVer = Get-CmdVersion "julia" "--version"
    $rVer = Get-CmdVersion "R" "--version"
    $luaVer = Get-CmdVersion "lua" "-v"
    $ghcVer = Get-CmdVersion "ghc" "--version"
    $perlVer = Get-CmdVersion "perl" "--version"
    $erlVer = if (Get-Command erl -ErrorAction SilentlyContinue) { "found" } else { "" }
    $ocamlVer = Get-CmdVersion "ocaml" "--version"
    $gfortranVer = Get-CmdVersion "gfortran" "--version"
    $ldcVer = Get-CmdVersion "ldc2" "--version"
    $nimVer = Get-CmdVersion "nim" "--version"
    $crystalVer = Get-CmdVersion "crystal" "--version"
    $vlangVer = Get-CmdVersion "v" "--version"
    $gleamVer = Get-CmdVersion "gleam" "--version"
    $solcVer = Get-CmdVersion "solcjs" "--version"
    $groovyVer = Get-CmdVersion "groovy" "--version"
    $gnatVer = Get-CmdVersion "gnat" "--version"
    $cobcVer = Get-CmdVersion "cobc" "--version"
    $sbclVer = Get-CmdVersion "sbcl" "--version"
    $racketVer = Get-CmdVersion "racket" "--version"

    # IDEs
    $code = Get-CmdVersion "code" "--version"
    $codium = Get-CmdVersion "codium" "--version"
    $nvim = Get-CmdVersion "nvim" "--version"
    $vimExe = Get-CmdVersion "vim" "--version"
    $cursorExe = if (Get-Command cursor -ErrorAction SilentlyContinue) { "found" } else { "" }
    $sublExe = Get-CmdVersion "subl" "--version"
    $emacsVer = Get-CmdVersion "emacs" "--version"
    $zedExe = if (Get-Command zed -ErrorAction SilentlyContinue) { "found" } else { "" }
    $windsurfExe = if (Get-Command windsurf -ErrorAction SilentlyContinue) { "found" } else { "" }
    $antigravExe = if (Get-Command antigravity -ErrorAction SilentlyContinue) { "found" } else { "" }
    $fleetExe = if (Get-Command fleet -ErrorAction SilentlyContinue) { "found" } else { "" }

    # JetBrains IDEs -- NEVER run --version (launches GUI and hangs!)
    # Only check file paths
    $ideaExe = if ((Get-ChildItem "${env:ProgramFiles}\JetBrains\IntelliJ IDEA*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\Programs\IntelliJ IDEA*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\JetBrains\Toolbox\apps\IDEA*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $pycharmExe = if ((Get-ChildItem "${env:ProgramFiles}\JetBrains\PyCharm*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\Programs\PyCharm*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\JetBrains\Toolbox\apps\PyCharm*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $webstormExe = if ((Get-ChildItem "${env:ProgramFiles}\JetBrains\WebStorm*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\JetBrains\Toolbox\apps\WebStorm*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $golandExe = if ((Get-ChildItem "${env:ProgramFiles}\JetBrains\GoLand*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\JetBrains\Toolbox\apps\GoLand*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $clionExe = if ((Get-ChildItem "${env:ProgramFiles}\JetBrains\CLion*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\JetBrains\Toolbox\apps\CLion*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $riderExe = if ((Get-ChildItem "${env:ProgramFiles}\JetBrains\Rider*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\JetBrains\Toolbox\apps\Rider*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $rustroverExe = if ((Get-ChildItem "${env:ProgramFiles}\JetBrains\RustRover*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:LOCALAPPDATA}\JetBrains\Toolbox\apps\RustRover*" -ErrorAction SilentlyContinue)) { "found" } else { "" }

    # Other GUI IDEs -- file path only
    $eclipseExe = if ((Test-Path "${env:ProgramFiles}\Eclipse\eclipse.exe") -or (Test-Path "C:\Eclipse\eclipse.exe") -or (Get-ChildItem "${env:LOCALAPPDATA}\Programs\Eclipse*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $netbeansExe = if ((Get-ChildItem "${env:ProgramFiles}\NetBeans*" -ErrorAction SilentlyContinue) -or (Get-ChildItem "${env:ProgramFiles}\Apache\NetBeans*" -ErrorAction SilentlyContinue)) { "found" } else { "" }
    $androidExe = if ((Test-Path "${env:ProgramFiles}\Android\Android Studio\bin\studio64.exe") -or (Test-Path "${env:LOCALAPPDATA}\Programs\Android Studio\bin\studio64.exe")) { "found" } else { "" }
    $notepadppExe = if ((Test-Path "${env:ProgramFiles}\Notepad++\notepad++.exe") -or (Test-Path "${env:ProgramFiles(x86)}\Notepad++\notepad++.exe")) { "found" } else { "" }

    # Tools
    $git = Get-CmdVersion "git" "--version"
    $docker = Get-CmdVersion "docker" "--version"
    $cmake = Get-CmdVersion "cmake" "--version"
    $gh = Get-CmdVersion "gh" "--version"

    # Package managers
    $npm = Get-CmdVersion "npm" "--version"
    $yarn = Get-CmdVersion "yarn" "--version"
    $pnpm = Get-CmdVersion "pnpm" "--version"
    $bun = Get-CmdVersion "bun" "--version"
    $uv = Get-CmdVersion "uv" "--version"
    $poetry = Get-CmdVersion "poetry" "--version"
    $condaVer = Get-CmdVersion "conda" "--version"
    $terraform = Get-CmdVersion "terraform" "--version"
    $kubectl = Get-CmdVersion "kubectl" "version --client"
    $helm = Get-CmdVersion "helm" "version --short"

    Write-Host "  Languages and Runtimes:" -ForegroundColor Cyan
    Show-ScanItem "Python"     $py     "latest"
    Show-ScanItem "Node.js"    $node   "latest"
    Show-ScanItem "Java (JDK)" $java   "latest"
    Show-ScanItem ".NET SDK"   $dotnet "latest"
    Show-ScanItem "C/C++ (GCC)" $gcc   "-"
    Show-ScanItem "Go"         $goVer  "latest"
    Show-ScanItem "Rust"       $rust   "latest"
    Show-ScanItem "PHP"        $php    "latest"
    Show-ScanItem "Ruby"       $ruby   "latest"
    Show-ScanItem "Kotlin"     $kotlin "latest"
    Show-ScanItem "Dart"       $dart   "latest"
    Show-ScanItem "Swift"      $swift  "latest"
    Show-ScanItem "Zig"        $zig    "latest"
    Show-ScanItem "Mojo"       $mojo   "latest"
    Show-ScanItem "TypeScript" $ts     "latest"
    Show-ScanItem "Elixir"     $elixir "latest"
    Show-ScanItem "Scala"      $scalaVer "latest"
    Show-ScanItem "Julia"      $juliaVer "latest"
    $wasmLabel = ""
    if ($wasmtime) { $wasmLabel = "wasmtime $wasmtime" }
    if ($wasmer) { if ($wasmLabel) { $wasmLabel += ", " }; $wasmLabel += "wasmer $wasmer" }
    Show-ScanItem "WebAssembly" $wasmLabel "latest"
    Show-ScanItem "Flutter"    $flutter "latest"
    Show-ScanItem "R"          $rVer    "latest"
    Show-ScanItem "Lua"        $luaVer  "latest"
    Show-ScanItem "Haskell"    $ghcVer  "latest"
    Show-ScanItem "Perl"       $perlVer "latest"
    Show-ScanItem "Erlang"     $erlVer  "latest"
    Show-ScanItem "OCaml"      $ocamlVer "latest"
    Show-ScanItem "Fortran"    $gfortranVer "latest"
    Show-ScanItem "D (LDC)"    $ldcVer  "latest"
    Show-ScanItem "Nim"        $nimVer  "latest"
    Show-ScanItem "Crystal"    $crystalVer "latest"
    Show-ScanItem "V"          $vlangVer "latest"
    Show-ScanItem "Gleam"      $gleamVer "latest"
    Show-ScanItem "Solidity"   $solcVer  "latest"
    Show-ScanItem "Groovy"     $groovyVer "latest"
    Show-ScanItem "Ada (GNAT)" $gnatVer "latest"
    Show-ScanItem "COBOL"      $cobcVer "latest"
    Show-ScanItem "Lisp (SBCL)" $sbclVer "latest"
    Show-ScanItem "Racket"     $racketVer "latest"
    Write-Host ""

    Write-Host "  IDEs and Editors:" -ForegroundColor Cyan
    Show-ScanItem "VS Code"      $code         "latest"
    Show-ScanItem "VSCodium"     $codium       "latest"
    Show-ScanItem "Antigravity"  $antigravExe  "latest"
    Show-ScanItem "Cursor"       $cursorExe    "latest"
    Show-ScanItem "Zed"          $zedExe       "latest"
    Show-ScanItem "Windsurf"     $windsurfExe  "latest"
    Show-ScanItem "Sublime"      $sublExe      "latest"
    Show-ScanItem "Vim"          $vimExe       "latest"
    Show-ScanItem "Neovim"       $nvim         "latest"
    Show-ScanItem "GNU Emacs"    $emacsVer     "latest"
    Show-ScanItem "IntelliJ"     $ideaExe      "latest"
    Show-ScanItem "PyCharm"      $pycharmExe   "latest"
    Show-ScanItem "WebStorm"     $webstormExe  "latest"
    Show-ScanItem "GoLand"       $golandExe    "latest"
    Show-ScanItem "CLion"        $clionExe     "latest"
    Show-ScanItem "Rider"        $riderExe     "latest"
    Show-ScanItem "RustRover"    $rustroverExe "latest"
    Show-ScanItem "Fleet"        $fleetExe     "latest"
    Show-ScanItem "Eclipse"      $eclipseExe   "latest"
    Show-ScanItem "NetBeans"     $netbeansExe  "latest"
    Show-ScanItem "Android St."  $androidExe   "latest"
    Show-ScanItem "Notepad++"    $notepadppExe "latest"
    Write-Host ""

    Write-Host "  Developer Tools:" -ForegroundColor Cyan
    Show-ScanItem "Git"        $git    "latest"
    Show-ScanItem "Docker"     $docker "latest"
    Show-ScanItem "CMake"      $cmake  "latest"
    Show-ScanItem "GitHub CLI" $gh     "latest"
    Write-Host ""

    Write-Host "  Package Managers:" -ForegroundColor Cyan
    Show-ScanItem "npm"        $npm        "latest"
    Show-ScanItem "Yarn"       $yarn       "latest"
    Show-ScanItem "pnpm"       $pnpm       "latest"
    Show-ScanItem "Bun"        $bun        "latest"
    Show-ScanItem "uv"         $uv         "latest"
    Show-ScanItem "Poetry"     $poetry     "latest"
    Show-ScanItem "Conda"      $condaVer   "latest"
    Show-ScanItem "Terraform"  $terraform  "latest"
    Show-ScanItem "kubectl"    $kubectl    "latest"
    Show-ScanItem "Helm"       $helm       "latest"
    Write-Host ""

    Write-Host "  ----------------------------------------" -ForegroundColor DarkGray
    $instCount = @($py,$node,$java,$dotnet,$gcc,$goVer,$rust,$php,$ruby,$git,$docker,$code,$npm) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
    $missCount = 13 - $instCount
    Write-Host "  " -NoNewline
    Write-Host "$instCount installed" -NoNewline -ForegroundColor Green
    Write-Host "  |  " -NoNewline -ForegroundColor DarkGray
    Write-Host "$missCount not found" -ForegroundColor DarkGray
    Write-Host ""

    $scanChoice = Read-Host "  Continue to profile selection? (Y/n)"
    if ($scanChoice -eq "n" -or $scanChoice -eq "N") { Write-Info "Exited."; return $false }
    return $true
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
    $hasScoop = Ensure-Scoop
    $hasChoco = Ensure-Chocolatey
    if (-not $hasWinGet -and -not $hasScoop -and -not $hasChoco) { Write-Fail "No package manager available."; return }

    # System scan - show what's installed
    $scanResult = Start-SystemScan
    if ($scanResult -eq $false) { return }

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
            "1" { Add-ProfileItems @("nodejs","typescript") @("vscode","zed") @("git") @("yarn","pnpm","vite","react","vue","tailwind") }
            "2" { Add-ProfileItems @("nodejs","python","typescript","php") @("vscode","sublime") @("git","docker","postman","nvm") @("yarn","pnpm","vite","react","nextjs","express","django","tailwind") }
            "3" { Add-ProfileItems @("java","kotlin","dart","swift") @("android","vscode") @("git") @("reactnative","expo") }
            "4" { Add-ProfileItems @("python","r","julia") @("vscode","pycharm") @("git","docker") @("venvstudio","uv","conda","streamlit","fastapi") }
            "5" { Add-ProfileItems @("python","mojo","rust","julia") @("vscode","pycharm","cursor") @("git","docker") @("venvstudio","uv","conda","streamlit","fastapi") }
            "6" { Add-ProfileItems @("cpp","rust","zig","go") @("vscode","clion","vim") @("git","cmake") @("cargo-watch","wasm-pack") }
            "7" { Add-ProfileItems @("csharp","nodejs","typescript") @("vs2026","vscode","rider") @("git","docker","postman") @("yarn","vite","react","nextjs","blazor") }
            "8" { Add-ProfileItems @("cpp","csharp","lua") @("vs2026","vscode","rider") @("git","cmake") @() }
            "9" { Add-ProfileItems @("python","go","rust") @("vscode","vim") @("git","docker") @("terraform","kubectl","helm") }
            "10" { Add-ProfileItems @("solidity","rust","typescript","nodejs") @("vscode","cursor") @("git") @("npm","yarn") }
            "11" { Add-ProfileItems @("cpp","rust","python","lua") @("vscode","clion","vim") @("git","cmake") @() }
            "12" { Add-ProfileItems @("fortran","python","r","julia","haskell") @("vscode","emacs") @("git") @("venvstudio","uv","conda") }
            "13" { Add-ProfileItems @("haskell","elixir","erlang","ocaml","scala","gleam") @("vscode","emacs","vim") @("git") @() }
            "14" { Add-ProfileItems @("java","kotlin","scala","groovy") @("intellij","eclipse","netbeans") @("git","docker") @() }
            "15" { Add-ProfileItems @("go","rust","python") @("vim","classicvim","emacs") @("git") @() }
            "16" { $isCustom = $true }
            "17" { $isInstallAll = $true }
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
        Write-Host "    - 39 programming languages and runtimes" -ForegroundColor White
        Write-Host "    - 23 IDEs and editors" -ForegroundColor White
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
