import { useState, useEffect, useCallback } from "react";
import { useI18n } from "./hooks/useI18n";
import { useApi } from "./hooks/useApi";
import TitleBar from "./components/TitleBar";
import TerminalPanel from "./components/TerminalPanel";
import ScanView from "./components/ScanView";
import ProfilesView from "./components/ProfilesView";
import "./styles/global.css";

const TABS = ["scan", "languages", "ides", "frameworks", "tools", "profiles"];

export default function App() {
  const { lang, setLang, t } = useI18n("en");
  const api = useApi();
  const [activeTab, setActiveTab] = useState("scan");
  const [scanResult, setScanResult] = useState(null);
  const [profiles, setProfiles] = useState([]);
  const [logs, setLogs] = useState([]);
  const [progress, setProgress] = useState(null);
  const [scanning, setScanning] = useState(false);
  const [target, setTarget] = useState({ type: "local" });
  const [backendOnline, setBackendOnline] = useState(null);

  const addLog = useCallback((line) => {
    setLogs((prev) => [...prev, line]);
  }, []);

  const clearLogs = useCallback(() => setLogs([]), []);

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

  useEffect(() => {
    checkBackend();
  }, []);

  const checkBackend = async () => {
    try {
      await api.getOsInfo();
      setBackendOnline(true);
      addLog("[+] Backend connected");
      api.getProfiles().then(setProfiles).catch(() => {});
      handleScan(true);
    } catch {
      setBackendOnline(false);
      addLog("[!] Backend not running — UI only mode");
    }
  };

  const handleTargetChange = (newTarget) => {
    setTarget(newTarget);
    clearLogs();
    setScanResult(null);
    setProgress(null);

    if (newTarget.type === "local") {
      addLog("[~] Target: localhost");
      if (backendOnline) handleScan(true);
    } else {
      const h = newTarget.host;
      addLog(`[~] Target: ${h.user}@${h.host}:${h.port} (SSH)`);
      addLog("[!] SSH remote requires Rust backend with ssh2 crate");
    }
  };

  const handleScan = async (forceRun = false) => {
    if (!forceRun && !backendOnline && !api.isTauri) {
      addLog("[-] Cannot scan — backend not running");
      return;
    }
    setScanning(true);
    setProgress(0);
    const prefix = target.type === "remote" ? `[${target.host?.label}] ` : "";
    addLog(`${prefix}[~] Scanning system...`);
    try {
      const result = await api.scanSystem();
      setScanResult(result);
      setProgress(100);
      addLog(`${prefix}[+] Scan complete. ${result.installed_count}/${result.total} installed.`);
    } catch (e) {
      addLog(`${prefix}[-] Scan error: ${e.message || e}`);
    }
    setScanning(false);
  };

  const handleInstall = async (names) => {
    if (!backendOnline && !api.isTauri) {
      addLog("[-] Cannot install — backend not running");
      return;
    }
    const prefix = target.type === "remote" ? `[${target.host?.label}] ` : "";
    for (const name of names) {
      addLog(`${prefix}[>] Installing ${name}...`);
      try {
        const result = await api.smartInstall(name);
        addLog(`${prefix}[+] ${result}`);
      } catch (e) {
        addLog(`${prefix}[-] ${name}: ${e.message || e}`);
      }
    }
    handleScan(true);
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
    setActiveTab("scan");
  };

  const getFilteredItems = () => {
    if (!scanResult) return [];
    if (activeTab === "scan") return scanResult.items;
    if (activeTab === "tools") {
      return scanResult.items.filter((i) => i.category === "tool" || i.category === "pkgmanager");
    }
    const categoryMap = {
      languages: "language",
      ides: "ide",
      frameworks: "framework",
    };
    const cat = categoryMap[activeTab];
    return cat ? scanResult.items.filter((i) => i.category === cat) : scanResult.items;
  };

  const fallbackLabels = { scan: "System Scan", languages: "Languages", ides: "IDEs", frameworks: "Frameworks", tools: "Tools", profiles: "Profiles" };

  return (
    <div className="h-screen flex flex-col bg-cr-bg">
      <TitleBar
        lang={lang}
        onToggleLang={setLang}
        target={target}
        onTargetChange={handleTargetChange}
      />

      {/* Header */}
      <div className="px-6 pt-6 pb-4 border-b border-[rgba(255,255,255,0.06)]">
        <div className="flex items-center gap-3 mb-1">
          <span className="text-[20px] font-semibold text-white tracking-wide">
            CodeReady
          </span>
          <span className="text-[11px] bg-white/10 text-cr-muted px-2.5 py-0.5 rounded-full">
            v2.2.0
          </span>
          {backendOnline === false && (
            <span className="text-[10px] bg-cr-red/15 text-cr-red px-2 py-0.5 rounded-full">
              Offline
            </span>
          )}
          {target.type === "remote" && (
            <span className="text-[10px] bg-cr-green/15 text-cr-green px-2 py-0.5 rounded-full">
              SSH: {target.host?.label}
            </span>
          )}
        </div>
        <span className="text-[13px] text-cr-muted">{t("subtitle")}</span>
      </div>

      {/* Tab bar */}
      <div className="flex border-b border-[rgba(255,255,255,0.06)] px-6">
        {TABS.map((tab) => {
          const label = t(`tabs.${tab}`);
          const displayLabel = label.startsWith("tabs.") ? (fallbackLabels[tab] || tab) : label;
          return (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`px-5 py-3 text-[13px] transition border-b-2 ${
                activeTab === tab
                  ? "text-white border-white"
                  : "text-cr-muted border-transparent hover:text-cr-text"
              }`}
            >
              {displayLabel}
            </button>
          );
        })}
      </div>

      {/* Main content */}
      <div className="flex flex-1 overflow-hidden">
        {activeTab === "profiles" ? (
          <ProfilesView profiles={profiles} t={t} onApply={handleApplyProfiles} />
        ) : (
          <ScanView
            items={getFilteredItems()}
            t={t}
            onInstall={handleInstall}
            onRescan={() => handleScan(true)}
            scanning={scanning}
          />
        )}

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
