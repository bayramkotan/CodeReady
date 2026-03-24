// useApi hook — dual mode: Tauri invoke OR REST API (web server)

const IS_TAURI = typeof window !== "undefined" && window.__TAURI_INTERNALS__;

let tauriInvoke = null;
let tauriListen = null;

if (IS_TAURI) {
  import("@tauri-apps/api/core").then((m) => { tauriInvoke = m.invoke; });
  import("@tauri-apps/api/event").then((m) => { tauriListen = m.listen; });
}

// Web mode: figure out base URL (same origin in production, localhost in dev)
const API_BASE = IS_TAURI ? "" : (window.location.origin === "http://localhost:5173"
  ? "http://127.0.0.1:3500"  // dev mode: Vite on 5173, backend on 3500
  : window.location.origin);  // production: same origin

async function safeFetch(url, options = {}) {
  try {
    const res = await fetch(url, {
      ...options,
      signal: AbortSignal.timeout(5000), // 5s timeout
    });
    if (!res.ok) {
      const text = await res.text().catch(() => "");
      // Check if we got HTML instead of JSON (common when backend is down)
      if (text.startsWith("<!") || text.startsWith("<html")) {
        throw new Error("Backend returned HTML instead of JSON — is the Rust server running?");
      }
      throw new Error(text || `HTTP ${res.status}`);
    }
    const contentType = res.headers.get("content-type") || "";
    if (!contentType.includes("application/json")) {
      const text = await res.text();
      if (text.startsWith("<!") || text.startsWith("<html")) {
        throw new Error("Backend returned HTML instead of JSON — is the Rust server running?");
      }
      // Try parsing as JSON anyway
      return JSON.parse(text);
    }
    return await res.json();
  } catch (e) {
    if (e.name === "AbortError" || e.name === "TimeoutError") {
      throw new Error("Backend not reachable (timeout). Start: cargo run --bin codeready-web");
    }
    if (e.message?.includes("Failed to fetch") || e.message?.includes("NetworkError")) {
      throw new Error("Backend not running. Start: cargo run --bin codeready-web --features web-server --no-default-features");
    }
    throw e;
  }
}

export function useApi() {
  const scanSystem = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("scan_system");
    }
    return await safeFetch(`${API_BASE}/api/scan`);
  };

  const smartInstall = async (name) => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("smart_install", { name });
    }
    const data = await safeFetch(`${API_BASE}/api/install`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    });
    if (data.status === "error") throw new Error(data.message);
    return data.message;
  };

  const getProfiles = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("get_profiles");
    }
    return await safeFetch(`${API_BASE}/api/profiles`);
  };

  const getPackages = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("get_packages");
    }
    return await safeFetch(`${API_BASE}/api/packages`);
  };

  const getOsInfo = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("get_os_info");
    }
    const data = await safeFetch(`${API_BASE}/api/os`);
    return data.os;
  };

  const listenEvent = async (event, callback) => {
    if (IS_TAURI && tauriListen) {
      return await tauriListen(event, (e) => callback(e.payload));
    }
    // Web mode: poll for updates (events not available via REST)
    // In web mode, scan/install are synchronous responses
    return () => {}; // noop unlisten
  };

  return {
    scanSystem,
    smartInstall,
    getProfiles,
    getPackages,
    getOsInfo,
    listenEvent,
    isTauri: IS_TAURI,
  };
}
