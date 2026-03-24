import { useState } from "react";

const IS_TAURI = typeof window !== "undefined" && window.__TAURI_INTERNALS__;

let appWindow = null;
if (IS_TAURI) {
  import("@tauri-apps/api/window").then((m) => {
    appWindow = m.getCurrentWindow();
  });
}

export default function TitleBar({ lang, onToggleLang, target, onTargetChange }) {
  const [showRemoteForm, setShowRemoteForm] = useState(false);
  const [remoteConfig, setRemoteConfig] = useState({
    label: "",
    host: "",
    user: "root",
    port: "22",
    authType: "key",
    keyPath: "~/.ssh/id_ed25519",
  });
  const [savedHosts, setSavedHosts] = useState(() => {
    try {
      return JSON.parse(localStorage.getItem("codeready-hosts") || "[]");
    } catch { return []; }
  });

  const handleTargetSelect = (e) => {
    const val = e.target.value;
    if (val === "add-new") {
      setShowRemoteForm(true);
      return;
    }
    if (val === "localhost") {
      onTargetChange({ type: "local" });
    } else {
      const host = savedHosts.find(h => h.label === val);
      if (host) onTargetChange({ type: "remote", host });
    }
  };

  const handleAddHost = () => {
    if (!remoteConfig.host) return;
    const newHost = {
      label: remoteConfig.label || remoteConfig.host,
      host: remoteConfig.host,
      user: remoteConfig.user || "root",
      port: parseInt(remoteConfig.port) || 22,
      authType: remoteConfig.authType,
      keyPath: remoteConfig.keyPath,
    };
    const updated = [...savedHosts.filter(h => h.label !== newHost.label), newHost];
    setSavedHosts(updated);
    localStorage.setItem("codeready-hosts", JSON.stringify(updated));
    setShowRemoteForm(false);
    onTargetChange({ type: "remote", host: newHost });
    setRemoteConfig({ label: "", host: "", user: "root", port: "22", authType: "key", keyPath: "~/.ssh/id_ed25519" });
  };

  const removeHost = (label) => {
    const updated = savedHosts.filter(h => h.label !== label);
    setSavedHosts(updated);
    localStorage.setItem("codeready-hosts", JSON.stringify(updated));
    if (target?.host?.label === label) {
      onTargetChange({ type: "local" });
    }
  };

  const isLocal = !target || target.type === "local";

  return (
    <>
      <div
        data-tauri-drag-region
        className="flex items-center justify-between px-4 py-2.5 bg-[#1a1a2e] border-b border-cr-border-light"
      >
        {/* Left: traffic lights or WEB MODE */}
        <div className="flex gap-2 items-center">
          {IS_TAURI ? (
            <>
              <button
                onClick={() => appWindow?.close()}
                className="w-3 h-3 rounded-full bg-cr-red hover:brightness-110 transition"
              />
              <button
                onClick={() => appWindow?.minimize()}
                className="w-3 h-3 rounded-full bg-cr-yellow hover:brightness-110 transition"
              />
              <button
                onClick={() => appWindow?.toggleMaximize()}
                className="w-3 h-3 rounded-full bg-cr-green hover:brightness-110 transition"
              />
            </>
          ) : (
            <span className="text-[11px] text-cr-accent">WEB MODE</span>
          )}
        </div>

        {/* Center: Target selector */}
        <div className="flex items-center gap-2">
          <span className="text-[10px] text-cr-muted uppercase tracking-wider">
            TARGET
          </span>
          <select
            value={isLocal ? "localhost" : (target?.host?.label || "localhost")}
            onChange={handleTargetSelect}
            className="bg-[#12122a] border border-cr-border-light rounded px-2 py-1 text-[11px] text-cr-text focus:border-cr-accent focus:outline-none cursor-pointer"
          >
            <option value="localhost">&#x1F5A5; localhost</option>
            {savedHosts.map(h => (
              <option key={h.label} value={h.label}>
                &#x1F310; {h.label} ({h.user}@{h.host})
              </option>
            ))}
            <option value="add-new">+ Remote ekle...</option>
          </select>

          {/* Connection indicator */}
          {!isLocal && (
            <span className="flex items-center gap-1 text-[10px] text-cr-green">
              <span className="w-1.5 h-1.5 bg-cr-green rounded-full animate-pulse" />
              SSH
            </span>
          )}

          <span className="text-[10px] text-cr-muted">|</span>
          <span className="text-xs text-cr-muted">CodeReady v2.2.0</span>
        </div>

        {/* Right: Language toggle */}
        <div className="flex gap-3 text-xs">
          <button
            onClick={() => onToggleLang("en")}
            className={`transition ${lang === "en" ? "text-cr-accent" : "text-cr-muted hover:text-cr-text"}`}
          >
            EN
          </button>
          <button
            onClick={() => onToggleLang("tr")}
            className={`transition ${lang === "tr" ? "text-cr-accent" : "text-cr-muted hover:text-cr-text"}`}
          >
            TR
          </button>
        </div>
      </div>

      {/* Add Remote Host Modal */}
      {showRemoteForm && (
        <div className="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
          <div className="bg-[#0f0f23] border border-cr-border-light rounded-lg p-5 w-[400px]">
            <h3 className="text-sm text-cr-accent mb-4 font-semibold tracking-wide">
              REMOTE HOST EKLE
            </h3>

            <div className="space-y-2.5">
              <div>
                <label className="block text-[10px] text-cr-muted mb-1 uppercase">Etiket</label>
                <input
                  type="text"
                  placeholder="dev-server"
                  value={remoteConfig.label}
                  onChange={(e) => setRemoteConfig({...remoteConfig, label: e.target.value})}
                  className="w-full bg-[#12122a] border border-cr-border-light rounded px-3 py-1.5 text-[12px] text-cr-text focus:border-cr-accent focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-[10px] text-cr-muted mb-1 uppercase">Hostname / IP *</label>
                <input
                  type="text"
                  placeholder="192.168.1.50"
                  value={remoteConfig.host}
                  onChange={(e) => setRemoteConfig({...remoteConfig, host: e.target.value})}
                  className="w-full bg-[#12122a] border border-cr-border-light rounded px-3 py-1.5 text-[12px] text-cr-text focus:border-cr-accent focus:outline-none"
                />
              </div>

              <div className="flex gap-2">
                <div className="flex-1">
                  <label className="block text-[10px] text-cr-muted mb-1 uppercase">User</label>
                  <input
                    type="text"
                    value={remoteConfig.user}
                    onChange={(e) => setRemoteConfig({...remoteConfig, user: e.target.value})}
                    className="w-full bg-[#12122a] border border-cr-border-light rounded px-3 py-1.5 text-[12px] text-cr-text focus:border-cr-accent focus:outline-none"
                  />
                </div>
                <div className="w-20">
                  <label className="block text-[10px] text-cr-muted mb-1 uppercase">Port</label>
                  <input
                    type="text"
                    value={remoteConfig.port}
                    onChange={(e) => setRemoteConfig({...remoteConfig, port: e.target.value})}
                    className="w-full bg-[#12122a] border border-cr-border-light rounded px-3 py-1.5 text-[12px] text-cr-text focus:border-cr-accent focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[10px] text-cr-muted mb-1 uppercase">Auth</label>
                <div className="flex gap-2">
                  {["key", "agent", "password"].map(type => (
                    <button
                      key={type}
                      onClick={() => setRemoteConfig({...remoteConfig, authType: type})}
                      className={`px-3 py-1 text-[11px] rounded border transition ${
                        remoteConfig.authType === type
                          ? "bg-cr-accent/20 border-cr-accent text-cr-accent"
                          : "bg-transparent border-cr-border-light text-cr-muted hover:border-cr-text"
                      }`}
                    >
                      {type === "key" ? "SSH Key" : type === "agent" ? "Agent" : "Password"}
                    </button>
                  ))}
                </div>
              </div>

              {remoteConfig.authType === "key" && (
                <div>
                  <label className="block text-[10px] text-cr-muted mb-1 uppercase">Key Path</label>
                  <input
                    type="text"
                    value={remoteConfig.keyPath}
                    onChange={(e) => setRemoteConfig({...remoteConfig, keyPath: e.target.value})}
                    className="w-full bg-[#12122a] border border-cr-border-light rounded px-3 py-1.5 text-[12px] text-cr-text focus:border-cr-accent focus:outline-none"
                  />
                </div>
              )}
            </div>

            {/* Saved hosts list */}
            {savedHosts.length > 0 && (
              <div className="mt-4 pt-3 border-t border-cr-border-light">
                <span className="text-[10px] text-cr-muted uppercase">Kayitli hostlar</span>
                <div className="mt-1.5 space-y-1">
                  {savedHosts.map(h => (
                    <div key={h.label} className="flex items-center justify-between text-[11px] text-cr-text bg-[#12122a] rounded px-2 py-1">
                      <span>{h.label} — {h.user}@{h.host}:{h.port}</span>
                      <button
                        onClick={() => removeHost(h.label)}
                        className="text-cr-red hover:text-red-400 text-[10px]"
                      >
                        Sil
                      </button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Actions */}
            <div className="flex justify-end gap-2 mt-4">
              <button
                onClick={() => setShowRemoteForm(false)}
                className="px-4 py-1.5 text-[12px] text-cr-muted hover:text-cr-text transition"
              >
                Iptal
              </button>
              <button
                onClick={handleAddHost}
                disabled={!remoteConfig.host}
                className="px-4 py-1.5 text-[12px] bg-cr-accent text-cr-bg rounded hover:bg-cr-accent-hover transition disabled:opacity-40"
              >
                Ekle ve Baglan
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
