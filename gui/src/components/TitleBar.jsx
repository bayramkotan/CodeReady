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
        className="flex items-center justify-between px-5 py-2.5 border-b border-[rgba(255,255,255,0.06)]"
      >
        {/* Left */}
        <div className="flex gap-2 items-center">
          {IS_TAURI ? (
            <>
              <button onClick={() => appWindow?.close()} className="w-3 h-3 rounded-full bg-cr-red hover:brightness-110 transition" />
              <button onClick={() => appWindow?.minimize()} className="w-3 h-3 rounded-full bg-cr-yellow hover:brightness-110 transition" />
              <button onClick={() => appWindow?.toggleMaximize()} className="w-3 h-3 rounded-full bg-cr-green hover:brightness-110 transition" />
            </>
          ) : (
            <span className="text-[11px] text-cr-muted tracking-wider uppercase">Web</span>
          )}
        </div>

        {/* Center: Target selector */}
        <div className="flex items-center gap-3">
          <span className="text-[10px] text-cr-muted uppercase tracking-widest">Target</span>
          <select
            value={isLocal ? "localhost" : (target?.host?.label || "localhost")}
            onChange={handleTargetSelect}
            className="bg-transparent border border-[rgba(255,255,255,0.08)] rounded-md px-3 py-1 text-[11px] text-cr-text focus:border-[rgba(255,255,255,0.25)] focus:outline-none cursor-pointer"
          >
            <option value="localhost">localhost</option>
            {savedHosts.map(h => (
              <option key={h.label} value={h.label}>
                {h.label} ({h.user}@{h.host})
              </option>
            ))}
            <option value="add-new">+ Remote ekle...</option>
          </select>

          {!isLocal && (
            <span className="flex items-center gap-1 text-[10px] text-cr-green">
              <span className="w-1.5 h-1.5 bg-cr-green rounded-full animate-pulse" />
              SSH
            </span>
          )}

          <span className="text-[10px] text-[rgba(255,255,255,0.15)]">|</span>
          <span className="text-[11px] text-cr-muted">CodeReady v2.2.0</span>
        </div>

        {/* Right: Language toggle */}
        <div className="flex gap-3 text-[11px]">
          <button
            onClick={() => onToggleLang("en")}
            className={`transition ${lang === "en" ? "text-white" : "text-cr-muted hover:text-cr-text"}`}
          >
            EN
          </button>
          <button
            onClick={() => onToggleLang("tr")}
            className={`transition ${lang === "tr" ? "text-white" : "text-cr-muted hover:text-cr-text"}`}
          >
            TR
          </button>
        </div>
      </div>

      {/* Add Remote Host Modal */}
      {showRemoteForm && (
        <div className="fixed inset-0 bg-black/70 flex items-center justify-center z-50 backdrop-blur-sm">
          <div className="bg-[#111] border border-[rgba(255,255,255,0.08)] rounded-xl p-6 w-[420px]">
            <h3 className="text-[14px] text-white mb-5 font-medium">
              Add Remote Host
            </h3>

            <div className="space-y-3">
              <div>
                <label className="block text-[11px] text-cr-muted mb-1.5">Label</label>
                <input
                  type="text"
                  placeholder="dev-server"
                  value={remoteConfig.label}
                  onChange={(e) => setRemoteConfig({...remoteConfig, label: e.target.value})}
                  className="w-full bg-[#0a0a0a] border border-[rgba(255,255,255,0.08)] rounded-lg px-3 py-2 text-[13px] text-cr-text focus:border-[rgba(255,255,255,0.25)] focus:outline-none"
                />
              </div>

              <div>
                <label className="block text-[11px] text-cr-muted mb-1.5">Hostname / IP</label>
                <input
                  type="text"
                  placeholder="192.168.1.50"
                  value={remoteConfig.host}
                  onChange={(e) => setRemoteConfig({...remoteConfig, host: e.target.value})}
                  className="w-full bg-[#0a0a0a] border border-[rgba(255,255,255,0.08)] rounded-lg px-3 py-2 text-[13px] text-cr-text focus:border-[rgba(255,255,255,0.25)] focus:outline-none"
                />
              </div>

              <div className="flex gap-3">
                <div className="flex-1">
                  <label className="block text-[11px] text-cr-muted mb-1.5">User</label>
                  <input
                    type="text"
                    value={remoteConfig.user}
                    onChange={(e) => setRemoteConfig({...remoteConfig, user: e.target.value})}
                    className="w-full bg-[#0a0a0a] border border-[rgba(255,255,255,0.08)] rounded-lg px-3 py-2 text-[13px] text-cr-text focus:border-[rgba(255,255,255,0.25)] focus:outline-none"
                  />
                </div>
                <div className="w-24">
                  <label className="block text-[11px] text-cr-muted mb-1.5">Port</label>
                  <input
                    type="text"
                    value={remoteConfig.port}
                    onChange={(e) => setRemoteConfig({...remoteConfig, port: e.target.value})}
                    className="w-full bg-[#0a0a0a] border border-[rgba(255,255,255,0.08)] rounded-lg px-3 py-2 text-[13px] text-cr-text focus:border-[rgba(255,255,255,0.25)] focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] text-cr-muted mb-1.5">Authentication</label>
                <div className="flex gap-2">
                  {["key", "agent", "password"].map(type => (
                    <button
                      key={type}
                      onClick={() => setRemoteConfig({...remoteConfig, authType: type})}
                      className={`px-3 py-1.5 text-[11px] rounded-lg border transition ${
                        remoteConfig.authType === type
                          ? "bg-white/10 border-white/20 text-white"
                          : "bg-transparent border-[rgba(255,255,255,0.06)] text-cr-muted hover:border-white/15"
                      }`}
                    >
                      {type === "key" ? "SSH Key" : type === "agent" ? "Agent" : "Password"}
                    </button>
                  ))}
                </div>
              </div>

              {remoteConfig.authType === "key" && (
                <div>
                  <label className="block text-[11px] text-cr-muted mb-1.5">Key Path</label>
                  <input
                    type="text"
                    value={remoteConfig.keyPath}
                    onChange={(e) => setRemoteConfig({...remoteConfig, keyPath: e.target.value})}
                    className="w-full bg-[#0a0a0a] border border-[rgba(255,255,255,0.08)] rounded-lg px-3 py-2 text-[13px] text-cr-text font-mono focus:border-[rgba(255,255,255,0.25)] focus:outline-none"
                  />
                </div>
              )}
            </div>

            {savedHosts.length > 0 && (
              <div className="mt-5 pt-4 border-t border-[rgba(255,255,255,0.06)]">
                <span className="text-[10px] text-cr-muted uppercase tracking-wider">Saved hosts</span>
                <div className="mt-2 space-y-1">
                  {savedHosts.map(h => (
                    <div key={h.label} className="flex items-center justify-between text-[12px] text-cr-text bg-[#0a0a0a] rounded-lg px-3 py-1.5">
                      <span className="text-cr-muted">{h.label} — {h.user}@{h.host}:{h.port}</span>
                      <button onClick={() => removeHost(h.label)} className="text-cr-red hover:text-red-400 text-[10px]">Remove</button>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="flex justify-end gap-3 mt-5">
              <button
                onClick={() => setShowRemoteForm(false)}
                className="px-4 py-2 text-[12px] text-cr-muted hover:text-cr-text transition rounded-lg"
              >
                Cancel
              </button>
              <button
                onClick={handleAddHost}
                disabled={!remoteConfig.host}
                className="px-5 py-2 text-[12px] bg-white text-black rounded-lg hover:bg-gray-200 transition disabled:opacity-30 font-medium"
              >
                Connect
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
