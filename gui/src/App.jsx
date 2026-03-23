import { useState, useEffect, useCallback } from "react";
import { useI18n } from "./hooks/useI18n";
import { useApi } from "./hooks/useApi";
import TitleBar from "./components/TitleBar";
import TerminalPanel from "./components/TerminalPanel";
import ScanView from "./components/ScanView";
import ProfilesView from "./components/ProfilesView";
import "./styles/global.css";

const TABS = ["scan", "languages", "ides", "frameworks", "profiles"];

export default function App() {
  const { lang, setLang, t } = useI18n("en");
  const api = useApi();
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

  // Listen for scan-progress events (Tauri only, web mode gets results synchronously)
  useEffect(() => {
    const setup = async () => {
      const unlisten = await api.listenEvent("scan-progress", (payload) => {
        addLog(payload);
      });
      return unlisten;
    };
    const promise = setup();
    return () => { promise.then((fn) => fn && fn()); };
  }, [addLog, api]);

  // Listen for install-progress events
  useEffect(() => {
    const setup = async () => {
      const unlisten = await api.listenEvent("install-progress", (payload) => {
        const p = payload;
        addLog(`${p.status === "done" ? "[+]" : p.status === "failed" ? "[-]" : "[>]"} ${p.message}`);
        setProgress(p.percent);
      });
      return unlisten;
    };
    const promise = setup();
    return () => { promise.then((fn) => fn && fn()); };
  }, [addLog, api]);

  // Load profiles on mount
  useEffect(() => {
    api.getProfiles().then(setProfiles).catch(console.error);
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
      const result = await api.scanSystem();
      setScanResult(result);
      setProgress(100);
      addLog(`[✓] ${t("scan.complete")} ${result.installed_count}/${result.total} ${t("scan.installed")}.`);
    } catch (e) {
      addLog(`[-] Scan error: ${e}`);
    }
    setScanning(false);
  };

  const handleInstall = async (names) => {
    for (const name of names) {
      addLog(`[>] Installing ${name}...`);
      try {
        const result = await api.smartInstall(name);
        addLog(`[+] ${result}`);
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
