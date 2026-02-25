#Requires -RunAsAdministrator
# ================================================================
# CodeReady v1.0.0
# Developer Environment Setup Tool (Windows)
# ================================================================

param(
    [switch]$Silent,
    [string]$ConfigFile
)

$ErrorActionPreference = "Continue"
$script:Version = "1.0.0"
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

function Write-Step($msg) {
    Write-Host "  [>] " -NoNewline -ForegroundColor Yellow
    Write-Host $msg
}

function Write-Success($msg) {
    Write-Host "  [+] " -NoNewline -ForegroundColor Green
    Write-Host $msg
    $logMsg = "[OK] " + $msg
    Add-Content -Path $script:LogFile -Value $logMsg
}

function Write-Fail($msg) {
    Write-Host "  [-] " -NoNewline -ForegroundColor Red
    Write-Host $msg
    $logMsg = "[FAIL] " + $msg
    Add-Content -Path $script:LogFile -Value $logMsg
}

function Write-Info($msg) {
    Write-Host "  [i] " -NoNewline -ForegroundColor DarkCyan
    Write-Host $msg -ForegroundColor Gray
}

function Write-SectionHeader($title) {
    Write-Host ""
    Write-Host "  === $title ===" -ForegroundColor DarkYellow
    Write-Host ""
}

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
        $chocoUrl = "https://community.chocolatey.org/install.ps1"
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($chocoUrl))
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        Write-Success "Chocolatey installed."
        return $true
    } catch {
        Write-Fail "Could not install Chocolatey: $_"
        return $false
    }
}

# --- Installation Functions -------------------------------------
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
        Write-Fail "Error installing $name : $_"
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
        Write-Fail "Error installing $name : $_"
        $script:FailedItems += $name
        return $false
    }
}

