<p align="center">
  <img src="https://img.shields.io/badge/CodeReady-v2.1-00d4ff?style=for-the-badge&labelColor=0a0a0a" alt="Version" />
  <img src="https://img.shields.io/badge/Languages-39-ff6b35?style=for-the-badge&labelColor=0a0a0a" alt="Languages" />
  <img src="https://img.shields.io/badge/IDEs-23-06d6a0?style=for-the-badge&labelColor=0a0a0a" alt="IDEs" />
  <img src="https://img.shields.io/badge/Frameworks-38+-7b2fbe?style=for-the-badge&labelColor=0a0a0a" alt="Frameworks" />
  <img src="https://img.shields.io/badge/Profiles-15-ef476f?style=for-the-badge&labelColor=0a0a0a" alt="Profiles" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/macOS-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS" />
  <img src="https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black" alt="Linux" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
</p>

<h1 align="center">CodeReady</h1>

<p align="center">
  <b>The ultimate developer environment setup tool.</b><br/>
  Scans your system. Detects what you have. Installs what you need. Zero guesswork.
</p>

<p align="center">
  <a href="#-quick-start">Quick Start</a> &bull;
  <a href="#-system-scan">System Scan</a> &bull;
  <a href="#-languages">Languages</a> &bull;
  <a href="#-ides--editors">IDEs</a> &bull;
  <a href="#-frameworks--tools">Frameworks</a> &bull;
  <a href="#-profiles">Profiles</a> &bull;
  <a href="#%EF%B8%8F-package-managers">Package Managers</a>
</p>

---

## Why CodeReady?

Setting up a new development machine is painful. You spend hours downloading compilers, configuring IDEs, installing package managers, and getting frameworks working. **CodeReady automates all of it** with a single interactive script.

- **System scan first** — detects what's already installed, skips what you have, suggests upgrades
- **Version selection** — choose between multiple versions for each language (latest, LTS, older)
- **15 profiles** — Web, Mobile, AI/ML, DevOps, Blockchain, Scientific, Functional, and more
- **Multi-profile** — combine profiles: `1 5 9` = Web Frontend + AI/ML + DevOps
- **Cross-platform** — Windows, macOS, Linux with the same experience
- **Safe installs** — failed installs auto-cleanup, never leaves broken repos on your system
- **109+ packages** — languages, IDEs, tools, frameworks, all in one place

---

## System Scan

CodeReady scans your system **before** installing anything. It detects every language, IDE, tool, and package manager already on your machine, and shows you what's outdated.

```
=== System Scan ===
  Scanning your system for installed software...

  Languages and Runtimes:
    Python            3.x.x       ⬆ upgrade available
    Node.js           2x.x.x      ✓ up to date
    Java (JDK)        —  not installed
    Rust              1.x.x       ✓
    ...

  IDEs and Editors:
    VS Code           x.xx        ✓
    Neovim            0.x.x       ✓
    Cursor            —  not installed
    ...

  ────────────────────────────────────────
  ✓ 12 installed  |  — 8 not found

  Continue to profile selection? (Y/n):
```

Already installed? **Skipped.** No redundant re-installs.

---

## Quick Start

### Windows

```powershell
# Option 1: Double-click codeready.bat (auto-elevates to Admin)

# Option 2: Run in Admin PowerShell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\codeready.ps1
```

### Linux / macOS

```bash
chmod +x codeready.sh
./codeready.sh
```

---

## Languages

**39 programming languages and runtimes** across every major paradigm.

### Mainstream

<p>
  <img src="https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white" />
  <img src="https://img.shields.io/badge/JavaScript-F7DF1E?style=flat-square&logo=javascript&logoColor=black" />
  <img src="https://img.shields.io/badge/TypeScript-3178C6?style=flat-square&logo=typescript&logoColor=white" />
  <img src="https://img.shields.io/badge/Java-ED8B00?style=flat-square&logo=openjdk&logoColor=white" />
  <img src="https://img.shields.io/badge/C%23-512BD4?style=flat-square&logo=csharp&logoColor=white" />
  <img src="https://img.shields.io/badge/C%2B%2B-00599C?style=flat-square&logo=cplusplus&logoColor=white" />
  <img src="https://img.shields.io/badge/C-A8B9CC?style=flat-square&logo=c&logoColor=black" />
  <img src="https://img.shields.io/badge/Go-00ADD8?style=flat-square&logo=go&logoColor=white" />
  <img src="https://img.shields.io/badge/Rust-000000?style=flat-square&logo=rust&logoColor=white" />
  <img src="https://img.shields.io/badge/PHP-777BB4?style=flat-square&logo=php&logoColor=white" />
  <img src="https://img.shields.io/badge/Ruby-CC342D?style=flat-square&logo=ruby&logoColor=white" />
  <img src="https://img.shields.io/badge/Kotlin-7F52FF?style=flat-square&logo=kotlin&logoColor=white" />
  <img src="https://img.shields.io/badge/Swift-F05138?style=flat-square&logo=swift&logoColor=white" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=flat-square&logo=dart&logoColor=white" />
  <img src="https://img.shields.io/badge/Flutter-02569B?style=flat-square&logo=flutter&logoColor=white" />
