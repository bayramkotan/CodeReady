// useApi hook — dual mode: Tauri invoke OR REST API (web server)

const IS_TAURI = typeof window !== "undefined" && window.__TAURI_INTERNALS__;

let tauriInvoke = null;
let tauriListen = null;

if (IS_TAURI) {
  import("@tauri-apps/api/core").then((m) => { tauriInvoke = m.invoke; });
  import("@tauri-apps/api/event").then((m) => { tauriListen = m.listen; });
}

// Web mode: figure out base URL (same origin in production, localhost in dev)
const API_BASE = IS_TAURI ? "" : (window.location.origin || "http://127.0.0.1:3500");

export function useApi() {
  const scanSystem = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("scan_system");
    }
    const res = await fetch(`${API_BASE}/api/scan`);
    if (!res.ok) throw new Error("Scan failed");
    return await res.json();
  };

  const smartInstall = async (name) => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("smart_install", { name });
    }
    const res = await fetch(`${API_BASE}/api/install`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name }),
    });
    const data = await res.json();
    if (data.status === "error") throw new Error(data.message);
    return data.message;
  };

  const getProfiles = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("get_profiles");
    }
    const res = await fetch(`${API_BASE}/api/profiles`);
    return await res.json();
  };

  const getPackages = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("get_packages");
    }
    const res = await fetch(`${API_BASE}/api/packages`);
    return await res.json();
  };

  const getOsInfo = async () => {
    if (IS_TAURI && tauriInvoke) {
      return await tauriInvoke("get_os_info");
    }
    const res = await fetch(`${API_BASE}/api/os`);
    const data = await res.json();
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