# --- Menu System ------------------------------------------------
function Show-MultiSelectMenu($title, $items) {
    Write-SectionHeader $title
    $selected = @{}
    foreach ($key in $items.Keys) { $selected[$key] = $false }
    $keys = @($items.Keys | Sort-Object)
    $currentIndex = 0
    $selectAllToggle = $false

    Write-Info "Use UP/DOWN arrows to navigate, SPACE to toggle, A to toggle all, ENTER to confirm"
    Write-Host ""

    $startLine = [Console]::CursorTop

    for ($i = 0; $i -lt $keys.Count; $i++) {
        $key = $keys[$i]
        $mark = "[ ]"
        if ($selected[$key]) { $mark = "[X]" }
        $pointer = "  "
        if ($i -eq $currentIndex) { $pointer = " >" }
        $color = "White"
        if ($i -eq $currentIndex) { $color = "Yellow" }
        Write-Host "$pointer $mark $($items[$key].Name) " -ForegroundColor $color -NoNewline
        Write-Host "- $($items[$key].Desc)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Write-Host "  [SPACE=Toggle] [A=All] [ENTER=Confirm]" -ForegroundColor DarkGray

    while ($true) {
        $keyPress = [Console]::ReadKey($true)

        switch ($keyPress.Key) {
            "UpArrow" {
                $currentIndex = if ($currentIndex -gt 0) { $currentIndex - 1 } else { $keys.Count - 1 }
            }
            "DownArrow" {
                $currentIndex = if ($currentIndex -lt $keys.Count - 1) { $currentIndex + 1 } else { 0 }
            }
            "Spacebar" {
                $key = $keys[$currentIndex]
                $selected[$key] = -not $selected[$key]
            }
            "A" {
                $selectAllToggle = -not $selectAllToggle
                foreach ($key in $keys) { $selected[$key] = $selectAllToggle }
            }
            "Enter" {
                $result = @()
                foreach ($key in $keys) {
                    if ($selected[$key]) { $result += $key }
                }
                Write-Host ""
                return $result
            }
        }

        [Console]::SetCursorPosition(0, $startLine)
        for ($i = 0; $i -lt $keys.Count; $i++) {
            $key = $keys[$i]
            $mark = "[ ]"
            if ($selected[$key]) { $mark = "[X]" }
            $pointer = "  "
            if ($i -eq $currentIndex) { $pointer = " >" }
            $color = "White"
            if ($i -eq $currentIndex) { $color = "Yellow" }
            Write-Host "$pointer $mark $($items[$key].Name)  " -ForegroundColor $color -NoNewline
            Write-Host "- $($items[$key].Desc)                    " -ForegroundColor DarkGray
        }
    }
}

# --- Language and IDE Definitions --------------------------------
function Get-LanguageDefinitions {
    return [ordered]@{
        "python"  = @{ Name="Python"; Desc="General purpose, AI/ML, scripting"; WinGet="Python.Python.3.12"; Choco="python3" }
        "nodejs"  = @{ Name="Node.js"; Desc="JavaScript/TypeScript runtime"; WinGet="OpenJS.NodeJS.LTS"; Choco="nodejs-lts" }
        "java"    = @{ Name="Java (JDK)"; Desc="Enterprise, Android, cross-platform"; WinGet="EclipseAdoptium.Temurin.21.JDK"; Choco="temurin21" }
        "csharp"  = @{ Name="C# / .NET SDK"; Desc="Microsoft ecosystem, web, desktop, games"; WinGet="Microsoft.DotNet.SDK.8"; Choco="dotnet-sdk" }
        "cpp"     = @{ Name="C/C++ (MinGW-w64)"; Desc="Systems programming, performance-critical"; WinGet=""; Choco="mingw" }
        "go"      = @{ Name="Go (Golang)"; Desc="Cloud, networking, microservices"; WinGet="GoLang.Go"; Choco="golang" }
        "rust"    = @{ Name="Rust"; Desc="Systems programming, memory safety"; WinGet="Rustlang.Rustup"; Choco="rustup.install" }
        "php"     = @{ Name="PHP"; Desc="Web development, CMS, server-side"; WinGet=""; Choco="php" }
        "ruby"    = @{ Name="Ruby"; Desc="Web development, scripting, DevOps"; WinGet="RubyInstallerTeam.Ruby.3.2"; Choco="ruby" }
        "kotlin"  = @{ Name="Kotlin"; Desc="Android, JVM, multiplatform"; WinGet=""; Choco="kotlin" }
        "dart"    = @{ Name="Dart and Flutter"; Desc="Mobile, web, desktop UI"; WinGet=""; Choco="dart-sdk" }
        "swift"   = @{ Name="Swift"; Desc="Apple ecosystem, server-side"; WinGet="Swift.Toolchain"; Choco="" }
    }
}

function Get-IDEDefinitions {
    return [ordered]@{
        "vscode"     = @{ Name="VS Code"; Desc="Lightweight, extensible, multi-language"; WinGet="Microsoft.VisualStudioCode"; Choco="vscode" }
        "vs2022"     = @{ Name="Visual Studio 2022 Community"; Desc="Full-featured IDE for .NET, C++"; WinGet="Microsoft.VisualStudio.2022.Community"; Choco="visualstudio2022community" }
        "intellij"   = @{ Name="IntelliJ IDEA Community"; Desc="Java, Kotlin, JVM languages"; WinGet="JetBrains.IntelliJIDEA.Community"; Choco="intellijidea-community" }
        "pycharm"    = @{ Name="PyCharm Community"; Desc="Python IDE with debugging and testing"; WinGet="JetBrains.PyCharm.Community"; Choco="pycharm-community" }
        "webstorm"   = @{ Name="WebStorm"; Desc="JavaScript/TypeScript IDE (paid)"; WinGet="JetBrains.WebStorm"; Choco="webstorm" }
        "goland"     = @{ Name="GoLand"; Desc="Go IDE by JetBrains (paid)"; WinGet="JetBrains.GoLand"; Choco="goland" }
        "clion"      = @{ Name="CLion"; Desc="C/C++ IDE by JetBrains (paid)"; WinGet="JetBrains.CLion"; Choco="clion" }
        "rider"      = @{ Name="Rider"; Desc=".NET IDE by JetBrains (paid)"; WinGet="JetBrains.Rider"; Choco="jetbrains-rider" }
        "eclipse"    = @{ Name="Eclipse IDE"; Desc="Java, C/C++, PHP, multi-language"; WinGet="EclipseAdoptium.Temurin.21.JDK"; Choco="eclipse" }
        "android"    = @{ Name="Android Studio"; Desc="Official Android development IDE"; WinGet="Google.AndroidStudio"; Choco="androidstudio" }
        "sublime"    = @{ Name="Sublime Text"; Desc="Fast, lightweight code editor"; WinGet="SublimeHQ.SublimeText.4"; Choco="sublimetext4" }
        "vim"        = @{ Name="Vim / Neovim"; Desc="Terminal-based editor for power users"; WinGet="Neovim.Neovim"; Choco="neovim" }
        "notepadpp"  = @{ Name="Notepad++"; Desc="Lightweight Windows code editor"; WinGet="Notepad++.Notepad++"; Choco="notepadplusplus" }
        "cursor"     = @{ Name="Cursor"; Desc="AI-powered code editor"; WinGet="Anysphere.Cursor"; Choco="" }
    }
}

function Get-ToolDefinitions {
    return [ordered]@{
        "git"       = @{ Name="Git"; Desc="Version control system"; WinGet="Git.Git"; Choco="git" }
        "docker"    = @{ Name="Docker Desktop"; Desc="Containerization platform"; WinGet="Docker.DockerDesktop"; Choco="docker-desktop" }
        "postman"   = @{ Name="Postman"; Desc="API testing and development"; WinGet="Postman.Postman"; Choco="postman" }
        "wsl"       = @{ Name="WSL 2 (Ubuntu)"; Desc="Linux subsystem for Windows"; WinGet=""; Choco="" }
        "terminal"  = @{ Name="Windows Terminal"; Desc="Modern terminal application"; WinGet="Microsoft.WindowsTerminal"; Choco="microsoft-windows-terminal" }
        "cmake"     = @{ Name="CMake"; Desc="Cross-platform build system"; WinGet="Kitware.CMake"; Choco="cmake" }
        "gh"        = @{ Name="GitHub CLI"; Desc="GitHub from command line"; WinGet="GitHub.cli"; Choco="gh" }
    }
}

# --- Installation Orchestrator ----------------------------------
function Install-Item($item) {
    if ($item.WinGet -and (Get-Command winget -ErrorAction SilentlyContinue)) {
        return Install-WithWinGet $item.WinGet $item.Name
    }
    elseif ($item.Choco -and (Get-Command choco -ErrorAction SilentlyContinue)) {
        return Install-WithChoco $item.Choco $item.Name
    }
    else {
        Write-Fail "No installation method available for $($item.Name)"
        $script:FailedItems += $item.Name
        return $false
    }
}

function Install-WSL {
    Write-Step "Installing WSL 2 with Ubuntu..."
    try {
        wsl --install -d Ubuntu 2>&1 | Out-Null
        Write-Success "WSL 2 (Ubuntu) installation initiated. Reboot may be required."
        $script:InstalledItems += "WSL 2 (Ubuntu)"
    } catch {
        Write-Fail "Failed to install WSL: $_"
        $script:FailedItems += "WSL 2 (Ubuntu)"
    }
}

# --- Summary Report ---------------------------------------------
function Show-Summary {
    Write-SectionHeader "Installation Summary"
    
    if ($script:InstalledItems.Count -gt 0) {
        Write-Host "  Successfully installed ($($script:InstalledItems.Count)):" -ForegroundColor Green
        foreach ($item in $script:InstalledItems) {
            Write-Host "    + $item" -ForegroundColor Green
        }
    }
    
    if ($script:FailedItems.Count -gt 0) {
        Write-Host ""
        Write-Host "  Failed installations ($($script:FailedItems.Count)):" -ForegroundColor Red
        foreach ($item in $script:FailedItems) {
            Write-Host "    - $item" -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "  Total: $($script:InstalledItems.Count) succeeded, $($script:FailedItems.Count) failed" -ForegroundColor Cyan
    Write-Host "  Log file: $script:LogFile" -ForegroundColor DarkGray
    Write-Host ""

    if ($script:InstalledItems.Count -gt 0) {
        Write-Host "  WARNING: Please restart your terminal/PC for PATH changes to take effect." -ForegroundColor Yellow
    }
}

# --- Config File Support ----------------------------------------
function Export-Config($languages, $ides, $tools) {
    $config = @{
        version = $script:Version
        date = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
        languages = $languages
        ides = $ides
        tools = $tools
    }
    $configPath = "$env:USERPROFILE\codeready_config.json"
    $config | ConvertTo-Json | Set-Content -Path $configPath
    Write-Info "Configuration saved to $configPath"
}

# --- Quick Setup Profiles ---------------------------------------
function Show-ProfileMenu {
    Write-SectionHeader "Quick Setup Profiles"
    Write-Host "  [1] Web Developer      - Node.js, Python, PHP + VS Code, Sublime" -ForegroundColor White
    Write-Host "  [2] Mobile Developer   - Java, Kotlin, Dart + Android Studio, VS Code" -ForegroundColor White
    Write-Host "  [3] Data Scientist     - Python, R + VS Code, PyCharm" -ForegroundColor White
    Write-Host "  [4] Systems Programmer - C/C++, Rust, Go + VS Code, CLion, Vim" -ForegroundColor White
    Write-Host "  [5] Full Stack .NET    - C#/.NET, Node.js + Visual Studio, VS Code" -ForegroundColor White
    Write-Host "  [6] Game Developer     - C/C++, C# + Visual Studio, VS Code" -ForegroundColor White
    Write-Host "  [7] Custom Setup       - Choose your own languages and IDEs" -ForegroundColor Yellow
    Write-Host ""
    
    $choice = Read-Host "  Select profile (1-7)"
    
    switch ($choice) {
        "1" { return @{ langs=@("nodejs","python","php"); ides=@("vscode","sublime"); tools=@("git","docker","postman") } }
        "2" { return @{ langs=@("java","kotlin","dart"); ides=@("android","vscode"); tools=@("git") } }
        "3" { return @{ langs=@("python","nodejs"); ides=@("vscode","pycharm"); tools=@("git","docker") } }
        "4" { return @{ langs=@("cpp","rust","go"); ides=@("vscode","clion","vim"); tools=@("git","cmake") } }
        "5" { return @{ langs=@("csharp","nodejs"); ides=@("vs2022","vscode"); tools=@("git","docker","postman") } }
        "6" { return @{ langs=@("cpp","csharp"); ides=@("vs2022","vscode"); tools=@("git","cmake") } }
        "7" { return $null }
        default { return $null }
    }
}

# --- MAIN -------------------------------------------------------
function Main {
    Write-Banner

    "CodeReady Installation Log - $(Get-Date)" | Set-Content -Path $script:LogFile

    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Fail "Please run this script as Administrator!"
        Write-Info "Right-click PowerShell -> Run as Administrator"
        return
    }

    Write-SectionHeader "Package Manager Setup"
    $hasWinGet = Ensure-WinGet
    $hasChoco = Ensure-Chocolatey

    if (-not $hasWinGet -and -not $hasChoco) {
        Write-Fail "No package manager available. Cannot proceed."
        return
    }

    $profile = Show-ProfileMenu
    
    $langDefs = Get-LanguageDefinitions
    $ideDefs = Get-IDEDefinitions
    $toolDefs = Get-ToolDefinitions

    if ($null -eq $profile) {
        $selectedLangs = Show-MultiSelectMenu "Select Programming Languages" $langDefs
        $selectedIDEs = Show-MultiSelectMenu "Select IDEs and Editors" $ideDefs
        $selectedTools = Show-MultiSelectMenu "Select Developer Tools" $toolDefs
    } else {
        $selectedLangs = $profile.langs
        $selectedIDEs = $profile.ides
        $selectedTools = $profile.tools
    }

    Write-SectionHeader "Installation Plan"
    Write-Host "  Languages: " -NoNewline -ForegroundColor Cyan
    Write-Host (($selectedLangs | ForEach-Object { $langDefs[$_].Name }) -join ", ")
    Write-Host "  IDEs:      " -NoNewline -ForegroundColor Cyan
    Write-Host (($selectedIDEs | ForEach-Object { $ideDefs[$_].Name }) -join ", ")
    Write-Host "  Tools:     " -NoNewline -ForegroundColor Cyan
    Write-Host (($selectedTools | ForEach-Object { $toolDefs[$_].Name }) -join ", ")
    Write-Host ""
    
    $confirm = Read-Host "  Proceed with installation? (Y/n)"
    if ($confirm -eq "n" -or $confirm -eq "N") {
        Write-Info "Installation cancelled."
        return
    }

    Export-Config $selectedLangs $selectedIDEs $selectedTools

    Write-SectionHeader "Installing Languages and Runtimes"
    foreach ($lang in $selectedLangs) {
        if ($langDefs.Contains($lang)) {
            Install-Item $langDefs[$lang]
        }
    }

    Write-SectionHeader "Installing IDEs and Editors"
    foreach ($ide in $selectedIDEs) {
        if ($ideDefs.Contains($ide)) {
            Install-Item $ideDefs[$ide]
        }
    }

    Write-SectionHeader "Installing Developer Tools"
    foreach ($tool in $selectedTools) {
        if ($tool -eq "wsl") {
            Install-WSL
        } elseif ($toolDefs.Contains($tool)) {
            Install-Item $toolDefs[$tool]
        }
    }

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

    Show-Summary
}

Main