</p>

### Scientific & Data

<p>
  <img src="https://img.shields.io/badge/R-276DC3?style=flat-square&logo=r&logoColor=white" />
  <img src="https://img.shields.io/badge/Julia-9558B2?style=flat-square&logo=julia&logoColor=white" />
  <img src="https://img.shields.io/badge/Fortran-734F96?style=flat-square&logo=fortran&logoColor=white" />
  <img src="https://img.shields.io/badge/Haskell-5D4F85?style=flat-square&logo=haskell&logoColor=white" />
  <img src="https://img.shields.io/badge/Mojo-FF7000?style=flat-square&logoColor=white" />
</p>

### Functional & Concurrent

<p>
  <img src="https://img.shields.io/badge/Elixir-4B275F?style=flat-square&logo=elixir&logoColor=white" />
  <img src="https://img.shields.io/badge/Erlang-A90533?style=flat-square&logo=erlang&logoColor=white" />
  <img src="https://img.shields.io/badge/Scala-DC322F?style=flat-square&logo=scala&logoColor=white" />
  <img src="https://img.shields.io/badge/OCaml-EC6813?style=flat-square&logo=ocaml&logoColor=white" />
  <img src="https://img.shields.io/badge/Common_Lisp-3FB68B?style=flat-square" />
  <img src="https://img.shields.io/badge/Racket-9F1D20?style=flat-square" />
  <img src="https://img.shields.io/badge/Gleam-FFAFF3?style=flat-square&logoColor=black" />
</p>

### Systems & Next-Gen

<p>
  <img src="https://img.shields.io/badge/Zig-F7A41D?style=flat-square&logo=zig&logoColor=black" />
  <img src="https://img.shields.io/badge/Nim-FFE953?style=flat-square&logo=nim&logoColor=black" />
  <img src="https://img.shields.io/badge/Crystal-000000?style=flat-square&logo=crystal&logoColor=white" />
  <img src="https://img.shields.io/badge/V-5D87BF?style=flat-square" />
  <img src="https://img.shields.io/badge/D-B03931?style=flat-square&logo=d&logoColor=white" />
  <img src="https://img.shields.io/badge/Carbon-0078D4?style=flat-square" />
  <img src="https://img.shields.io/badge/Ada-02f88c?style=flat-square" />
  <img src="https://img.shields.io/badge/WebAssembly-654FF0?style=flat-square&logo=webassembly&logoColor=white" />
</p>

### Scripting & Legacy

<p>
  <img src="https://img.shields.io/badge/Lua-2C2D72?style=flat-square&logo=lua&logoColor=white" />
  <img src="https://img.shields.io/badge/Perl-39457E?style=flat-square&logo=perl&logoColor=white" />
  <img src="https://img.shields.io/badge/Groovy-4298B8?style=flat-square&logo=apachegroovy&logoColor=white" />
  <img src="https://img.shields.io/badge/Solidity-363636?style=flat-square&logo=solidity&logoColor=white" />
  <img src="https://img.shields.io/badge/COBOL-005CA5?style=flat-square" />
  <img src="https://img.shields.io/badge/Objective--C-438EFF?style=flat-square" />
</p>

> **Version selection** is available for Python, Node.js, Java, .NET, Go, PHP, Ruby, Zig, and Julia. Other languages install the latest stable release.

---

## IDEs & Editors

**23 editors and IDEs** — from AI-powered to classic terminal editors.

### AI-Powered & Modern

<p>
  <img src="https://img.shields.io/badge/VS_Code-007ACC?style=flat-square&logo=visualstudiocode&logoColor=white" />
  <img src="https://img.shields.io/badge/VSCodium-2F80ED?style=flat-square&logo=vscodium&logoColor=white" />
  <img src="https://img.shields.io/badge/Cursor-000000?style=flat-square&logoColor=white" />
  <img src="https://img.shields.io/badge/Windsurf-09B6A2?style=flat-square" />
  <img src="https://img.shields.io/badge/Antigravity-FF4500?style=flat-square" />
  <img src="https://img.shields.io/badge/Zed-084CCF?style=flat-square" />
</p>

### JetBrains Suite

