#!/usr/bin/env bash
# ================================================================
# CodeReady - Package Definitions
# Central lookup table for distro-specific package names.
#
# Format:
#   PKG_MAP["<key>:<manager>"]="<space-separated-package-names>"
#   BREW_MAP["<key>"]="<brew install args>"        # brew formula/cask
#   AUR_MAP["<key>"]="<aur-package-name>"          # Arch AUR fallback
#   FLATPAK_MAP["<key>"]="<flathub-id>"            # Flatpak fallback
#   SNAP_MAP["<key>"]="<snap-name>"                # Snap last-resort fallback
#
# Fallback order (see try_fallback_install in codeready.sh):
#   1. PKG_MAP direct native install
#   2. AUR (only on pacman)
#   3. Flatpak
#   4. Snap (last resort)
#
# Requires: bash 4+ (associative arrays)
# ================================================================

declare -gA PKG_MAP
declare -gA BREW_MAP
declare -gA AUR_MAP
declare -gA FLATPAK_MAP
declare -gA SNAP_MAP
declare -gA CONFIG_MAP

# ================================================================
# LANGUAGES (version-agnostic ones only)
# Version-specific installs (Python 3.13, Java 21, .NET 8, etc.)
# stay in their dedicated install_* functions.
# ================================================================

# --- C/C++ ------------------------------------------------------
PKG_MAP["cpp:apt"]="build-essential gcc g++ gdb cmake"
PKG_MAP["cpp:dnf"]="gcc gcc-c++ gdb cmake make"
PKG_MAP["cpp:pacman"]="base-devel gcc gdb cmake"
PKG_MAP["cpp:zypper"]="gcc gcc-c++ gdb cmake make"
BREW_MAP["cpp"]="gcc llvm cmake"

# --- Fortran ----------------------------------------------------
PKG_MAP["fortran:apt"]="gfortran"
PKG_MAP["fortran:dnf"]="gcc-gfortran"
PKG_MAP["fortran:pacman"]="gcc-fortran"
PKG_MAP["fortran:zypper"]="gcc-fortran"
BREW_MAP["fortran"]="gcc"

# --- D (LDC) ----------------------------------------------------
PKG_MAP["d:apt"]="ldc dub"
PKG_MAP["d:dnf"]="ldc dub"
PKG_MAP["d:pacman"]="ldc dub"
PKG_MAP["d:zypper"]="ldc dub"
BREW_MAP["d"]="ldc dub"

# --- R ----------------------------------------------------------
PKG_MAP["r:apt"]="r-base r-base-dev"
PKG_MAP["r:dnf"]="R"
PKG_MAP["r:pacman"]="r"
PKG_MAP["r:zypper"]="R-base R-base-devel"
BREW_MAP["r"]="r"

# --- Lua --------------------------------------------------------
PKG_MAP["lua:apt"]="lua5.4 liblua5.4-dev luarocks"
PKG_MAP["lua:dnf"]="lua lua-devel luarocks"
PKG_MAP["lua:pacman"]="lua luarocks"
PKG_MAP["lua:zypper"]="lua54 lua54-devel luarocks"
BREW_MAP["lua"]="lua luarocks"

# --- Perl -------------------------------------------------------
PKG_MAP["perl:apt"]="perl cpanminus"
PKG_MAP["perl:dnf"]="perl perl-App-cpanminus"
PKG_MAP["perl:pacman"]="perl cpanminus"
PKG_MAP["perl:zypper"]="perl perl-App-cpanminus"
BREW_MAP["perl"]="perl"

# --- Erlang -----------------------------------------------------
PKG_MAP["erlang:apt"]="erlang"
PKG_MAP["erlang:dnf"]="erlang"
PKG_MAP["erlang:pacman"]="erlang"
PKG_MAP["erlang:zypper"]="erlang"
BREW_MAP["erlang"]="erlang"

# --- Elixir -----------------------------------------------------
PKG_MAP["elixir:apt"]="elixir"
PKG_MAP["elixir:dnf"]="elixir"
PKG_MAP["elixir:pacman"]="elixir"
PKG_MAP["elixir:zypper"]="elixir"
BREW_MAP["elixir"]="elixir"

# --- Haskell (GHCup preferred, this is fallback) ---------------
PKG_MAP["haskell:apt"]="ghc cabal-install"
PKG_MAP["haskell:dnf"]="ghc cabal-install"
PKG_MAP["haskell:pacman"]="ghc cabal-install"
PKG_MAP["haskell:zypper"]="ghc"
BREW_MAP["haskell"]="ghc cabal-install"

# --- Ada (GNAT) -------------------------------------------------
PKG_MAP["ada:apt"]="gnat"
PKG_MAP["ada:dnf"]="gcc-gnat"
PKG_MAP["ada:pacman"]="gcc-ada"
PKG_MAP["ada:zypper"]="gcc-ada"
BREW_MAP["ada"]="gnat"

