@echo off
:: ╔══════════════════════════════════════════════════════════════════╗
:: ║                   CodeReady v1.0.0                               ║
:: ║       Developer Environment Setup Tool - Windows Launcher        ║
:: ╚══════════════════════════════════════════════════════════════════╝

title CodeReady - Developer Environment Setup

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo   [!] CodeReady requires Administrator privileges.
    echo   [!] Requesting elevation...
    echo.
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Run the PowerShell script
echo.
echo   Starting CodeReady...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0codeready.ps1"

echo.
echo   Press any key to exit...
pause > nul