<p>
  <img src="https://img.shields.io/badge/IntelliJ_IDEA-000000?style=flat-square&logo=intellijidea&logoColor=white" />
  <img src="https://img.shields.io/badge/PyCharm-000000?style=flat-square&logo=pycharm&logoColor=white" />
  <img src="https://img.shields.io/badge/WebStorm-000000?style=flat-square&logo=webstorm&logoColor=white" />
  <img src="https://img.shields.io/badge/GoLand-000000?style=flat-square&logo=goland&logoColor=white" />
  <img src="https://img.shields.io/badge/CLion-000000?style=flat-square&logo=clion&logoColor=white" />
  <img src="https://img.shields.io/badge/Rider-000000?style=flat-square&logo=rider&logoColor=white" />
  <img src="https://img.shields.io/badge/RustRover-000000?style=flat-square" />
  <img src="https://img.shields.io/badge/Fleet-000000?style=flat-square" />
</p>

### Classic & Terminal

<p>
  <img src="https://img.shields.io/badge/Visual_Studio-5C2D91?style=flat-square&logo=visualstudio&logoColor=white" />
  <img src="https://img.shields.io/badge/Sublime_Text-FF9800?style=flat-square&logo=sublimetext&logoColor=white" />
  <img src="https://img.shields.io/badge/Vim-019733?style=flat-square&logo=vim&logoColor=white" />
  <img src="https://img.shields.io/badge/Neovim-57A143?style=flat-square&logo=neovim&logoColor=white" />
  <img src="https://img.shields.io/badge/GNU_Emacs-7F5AB6?style=flat-square&logo=gnuemacs&logoColor=white" />
  <img src="https://img.shields.io/badge/Notepad++-90E59A?style=flat-square&logo=notepadplusplus&logoColor=black" />
  <img src="https://img.shields.io/badge/Eclipse-2C2255?style=flat-square&logo=eclipseide&logoColor=white" />
  <img src="https://img.shields.io/badge/NetBeans-1B6AC6?style=flat-square&logo=apachenetbeans&logoColor=white" />
  <img src="https://img.shields.io/badge/Android_Studio-3DDC84?style=flat-square&logo=androidstudio&logoColor=white" />
</p>

---

## Frameworks & Tools

**38+ frameworks, libraries, and package managers** — currently installed, with [many more planned](codeready_todo.md).

### Package Managers

<p>
  <img src="https://img.shields.io/badge/npm-CB3837?style=flat-square&logo=npm&logoColor=white" />
  <img src="https://img.shields.io/badge/Yarn-2C8EBB?style=flat-square&logo=yarn&logoColor=white" />
  <img src="https://img.shields.io/badge/pnpm-F69220?style=flat-square&logo=pnpm&logoColor=white" />
  <img src="https://img.shields.io/badge/Bun-000000?style=flat-square&logo=bun&logoColor=white" />
  <a href="https://github.com/bayramkotan/VenvStudio"><img src="https://img.shields.io/badge/VenvStudio-4B8BBE?style=flat-square&logo=python&logoColor=white" /></a>
  <img src="https://img.shields.io/badge/uv-DE5FE9?style=flat-square" />
  <img src="https://img.shields.io/badge/Poetry-60A5FA?style=flat-square&logo=poetry&logoColor=white" />
  <img src="https://img.shields.io/badge/Conda-44A833?style=flat-square&logo=anaconda&logoColor=white" />
  <img src="https://img.shields.io/badge/pipx-2CFFAA?style=flat-square" />
</p>

### Web Frameworks

<p>
  <img src="https://img.shields.io/badge/React-61DAFB?style=flat-square&logo=react&logoColor=black" />
  <img src="https://img.shields.io/badge/Next.js-000000?style=flat-square&logo=nextdotjs&logoColor=white" />
  <img src="https://img.shields.io/badge/Vue-4FC08D?style=flat-square&logo=vuedotjs&logoColor=white" />
  <img src="https://img.shields.io/badge/Nuxt-00DC82?style=flat-square&logo=nuxtdotjs&logoColor=black" />
  <img src="https://img.shields.io/badge/Angular-DD0031?style=flat-square&logo=angular&logoColor=white" />
  <img src="https://img.shields.io/badge/Svelte-FF3E00?style=flat-square&logo=svelte&logoColor=white" />
  <img src="https://img.shields.io/badge/Vite-646CFF?style=flat-square&logo=vite&logoColor=white" />
  <img src="https://img.shields.io/badge/Astro-BC52EE?style=flat-square&logo=astro&logoColor=white" />
  <img src="https://img.shields.io/badge/Remix-000000?style=flat-square&logo=remix&logoColor=white" />
</p>

### Backend Frameworks

<p>
  <img src="https://img.shields.io/badge/Express-000000?style=flat-square&logo=express&logoColor=white" />
  <img src="https://img.shields.io/badge/NestJS-E0234E?style=flat-square&logo=nestjs&logoColor=white" />
  <img src="https://img.shields.io/badge/Django-092E20?style=flat-square&logo=django&logoColor=white" />
  <img src="https://img.shields.io/badge/Flask-000000?style=flat-square&logo=flask&logoColor=white" />
  <img src="https://img.shields.io/badge/FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white" />
  <img src="https://img.shields.io/badge/Streamlit-FF4B4B?style=flat-square&logo=streamlit&logoColor=white" />
