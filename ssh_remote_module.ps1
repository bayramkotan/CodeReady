# ============================================================================
# CodeReady v2.2 — SSH Remote Execution Module (PowerShell)
# Add these functions to codeready.ps1
# ============================================================================

# --- Remote Configuration ---
$script:RemoteMode = $false
$script:RemoteHost = ""
$script:RemoteUser = ""
$script:RemotePort = 22
$script:RemoteKey = ""
$script:RemoteAuth = "key"  # key | agent | password

# --- Target Selection --------------------------------------------------------
function Select-Target {
    Write-Host ""
    Write-Host "  === Target Machine ===" -ForegroundColor Cyan
    Write-Host "    1) This machine (localhost)" -ForegroundColor Green -NoNewline
    Write-Host " <- default" -ForegroundColor DarkGray
    Write-Host "    2) Remote machine (SSH)" -ForegroundColor Green
    Write-Host ""
    $choice = Read-Host "  Select target [1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    switch ($choice) {
        "1" {
            $script:RemoteMode = $false
            Write-Host "  [OK] Target: localhost" -ForegroundColor Green
        }
        "2" {
            $script:RemoteMode = $true
            Configure-Remote
        }
        default {
            $script:RemoteMode = $false
            Write-Host "  [OK] Target: localhost" -ForegroundColor Green
        }
    }
}

# --- Remote Configuration Wizard ---------------------------------------------
function Configure-Remote {
    Write-Host ""
    Write-Host "  === Remote SSH Configuration ===" -ForegroundColor Cyan
    Write-Host ""

    # Check for saved hosts
    $configDir = Join-Path $env:USERPROFILE ".codeready"
    $hostsFile = Join-Path $configDir "remote-hosts.json"

    if (Test-Path $hostsFile) {
        try {
            $savedHosts = Get-Content $hostsFile -Raw | ConvertFrom-Json
            if ($savedHosts.Count -gt 0) {
                Write-Host "  Saved hosts:" -ForegroundColor Yellow
                for ($i = 0; $i -lt $savedHosts.Count; $i++) {
                    $h = $savedHosts[$i]
                    $label = if ($h.label) { $h.label } else { $h.host }
                    $port = if ($h.port) { $h.port } else { 22 }
                    Write-Host "    $($i+1)) $label ($($h.user)@$($h.host):$port)" -ForegroundColor White
                }
                Write-Host "    $($savedHosts.Count + 1)) New connection" -ForegroundColor White
                Write-Host ""

                $hostChoice = Read-Host "  Select host"
                $idx = 0
                if ([int]::TryParse($hostChoice, [ref]$idx) -and $idx -ge 1 -and $idx -le $savedHosts.Count) {
                    $h = $savedHosts[$idx - 1]
                    $script:RemoteHost = $h.host
                    $script:RemoteUser = $h.user
                    $script:RemotePort = if ($h.port) { $h.port } else { 22 }
                    $script:RemoteKey = if ($h.key) { $h.key } else { "" }
                    Write-Host "  [OK] Loaded: $($script:RemoteUser)@$($script:RemoteHost):$($script:RemotePort)" -ForegroundColor Green
                    Test-RemoteConnection
                    return
                }
            }
        } catch {
            # Invalid JSON, continue to new connection
        }
    }

    # New connection
    $script:RemoteHost = Read-Host "  Hostname or IP"
    if ([string]::IsNullOrWhiteSpace($script:RemoteHost)) {
        Write-Host "  [ERR] No hostname provided, falling back to localhost" -ForegroundColor Red
        $script:RemoteMode = $false
        return
    }

    $userInput = Read-Host "  Username [$env:USERNAME]"
    $script:RemoteUser = if ([string]::IsNullOrWhiteSpace($userInput)) { $env:USERNAME } else { $userInput }

    $portInput = Read-Host "  Port [22]"
    $script:RemotePort = if ([string]::IsNullOrWhiteSpace($portInput)) { 22 } else { [int]$portInput }

    Write-Host ""
    Write-Host "  Authentication:" -ForegroundColor Cyan
    Write-Host "    1) SSH key (default)" -ForegroundColor White
    Write-Host "    2) SSH agent" -ForegroundColor White
    Write-Host "    3) Password" -ForegroundColor White
    $authChoice = Read-Host "  Auth method [1]"
    if ([string]::IsNullOrWhiteSpace($authChoice)) { $authChoice = "1" }

    switch ($authChoice) {
        "1" {
            $defaultKey = Join-Path $env:USERPROFILE ".ssh\id_ed25519"
            if (!(Test-Path $defaultKey)) {
                $defaultKey = Join-Path $env:USERPROFILE ".ssh\id_rsa"
            }
            $keyInput = Read-Host "  Key path [$defaultKey]"
            $script:RemoteKey = if ([string]::IsNullOrWhiteSpace($keyInput)) { $defaultKey } else { $keyInput }
            if (!(Test-Path $script:RemoteKey)) {
                Write-Host "  [ERR] Key file not found: $($script:RemoteKey)" -ForegroundColor Red
                $script:RemoteMode = $false
                return
            }
            $script:RemoteAuth = "key"
        }
        "2" {
            $script:RemoteAuth = "agent"
        }
        "3" {
            $script:RemoteAuth = "password"
            # Password will be prompted by ssh.exe interactively
        }
    }

    if (Test-RemoteConnection) {
        $saveAns = Read-Host "  Save this host for future use? [Y/n]"
        if ([string]::IsNullOrWhiteSpace($saveAns) -or $saveAns -match "^[Yy]$") {
            $label = Read-Host "  Label (e.g. 'dev-server')"
            Save-RemoteHost -Label $label
        }
    }
}

