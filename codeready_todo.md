# CodeReady TODO / Roadmap

> Repository roadmap and outstanding tasks.
> For full project context, see `CodeReady_Handoff.md` in the handoff folder.

---

## Roadmap

| Version | Title | Status |
|---------|-------|--------|
| v2.2 | Frameworks, GUI sync, CachyOS | ✅ Shipped |
| v2.2.1 | Multi-distro pkg_install refactor (definitions.sh) | ✅ Shipped (commit 4702b04) |
| v2.3.0 | Uninstall support (Phase 1) — helpers, dispatcher, action menu, top 4 complex uninstallers | ✅ Shipped |
| v2.3.1 | Uninstall Phase 2a — remaining 20 complex uninstallers wired into dispatcher | ✅ Shipped |
| v2.3.2 | Uninstall Phase 2b — profile-based uninstall (shared resolver, mode submenu, YES-gate) + scan fixes (ready() helper, UNINSTALLED counter, framework versions in scan) | ✅ Shipped |
| v2.3.3 | Cloud CLI support — az, aws, gcloud, aliyun, oci, doctl, hcloud (Huawei/Hetzner clash noted): scan + install + uninstall + maps + DevOps profile | ✅ Shipped |
| v2.3.4 | Uninstall Phase 2c — codeready.ps1 + scanner.rs (GUI) integration + cloud CLI GUI parity (definitions.rs) | Next |
| v2.4 | Admin/sudo-free mode, .bashrc alias polish, ARM/Silicon | Planned |
| v2.5 | Dynamic version from config.json | Planned |
| v2.6 | Profile JSON export/import | Planned |
| v2.7 | Update Manager | Planned |
| v3.0 | Platform Evolution, Docker, CI/CD | Planned |

---

## TODO Items

| # | Item | Priority | Status |
|---|------|----------|--------|
| 1 | ~~**CRITICAL: pkg_install multi-distro** — codeready.sh install functions currently only use `apt`. Must support `pacman -S` (Arch/CachyOS), `dnf install` (Fedora/RHEL), `zypper install` (openSUSE), `brew install` (macOS) for ALL languages, IDEs, tools.~~ | ~~Critical~~ | ✅ **Done (v2.2.1)** — `definitions.sh` + `install_from_map`. New coverage: Cursor/Windsurf/Sublime AUR on Arch, Crystal on dnf/zypper, Racket/Ada/Neovim/Vim/Emacs on zypper. |
| 2 | **Flutter/Dart on Arch** — not in pacman repos, needs AUR (yay/paru) or snap/flatpak or git clone from flutter.dev SDK. Add AUR helper detection + install. | High | Partial (`aur_install` exists; add `flutter` to `AUR_MAP` for auto-fallback) |
| 3 | SSH remote integration | High | Designed, not wired |
| 4 | ~~Uninstall support~~ | ~~High~~ | ✅ **Phase 1 done (v2.3.0)**, ✅ **Phase 2a done (v2.3.1)** — all 24 complex uninstallers implemented. ✅ **Phase 2b done (v2.3.2)** — profile-based uninstall. Remaining: ps1/scanner.rs (v2.3.4) |
| 5 | Language selection at startup (EN/TR) | Medium | GUI done, terminal not |
| 6 | Docker sudo-free + Desktop | Medium | Not started |
| 7 | Profile JSON export/import | Medium | Not started |
| 8 | Dynamic version from config.json | Medium | Not started |
| 9 | Admin/sudo-free mode | High | Not started |
| 10 | Windows ARM + macOS Silicon | Low | Not started |
| 11 | Nix PATH persistence fix | Medium | Not started |
| 12 | useApi.js scope param | Low | Manual 1-line edit |
| 13 | **.bashrc cp alias conflict** — CachyOS `.bashrc` has `alias cp='cp -i'` which blocks scripted `cp`. Use `\cp` or `command cp` in docs/scripts. | Low | Noted |
| 14 | **OS-specific filtering** — Don't show OS-irrelevant items. Notepad++, Visual Studio = Windows only. Xcode = Mac only. Hide them on Linux. Apply to both terminal scan and GUI `definitions.rs`. Easier now that `definitions.sh` centralizes package availability. | High | Not started |
| 15 | **Framework/tool conflict detection** — Warn if conflicting packages selected (e.g. Dart standalone vs Flutter which includes Dart). Prevent double-install or show dependency info. | Medium | Not started |
| 16 | **VenvStudio first in pip frameworks** — In terminal scan output and install menu, VenvStudio should appear before Django/Flask/FastAPI/Streamlit. Already first in `definitions.rs` but not in `codeready.sh`. | High | Not started |
| 17 | **Kotlin SDKMAN fix** — "Installing Kotlin via SDKMAN..." then exits without installing. SDKMAN install may need shell reload or interactive mode. Add pacman/brew fallback. | High | Not started |
| 18 | **Add Flet framework** — flet.dev, Python UI framework. Install: `pip install flet`. Add to pip frameworks in both `codeready.sh` and `definitions.rs`. | Medium | Not started |
| 19 | **Add CustomTkinter framework** — Modern Python GUI. Install: `pip install customtkinter`. Add to pip frameworks in both `codeready.sh` and `definitions.rs`. | Medium | Not started |
| 20 | **OCaml uninstaller** — `ocaml` is not in the dispatcher's complex list and has no `PKG_MAP` entry, so uninstall falls through to "no native mapping". Installed via opam → needs a dedicated `uninstall_ocaml` (remove opam switch dirs `~/.opam`, opam rc lines, native opam package fallback). | Medium | Not started |
