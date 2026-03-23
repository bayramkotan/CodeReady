// CodeReady Web Server — LAN-accessible GUI
// Run: cargo run --bin codeready-web --features web-server
// Access: http://LOCAL_IP:3500

mod definitions;
mod scanner;

use actix_cors::Cors;
use actix_files as fs;
use actix_web::{web, App, HttpResponse, HttpServer, middleware};
use definitions::{get_all_packages, PackageDef};
use local_ip_address::local_ip;
use scanner::{scan_system_sync, run_install, get_os, get_profiles, InstallRequest, ScanResult};
use serde::Deserialize;

// ─── API Handlers ────────────────────────────────────────────────

async fn api_scan() -> HttpResponse {
    let result = tokio::task::spawn_blocking(scan_system_sync)
        .await
        .unwrap_or_else(|_| ScanResult {
            items: vec![],
            total: 0,
            installed_count: 0,
            missing_count: 0,
        });
    HttpResponse::Ok().json(result)
}

#[derive(Deserialize)]
struct SmartInstallReq {
    name: String,
}

async fn api_smart_install(body: web::Json<SmartInstallReq>) -> HttpResponse {
    let name = body.name.clone();
    let packages = get_all_packages();
    let pkg = match packages.iter().find(|p| p.name == name) {
        Some(p) => p.clone(),
        None => return HttpResponse::BadRequest().json(serde_json::json!({
            "error": format!("Unknown package: {}", name)
        })),
    };

    let os = get_os();
    let (method, package_id) = match pkg.best_method(&os) {
        Some((m, id)) => (m.to_string(), id.to_string()),
        None => return HttpResponse::BadRequest().json(serde_json::json!({
            "error": format!("No install method for {} on {}", name, os)
        })),
    };

    let request = InstallRequest {
        name: name.clone(),
        method,
        package_id,
    };

    let result = tokio::task::spawn_blocking(move || run_install(&request))
        .await
        .unwrap_or_else(|e| Err(format!("Task error: {}", e)));

    match result {
        Ok(msg) => HttpResponse::Ok().json(serde_json::json!({ "status": "ok", "message": msg })),
        Err(e) => HttpResponse::InternalServerError().json(serde_json::json!({ "status": "error", "message": e })),
    }
}

async fn api_profiles() -> HttpResponse {
    HttpResponse::Ok().json(get_profiles())
}

async fn api_packages() -> HttpResponse {
    HttpResponse::Ok().json(get_all_packages())
}

async fn api_os_info() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({ "os": get_os() }))
}

// ─── Main ────────────────────────────────────────────────────────

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let port: u16 = 3500;
    let local_ip = local_ip().unwrap_or_else(|_| "127.0.0.1".parse().unwrap());

    println!();
    println!("  ============================================");
    println!("  CodeReady Web Server v2.1.0");
    println!("  ============================================");
    println!();
    println!("  Local:   http://127.0.0.1:{}", port);
    println!("  Network: http://{}:{}", local_ip, port);
    println!();
    println!("  Any device on your network can access this");
    println!("  URL to scan and install developer tools on");
    println!("  THIS machine.");
    println!();
    println!("  Press Ctrl+C to stop.");
    println!();

    HttpServer::new(|| {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .wrap(cors)
            // API routes
            .route("/api/scan", web::get().to(api_scan))
            .route("/api/install", web::post().to(api_smart_install))
            .route("/api/profiles", web::get().to(api_profiles))
            .route("/api/packages", web::get().to(api_packages))
            .route("/api/os", web::get().to(api_os_info))
            // Serve React frontend (built files from ../dist)
            .service(fs::Files::new("/", "../dist").index_file("index.html"))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