# --- Build SSH Command -------------------------------------------------------
function Get-SshCommand {
    param([string]$Command)

    # Windows 10+ has built-in ssh.exe (OpenSSH)
    $sshExe = "ssh"
    if (!(Get-Command ssh -ErrorAction SilentlyContinue)) {
        # Fallback to plink (PuTTY)
        if (Get-Command plink -ErrorAction SilentlyContinue) {
            $sshExe = "plink"
        } else {
            Write-Host "  [ERR] No SSH client found. Install OpenSSH or PuTTY." -ForegroundColor Red
            return $null
        }
    }

    $args = @(
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "ConnectTimeout=10",
        "-p", $script:RemotePort
    )

    if ($script:RemoteAuth -eq "key" -and $script:RemoteKey) {
        $args += @("-i", $script:RemoteKey)
    }

    $target = "$($script:RemoteUser)@$($script:RemoteHost)"

    return @{
        Exe = $sshExe
        Args = $args + @($target, $Command)
        Target = $target
    }
}

# --- Test Remote Connection --------------------------------------------------
function Test-RemoteConnection {
    Write-Host "  [..] Testing SSH connection to $($script:RemoteUser)@$($script:RemoteHost):$($script:RemotePort)..." -ForegroundColor Cyan

    $cmd = Get-SshCommand -Command "echo CodeReady-SSH-OK && uname -s"
    if ($null -eq $cmd) { return $false }

    try {
        $result = & $cmd.Exe $cmd.Args 2>&1 | Out-String
        if ($result -match "CodeReady-SSH-OK") {
            Write-Host "  [OK] SSH connection successful" -ForegroundColor Green
            if ($result -match "Linux|Darwin") {
                $os = if ($result -match "Darwin") { "macOS" } else { "Linux" }
                Write-Host "  [..] Remote OS: $os" -ForegroundColor Cyan
            }
            return $true
        }
    } catch {
        # Connection failed
    }

    Write-Host "  [ERR] SSH connection failed. Check credentials." -ForegroundColor Red
    $script:RemoteMode = $false
    return $false
}