</p>

### CSS, Mobile & Cross-Platform

<p>
  <img src="https://img.shields.io/badge/Tailwind-06B6D4?style=flat-square&logo=tailwindcss&logoColor=white" />
  <img src="https://img.shields.io/badge/Bootstrap-7952B3?style=flat-square&logo=bootstrap&logoColor=white" />
  <img src="https://img.shields.io/badge/React_Native-61DAFB?style=flat-square&logo=react&logoColor=black" />
  <img src="https://img.shields.io/badge/Expo-000020?style=flat-square&logo=expo&logoColor=white" />
  <img src="https://img.shields.io/badge/Electron-47848F?style=flat-square&logo=electron&logoColor=white" />
  <img src="https://img.shields.io/badge/Tauri-24C8D8?style=flat-square&logo=tauri&logoColor=white" />
  <img src="https://img.shields.io/badge/Ionic-3880FF?style=flat-square&logo=ionic&logoColor=white" />
</p>

### DevOps & Infrastructure

<p>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white" />
  <img src="https://img.shields.io/badge/Kubernetes-326CE5?style=flat-square&logo=kubernetes&logoColor=white" />
  <img src="https://img.shields.io/badge/Helm-0F1689?style=flat-square&logo=helm&logoColor=white" />
  <img src="https://img.shields.io/badge/Git-F05032?style=flat-square&logo=git&logoColor=white" />
  <img src="https://img.shields.io/badge/GitHub_CLI-181717?style=flat-square&logo=github&logoColor=white" />
  <img src="https://img.shields.io/badge/CMake-064F8C?style=flat-square&logo=cmake&logoColor=white" />
  <img src="https://img.shields.io/badge/Postman-FF6C37?style=flat-square&logo=postman&logoColor=white" />
</p>

### Language Ecosystems

<p>
  <img src="https://img.shields.io/badge/cargo--watch-000000?style=flat-square&logo=rust&logoColor=white" />
  <img src="https://img.shields.io/badge/wasm--pack-654FF0?style=flat-square&logo=webassembly&logoColor=white" />
  <img src="https://img.shields.io/badge/Blazor-512BD4?style=flat-square&logo=blazor&logoColor=white" />
  <img src="https://img.shields.io/badge/.NET_MAUI-512BD4?style=flat-square&logo=dotnet&logoColor=white" />
</p>

---

## Profiles

**15 profiles** for common developer roles. Select **one or multiple**, or go fully custom.

```
Select profile(s): 2 5 9     <- combine Web Full Stack + AI/ML + DevOps
Select profile(s): 17        <- install EVERYTHING (with safety warnings)
```

### Popular Stacks

