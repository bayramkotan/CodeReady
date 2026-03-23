import { useState, useEffect, useCallback } from "react";
import { invoke } from "@tauri-apps/api/core";
import { listen } from "@tauri-apps/api/event";
import { useI18n } from "./hooks/useI18n";
import TitleBar from "./components/TitleBar";
import TerminalPanel from "./components/TerminalPanel";
import ScanView from "./components/ScanView";
import ProfilesView from "./components/ProfilesView";
import "./styles/global.css";

const TABS = ["scan", "languages", "ides", "frameworks", "profiles"];

export default function App() {
  const { lang, setLang, t } = useI18n("en");
  const [activeTab, setActiveTab] = useState("scan");
  const [scanResult, setScanResult] = useState(null);
  const [profiles, setProfiles] = useState([]);
  const [logs, setLogs] = useState([]);
  const [progress, setProgress] = useState(null);
  const [scanning, setScanning] = useState(false);

  const addLog = useCallback((line) => {
    setLogs((prev) => [...prev, line]);
  }, []);

  const clearLogs = useCallback(() => setLogs([]), []);

  // Listen for scan-progress events from Rust
  useEffect(() => {
    const unlisten = listen("scan-progress", (event) => {
      addLog(event.payload);
    });
    return () => { unlisten.then((fn) => fn()); };
  }, [addLog]);

  // Listen for install-progress events
  useEffect(() => {
    const unlisten = listen("install-progress", (event) => {
      const p = event.payload;
      addLog(`${p.status === "done" ? "[+]" : p.status === "failed" ? "[-]" : "[>]"} ${p.message}`);
      setProgress(p.percent);
    });
    return () => { unlisten.then((fn) => fn()); };
  }, [addLog]);

  // Load profiles on mount
  useEffect(() => {
    invoke("get_profiles").then(setProfiles).catch(console.error);
  }, []);

  // Auto-scan on mount
  useEffect(() => {
    handleScan();
  }, []);

  const handleScan = async () => {
    setScanning(true);
    setProgress(0);
    addLog("[~] " + t("scan.scanning"));
    try {
      const result = await invoke("scan_system");
      setScanResult(result);
      setProgress(100);
      addLog(`[✓] ${t("scan.complete")} ${result.installed_count}/${result.total} ${t("scan.installed")}.`);
    } catch (e) {
      addLog(`[-] Scan error: ${e}`);
    }
    setScanning(false);
  };

  const handleInstall = async (names) => {
    // For now, log selected items — full install logic maps names to package IDs
    for (const name of names) {
      addLog(`[>] Installing ${name}...`);
      try {
        // TODO: Map name → InstallRequest with correct method + package_id
        // This will use the language/IDE/framework definitions
        await invoke("install_item", {
          request: {
            name,
            method: "winget", // placeholder — should be dynamic
            package_id: name.toLowerCase(),
          },
        });
      } catch (e) {
        addLog(`[-] ${name}: ${e}`);
      }
    }
    // Rescan after install
    handleScan();
  };

  const handleApplyProfiles = (profileIds) => {
    const selected = profiles.filter((p) => profileIds.includes(p.id));
    const allItems = new Set();
    for (const p of selected) {
      [...p.languages, ...p.ides, ...p.frameworks, ...p.tools].forEach((i) =>
        allItems.add(i)
      );
    }
    addLog(`[~] Profile applied: ${allItems.size} items selected`);
    // Switch to scan tab and select missing items
    setActiveTab("scan");
  };

  // Filter scan items by tab
  const getFilteredItems = () => {
    if (!scanResult) return [];
    const categoryMap = {
      scan: null, // show all
      languages: "language",
      ides: "ide",
      frameworks: "framework",
    };
    const cat = categoryMap[activeTab];
    return cat ? scanResult.items.filter((i) => i.category === cat) : scanResult.items;
  };

  return (
    <div className="h-screen flex flex-col bg-cr-bg font-mono">
      {/* Title bar */}
      <TitleBar lang={lang} onToggleLang={setLang} />

      {/* Header */}
      <div className="px-6 pt-5 pb-3 border-b border-cr-border">
        <div className="flex items-center gap-3 mb-1">
          <span className="text-xl font-semibold text-cr-accent tracking-[2px]">
            {t("appName")}
          </span>
          <span className="text-[11px] bg-[#1e3a5f] text-cr-blue px-2.5 py-0.5 rounded-full">
            v2.1.0
          </span>
        </div>
        <span className="text-[12px] text-cr-muted">{t("subtitle")}</span>
      </div>

      {/* Tab bar */}
      <div className="flex border-b border-cr-border px-6">
        {TABS.map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab)}
            className={`px-5 py-3 text-[13px] transition border-b-2 ${
              activeTab === tab
                ? "text-cr-accent border-cr-accent"
                : "text-cr-muted border-transparent hover:text-cr-text"
            }`}
          >
            {t(`tabs.${tab}`)}
          </button>
        ))}
      </div>

      {/* Main content */}
      <div className="flex flex-1 overflow-hidden">
        {/* Left panel — content */}
        {activeTab === "profiles" ? (
          <ProfilesView profiles={profiles} t={t} onApply={handleApplyProfiles} />
        ) : (
          <ScanView
            items={getFilteredItems()}
            t={t}
            onInstall={handleInstall}
          />
        )}

        {/* Right panel — terminal */}
        <TerminalPanel
          logs={logs}
          t={t}
          onClear={clearLogs}
          progress={progress}
        />
      </div>
    </div>
  );
}
