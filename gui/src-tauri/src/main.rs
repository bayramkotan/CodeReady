// CodeReady GUI — Tauri v2 Entry Point
// Uses shared scanner module for scan/install logic

#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod definitions;
mod scanner;

use definitions::get_all_packages;
use scanner::{scan_system_sync, run_install, get_os, InstallRequest};
use tauri::Manager;

// ─── Tauri Commands ──────────────────────────────────────────────

#[tauri::command]
async fn scan_system(app: tauri::AppHandle) -> Result<scanner::ScanResult, String> {
    let result = tokio::task::spawn_blocking(move || {
        let res = scan_system_sync();
        for item in &res.items {
            let status = if item.installed {
                format!("[+] {} {} found", item.name, item.version.as_deref().unwrap_or(""))
            } else {
                format!("[-] {} not found", item.name)
            };
            let _ = app.emit("scan-progress", &status);
        }
        let _ = app.emit("scan-progress", &format!(
            "[✓] Scan complete. {}/{} installed.", res.installed_count, res.total
        ));
        res
    }).await.map_err(|e| format!("Scan error: {}", e))?;
    Ok(result)
}

#[tauri::command]
async fn install_item(app: tauri::AppHandle, request: InstallRequest) -> Result<String, String> {
    let name = request.name.clone();
    let _ = app.emit("install-progress", serde_json::json!({
        "name": &name, "status": "starting",
        "message": format!("Installing {}...", &name), "percent": 0
    }));

    let result = tokio::task::spawn_blocking(move || run_install(&request))
        .await.map_err(|e| format!("Task error: {}", e))?;

    match &result {
        Ok(msg) => {
            let _ = app.emit("install-progress", serde_json::json!({
                "name": &name, "status": "done", "message": msg, "percent": 100
            }));
        }
        Err(e) => {
            let _ = app.emit("install-progress", serde_json::json!({
                "name": &name, "status": "failed", "message": e, "percent": 0
            }));
        }
    }
    result
}

#[tauri::command]
async fn smart_install(app: tauri::AppHandle, name: String) -> Result<String, String> {
    let packages = get_all_packages();
    let pkg = packages.iter().find(|p| p.name == name)
        .ok_or_else(|| format!("Unknown package: {}", name))?;

    let os = get_os();
    let (method, package_id) = pkg.best_method(&os)
        .ok_or_else(|| format!("No install method for {} on {}", name, os))?;

    install_item(app, InstallRequest {
        name,
        method: method.to_string(),
        package_id: package_id.to_string(),
    }).await
}

#[tauri::command]
fn get_profiles() -> Vec<scanner::ProfileDef> {
    scanner::get_profiles()
}

#[tauri::command]
fn get_packages() -> Vec<definitions::PackageDef> {
    get_all_packages()
}

#[tauri::command]
fn get_os_info() -> String {
    get_os()
}

// ─── Main ────────────────────────────────────────────────────────

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            scan_system,
            install_item,
            smart_install,
            get_profiles,
            get_packages,
            get_os_info,
        ])
        .run(tauri::generate_context!())
        .expect("error while running CodeReady");
}