| # | Profile | What You Get |
|:-:|---------|-------------|
| **1** | **Web Frontend** | ![Node.js](https://img.shields.io/badge/-Node.js-339933?style=flat-square&logo=nodedotjs&logoColor=white) ![TypeScript](https://img.shields.io/badge/-TS-3178C6?style=flat-square&logo=typescript&logoColor=white) ![React](https://img.shields.io/badge/-React-61DAFB?style=flat-square&logo=react&logoColor=black) ![Vue](https://img.shields.io/badge/-Vue-4FC08D?style=flat-square&logo=vuedotjs&logoColor=white) ![Tailwind](https://img.shields.io/badge/-Tailwind-06B6D4?style=flat-square&logo=tailwindcss&logoColor=white) ![Vite](https://img.shields.io/badge/-Vite-646CFF?style=flat-square&logo=vite&logoColor=white) |
| **2** | **Web Full Stack** | ![Node.js](https://img.shields.io/badge/-Node.js-339933?style=flat-square&logo=nodedotjs&logoColor=white) ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat-square&logo=python&logoColor=white) ![React](https://img.shields.io/badge/-React-61DAFB?style=flat-square&logo=react&logoColor=black) ![Next.js](https://img.shields.io/badge/-Next.js-000?style=flat-square&logo=nextdotjs&logoColor=white) ![Django](https://img.shields.io/badge/-Django-092E20?style=flat-square&logo=django&logoColor=white) ![Express](https://img.shields.io/badge/-Express-000?style=flat-square&logo=express&logoColor=white) |
| **3** | **Mobile Developer** | ![Kotlin](https://img.shields.io/badge/-Kotlin-7F52FF?style=flat-square&logo=kotlin&logoColor=white) ![Flutter](https://img.shields.io/badge/-Flutter-02569B?style=flat-square&logo=flutter&logoColor=white) ![Swift](https://img.shields.io/badge/-Swift-F05138?style=flat-square&logo=swift&logoColor=white) ![Android Studio](https://img.shields.io/badge/-Android_Studio-3DDC84?style=flat-square&logo=androidstudio&logoColor=white) |
| **4** | **Data Scientist** | ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat-square&logo=python&logoColor=white) ![R](https://img.shields.io/badge/-R-276DC3?style=flat-square&logo=r&logoColor=white) ![Julia](https://img.shields.io/badge/-Julia-9558B2?style=flat-square&logo=julia&logoColor=white) ![VenvStudio](https://img.shields.io/badge/-VenvStudio-4B8BBE?style=flat-square&logo=python&logoColor=white) ![Streamlit](https://img.shields.io/badge/-Streamlit-FF4B4B?style=flat-square&logo=streamlit&logoColor=white) ![Conda](https://img.shields.io/badge/-Conda-44A833?style=flat-square&logo=anaconda&logoColor=white) |
| **5** | **AI / ML Engineer** | ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat-square&logo=python&logoColor=white) ![Mojo](https://img.shields.io/badge/-Mojo-FF7000?style=flat-square) ![Rust](https://img.shields.io/badge/-Rust-000?style=flat-square&logo=rust&logoColor=white) ![Cursor](https://img.shields.io/badge/-Cursor-000?style=flat-square) ![VenvStudio](https://img.shields.io/badge/-VenvStudio-4B8BBE?style=flat-square&logo=python&logoColor=white) ![FastAPI](https://img.shields.io/badge/-FastAPI-009688?style=flat-square&logo=fastapi&logoColor=white) |
| **6** | **Systems Programmer** | ![C++](https://img.shields.io/badge/-C++-00599C?style=flat-square&logo=cplusplus&logoColor=white) ![Rust](https://img.shields.io/badge/-Rust-000?style=flat-square&logo=rust&logoColor=white) ![Zig](https://img.shields.io/badge/-Zig-F7A41D?style=flat-square&logo=zig&logoColor=black) ![Go](https://img.shields.io/badge/-Go-00ADD8?style=flat-square&logo=go&logoColor=white) ![CMake](https://img.shields.io/badge/-CMake-064F8C?style=flat-square&logo=cmake&logoColor=white) |
| **7** | **Full Stack .NET** | ![C#](https://img.shields.io/badge/-C%23-512BD4?style=flat-square&logo=csharp&logoColor=white) ![Node.js](https://img.shields.io/badge/-Node.js-339933?style=flat-square&logo=nodedotjs&logoColor=white) ![React](https://img.shields.io/badge/-React-61DAFB?style=flat-square&logo=react&logoColor=black) ![Blazor](https://img.shields.io/badge/-Blazor-512BD4?style=flat-square&logo=blazor&logoColor=white) ![Visual Studio](https://img.shields.io/badge/-VS-5C2D91?style=flat-square&logo=visualstudio&logoColor=white) |
| **8** | **Game Developer** | ![C++](https://img.shields.io/badge/-C++-00599C?style=flat-square&logo=cplusplus&logoColor=white) ![C#](https://img.shields.io/badge/-C%23-512BD4?style=flat-square&logo=csharp&logoColor=white) ![Lua](https://img.shields.io/badge/-Lua-2C2D72?style=flat-square&logo=lua&logoColor=white) ![Rider](https://img.shields.io/badge/-Rider-000?style=flat-square&logo=rider&logoColor=white) |

### Specialized

| # | Profile | What You Get |
|:-:|---------|-------------|
| **9** | **DevOps / Cloud** | ![Go](https://img.shields.io/badge/-Go-00ADD8?style=flat-square&logo=go&logoColor=white) ![Rust](https://img.shields.io/badge/-Rust-000?style=flat-square&logo=rust&logoColor=white) ![Docker](https://img.shields.io/badge/-Docker-2496ED?style=flat-square&logo=docker&logoColor=white) ![Terraform](https://img.shields.io/badge/-Terraform-7B42BC?style=flat-square&logo=terraform&logoColor=white) ![K8s](https://img.shields.io/badge/-K8s-326CE5?style=flat-square&logo=kubernetes&logoColor=white) ![Helm](https://img.shields.io/badge/-Helm-0F1689?style=flat-square&logo=helm&logoColor=white) |
| **10** | **Blockchain / Web3** | ![Solidity](https://img.shields.io/badge/-Solidity-363636?style=flat-square&logo=solidity&logoColor=white) ![Rust](https://img.shields.io/badge/-Rust-000?style=flat-square&logo=rust&logoColor=white) ![TypeScript](https://img.shields.io/badge/-TS-3178C6?style=flat-square&logo=typescript&logoColor=white) ![Cursor](https://img.shields.io/badge/-Cursor-000?style=flat-square) |
| **11** | **Embedded / IoT** | ![C++](https://img.shields.io/badge/-C++-00599C?style=flat-square&logo=cplusplus&logoColor=white) ![Rust](https://img.shields.io/badge/-Rust-000?style=flat-square&logo=rust&logoColor=white) ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat-square&logo=python&logoColor=white) ![Lua](https://img.shields.io/badge/-Lua-2C2D72?style=flat-square&logo=lua&logoColor=white) |
| **12** | **Scientific Computing** | ![Fortran](https://img.shields.io/badge/-Fortran-734F96?style=flat-square&logo=fortran&logoColor=white) ![Python](https://img.shields.io/badge/-Python-3776AB?style=flat-square&logo=python&logoColor=white) ![R](https://img.shields.io/badge/-R-276DC3?style=flat-square&logo=r&logoColor=white) ![Julia](https://img.shields.io/badge/-Julia-9558B2?style=flat-square&logo=julia&logoColor=white) ![Haskell](https://img.shields.io/badge/-Haskell-5D4F85?style=flat-square&logo=haskell&logoColor=white) |
| **13** | **Functional** | ![Haskell](https://img.shields.io/badge/-Haskell-5D4F85?style=flat-square&logo=haskell&logoColor=white) ![Elixir](https://img.shields.io/badge/-Elixir-4B275F?style=flat-square&logo=elixir&logoColor=white) ![Erlang](https://img.shields.io/badge/-Erlang-A90533?style=flat-square&logo=erlang&logoColor=white) ![OCaml](https://img.shields.io/badge/-OCaml-EC6813?style=flat-square&logo=ocaml&logoColor=white) ![Scala](https://img.shields.io/badge/-Scala-DC322F?style=flat-square&logo=scala&logoColor=white) ![Gleam](https://img.shields.io/badge/-Gleam-FFAFF3?style=flat-square) |
| **14** | **JVM Ecosystem** | ![Java](https://img.shields.io/badge/-Java-ED8B00?style=flat-square&logo=openjdk&logoColor=white) ![Kotlin](https://img.shields.io/badge/-Kotlin-7F52FF?style=flat-square&logo=kotlin&logoColor=white) ![Scala](https://img.shields.io/badge/-Scala-DC322F?style=flat-square&logo=scala&logoColor=white) ![Groovy](https://img.shields.io/badge/-Groovy-4298B8?style=flat-square&logo=apachegroovy&logoColor=white) ![IntelliJ](https://img.shields.io/badge/-IntelliJ-000?style=flat-square&logo=intellijidea&logoColor=white) |
| **15** | **Minimalist** | ![Go](https://img.shields.io/badge/-Go-00ADD8?style=flat-square&logo=go&logoColor=white) ![Rust](https://img.shields.io/badge/-Rust-000?style=flat-square&logo=rust&logoColor=white) ![Neovim](https://img.shields.io/badge/-Neovim-57A143?style=flat-square&logo=neovim&logoColor=white) ![Vim](https://img.shields.io/badge/-Vim-019733?style=flat-square&logo=vim&logoColor=white) ![Emacs](https://img.shields.io/badge/-Emacs-7F5AB6?style=flat-square&logo=gnuemacs&logoColor=white) |

| **16** | **Custom** | Choose your own languages, IDEs, tools, and frameworks |
| **17** | **EVERYTHING** | All 39 languages, 23 IDEs, 38+ frameworks (with safety warnings) |

---

## Package Managers

CodeReady uses the best available package manager on each platform.

| Platform | Priority Order |
|----------|---------------|
| ![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat-square&logo=windows&logoColor=white) | **winget** → **Scoop** → **Chocolatey** |
| ![macOS](https://img.shields.io/badge/macOS-000?style=flat-square&logo=apple&logoColor=white) | **Homebrew** → **MacPorts** → **Nix** |
| ![Linux](https://img.shields.io/badge/Linux-FCC624?style=flat-square&logo=linux&logoColor=black) | **apt/dnf/pacman/zypper** → **Nix** → **Flatpak** → snap |

Special installers: `nvm` for Node.js, `rustup` for Rust, `SDKMAN` for Kotlin/Groovy, `GHCup` for Haskell, `choosenim` for Nim, `opam` for OCaml.

---

## How It Works

```
 ┌─────────────────────────────────────────────────────────┐
 │  1. System scan — detect installed software & versions  │
 │  2. Select profile(s) or custom setup                   │
 │  3. Pick programming languages                          │
 │  4. Choose version for each language                    │
 │  5. Select IDEs and editors                             │
 │  6. Pick developer tools                                │
 │  7. Choose frameworks, libraries and package managers   │
 │  8. Review installation plan                            │
 │  9. Confirm -> CodeReady installs everything            │
 │ 10. Auto-reload shell -> tools work immediately         │
 │ 11. Summary: succeeded / failed / log file              │
 └─────────────────────────────────────────────────────────┘
```

### Safety Features

- **Skip installed** — already have it? Skipped automatically
- **Safe repo install** — if a repo-based install fails, the repo and GPG key are cleaned up
- **Debian/Ubuntu detection** — Docker and other repo tools use the correct distro name
- **Non-blocking failures** — one failed package doesn't stop the rest
- **Full log** — everything is logged to `~/codeready_install.log`

---

## Project Structure

```
CodeReady/
├── codeready.bat           # Windows launcher (auto-elevates to Admin)
├── codeready.ps1           # Windows PowerShell script
├── codeready.sh            # Linux/macOS bash script
├── codeready_todo.md       # Development roadmap
└── README.md
```

---

## Requirements

| Platform | Requirements |
|----------|-------------|
| ![Windows](https://img.shields.io/badge/-Win-0078D6?style=flat-square&logo=windows&logoColor=white) | Windows 10/11, Administrator privileges, Internet |
| ![macOS](https://img.shields.io/badge/-Mac-000?style=flat-square&logo=apple&logoColor=white) | macOS 12+, Internet |
| ![Linux](https://img.shields.io/badge/-Linux-FCC624?style=flat-square&logo=linux&logoColor=black) | Ubuntu 20.04+ / Debian 11+ / Fedora 36+ / Arch / openSUSE, sudo, Internet |

---

## Coming Soon

CodeReady is actively growing. Here's what's planned for upcoming releases. See the full [Roadmap](codeready_todo.md) for details.

### Databases (v2.2)

<p>
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=flat-square&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/MySQL-4479A1?style=flat-square&logo=mysql&logoColor=white" />
  <img src="https://img.shields.io/badge/MariaDB-003545?style=flat-square&logo=mariadb&logoColor=white" />
  <img src="https://img.shields.io/badge/SQLite-003B57?style=flat-square&logo=sqlite&logoColor=white" />
  <img src="https://img.shields.io/badge/MongoDB-47A248?style=flat-square&logo=mongodb&logoColor=white" />
  <img src="https://img.shields.io/badge/Redis-DC382D?style=flat-square&logo=redis&logoColor=white" />
  <img src="https://img.shields.io/badge/Neo4j-4581C3?style=flat-square&logo=neo4j&logoColor=white" />
  <img src="https://img.shields.io/badge/Elasticsearch-005571?style=flat-square&logo=elasticsearch&logoColor=white" />
  <img src="https://img.shields.io/badge/Cassandra-1287B1?style=flat-square&logo=apachecassandra&logoColor=white" />
</p>

Database GUI tools: DBeaver, pgAdmin, MongoDB Compass, Redis Insight, TablePlus

### More Frameworks (v2.2)

<p>
  <img src="https://img.shields.io/badge/Laravel-FF2D20?style=flat-square&logo=laravel&logoColor=white" />
  <img src="https://img.shields.io/badge/Symfony-000000?style=flat-square&logo=symfony&logoColor=white" />
  <img src="https://img.shields.io/badge/Spring_Boot-6DB33F?style=flat-square&logo=springboot&logoColor=white" />
  <img src="https://img.shields.io/badge/Rails-D30001?style=flat-square&logo=rubyonrails&logoColor=white" />
  <img src="https://img.shields.io/badge/Phoenix-FD4F00?style=flat-square&logo=phoenixframework&logoColor=white" />
  <img src="https://img.shields.io/badge/Gin-00ADD8?style=flat-square&logo=go&logoColor=white" />
  <img src="https://img.shields.io/badge/Actix-000000?style=flat-square&logo=rust&logoColor=white" />
  <img src="https://img.shields.io/badge/Axum-000000?style=flat-square&logo=rust&logoColor=white" />
  <img src="https://img.shields.io/badge/Hono-E36002?style=flat-square" />
  <img src="https://img.shields.io/badge/Prisma-2D3748?style=flat-square&logo=prisma&logoColor=white" />
  <img src="https://img.shields.io/badge/WordPress_CLI-21759B?style=flat-square&logo=wordpress&logoColor=white" />
  <img src="https://img.shields.io/badge/Jupyter-F37626?style=flat-square&logo=jupyter&logoColor=white" />
</p>

### LaTeX & Typesetting (v2.2)

<p>
  <img src="https://img.shields.io/badge/TeX_Live-008080?style=flat-square&logo=latex&logoColor=white" />
  <img src="https://img.shields.io/badge/MiKTeX-00796B?style=flat-square&logo=latex&logoColor=white" />
  <img src="https://img.shields.io/badge/Pandoc-1A1A1A?style=flat-square" />
  <img src="https://img.shields.io/badge/latexmk-008080?style=flat-square" />
</p>

### Essential Desktop Tools (v2.2)

<p>
  <img src="https://img.shields.io/badge/7--Zip-00599C?style=flat-square" />
  <img src="https://img.shields.io/badge/KeePassXC-6CAC4D?style=flat-square&logo=keepassxc&logoColor=white" />
  <img src="https://img.shields.io/badge/Firefox_Dev-FF7139?style=flat-square&logo=firefoxbrowser&logoColor=white" />
  <img src="https://img.shields.io/badge/PowerToys-015BFF?style=flat-square&logo=windows&logoColor=white" />
  <img src="https://img.shields.io/badge/Obsidian-7C3AED?style=flat-square&logo=obsidian&logoColor=white" />
  <img src="https://img.shields.io/badge/Alacritty-F46D01?style=flat-square&logo=alacritty&logoColor=white" />
  <img src="https://img.shields.io/badge/OBS_Studio-302E31?style=flat-square&logo=obsstudio&logoColor=white" />
  <img src="https://img.shields.io/badge/Wireshark-1679A7?style=flat-square&logo=wireshark&logoColor=white" />
  <img src="https://img.shields.io/badge/ShareX-2D9FD9?style=flat-square" />
  <img src="https://img.shields.io/badge/ngrok-1F1E37?style=flat-square&logo=ngrok&logoColor=white" />
  <img src="https://img.shields.io/badge/Slack-4A154B?style=flat-square&logo=slack&logoColor=white" />
  <img src="https://img.shields.io/badge/Discord-5865F2?style=flat-square&logo=discord&logoColor=white" />
  <img src="https://img.shields.io/badge/Figma-F24E1E?style=flat-square&logo=figma&logoColor=white" />
</p>

### Terminal Beautification (v2.3)

<p>
  <img src="https://img.shields.io/badge/Starship-DD0B78?style=flat-square&logo=starship&logoColor=white" />
  <img src="https://img.shields.io/badge/Oh_My_Posh-14162B?style=flat-square" />
  <img src="https://img.shields.io/badge/Oh_My_Zsh-1A2C34?style=flat-square" />
  <img src="https://img.shields.io/badge/Nerd_Fonts-000000?style=flat-square" />
  <img src="https://img.shields.io/badge/Catppuccin-EBA0AC?style=flat-square" />
  <img src="https://img.shields.io/badge/Dracula-BD93F9?style=flat-square" />
  <img src="https://img.shields.io/badge/Nord-5E81AC?style=flat-square" />
  <img src="https://img.shields.io/badge/Tokyo_Night-7AA2F7?style=flat-square" />
</p>

### Modern CLI Tools (v2.3)

<p>
  <img src="https://img.shields.io/badge/bat-FCA121?style=flat-square" />
  <img src="https://img.shields.io/badge/eza-4E9A06?style=flat-square" />
  <img src="https://img.shields.io/badge/ripgrep-E44D26?style=flat-square" />
  <img src="https://img.shields.io/badge/fzf-1D1D1D?style=flat-square" />
  <img src="https://img.shields.io/badge/zoxide-F5A623?style=flat-square" />
  <img src="https://img.shields.io/badge/lazygit-FCA121?style=flat-square" />
  <img src="https://img.shields.io/badge/delta-000000?style=flat-square" />
  <img src="https://img.shields.io/badge/jq-B5BD68?style=flat-square" />
  <img src="https://img.shields.io/badge/httpie-73DC8C?style=flat-square" />
  <img src="https://img.shields.io/badge/tldr-259CE6?style=flat-square" />
</p>

### Diagnostics Engine (v2.7)

```
$ codeready --doctor

  [✓] PATH — no duplicates, no broken entries
  [✓] Python — pip3 matches python3
  [!] Node.js — nvm not loaded in .bashrc
  [✗] Docker — daemon not running
  [✓] Git — user.name and user.email configured
  [!] Disk — 4.2 GB free (< 5 GB warning)

  3 passed, 2 warnings, 1 error
  Run: codeready --doctor --fix
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| PowerShell encoding errors | Script uses pure ASCII — save as UTF-8 without BOM |
| Permission denied (Linux) | `chmod +x codeready.sh` |
| Package not found | Check `~/codeready_install.log` for details |
| Command not found after install | Run `source ~/.bashrc` or restart terminal |
| Mojo on Windows | Install WSL 2 first, then Mojo inside WSL |
| Docker fails on Debian | CodeReady auto-detects debian/trixie — uses bookworm repo as fallback |

---

## Contributing

Found a bug? Want to add a new language or framework? Pull requests are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/new-language`)
3. Commit your changes
4. Push and open a Pull Request

See [codeready_todo.md](codeready_todo.md) for the full roadmap.

---

## License

MIT License — see [LICENSE](LICENSE) for details.

---

<p align="center">
  <b>Made with care for developers who value their time.</b><br/>
  <sub>If CodeReady saved you time, consider giving it a ⭐ on GitHub!</sub>
</p>