# --- COBOL (GnuCOBOL) -------------------------------------------
PKG_MAP["cobol:apt"]="gnucobol"
PKG_MAP["cobol:dnf"]="gnucobol"
PKG_MAP["cobol:pacman"]="gnucobol"
PKG_MAP["cobol:zypper"]="gnucobol"
BREW_MAP["cobol"]="gnu-cobol"

# --- Lisp (SBCL) ------------------------------------------------
PKG_MAP["lisp:apt"]="sbcl"
PKG_MAP["lisp:dnf"]="sbcl"
PKG_MAP["lisp:pacman"]="sbcl"
PKG_MAP["lisp:zypper"]="sbcl"
BREW_MAP["lisp"]="sbcl"

# --- Racket -----------------------------------------------------
PKG_MAP["racket:apt"]="racket"
PKG_MAP["racket:dnf"]="racket"
PKG_MAP["racket:pacman"]="racket"
PKG_MAP["racket:zypper"]="racket"
BREW_MAP["racket"]="--cask racket"

# --- Objective-C (GCC ObjC) ------------------------------------
PKG_MAP["objc:apt"]="gobjc gnustep gnustep-devel"
PKG_MAP["objc:dnf"]="gcc-objc gnustep-base-devel"
PKG_MAP["objc:pacman"]="gcc-objc"
PKG_MAP["objc:zypper"]="gcc-objc gnustep-base-devel"
# brew: objc is bundled with Xcode CLT

# --- Crystal ----------------------------------------------------
PKG_MAP["crystal:pacman"]="crystal shards"
PKG_MAP["crystal:dnf"]="crystal shards"
PKG_MAP["crystal:zypper"]="crystal"
BREW_MAP["crystal"]="crystal"

# --- Zig --------------------------------------------------------
PKG_MAP["zig:pacman"]="zig"
PKG_MAP["zig:dnf"]="zig"
BREW_MAP["zig"]="zig"

# ================================================================
# IDEs / EDITORS
# ================================================================

# --- Vim --------------------------------------------------------
PKG_MAP["vim:apt"]="vim"
PKG_MAP["vim:dnf"]="vim-enhanced"
PKG_MAP["vim:pacman"]="vim"
PKG_MAP["vim:zypper"]="vim"
BREW_MAP["vim"]="vim"

# --- Neovim -----------------------------------------------------
PKG_MAP["neovim:apt"]="neovim"
PKG_MAP["neovim:dnf"]="neovim"
PKG_MAP["neovim:pacman"]="neovim"
PKG_MAP["neovim:zypper"]="neovim"
BREW_MAP["neovim"]="neovim"

# --- GNU Emacs --------------------------------------------------
PKG_MAP["emacs:apt"]="emacs"
PKG_MAP["emacs:dnf"]="emacs"
PKG_MAP["emacs:pacman"]="emacs"
PKG_MAP["emacs:zypper"]="emacs"
BREW_MAP["emacs"]="--cask emacs"

# --- JetBrains IDEs (native pkg only via brew, everything else via flatpak/snap)
BREW_MAP["intellij"]="--cask intellij-idea-ce"
FLATPAK_MAP["intellij"]="com.jetbrains.IntelliJ-IDEA-Community"
SNAP_MAP["intellij"]="intellij-idea-community"

BREW_MAP["pycharm"]="--cask pycharm-ce"
FLATPAK_MAP["pycharm"]="com.jetbrains.PyCharm-Community"
SNAP_MAP["pycharm"]="pycharm-community"

BREW_MAP["webstorm"]="--cask webstorm"
FLATPAK_MAP["webstorm"]="com.jetbrains.WebStorm"
SNAP_MAP["webstorm"]="webstorm"

BREW_MAP["goland"]="--cask goland"
FLATPAK_MAP["goland"]="com.jetbrains.GoLand"
SNAP_MAP["goland"]="goland"

BREW_MAP["clion"]="--cask clion"
FLATPAK_MAP["clion"]="com.jetbrains.CLion"
SNAP_MAP["clion"]="clion"

BREW_MAP["rider"]="--cask rider"
FLATPAK_MAP["rider"]="com.jetbrains.Rider"
SNAP_MAP["rider"]="rider"

BREW_MAP["rustrover"]="--cask rustrover"
FLATPAK_MAP["rustrover"]="com.jetbrains.RustRover"
SNAP_MAP["rustrover"]="rustrover"

BREW_MAP["fleet"]="--cask jetbrains-fleet"
FLATPAK_MAP["fleet"]="com.jetbrains.Fleet"
SNAP_MAP["fleet"]="fleet"