# --- Save Remote Host --------------------------------------------------------
function Save-RemoteHost {
    param([string]$Label = "")

    $configDir = Join-Path $env:USERPROFILE ".codeready"
    $hostsFile = Join-Path $configDir "remote-hosts.json"

    if (!(Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }

    $hosts = @()
    if (Test-Path $hostsFile) {
        try {
            $hosts = @(Get-Content $hostsFile -Raw | ConvertFrom-Json)
        } catch { $hosts = @() }
    }

    # Remove duplicate
    $hosts = @($hosts | Where-Object {
        -not ($_.host -eq $script:RemoteHost -and $_.user -eq $script:RemoteUser -and $_.port -eq $script:RemotePort)
    })

    $newHost = @{
        label = if ($Label) { $Label } else { $script:RemoteHost }
        host  = $script:RemoteHost
        user  = $script:RemoteUser
        port  = $script:RemotePort
        key   = $script:RemoteKey
    }

    $hosts += $newHost

    $hosts | ConvertTo-Json -Depth 3 | Set-Content $hostsFile -Encoding UTF8

    Write-Host "  [OK] Host saved: $($newHost.label)" -ForegroundColor Green
}

# --- Remote Bootstrap (copy codeready.sh to remote) -------------------------
function Invoke-RemoteBootstrap {
    Write-Host "  [..] Bootstrapping remote machine..." -ForegroundColor Cyan

    # Create temp dir on remote
    $cmd = Get-SshCommand -Command "mktemp -d /tmp/codeready.XXXXXX"
    $remoteTmp = (& $cmd.Exe $cmd.Args 2>$null).Trim()

    if ([string]::IsNullOrWhiteSpace($remoteTmp)) {
        Write-Host "  [ERR] Failed to create temp dir on remote" -ForegroundColor Red
        return $null
    }

    # Copy codeready.sh via scp
    $scriptDir = Split-Path -Parent $PSCommandPath
    $shScript = Join-Path $scriptDir "codeready.sh"

    if (!(Test-Path $shScript)) {
        Write-Host "  [ERR] codeready.sh not found at $shScript" -ForegroundColor Red
        return $null
    }

    Write-Host "  [..] Copying codeready.sh to remote..." -ForegroundColor Cyan

    $scpArgs = @(
        "-o", "StrictHostKeyChecking=accept-new",
        "-P", $script:RemotePort
    )
    if ($script:RemoteAuth -eq "key" -and $script:RemoteKey) {
        $scpArgs += @("-i", $script:RemoteKey)
    }
    $scpArgs += @($shScript, "$($script:RemoteUser)@$($script:RemoteHost):$remoteTmp/codeready.sh")

    & scp $scpArgs 2>$null

    # Make executable
    $cmd = Get-SshCommand -Command "chmod +x $remoteTmp/codeready.sh"
    & $cmd.Exe $cmd.Args 2>$null

    Write-Host "  [OK] Bootstrap complete" -ForegroundColor Green
    return $remoteTmp
}

# --- Remote Exec (live streaming) --------------------------------------------
function Invoke-RemoteExec {
    param([string]$Command)

    $cmd = Get-SshCommand -Command $Command

    # Stream output live
    $process = Start-Process -FilePath $cmd.Exe -ArgumentList ($cmd.Args -join " ") `
        -NoNewWindow -PassThru -Wait -RedirectStandardOutput "NUL"

    # Actually, for live streaming we need a different approach
    & $cmd.Exe $cmd.Args 2>&1 | ForEach-Object { Write-Host $_ }
    return $LASTEXITCODE
}

# --- Remote Scan / Install / Profile ----------------------------------------
function Invoke-RemoteScan {
    $remoteTmp = Invoke-RemoteBootstrap
    if ($null -eq $remoteTmp) { return }

    Write-Host ""
    Write-Host "  --- Remote Scan Output ---" -ForegroundColor DarkGray
    Invoke-RemoteExec -Command "sudo bash $remoteTmp/codeready.sh --scan"
    Write-Host "  --- End Remote Output ---" -ForegroundColor DarkGray

    # Cleanup
    $cmd = Get-SshCommand -Command "rm -rf $remoteTmp"
    & $cmd.Exe $cmd.Args 2>$null
}

function Invoke-RemoteInstall {
    param([string]$Items)

    $remoteTmp = Invoke-RemoteBootstrap
    if ($null -eq $remoteTmp) { return }

    Write-Host ""
    Write-Host "  --- Remote Install Output ---" -ForegroundColor DarkGray
    Invoke-RemoteExec -Command "sudo bash $remoteTmp/codeready.sh --install '$Items'"
    Write-Host "  --- End Remote Output ---" -ForegroundColor DarkGray

    $cmd = Get-SshCommand -Command "rm -rf $remoteTmp"
    & $cmd.Exe $cmd.Args 2>$null
}

function Invoke-RemoteProfile {
    param([int]$ProfileNum)

    $remoteTmp = Invoke-RemoteBootstrap
    if ($null -eq $remoteTmp) { return }

    Write-Host ""
    Write-Host "  --- Remote Profile Output ---" -ForegroundColor DarkGray
    Invoke-RemoteExec -Command "sudo bash $remoteTmp/codeready.sh --profile $ProfileNum"
    Write-Host "  --- End Remote Output ---" -ForegroundColor DarkGray

    $cmd = Get-SshCommand -Command "rm -rf $remoteTmp"
    & $cmd.Exe $cmd.Args 2>$null
}

# --- Updated Banner ----------------------------------------------------------
function Show-Banner {
    Write-Host ""
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host "   CodeReady -- Developer Environment Setup    v2.2.0" -ForegroundColor Green
    Write-Host "  =====================================================" -ForegroundColor Cyan
    if ($script:RemoteMode) {
        Write-Host "   TARGET: $($script:RemoteUser)@$($script:RemoteHost):$($script:RemotePort)" -ForegroundColor Yellow
        Write-Host "   Mode: SSH Remote" -ForegroundColor Yellow
    } else {
        Write-Host "   TARGET: localhost" -ForegroundColor Green
        Write-Host "   Mode: Local" -ForegroundColor Green
    }
    Write-Host "  =====================================================" -ForegroundColor Cyan
    Write-Host ""
}

# --- CLI Parameter Support ---------------------------------------------------
# Add to param() block at top of codeready.ps1:
#
# param(
#     [string]$Remote = "",
#     [string]$RemoteUser = "",
#     [int]$RemotePort = 22,
#     [string]$RemoteKey = "",
#     [switch]$Scan,
#     [string]$Install = "",
#     [int]$Profile = 0,
#     [switch]$LocalOnly
# )
#
# Usage:
#   .\codeready.ps1 -Remote "192.168.1.50" -RemoteUser "deploy" -Profile 5
#   .\codeready.ps1 -Remote "myserver.com" -Scan
#   .\codeready.ps1 -Remote "dev-box" -RemoteKey "~/.ssh/id_ed25519" -Install "python,nodejs"
