@echo off
title CodeReady v2.0 - Developer Environment Setup
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo   [!] CodeReady requires Administrator privileges. Requesting elevation...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
echo.
echo   Starting CodeReady v2.0...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0codeready.ps1"
echo.
echo   Press any key to exit...
pause > nul