# --- Eclipse ----------------------------------------------------
BREW_MAP["eclipse"]="--cask eclipse-jee"
FLATPAK_MAP["eclipse"]="org.eclipse.Java"
SNAP_MAP["eclipse"]="eclipse"

# --- NetBeans ---------------------------------------------------
BREW_MAP["netbeans"]="--cask netbeans"
FLATPAK_MAP["netbeans"]="org.apache.netbeans"
SNAP_MAP["netbeans"]="netbeans"

# --- Android Studio ---------------------------------------------
BREW_MAP["android"]="--cask android-studio"
FLATPAK_MAP["android"]="com.google.AndroidStudio"
SNAP_MAP["android"]="android-studio"

# --- Sublime Text (apt+dnf via repo — special handling; others via fallback)
BREW_MAP["sublime"]="--cask sublime-text"
AUR_MAP["sublime"]="sublime-text-4"
FLATPAK_MAP["sublime"]="com.sublimetext.three"
SNAP_MAP["sublime"]="sublime-text"

# --- Cursor / Windsurf (mostly manual, but AUR available)
BREW_MAP["cursor"]="--cask cursor"
AUR_MAP["cursor"]="cursor-bin"

BREW_MAP["windsurf"]="--cask windsurf"
AUR_MAP["windsurf"]="windsurf-bin"

# --- Zed --------------------------------------------------------
BREW_MAP["zed"]="--cask zed"
AUR_MAP["zed"]="zed"

# --- Antigravity ------------------------------------------------
BREW_MAP["antigravity"]="--cask antigravity"

# ================================================================
# TOOLS
# ================================================================

# --- Git --------------------------------------------------------
PKG_MAP["git:apt"]="git"
PKG_MAP["git:dnf"]="git"
PKG_MAP["git:pacman"]="git"
PKG_MAP["git:zypper"]="git"
BREW_MAP["git"]="git"

# --- CMake ------------------------------------------------------
PKG_MAP["cmake:apt"]="cmake"
PKG_MAP["cmake:dnf"]="cmake"
PKG_MAP["cmake:pacman"]="cmake"
PKG_MAP["cmake:zypper"]="cmake"
BREW_MAP["cmake"]="cmake"

# --- GitHub CLI (gh) --------------------------------------------
# apt keeps custom repo path (see codeready.sh); native fallback here:
PKG_MAP["gh:dnf"]="gh"
PKG_MAP["gh:pacman"]="github-cli"
PKG_MAP["gh:zypper"]="gh"
BREW_MAP["gh"]="gh"

# --- Postman ----------------------------------------------------
BREW_MAP["postman"]="--cask postman"
FLATPAK_MAP["postman"]="com.getpostman.Postman"
SNAP_MAP["postman"]="postman"

# ================================================================
# USER CONFIG PATHS (for uninstall)
# Space-separated paths that a package creates in the user's HOME.
# On uninstall, user is asked whether to remove these too.
# Paths are literal (single-quoted) — expanded at removal time.
# ================================================================

# Version managers / external installers create user-space state
CONFIG_MAP["rust"]='$HOME/.cargo $HOME/.rustup'
CONFIG_MAP["nodejs"]='$HOME/.nvm $HOME/.npm $HOME/.npmrc $HOME/.node-gyp'
CONFIG_MAP["kotlin"]='$HOME/.sdkman'
CONFIG_MAP["java"]='$HOME/.jenv'
CONFIG_MAP["python"]='$HOME/.pyenv $HOME/.local/share/uv $HOME/.cache/pip'
CONFIG_MAP["go"]='$HOME/go $HOME/.config/go'
CONFIG_MAP["ruby"]='$HOME/.rbenv $HOME/.gem'
CONFIG_MAP["php"]='$HOME/.composer'
CONFIG_MAP["dart"]='$HOME/.pub-cache $HOME/.dart $HOME/.dart-tool'
CONFIG_MAP["swift"]='$HOME/.swiftpm'
CONFIG_MAP["julia"]='$HOME/.julia $HOME/.juliaup'
CONFIG_MAP["haskell"]='$HOME/.ghcup $HOME/.cabal $HOME/.stack'
CONFIG_MAP["scala"]='$HOME/.sbt $HOME/.coursier $HOME/.cache/coursier'
CONFIG_MAP["nim"]='$HOME/.nimble $HOME/.choosenim'
CONFIG_MAP["groovy"]='$HOME/.groovy'
CONFIG_MAP["csharp"]='$HOME/.dotnet $HOME/.nuget'
CONFIG_MAP["zig"]='/usr/local/zig-linux'
# Note: leading /usr/local paths are absolute and will require sudo to remove

# ================================================================
# End of definitions.sh
# ================================================================
